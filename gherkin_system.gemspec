# frozen_string_literal: true

require_relative "lib/gherkin_system/version"

Gem::Specification.new do |spec|
  spec.name = "gherkin_system"
  spec.version = GherkinSystem::VERSION
  spec.authors = ["David Paluy"]
  spec.email = ["dpaluy@users.noreply.github.com"]

  spec.summary = "Compile Gherkin features into Rails system tests."
  spec.description = "gherkin_system turns Gherkin scenarios into Minitest methods on the " \
                     "application's ApplicationSystemTestCase. Rails owns execution. Gherkin describes behavior."
  spec.homepage = "https://github.com/dpaluy/gherkin_system"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["documentation_uri"] = "https://rubydoc.info/gems/gherkin_system"
  spec.metadata["source_code_uri"] = "https://github.com/dpaluy/gherkin_system"
  spec.metadata["changelog_uri"] = "https://github.com/dpaluy/gherkin_system/blob/master/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/dpaluy/gherkin_system/issues"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[
                        test/ spec/ bin/ Gemfile .gitignore .github/ .rubocop.yml
                        docs/ .agents/ .cursor/ AGENTS.md CLAUDE.md Rakefile .yardopts
                        .ruby-version .tool-versions
                      ])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extra_rdoc_files = Dir["README.md", "CHANGELOG.md", "LICENSE.txt"]

  spec.add_dependency "cucumber-cucumber-expressions", ">= 17", "< 21"
  spec.add_dependency "cucumber-gherkin", ">= 28", "< 40"
  spec.add_dependency "cucumber-tag-expressions", ">= 6", "< 12"
end
