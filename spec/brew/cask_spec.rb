require_relative "../spec_helper"

RSpec.describe Brew::Cask do
  
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

  let(:stdout) {""}

  describe "#search" do

    let(:searchTerm) {"test"}

    subject { 
      allow(Open3).to receive(:popen3).with("brew cask search #{searchTerm}").and_yield(*out)
      described_class.new.search searchTerm 
    }

    let(:stdout) {["==> Exact Match","test1", "==> Partial Matches", "test2"].join("\n")}

    it "calls brew cask command" do
      subject = described_class.new
      expect(Open3).to receive(:popen3).with("brew cask search #{searchTerm}")
      subject.search searchTerm
    end

    it { is_expected.not_to be_nil }
    it { is_expected.to respond_to(:each) }

    it "returns matching results" do
      expect(subject).to include("test1", "test2")
    end

    it "filters matching headers" do
      expect(subject).not_to include("==> Exact Match", "==> Partial Matches")
    end
  end

  describe "#install" do
    it "calls brew cask install with cask name" do
      expect(subject).to receive(:exec).with("brew cask install test/test")
      subject.install "test/test"
    end
  end

  describe "#uninstall" do
    it "calls brew cask uninstall with cask name" do
      expect(subject).to receive(:exec).with("brew cask uninstall test/test")
      subject.uninstall "test/test"
    end
  end

  describe "#list" do
    subject { 
      allow(Open3).to receive(:popen3).with("brew cask list").and_yield(*out)
      described_class.new.list
    }

    it { is_expected.not_to be_nil }
    it { is_expected.to respond_to(:each) }

    it "calls brew cask command" do
      subject = described_class.new
      expect(Open3).to receive(:popen3).with("brew cask list")
      subject.list
    end

    context "when cask returns values" do
      let(:stdout) { ["test1", "test2", "test3"].join("\n") }

      it { is_expected.not_to be_nil }
      it { is_expected.to respond_to(:each) }

      it "returns results" do
        expect(subject).to include("test1", "test2", "test3")
      end
    end
  end
end