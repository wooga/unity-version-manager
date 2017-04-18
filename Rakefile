# # #
# Get gemspec info

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "json"
require 'octokit'
require 'httpclient'

RSpec::Core::RakeTask.new(:spec)
task :default => :spec do
  `bundle exec codeclimate-test-reporter`
end

gemspec_file = Dir['*.gemspec'].first
gemspec = eval File.read(gemspec_file), binding, gemspec_file
info = "#{gemspec.name} | #{gemspec.version} | " \
       "#{gemspec.runtime_dependencies.size} dependencies | " \
       "#{gemspec.files.size} files"


# # #
# Gem build and install task

desc info
task :gem do
  puts info + "\n\n"
  print "  "; sh "gem build #{gemspec_file}"
  FileUtils.mkdir_p 'pkg'
  FileUtils.mv "#{gemspec.name}-#{gemspec.version}.gem", 'pkg'
end


# # #
# Start an IRB session with the gem loaded

desc "#{gemspec.name} | IRB"
task :irb do
  sh "irb -I ./lib -r #{gemspec.name.gsub '-','/'}"
end

desc "create github release"
task :github_release => :gem do
  name = "#{gemspec.name}-#{gemspec.version}"
  access_token = JSON.parse(File.open(File.expand_path("~/.wooget")).read)["credentials"]["github_token"]

  #create github release
  puts "Preparing github release #{name}"
  git_url = `git remote get-url origin`.chomp.chomp ".git"
  url = git_url.split(":").last
  repo_name = url.split('/').last(2).join("/")

  client = Octokit::Client.new access_token: access_token

  release_options = {
    draft: true,
    name: gemspec.version,
    body: "Release #{gemspec.version}"
  }

  release = client.create_release repo_name, gemspec.version, release_options
  puts "uploading assets"
  client.upload_asset release.url, "pkg/#{name}.gem", {content_type: "application/x-gzip" }
  puts "publishing.."
  client.update_release release.url, {draft: false}
  puts "done"
end
