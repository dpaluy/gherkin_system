# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-10-04

### Changed

- Default feature discovery uses `features/**/*.feature`; existing `features/system/` files remain included
- Install and feature generators write directly under `features/`

## [0.1.1] - 2026-10-04

### Added

- `bin/rails g gherkin_system:install` scaffolds the loader, `features/system/`, and `test/support/gherkin/`
- `bin/rails g gherkin_system:feature NAME` and `bin/rails g gherkin_system:steps NAME`

### Fixed

- Step assertion failures (`flunk` / `assert`) now wrap in `StepFailure` with feature, step, and line
- `StepFailure` subclasses `Minitest::Assertion` so Capybara and other step errors report as Failures
- Failure messages include `bin/rails gherkin path/to.feature:LINE` for rerun
- Directory paths in `bin/rails gherkin PATH` select features under that directory; unmatched path/line filters raise instead of compiling nothing
- Nested step generators create the enclosing namespaces, so generated files load without existing modules
- Step skips remain Minitest skips, and wrapped failures appear in Minitest summary counts
- Generator tests remove their temporary Ruby files after each test, so test order cannot cause RuboCop failures

## [0.1.0] - 2026-10-03

### Initial Release

- Compile Gherkin features into Minitest methods on the application's system test class
- Cucumber Expressions, regex step definitions, and custom parameter types
- Before, After, and Around hooks, tags, data tables, and doc strings
- `bin/rails gherkin`, `gherkin:check`, and `gherkin:list`
