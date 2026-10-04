# gherkin_system

Compile Gherkin features into Rails system tests.

[![Gem Version](https://badge.fury.io/rb/gherkin_system.svg)](https://badge.fury.io/rb/gherkin_system)
[![ci](https://github.com/dpaluy/gherkin_system/actions/workflows/ci.yml/badge.svg)](https://github.com/dpaluy/gherkin_system/actions/workflows/ci.yml)

Gherkin describes behavior. Rails owns execution. Each scenario becomes a Minitest method on your `ApplicationSystemTestCase`, so Capybara, fixtures, routes, and screenshots stay the ones you already use. cucumber-rails is a separate runner. This gem is not.

## Installation

```ruby
gem "gherkin_system"
```

## Agent skill

For agents writing Gherkin scenarios in a Rails app, install the skill with [`npx skills`](https://www.skills.sh/docs/cli):

```sh
npx skills add dpaluy/gherkin_system
```

Use `-g` for a global install, `-a` to target specific agents, and `-y` to skip prompts. The skill source is [`skills/gherkin-system`](skills/gherkin-system/SKILL.md).

## Configuration

```ruby
# config/initializers/gherkin_system.rb
GherkinSystem.configure do |config|
  config.features = Rails.root.join("features/system/**/*.feature")
  config.base_test_class = ApplicationSystemTestCase
  config.include_steps AuthenticationSteps
  config.strict = true
end
```

| Option | ENV variable | Default |
| --- | --- | --- |
| `features` | | `features/system/**/*.feature` |
| `tags` | `GHERKIN_TAGS` | unset → every scenario is compiled |
| `strict` | | `true`. A broken scenario fails itself. The rest still run |
| `base_test_class` | | required by `load!` when `base:` is omitted |
| `test_file` | | `test/system/gherkin_test.rb` |

`config.tags` / `GHERKIN_TAGS` is a [Cucumber tag expression](https://github.com/cucumber/tag-expressions). Only matching scenarios are compiled into Minitest methods:

```sh
GHERKIN_TAGS="@critical and not @slow" bin/rails test:system
```

Same filter via the CLI: `bin/rails gherkin --tags "@critical and not @slow"` (sets `GHERKIN_TAGS` for that run). Leave it unset to compile every scenario. If the env var stays set, later `bin/rails test:system` runs keep the filter.

## Rails setup

```ruby
# test/system/gherkin_test.rb
require "application_system_test_case"
require "gherkin_system/rails"

GherkinSystem.load!(base: ApplicationSystemTestCase)
```

Generated tests subclass the class you pass. The gem does not install its own system-test superclass.

## Steps

```ruby
module AuthenticationSteps
  extend GherkinSystem::Steps

  Given("I am signed in") do
    sign_in users(:customer)
  end

  When("I purchase the {string} plan") do |plan|
    visit plans_path
    click_on plan
  end

  Then(/^I have (\d+) products$/) do |count|
    assert_equal count.to_i, Product.count
  end

  ParameterType(
    name: "user",
    regexp: /alice|bob/,
    type: User,
    transformer: ->(name) { users(name.to_sym) }
  )
end
```

`Given`, `When`, `Then`, `And`, and `But` share one registry. Blocks run with `instance_exec` on the system test, so instance variables set in one step are visible in the next.

## Hooks

```ruby
module CheckoutHooks
  extend GherkinSystem::Hooks

  Before do
  end

  Before("@admin") do
  end

  After do |scenario|
  end

  Around("@external") do |scenario|
    scenario.run
  end
end
```

Rails `setup` runs first. Gherkin hooks and steps run inside the test method. Rails `teardown` and failure screenshots run after.

## Commands

```sh
bin/rails gherkin
bin/rails gherkin features/system/checkout.feature
bin/rails gherkin features/system/checkout.feature:42
bin/rails gherkin --tags "@critical and not @slow"
bin/rails gherkin:check
bin/rails gherkin:list
```

`gherkin:check` parses features and resolves steps. It does not start a browser. `bin/rails test:system` and `bin/rails test:all` run the generated tests as normal Minitest tests.

Tag filters use [Cucumber tag expressions](https://github.com/cucumber/tag-expressions).

## Error handling

```ruby
begin
  GherkinSystem.load!(base: ApplicationSystemTestCase)
rescue GherkinSystem::ConfigurationError => e
  warn e.message
rescue GherkinSystem::CompilationError => e
  warn e.message
end
```

| Class | When |
| --- | --- |
| `ConfigurationError` | Missing base class or test file |
| `CompilationError` | Invalid Gherkin, tag expression, or hook |
| `UndefinedStep` | No definition matches the step |
| `AmbiguousStep` | More than one definition matches |
| `DuplicateStep` | The same pattern is registered twice |
| `StepFailure` | A step raised. `cause` is the original exception |

Undefined and ambiguous steps raise in `before_setup`, before the driver starts. The message names the feature, scenario, step, feature line, and a suggested definition.

## Development

```sh
bin/setup
bundle exec rake
bundle exec rake test
bundle exec rubocop
```

## Contributing

Issues and pull requests: [github.com/dpaluy/gherkin_system](https://github.com/dpaluy/gherkin_system/issues).

## License

MIT. See [LICENSE.txt](LICENSE.txt).

Supported by [Majestic Labs](https://majesticlabs.dev/).
