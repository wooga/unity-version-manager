require_relative "../spec_helper"

RSpec.describe Brew::Cask do
  
  let(:subject) {described_class.new}
  let(:out) {}


  describe "#search" do
    let(:out) {
      stdOut = double(IO)
      allow(stdOut).to receive(:read).and_return(["==> Exact Match","test1", "==> Partial Matches", "test2"].join("\n"))

      response = []
      response << double(IO)
      response << stdOut
      response << double(IO)
      response << '1'
      response
    }

    it "calls brew cask command" do
      searchTerm = "test"
      
      expect(Open3).to receive(:popen3).with("brew cask search #{searchTerm}")
      subject.search searchTerm
    end

    it "returns list of results" do
      searchTerm = "test"
      allow(Open3).to receive(:popen3).with("brew cask search #{searchTerm}").and_yield(*out)

      expect(subject.search searchTerm).to be_kind_of(Array)
    end

    it "returns matching results" do
      searchTerm = "test"
      allow(Open3).to receive(:popen3).with("brew cask search #{searchTerm}").and_yield(*out)
      expect(subject.search searchTerm).to include("test1", "test2")
    end

    it "filters matching headers" do
      searchTerm = "test"
      allow(Open3).to receive(:popen3).with("brew cask search #{searchTerm}").and_yield(*out)
      expect(subject.search searchTerm).not_to include("==> Exact Match", "==> Partial Matches")
    end
  end

  describe "#install" do
    it "calls brew cask command" do
      tool = "testTool"
      expect(Open3).to receive(:popen3).with("brew cask search #{tool}")
      subject.search tool
    end
  end
end