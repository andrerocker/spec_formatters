Gem::Specification.new do |spec|
  spec.name        = "spec_formatters"
  spec.version     = "0.1"
  spec.date        = %q{2011-05-26}
  spec.summary     = "TAP and JUnit formatters for rspec"
  spec.authors     = ["Andre Souza"]
  spec.email       = "andre.souza@gmail.com"
  spec.homepage    = "http://github.com/andrerocker/spec_formatters"
  spec.files       = Dir["lib/**/*.rb"]
  spec.test_files  = Dir["spec/**/*spec*.rb"]
  spec.extra_rdoc_files = ["LICENSE", "README.rst"]
  spec.description = <<-EOF
    spec_formatters Provides TAP and JUnit formatters for rspec
  EOF

  spec.add_development_dependency("rspec")
end
