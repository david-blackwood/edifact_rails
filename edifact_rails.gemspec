# frozen_string_literal: true

require File.expand_path("lib/edifact_rails/version.rb", __dir__)

Gem::Specification.new do |spec|
  spec.name = "edifact_rails"
  spec.version = EdifactRails::VERSION
  spec.authors = "David Blackwood"
  spec.email = "david.blackwood.94@gmail.com"
  spec.summary = "Ruby gem that parses an EDIFACT input into a ruby array structure"
  spec.description = "This gem allows you to pass in a EDIFACT string or file, and returns an array structure, " \
                     "to enable additional processing and validation"
  spec.homepage = "https://github.com/david-blackwood/edifact_rails"
  spec.platform = Gem::Platform::RUBY
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"
  spec.files = Dir[
    "README.md",
    "LICENSE",
    "CHANGELOG.md",
    "lib/**/*.rb",
    "lib/**/*.rake",
    "lokalise_rails.gemspec",
    ".github/*.md",
    "Gemfile"
  ]
  spec.extra_rdoc_files = ["README.md"]

  spec.add_development_dependency "byebug", "~> 11.1"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-performance", "~> 1.17"
  spec.add_development_dependency "rubocop-rspec", "~> 2.20"
  # Testing
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.6"
  spec.add_development_dependency "rspec-rails", "~> 4.0"

  spec.metadata["rubygems_mfa_required"] = "true"
end
