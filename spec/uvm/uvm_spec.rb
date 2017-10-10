require_relative "../spec_helper"
require "rspec/temp_dir"
require "fileutils"

RSpec.describe Uvm::Uvm do

  include_context "uses temp dir"

  let(:tap) {instance_double Brew::Tap, include?: false, add:false, ensure: false }
  let(:cask) {instance_double Brew::Cask, search: [], list: [] }

  let(:cmd) {described_class.new tap:tap, cask:cask}
  let(:options) { {} }

  subject {cmd}

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

        it "returns path to active version" do
          expect(subject).to eql File.join(Uvm::UNITY_INSTALL_LOCATION, "Unity-1.0.0f1")
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

  RSpec.shared_context "launch Unity" do

    include_context "mock a unity installation"

    it "launches active unity" do
      expect(cmd).to receive(:exec)
      subject
    end

    it "passes platform arguments" do
      expect(cmd).to receive(:exec).with(/--args -buildTarget android/)
      subject
    end

  end

  describe "#launch" do
    let(:project_path) {temp_dir}
    let(:platform) {"android"}

    let(:options) {{project_path: project_path, platform: platform}}

    subject {cmd.launch(**options)}

    context "when `project_path` is a Unity project" do
      include_context "launch Unity"

      before :each do
        allow(cmd).to receive(:is_a_unity_project_dir?).and_return(true)
      end

      it "appends project path to Unity invoke command" do
        expect(cmd).to receive(:exec).with(/-projectPath '#{project_path}'/)
        subject
      end
    end

    context "when `project_path` is not a Unity project" do
      include_context "launch Unity"
      it "leaves out project path" do
        expect(cmd).not_to receive(:exec).with(/-projectPath '#{project_path}'/)
        subject
      end
    end
  end

  describe "#install" do

    RSpec.shared_examples "ensure tap" do |parameter|
      let(:expected_tap) {parameter}

      it "ensures correct tap" do
        expect(tap).to receive(:ensure).with(expected_tap)
        allow(cask).to receive(:install)

        subject.install version: version
      end
    end

    let(:version) {"1.2.3f1"}

    context "when version is a beta version" do
      let(:version) {"1.2.3fb"}
      include_examples "ensure tap", "wooga/unityversions-beta"
    end

    context "when version is a patch version" do
      let(:version) {"1.2.3fp"}
      include_examples "ensure tap", "wooga/unityversions-patch"
    end

    context "when version is a release version" do
      include_examples "ensure tap", "wooga/unityversions"
    end

    context "when version is not installed" do

      it "calls install with correct cask name" do

        expected_params = [subject.cask_name_for_type_version("unity", version)]
        expect(cask).to receive(:install).with(*expected_params)

        subject.install version: version
      end

      context "with single support option" do
        [:ios, :android, :webgl, :linux, :windows].each {|i|
          it "calls install with support casks #{i}" do

            expected_params = [
              subject.cask_name_for_type_version("unity", version),
              subject.cask_name_for_type_version(i, version)
            ]
            expect(cask).to receive(:install).with(*expected_params)

            subject.install version: version, i => true
          end
        }
      end

      context "with all support options" do
        it "calls install with all support casks" do
          version = "1.2.3f1"
          expected_params = [
            subject.cask_name_for_type_version("unity", version),
            subject.cask_name_for_type_version("ios", version),
            subject.cask_name_for_type_version("android", version),
            subject.cask_name_for_type_version("webgl", version),
            subject.cask_name_for_type_version("linux", version),
            subject.cask_name_for_type_version("windows", version),
          ]
          expect(cask).to receive(:install).with(*expected_params)

          subject.install version: version, ios: true, android:true, webgl:true, linux:true, windows: true
        end
      end
    end

    context "when version is installed" do
      it "filters unity cask from install call" do
        version = "1.2.3f1"
        allow(cask).to receive(:list).and_return ["unity@#{version}"]
        expected_params = [subject.cask_name_for_type_version("unity", version)]
        expect(cask).not_to receive(:install)

        subject.install version: version
      end

      context "and support version is installed" do
        it "filters support version cask from install call" do
          version = "1.2.3f1"
          allow(cask).to receive(:list).and_return [
            subject.cask_name_for_type_version("unity", version),
            subject.cask_name_for_type_version("webgl", version),
            subject.cask_name_for_type_version("windows", version),
          ]

          expected_params = [
            subject.cask_name_for_type_version("ios", version),
            subject.cask_name_for_type_version("android", version),
            subject.cask_name_for_type_version("linux", version),
          ]
          expect(cask).to receive(:install).with(*expected_params)

          subject.install version: version, ios: true, android:true, webgl:true, linux:true, windows: true
        end
      end
    end
  end

  describe "#uninstall" do
    let(:version) {"1.2.3f1"}

    RSpec.shared_examples "ensure tap" do |parameter|
      let(:expected_tap) {parameter}

      it "ensures correct tap" do
        expect(tap).to receive(:ensure).with(expected_tap)
        allow(cask).to receive(:uninstall)

      subject.uninstall version: version
      end
    end

    context "when version is a beta version" do
      let(:version) {"1.2.3fb"}
      include_examples "ensure tap", "wooga/unityversions-beta"
    end

    context "when version is a patch version" do
      let(:version) {"1.2.3fp"}
      include_examples "ensure tap", "wooga/unityversions-patch"
    end

    context "when version is a release version" do
      include_examples "ensure tap", "wooga/unityversions"
    end

    context "when version is installed" do
      context "and no options are set" do
        context "and no support packages are installed" do
          it "calls uninstall with unity version" do
            list = [
              subject.cask_name_for_type_version("unity", version)
            ]

            allow(cask).to receive(:list).and_return list

            expect(cask).to receive(:uninstall).with(*list)

            subject.uninstall version: version
          end
        end

        context "and support packages are installed" do
          it "calls uninstall with all casks for version" do
            list = [
              subject.cask_name_for_type_version("unity", version),
              subject.cask_name_for_type_version("ios", version),
              subject.cask_name_for_type_version("android", version),
              subject.cask_name_for_type_version("webgl", version),
              subject.cask_name_for_type_version("linux", version),
              subject.cask_name_for_type_version("windows", version),
            ]

            allow(cask).to receive(:list).and_return list

            expect(cask).to receive(:uninstall).with(*list)

            subject.uninstall version: version
          end
        end
      end

      context "and single support option is set" do
        [:ios, :android, :webgl, :linux, :windows].each {|i|
          it "calls uninstall with support casks #{i}" do
            allow(cask).to receive(:list).and_return [
              subject.cask_name_for_type_version("unity", version),
              subject.cask_name_for_type_version(i, version)
            ]

            expected_params = [
              subject.cask_name_for_type_version(i, version)
            ]

            expect(cask).to receive(:uninstall).with(*expected_params)

            subject.uninstall version: version, i => true
          end
        }
      end
    end

    context "when version is not installed" do
      it "will do nothing" do
        version = "1.2.3f1"
        expect(cask).not_to receive(:uninstall)
        subject.uninstall version: version
      end
    end

  end

  describe "#versions" do

    RSpec.shared_examples "ensure tap in #versions" do |expected_tap, h={}|
      let(:expected_tap) {expected_tap}
      let(:flags) { h }

      it "ensures #{expected_tap} tap" do
        expect(tap).to receive(:ensure).with(expected_tap)
        allow(cask).to receive(:search).with("unity").and_return(cask_out)
        subject.versions **flags
      end
    end

    RSpec.shared_examples "expect version list" do |h={}|

      let(:flags) {h}

      before(:each) do
        allow(cask).to receive(:search).with("unity").and_return(cask_out)
      end

      context "when casks available" do
        it "contains at least one item" do
          expect(subject.versions **flags).not_to be_empty
        end

        it "contains unity versions" do
          expect(subject.versions **flags).to all(be_a_unity_version)
        end

        if h.include?(:all)
          it "contains unity release, beta and patch versions" do
            expect(subject.versions **flags).to include(be_a_beta_version)
            expect(subject.versions **flags).to include(be_a_patch_version)
            expect(subject.versions **flags).to include(be_a_release_version)
          end
        elsif h.include?(:beta) and h.include?(:patch)
          it "contains unity beta and patch versions" do
            expect(subject.versions **flags).to include(be_a_beta_version)
            expect(subject.versions **flags).to include(be_a_patch_version)
          end
        elsif h.include?(:beta)
          it "contains unity beta versions" do
            expect(subject.versions **flags).to all(be_a_beta_version)
          end
        elsif h.include?(:patch)
          it "contains unity patch versions" do
            expect(subject.versions **flags).to all(be_a_patch_version)
          end
        else
          it "contains unity release versions" do
            expect(subject.versions **flags).to all(be_a_release_version)
          end
        end
      end

      context "when no casks available" do
        let(:cask_out) {[]}

        it "returns empty list" do
          expect(subject.versions **flags).to be_empty
        end
      end
    end

    it "should not be nil" do
      expect(subject.versions).not_to be_nil
    end

    it "should respond to #each" do
      expect(subject.versions).to respond_to(:each)
    end

    context "when `beta` switch is supplied" do
      include_examples "ensure tap in #versions", "wooga/unityversions-beta", beta: true
      include_examples "expect version list", beta: true
    end

    context "when `patch` switch is supplied" do
      include_examples "ensure tap in #versions", "wooga/unityversions-patch", patch: true
      include_examples "expect version list", patch: true
    end

    context "when `all` switch is supplied" do
      include_examples "ensure tap in #versions", "wooga/unityversions-patch", all: true
      include_examples "ensure tap in #versions", "wooga/unityversions-beta", all: true
      include_examples "ensure tap in #versions", "wooga/unityversions", all: true
      include_examples "expect version list", all: true
    end

    context "when `all` and `patch` switch is supplied" do
      include_examples "ensure tap in #versions", "wooga/unityversions-patch", all: true, patch: true
      include_examples "ensure tap in #versions", "wooga/unityversions-beta", all: true, patch: true
      include_examples "ensure tap in #versions", "wooga/unityversions", all: true, patch: true
      include_examples "expect version list", all: true, patch: true
    end

    context "when `all` and `beta` switch is supplied" do
      include_examples "ensure tap in #versions", "wooga/unityversions-patch", all: true, beta: true
      include_examples "ensure tap in #versions", "wooga/unityversions-beta", all: true, beta: true
      include_examples "ensure tap in #versions", "wooga/unityversions", all: true, beta: true
      include_examples "expect version list", all: true, beta: true
    end

    context "when all switches are supplied" do
      include_examples "ensure tap in #versions", "wooga/unityversions-patch", all: true, beta: true, patch: true
      include_examples "ensure tap in #versions", "wooga/unityversions-beta", all: true, beta: true, patch: true
      include_examples "ensure tap in #versions", "wooga/unityversions", all: true, beta: true, patch: true
      include_examples "expect version list", all: true, beta: true, patch: true
    end

    context "when `beta` and `patch` switch is supplied" do
      include_examples "ensure tap in #versions", "wooga/unityversions-patch", patch: true, beta: true
      include_examples "ensure tap in #versions", "wooga/unityversions-beta", patch: true, beta: true
      include_examples "expect version list", patch: true, beta: true
    end

    context "when no switch is supplied" do
      include_examples "ensure tap in #versions", "wooga/unityversions"
      include_examples "expect version list"
    end

    let(:cask_out) {
      [
        "unity",
        "astah-community",
        "couchbase-server-community",
        "dbeaver-community",
        "unity-android-support-for-editor",
        "unity-android-support-for-editor@2017.1.0b7",
        "unity-android-support-for-editor@2017.1.0f3",
        "unity-android-support-for-editor@5.6.0p2",
        "unity-android-support-for-editor@5.6.2f1",
        "unity-download-assistant",
        "unity-download-assistant@5.6.0p2",
        "unity-download-assistant@5.6.1f1",
        "unity-download-assistant@5.6.1p1",
        "unity-download-assistant@5.6.2f1",
        "unity-ios-support-for-editor",
        "unity-ios-support-for-editor@2017.1.0b7",
        "unity-ios-support-for-editor@2017.1.0f3",
        "unity-ios-support-for-editor@5.6.1f1",
        "unity-ios-support-for-editor@5.6.1p1",
        "unity-ios-support-for-editor@5.6.2f1",
        "unity-linux-support-for-editor",
        "unity-linux-support-for-editor@5.6.1f1",
        "unity-linux-support-for-editor@5.6.1p1",
        "unity-linux-support-for-editor@5.6.2f1",
        "unity-standard-assets",
        "unity-standard-assets@2017.1.0b7",
        "unity-standard-assets@5.6.1f1",
        "unity-standard-assets@5.6.1p1",
        "unity-standard-assets@5.6.2f1",
        "unity-web-player",
        "unity-webgl-support-for-editor@5.6.0p2",
        "unity-webgl-support-for-editor@5.6.1f1",
        "unity-windows-support-for-editor",
        "unity-windows-support-for-editor@2017.1.0b7",
        "unity-windows-support-for-editor@5.6.1p1",
        "unity-windows-support-for-editor@5.6.2f1",
        "unity@5.5.1f3",
        "unity@5.4.2b2",
        "unity@2017.2.1b3",
        "unity@2017.1.0p2",
        "unity@5.4.1p3",
        "unity@5.5.1f1",
        "younity"
      ]
    }
  end
end
