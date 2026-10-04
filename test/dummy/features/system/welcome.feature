Feature: Welcome

  @critical
  Scenario: Visitor sees welcome
    When I visit the homepage
    Then I should see "Welcome"

  @slow
  Scenario: Visitor sees the slow welcome
    When I visit the homepage
    Then I should see "Welcome"
