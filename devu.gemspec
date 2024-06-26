# frozen_string_literal: true

require_relative "lib/devu/version"

Gem::Specification.new do |spec|
  spec.name = "devu"
  spec.version = Devu::VERSION
  spec.platform = Gem::Platform::RUBY
  spec.authors = ["Dan LeGrand"]
  spec.email = ["dan.legrand@proton.me"]

  spec.summary = "Utility scripts for developers"
  spec.description = "DEVeloper Utilities (DEVU) is a collection of utility scripts written in Ruby to help developers."
  spec.homepage = "https://github.com/dlegr250/devu"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "zeitwerk"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
