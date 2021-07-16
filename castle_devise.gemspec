# frozen_string_literal: true

require_relative "lib/castle_devise/version"

Gem::Specification.new do |spec|
  spec.name = "castle_devise"
  spec.version = CastleDevise::VERSION
  spec.license = "MIT"
  spec.summary = "Integrates Castle with Devise"
  spec.description = "castle_devise provides out-of-the-box protection against bot registrations and account takeover attacks."
  spec.homepage = "https://github.com/castle/castle_devise"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.authors = ["Kacper Madej", "Johan Brissmyr"]
  spec.email = ["kacper@castle.io"]

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/castle/castle_devise"
  spec.metadata["changelog_uri"] = "https://github.com/castle/castle_devise/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 5.0"
  spec.add_dependency "castle-rb", ">= 7.0", "< 8.0"
  spec.add_dependency "devise", ">= 4.3.0", "< 5.0"

  spec.add_development_dependency "appraisal", "~> 2.3.0"
end
