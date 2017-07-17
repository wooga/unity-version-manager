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
            "install" => true,
            "<version>" => "some version"
          }
        }

        it "throws error" do
          expect { subject.dispatch }.to raise_exception(RuntimeError, "Unknown command")
        end
      end
    end    
  end
end