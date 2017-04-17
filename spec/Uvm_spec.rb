require_relative "spec_helper"
require "rspec/temp_dir"
require "fileutils"

RSpec.describe Uvm do
  describe "#dispatch" do
    let(:command) {}
    let(:options) {}

    subject {described_class.dispatch options}


  end
end

RSpec.describe Uvm::Uvm do
  
  include_context "uses temp dir"

  let(:cmd) {described_class.new}
  let(:options) { {} }

  before(:each) {
    stub_const("Uvm::UNITY_INSTALL_LOCATION", temp_dir)
    stub_const("Uvm::UNITY_LINK", "#{Uvm::UNITY_INSTALL_LOCATION}/Unity")
    stub_const("Uvm::UNITY_CONTENTS", "#{Uvm::UNITY_LINK}/Unity.app/Contents")
  }

  describe "#initialize" do
    subject {cmd}

    it { is_expected.not_to be_nil }

    context "when unity is already installed" do
      include_context "mock a unity installation" do
        let(:unity_version) {"1.0.0f1"}
        let(:linked_version) {false}
      end

      it "moves installation" do
        subject
        expected_install_dir = File.join(Uvm::UNITY_INSTALL_LOCATION, "Unity-#{unity_version}")
        exists = File.exists? expected_install_dir
        expect(exists).to be true
      end

      it "creates link" do
        subject
        symlink = File.symlink? Uvm::UNITY_LINK
        expect(symlink).to be true
      end

      it "activates this version" do
        expect(subject.current).to eql unity_version
      end
    end
  end

  describe "#list" do
    subject {cmd.list(**options)}

    it { is_expected.not_to be_nil }
    it { is_expected.to respond_to(:each) }

    context "when unity version is installed" do
      
      include_context "mock a side unity" do
        let(:unity_version) {"1.0.0f1"}
      end

      it { is_expected.not_to be_empty }

      it "contains all installed versions" do
        expect(subject.size).to eql 1
      end

      it "contains installed unity version" do
        expect(subject).to include(unity_version)
      end
    end

    context "when release and patch versionen are installed" do
      include_context "mock a side unity" do
        let(:unity_version) {["1.0.0f1", "1.0.1p3"]}
      end

      it "contains installed unity versions" do
        expect(subject).to match_array(unity_version)
      end

      it "contains all installed versions" do
        expect(subject.size).to eql 2
      end
    end

    context "when no unity version is installed" do
      it { is_expected.to be_empty }
    end

    context "when unity is activated" do
      include_context "mock a unity installation"

      it "marks active version in output" do
        expect(subject).to include(active_unity + " [active]")
      end
    end
  end

  describe "#use" do
    subject {cmd.use(**options)}
    let(:options) {{version: "1.0.0f1"}}

    context "when version parameter is invalid" do
      let(:options) {{version: "invalid1.2.3xx"}}

      it "throws argument error" do
        expect{subject}.to raise_error( ArgumentError, /Invalid format '.*' - please try .*/)
      end
    end

    context "when version is not available" do
      it "throws runtime error" do
        expect{subject}.to raise_error( RuntimeError, /Invalid version '.*' - version is not available/)
      end
    end

    context "when version is available" do
      include_context "mock a side unity" do
        let(:unity_version) {["1.0.0f1", "1.0.1p3"]}
      end

      context "and another unity version is active" do
        include_context "mock a unity installation" do
          let (:unity_version) {"2.0.0f1"}
        end

        include_context "mock a side unity" do
          let(:unity_version) {["1.0.0f1", "1.0.1p3"]}
        end

        it "removes old link" do
          subject
          expect(File.readlink(Uvm::UNITY_LINK)).not_to include("Unity-2.0.0f1") 
        end

        it "sets new link" do
          subject
          expect(File.readlink(Uvm::UNITY_LINK)).to include("Unity-1.0.0f1")
        end
      end

      context "and version is active" do
        include_context "mock a unity installation" do
          let (:unity_version) {"1.0.0f1"}
        end

        it "throws argument error" do
          expect{subject}.to raise_error( ArgumentError, /Invalid version '.*' - version is already active/)
        end
      end

      context "and no unity version is active" do
        it "sets new link" do
          subject
          expect(File.readlink(Uvm::UNITY_LINK)).to include("Unity-1.0.0f1")
        end
      end
    end
  end

  describe "#clear" do
    subject {cmd.clear(**options)}

    context "when a unity version is activated" do
      
      include_context "mock a unity installation"
      it "removes old link" do
        subject
        expect(File.exists?(Uvm::UNITY_LINK)).not_to be true
      end

      context "and current version is not a symlink"  do
        include_context "mock a unity installation" do
            let (:linked_version) {false}
        end
      end
    end

    context "when no unity version is activated" do
      it "throws runtime error" do
        expect{subject}.to raise_error(RuntimeError, /Invalid operation - no version active/)
      end
    end
  end

  describe "#detect" do
    subject {cmd.detect(**options)}

    context "when working directory contains unity project" do
      let!(:project_version) {
        version = "1.0.0f1"
        project_path = File.join(temp_dir, "ProjectSettings")
        FileUtils.mkdir(project_path)
        File.open(File.join(project_path, "ProjectVersion.txt"), "w") {|f| f.write "m_EditorVersion: #{version}"}
        version
      }

      it "returns project editor version" do
        Dir.chdir(temp_dir) {|_|
          expect(subject).to eql(project_version)
        }
      end
    end

    context "when working dir contains no unity project" do
      it "throws runtime error"  do
        Dir.chdir(temp_dir) {|_|
          expect{subject}.to raise_error(RuntimeError, "Invalid operation - could not detect project")
        }
      end
    end

    context "when project version file is missing/corupted" do
      let!(:project_version) {
        version = "1.0.0f1"
        project_path = File.join(temp_dir, "ProjectSettings")
        FileUtils.mkdir(project_path)
        File.open(File.join(project_path, "ProjectVersion.txt"), "w") {|f| f.write "sddjsdsdj"}
        version
      }

      it "throws runtime error"  do
        Dir.chdir(temp_dir) {|_|
          expect{subject}.to raise_error(RuntimeError, "Invalid operation - could not detect project version")
        }
      end
    end
  end

  describe "#current" do
    subject {cmd.current(**options)}

    context "when a unity version is in use" do
      include_context "mock a unity installation"

      it { is_expected.not_to be_empty }

      it "returns active unity version" do
        expect(subject).to eql(active_unity)
      end
    end

    context "when no unity version is in use" do
      it { is_expected.to be_empty }
    end
  end
end
