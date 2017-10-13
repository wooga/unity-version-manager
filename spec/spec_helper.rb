require "bundler/setup"
require "simplecov"
require "rspec"
SimpleCov.start do
  add_filter "/spec/"
end

require "plist"
require "uvm"
require "uvm/uvm"
require "brew/tap"
require "brew/cask"

def mock_unity_app bundle_version, base_path, app_name="Unity", as_link=false
  link_name = app_name
  if as_link
    app_name = "Unity-#{bundle_version}"
  end

  app_path = File.join base_path, app_name
  link_path = File.join base_path, link_name

  bundle_path = File.join(app_path, 'Unity.app', 'Contents')
  FileUtils.mkdir_p bundle_path
  File.open(File.join(bundle_path,"Info.plist"), "w") do |f|
    f.write({"CFBundleVersion" => bundle_version.to_s }.to_plist)
  end

  if as_link
    FileUtils.ln_s app_path, link_path
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

RSpec.configure do |config|
  original_stderr = $stderr
  original_stdout = $stdout
  config.before(:all) do
    # Redirect stderr and stdout
    $stderr = File.open(File::NULL, "w")
    $stdout = File.open(File::NULL, "w")
  end
  config.after(:all) do
    $stderr = original_stderr
    $stdout = original_stdout
  end
end

RSpec.shared_context "mock stderr stdout" do
  original_stderr = $stderr
  original_stdout = $stdout

  let(:stdout_double) {instance_double(IO, "$stdout", write: true, puts: true)}
  let(:stderr_double) {instance_double(IO, "$stderr", write: true, puts: true)}

  before(:each) do
    $stderr = stderr_double
    $stdout = stdout_double
  end
  
  after(:each) do
    $stderr = original_stderr
    $stdout = original_stdout
  end
end

RSpec.shared_context "mock a unity installation" do
  include_context "uses temp dir"
  let (:unity_version) {"1.0.0f1"}
  let (:linked_version) {true}

  let!(:active_unity) {
    version = unity_version
    mock_unity_app version, temp_dir, "Unity", linked_version
    version
  }
end

RSpec.shared_context "mock a side unity" do
  include_context "uses temp dir"
  let (:unity_version) {"1.0.0f1"}
  
  let!(:unity) {
    version = unity_version
    version = [version] unless version.respond_to? :each
    version.each do |v|
      mock_unity_app v, temp_dir, "Unity-#{v}", false
    end
    version
  }
end

RSpec::Matchers.define :be_a_unity_version do
  match do |actual|
    /(\d+\.\d+\.\d+((f|p|b)\d+)?)$/.match(actual)
  end
end

RSpec::Matchers.define :be_a_beta_version do
  match do |actual|
    actual.include?('b')
  end
end

RSpec::Matchers.define :be_a_patch_version do
  match do |actual|
    actual.include?('p')
  end
end

RSpec::Matchers.define :be_a_release_version do
  match do |actual|
    actual.include?('f')
  end
end
