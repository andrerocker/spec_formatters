require "rubygems"
require "rake"
require "spec/rake/spectask"
require "rubygems/package_task"
require "rake/clean"
$:.unshift File.expand_path "lib"

task :default => :rspec

Spec::Rake::SpecTask.new("rspec") do |t|
  mapper       = { "junit" => "JUnitFormatter", "tap" => "TapFormatter" }
  format       = mapper[ENV["format"]] || "progress"
  formatters   = "spec_formatters"
  t.spec_opts = ["-r \"#{formatters}\"", "-f \"#{format}\""]
  t.pattern    = "spec/**/*_spec.rb"
end

Gem::PackageTask.new(Gem::Specification.load("spec_formatters.gemspec")) do |g|
end
