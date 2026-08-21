Feature: Audit trail and statistics
  As the BotHunter owner
  I want to review action history and job search statistics
  So that I can understand what BotHunter did and how effective my search is

  Background:
    Given BotHunter is running locally for the owner

  # --- Audit trail ---

  Scenario: Review audit trail of automated actions
    Given BotHunter has performed automated actions
    When the owner reviews the audit trail
    Then the owner can see which automated actions were performed
    And the owner can see when each action was performed

  Scenario: Review reasons for automated decisions
    Given BotHunter has made automated decisions
    When the owner reviews decision reasons in the audit trail
    Then the owner can see why each decision was made

  Scenario: Review audit record for a submitted application
    Given BotHunter has submitted an application for a vacancy
    When the owner reviews the audit trail for the vacancy
    Then the owner can see the application submission action
    And the owner can see the application outcome when it is known

  Scenario: Review audit record for vacancy discovery and evaluation
    Given BotHunter has discovered and evaluated a vacancy
    When the owner reviews the audit trail for the vacancy
    Then the owner can see whether the vacancy was accepted or excluded during discovery
    And the owner can see the match evaluation result when evaluation was performed

  Scenario: Review audit record for activity index maintenance actions
    Given the activity index module has performed maintenance actions
    When the owner reviews the audit trail for activity index maintenance
    Then the owner can see which maintenance actions were performed
    And the owner can see when each maintenance action was performed

  # --- Application statistics ---

  Scenario: View daily application count
    Given BotHunter has submitted applications today
    When the owner reviews application statistics
    Then the owner can see the number of applications submitted today

  Scenario: View whether rejections are present
    Given BotHunter has recorded application rejections
    When the owner reviews application statistics
    Then the owner can see whether rejections are present

  Scenario: View total application count for the recent month
    Given BotHunter has recorded application history for the recent month
    When the owner reviews application statistics
    Then the owner can see the total number of applications for the recent month

  # --- Search workflow statistics ---

  Scenario: View vacancy discovery statistics
    Given BotHunter has discovered vacancies
    When the owner reviews vacancy discovery statistics
    Then the owner can see how many vacancies were accepted for further processing
    And the owner can see how many vacancies were excluded

  Scenario: View vacancy evaluation statistics
    Given BotHunter has evaluated vacancies
    When the owner reviews vacancy evaluation statistics
    Then the owner can see how many vacancies were evaluated
    And the owner can see how many evaluations required owner intervention

  Scenario: View workflow stage counts for the recent month
    Given BotHunter has recorded workflow history for the recent month
    When the owner reviews workflow statistics for the recent month
    Then the owner can see counts for discovered, evaluated, and submitted vacancies
