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
    let(:options) {{"<version>" => "1.2.3f1", delegate_method.to_s => true}}
    
    it "calls uvm install/uninstall with version" do
      expect(uvm).to receive(delegate_method).with(version: "1.2.3f1")
      subject.dispatch
    end
    
    [:ios, :android, :webgl, :linux, :windows].each do |i|
      context "with option --#{i}" do
        it "calls uvm install/uninstall  with version and platform support option #{i}" do
          options = {
            "<version>" => "1.2.3f1",
            "--#{i}" => true,
            delegate_method.to_s => true
          }

          subject = described_class.new uvm, options
          expect(uvm).to receive(delegate_method).with(version: "1.2.3f1", i => true)
          subject.dispatch
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
            option => true,
            delegate_method.to_s => true
          }

          subject = described_class.new uvm, options
          expect(uvm).to receive(delegate_method).with(version: "1.2.3f1", **expected_options)
          subject.dispatch
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

  describe "#dispatch_use" do
    include_context "mock stderr stdout"
    let(:options) {{"use" => true, "<version>" => "1.2.3f1"}}

    it "calls uvm use and prints output message" do
      allow(uvm).to receive(:use).and_return("new_path")
      expect(stdout_double).to receive(:puts).with(/Using 1.2.3f1.*new_path/)
      subject.dispatch
    end

    context "when use throws error" do
      before(:each) {
        allow(uvm).to receive(:use).and_raise("random error")
        allow(uvm).to receive(:list).and_return(["1.3.2f1"])
      }

      it "prints help message" do
        expect(stderr_double).to receive(:puts).with(/Version .* isn't available/)
        expect(stderr_double).to receive(:puts).with(duck_type(:each))
        expect { subject.dispatch }.to raise_error(SystemExit)
      end

      it "aborts" do
        expect { subject.dispatch }.to raise_error(SystemExit)
      end      
    end

    context "when use throws ArgumentError" do
      before(:each) {
        allow(uvm).to receive(:use).and_raise(ArgumentError)
      }

      it "aborts" do
        expect { subject.dispatch }.to raise_error(SystemExit)        
      end
    end
  end

  describe "#dispatch_clear" do
    include_context "mock stderr stdout"
    let(:options) {{"clear" => true}}

    it "calls uvm clear" do
      allow(uvm).to receive(:current).and_return("1.2.3f1")
      expect(uvm).to receive(:clear)
      subject.dispatch
    end

    it "prints message" do
      allow(uvm).to receive(:current).and_return("1.2.3f1")
      allow(uvm).to receive(:clear)
      expect(stdout_double).to receive(:puts).with(/Clear active Unity version old:/)
      subject.dispatch
    end

    context "when clear throws Error" do
      before(:each) {
        allow(uvm).to receive(:current).and_return("1.2.3f1")
        allow(uvm).to receive(:clear).and_raise(ArgumentError)
      }

      it "aborts" do
        expect { subject.dispatch }.to raise_error(SystemExit)        
      end
    end
  end

  describe "#dispatch_detect" do
    include_context "mock stderr stdout"
    let(:options) {{"detect" => true}}

    it "calls uvm detect" do
      expect(uvm).to receive(:detect)
      subject.dispatch
    end

    it "prints message" do
      allow(uvm).to receive(:detect).and_return("1.2.3f1")
      expect(stdout_double).to receive(:puts).with("1.2.3f1")
      subject.dispatch
    end

    context "when detect throws Error" do
      before(:each) {
        allow(uvm).to receive(:detect).and_raise(ArgumentError)
      }

      it "aborts" do
        expect { subject.dispatch }.to raise_error(SystemExit)        
      end
    end
  end

  describe "#dispatch_launch" do
    include_context "mock stderr stdout"
    let(:options) {{"launch" => true}}

    ["project-path", "platform"].each do |i|
      context "with option <#{i}>" do
        it "calls uvm launch with #{i.sub("-","_")}" do
          options = {
            "launch" => true,
            "<#{i}>" => "value"
          }

          subject = described_class.new uvm, options
          expect(uvm).to receive(:launch).with(i.sub("-","_").to_sym => "value")
          subject.dispatch
        end
      end
    end
  end

  describe "#dispatch_versions" do
    include_context "mock stderr stdout"
    let(:options) {{"versions" => true}}

    let(:remote_versions) {
      [
        "1.2.3f1",
        "1.3.0f1",
        "1.3.1f1",
      ]
    }

    let(:local_versions) {[]}

    before(:each) {
      allow(uvm).to receive(:versions).and_return(remote_versions)
      allow(uvm).to receive(:list).and_return(local_versions)
    }

    it "prints header" do
      expect(stderr_double).to receive(:puts).with("Available Unity versions:")
      subject.dispatch
    end

    it "prints list of versions" do
      expect(stdout_double).to receive(:puts).with(remote_versions)
      subject.dispatch
    end

    context "when versions are installed" do
      let(:local_versions) {
        [
          "1.3.0f1"
        ]
      }

      it "removes local versions from remote versions" do
        expect(stdout_double).to receive(:puts).with(remote_versions - local_versions)
        subject.dispatch
      end
    end

    context "when versions are empty" do
      let(:local_versions) { remote_versions }
      
      it "removes local versions from remote versions" do
        expect(stderr_double).to receive(:puts).with("None")
        subject.dispatch
      end
    end
  end

  describe "#dispatch_current" do
    include_context "mock stderr stdout"

    let(:options) {{"current" => true}}
    
    it "calls uvm current" do
      expect(uvm).to receive(:current)
      subject.dispatch
    end

    it "prints result" do
      expect(uvm).to receive(:current).and_return("1.2.3f1")
      expect(stdout_double).to receive(:puts).with("1.2.3f1")
      subject.dispatch
    end

    context "when current throws error" do
      it "aborts" do
        allow(uvm).to receive(:current).and_throw
        expect { subject.dispatch }.to raise_error(SystemExit)
      end
    end
  end
end