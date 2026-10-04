---
name: gherkin-system
description: >-
  Write and run Rails system tests as Gherkin features with the gherkin_system
  gem. Use when adding or changing user-facing Rails behavior, acceptance
  tests, .feature files, step definitions, or bin/rails gherkin commands.
---

# gherkin_system

Gherkin describes the behavior. Rails runs it. Each scenario becomes a Minitest method on the app's `ApplicationSystemTestCase`.

Do not add cucumber-rails, a Cucumber World, or a second test runner. Do not use this skill to change the gem's own compiler. Gem development follows `AGENTS.md`.

## Add a scenario

1. Scaffold with `bin/rails g gherkin_system:feature NAME` and `bin/rails g gherkin_system:steps NAME` (or write the files by hand under `features/system/**/*.feature` and `test/support/gherkin/*_steps.rb`).
2. Require the steps file from `test/system/gherkin_test.rb` before `GherkinSystem.load!`.
3. Run `bin/rails gherkin:check`.
4. Run the scenario with `bin/rails gherkin path/to/file.feature:LINE`.

Create the loader once if it is missing:

```sh
bin/rails g gherkin_system:install
```

Then require step modules and register them before `load!`:

```ruby
# test/system/gherkin_test.rb
require "application_system_test_case"
require_relative "../support/gherkin/checkout_steps"
require "gherkin_system/rails"

GherkinSystem.configure do |config|
  config.include_steps CheckoutSteps
end

GherkinSystem.load!(base: ApplicationSystemTestCase)
```

`base:` must be the application's system test class. The generated tests subclass it.

## Write behavior

One scenario proves one outcome. Name it for the condition and the result.

```gherkin
Feature: Subscription purchase

  Scenario: Customer purchases Pro
    Given I am signed in
    When I purchase the "Pro" plan
    Then my subscription should be active
```

Use a Scenario Outline only when each row is the same rule with different data. Each row becomes its own test.

Assert the outcome the user was promised. Drive it through the browser and the real application. Do not mock models, controllers, jobs, or mailers to make the scenario pass.

## Bind steps

```ruby
module CheckoutSteps
  extend GherkinSystem::Steps

  Given("I am signed in") do
    sign_in users(:customer)
  end

  When("I purchase the {string} plan") do |plan|
    visit plans_path
    click_on plan
  end

  Then("my subscription should be active") do
    assert_text "Purchase complete"
    assert_predicate users(:customer).reload.subscription, :active?
  end
end
```

- `Given`, `When`, `Then`, `And`, and `But` share one registry.
- Blocks run with `instance_exec` on the system test. `visit`, fixtures, routes, assertions, and `@ivars` are that test instance.
- Call `config.include_steps` when the module also defines helper methods.
- Prefer Cucumber Expressions (`{string}`, `{int}`). Use a regex only to match an existing definition.
- Data tables arrive as an object with `#hashes` (string keys) and `#raw`. Doc strings arrive as the content string.

## Hooks

```ruby
module CheckoutHooks
  extend GherkinSystem::Hooks

  Before("@admin") do
  end

  After do |scenario|
  end

  Around("@external") do |scenario|
    scenario.run
  end
end
```

Require the hook file before `load!`. Rails `setup` runs before these hooks. Rails `teardown` and failure screenshots run after them. An `Around` hook must call `scenario.run`.

## Commands

| Command | Use |
| --- | --- |
| `bin/rails gherkin:check` | Parse and resolve steps. No browser. Run this before executing a scenario. |
| `bin/rails gherkin PATH:LINE` | Run the scenario at that line. |
| `bin/rails gherkin --tags "@critical and not @slow"` | Cucumber tag expression. |
| `bin/rails gherkin:list` | Show compiled scenarios. |
| `bin/rails test:system` | Run every system test, including compiled scenarios. |

`GHERKIN_TAGS` left set in the environment also filters `bin/rails test:system`. Unset it to compile every scenario.

## When check fails

- Undefined step: add the suggested definition, then re-run check.
- Ambiguous step: delete or narrow one of the matching definitions.
- Duplicate pattern: the same string or regex is registered twice.
- Invalid Gherkin or tag expression: the message includes the feature path.

A missing step fails that scenario before the driver starts. Other scenarios still run.

## Done

`gherkin:check` exits 0, and the scenario exits 0 through `bin/rails gherkin` or `bin/rails test:system`. A check or execution that cannot run is a failure, not a skipped acceptance test.
