require_relative "../spec_helper"

RSpec.describe Brew::Tap do
  let(:subject) {described_class.new}
  
  describe "#include?" do
    it "returns true when tap is available" do
      stdOut = double(IO)
      allow(stdOut).to receive(:read).and_return(["test/test","tap/test","test/tap"].join("\n"))

      response = []
      response << double(IO)
      response << stdOut
      response << double(IO)
      response << '1'

      allow(Open3).to receive(:popen3).with("brew tap").and_yield(*response)

      expect(subject.include? "test/test").to be_truthy
    end

    it "returns false when tap is available" do
      stdOut = double(IO)
      allow(stdOut).to receive(:read).and_return(["test/test","tap/test","test/tap"].join("\n"))

      response = []
      response << double(IO)
      response << stdOut
      response << double(IO)
      response << '1'

      allow(Open3).to receive(:popen3).with("brew tap").and_yield(*response)

      expect(subject.include? "test/test2").not_to be_truthy
    end
  end

  describe "#add" do
    it "calls brew tap with tap name to add tap" do
      expect(subject).to receive(:system).with("brew tap test/test")
      subject.add "test/test"
    end
  end
end