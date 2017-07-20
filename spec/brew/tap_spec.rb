require_relative "../spec_helper"

RSpec.describe Brew::Tap do
  let(:subject) {described_class.new}

  let(:out) {
    stdOut = double(IO)
      allow(stdOut).to receive(:read).and_return(stdout)

      response = []
      response << double(IO)
      response << stdOut
      response << double(IO)
      response << '1'
      response
  }

  let(:stdout) {["test/test","tap/test","test/tap"].join("\n")}
  let(:tap_name) {""}

  before(:each) {
    allow(Open3).to receive(:popen3).with("brew tap").and_yield(*out)
  }
  
  describe "#include?" do
    
    subject {
      described_class.new.include? tap_name
    }

    context "when tap is available" do
      let(:tap_name) {"test/test"}

      it { is_expected.to be_truthy }
    end

    context "when tap is not available" do
      let(:tap_name) {"test/test2"}

      it { is_expected.not_to be_truthy }
    end

  end

  describe "#add" do
    it "calls brew tap with tap name to add tap" do
      expect(subject).to receive(:system).with("brew tap test/test")
      subject.add "test/test"
    end
  end

  describe "#ensure" do
    context "when tap is added" do
      let(:tap_name) {"test/test"}

      it "does nothing" do
        expect(subject).not_to receive(:system).with("brew tap #{tap_name}")
        subject.ensure tap_name
      end
    end

    context "when tap is not added" do
      let(:tap_name) {"test/test2"}

      it "calls add" do
        expect(subject).to receive(:system).with("brew tap #{tap_name}")
        subject.ensure tap_name
      end
    end
  end
end