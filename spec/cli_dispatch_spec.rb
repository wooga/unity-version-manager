require_relative "spec_helper"

RSpec.describe Uvm::CLIDispatch do

  let(:uvm) {double(Uvm::Uvm)}
  let(:options) {{}}
  let(:subject) {described_class.new uvm, options }

  it { is_expected.not_to be_nil }

  context "#dispatch" do
    context "when options are empty" do
      it "throws error" do
        expect { subject.dispatch }.to raise_exception(RuntimeError, "No options provided")
      end
    end

    context "when options are nil" do
      let(:options) {nil}
      it "throws error" do
        expect { subject.dispatch }.to raise_exception(RuntimeError, "No options provided")
      end
    end

    context "with valid options" do
      context "and multiple commands in options" do
        let(:options) {
          {
            "clear" => true,
            "use" => true,
            "<version>" => "some version"
          }
        }

        it "breaks after first dispatch" do
          expect(uvm).to receive(:current)
          expect(uvm).to receive(:clear)
          expect(uvm).not_to receive(:use)
          
          subject.dispatch
        end
      end

      context "and unknown command in options" do
        
        let(:options) {
          {
            "disrupt" => true,
            "<version>" => "some version"
          }
        }

        it "throws error" do
          expect { subject.dispatch }.to raise_exception(RuntimeError, "Unknown command")
        end
      end
    end    
  end

  RSpec.shared_context "install/uninstall" do
    let(:options) {{"<version>" => "1.2.3f1"}}
    
    it "calls uvm install/uninstall with version" do
      expect(uvm).to receive(delegate_method).with(version: "1.2.3f1")
      subject.public_send(dispatch_method_name)
    end
    
    [:ios, :android, :webgl, :linux, :windows].each do |i|
      context "with option --#{i}" do
        it "calls uvm install/uninstall  with version and platform support option #{i}" do
          options = {
            "<version>" => "1.2.3f1",
            "--#{i}" => true
          }

          subject = described_class.new uvm, options
          expect(uvm).to receive(delegate_method).with(version: "1.2.3f1", i => true)
          subject.public_send(dispatch_method_name)
        end
      end
    end

    {
      "--mobile" => {ios: true, android: true, webgl: true},
      "--desktop" => {linux: true, windows:true},
      "--all" => {ios: true, android: true, webgl: true, linux: true, windows:true}
    }.each_pair do |option, expected_options|

      context "with meta option #{option}" do
        it "calls uvm install/uninstall  with version and platform support option #{expected_options.keys}" do
          options = {
            "<version>" => "1.2.3f1",
            option => true
          }

          subject = described_class.new uvm, options
          expect(uvm).to receive(delegate_method).with(version: "1.2.3f1", **expected_options)
          subject.public_send(dispatch_method_name)
        end
      end
    end
  end

  describe "#dispatch_install" do
    let(:dispatch_method_name) {"dispatch_install"}
    let(:delegate_method) {:install}
    include_context "install/uninstall"
  end

  describe "#dispatch_uninstall" do
    let(:dispatch_method_name) {"dispatch_uninstall"}
    let(:delegate_method) {:uninstall}
    include_context "install/uninstall"
  end
end