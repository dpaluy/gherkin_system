# gherkin_system

Ruby gem that compiles Gherkin features into Minitest methods on the host application's `ApplicationSystemTestCase`. Entry point: `lib/gherkin_system.rb`. Rails command: `lib/rails/commands/gherkin/gherkin_command.rb`.

Agents adding scenarios in an application follow `skills/gherkin-system/SKILL.md` (install with `npx skills add dpaluy/gherkin_system`). This file is for changing the gem.

## Commands

| Command | Purpose | Mutates |
| --- | --- | --- |
| `bin/setup` | `bundle install` | Local gems |
| `bundle exec rake` | Unit tests, then RuboCop. Same as CI | No |
| `bundle exec rake test` | Unit tests only | No |
| `ruby -Itest test/<file>_test.rb` | One test file | No |
| `bundle exec rubocop` | Style check | No |
| `bundle exec ruby bin/console` | IRB with the gem loaded | No |
| `cd test/dummy && bin/rails gherkin:check` | Dummy acceptance, no browser | Dummy test DB |
| `cd test/dummy && bin/rails test:system` | Dummy scenarios through rack_test | Dummy test DB |
| `gem build gherkin_system.gemspec` | Package. Inspect files before publishing | Writes `*.gem` locally |

`test/dummy` has its own `bundle install`. The root suite does not boot it.

## Layout

| Path | Role |
| --- | --- |
| `lib/gherkin_system/parser.rb` | Only file that reads Cucumber messages. Emits `Scenario` and `Step`. |
| `lib/gherkin_system/feature_loader.rb` | Glob plus `GHERKIN_FEATURES` and `GHERKIN_LINE`. |
| `lib/gherkin_system/tag_filter.rb` | Cucumber tag expressions. |
| `lib/gherkin_system/test_class_builder.rb` | One subclass of `base:` per feature file. One `test_*` method per Pickle. |
| `lib/gherkin_system/executor.rb` | `instance_exec`, hooks, step failures. |
| `lib/gherkin_system/steps.rb` | `Given` / `When` / `Then` / `And` / `But` / `ParameterType`. |
| `lib/gherkin_system/hooks.rb` | `Before` / `After` / `Around`. |
| `lib/gherkin_system/checker.rb` | Static validation used by `gherkin:check`. |
| `lib/rails/commands/gherkin/gherkin_command.rb` | `gherkin`, `gherkin:check`, and `gherkin:list` on one command class. |
| `sig/gherkin_system.rbs` | Public configuration, load, and error surface. Update it with those signatures. |
| `test/dummy` | Rails app that proves system-test integration. |
| `docs/prd.md` | Product requirements. Does not ship in the gem. |

## Boundaries

- Generated tests subclass the `base:` class passed to `GherkinSystem.load!`. Do not introduce `GherkinSystem::TestCase` as the system-test superclass.
- Step blocks run with `instance_exec` on that test instance. Do not `block.call`.
- One Pickle is one Minitest method. Do not run a Scenario Outline inside a single test.
- Parse, expand outlines, and evaluate tags with `cucumber-gherkin`, `cucumber-cucumber-expressions`, and `cucumber-tag-expressions`. Do not reimplement those grammars.
- `gherkin:check` and `gherkin:list` are methods on `Rails::Command::GherkinCommand`. Rails loads the first matching command file and stops, so new subcommands belong in that same file.
- Undefined steps fail in `before_setup` before `super` when `config.strict` is true, so the driver does not start.
- Failures keep the original exception as `StepFailure#cause` and name the feature, scenario, step, feature line, and definition location.
- The published gem excludes `test/`, `docs/`, `.github/`, `.cursor/`, `AGENTS.md`, and `CLAUDE.md`. Check with `gem build`.

## Testing

Unit tests live in `test/*_test.rb` and subclass `GherkinSystemTest`. `setup` clears configuration, registries, generated classes, and `GHERKIN_*` env vars. Register step modules inside the test. A module body that runs at file load is wiped by that reset.

| Change | Prove it with |
| --- | --- |
| Parsing, outlines, tags, tables, doc strings | `test/parser_test.rb` |
| One method per Pickle, superclass, filters | `test/compiler_test.rb` |
| `instance_exec`, hooks, failures | `test/executor_test.rb` |
| `gherkin:check` behavior | `test/checker_test.rb` |
| Rails command and browser boundary | `cd test/dummy && bin/rails gherkin:check` and `bin/rails test:system` |

The dummy uses `driven_by :rack_test`. Do not add a browser driver to prove the compiler.

## Release

- Base branch is `master`.
- Conventional Commits: `feat:`, `fix:`, `chore:`.
- Note user-visible changes in `CHANGELOG.md` before a release.
- CI is `.github/workflows/ci.yml` (Ruby 3.4.5, plus experimental 4.0). Publishing is `.github/workflows/release.yml` on a `v*` tag via trusted publishing.
- Do not publish from a workstation without an explicit request. A tag push is the release path.
