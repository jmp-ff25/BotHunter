Feature: Vacancy evaluation
  As the BotHunter owner
  I want BotHunter to evaluate how well a discovered vacancy matches my resume
  So that I can prioritize suitable vacancies before applying

  Background:
    Given BotHunter is running locally for the owner
    And the owner has registered a resume
    And a vacancy is available for further processing

  # --- Match evaluation ---

  Scenario: Evaluate vacancy match against the registered resume
    When BotHunter evaluates the vacancy
    Then the owner can see a match evaluation for the vacancy
    And the owner can see which vacancy requirements were considered

  Scenario: Provide a match score for the vacancy
    When BotHunter evaluates the vacancy
    Then the owner can see a match score for the vacancy

  Scenario: Explain the match evaluation result
    When BotHunter evaluates the vacancy
    Then the owner can see an explanation of the match evaluation result
    And the owner can see which candidate experience supported the evaluation

  Scenario: Use registered resume context in the evaluation
    Given the vacancy requires experience described in the registered resume
    When BotHunter evaluates the vacancy
    Then the owner can see that relevant resume experience was used in the evaluation

  # --- Evaluation visibility and reuse ---

  Scenario: Review evaluated vacancies and their scores
    Given BotHunter has evaluated one or more vacancies
    When the owner reviews evaluated vacancies
    Then the owner can see the match score for each evaluated vacancy
    And the owner can see the explanation for each evaluated vacancy

  Scenario: Do not re-evaluate an unchanged vacancy unnecessarily
    Given BotHunter has already evaluated the vacancy
    And the vacancy and registered resume have not changed
    When BotHunter evaluates the vacancy again
    Then the owner sees the same evaluation result
    And the owner can see that the vacancy was not re-evaluated unnecessarily

  Scenario: Re-evaluate vacancy after resume replacement
    Given BotHunter has already evaluated the vacancy
    When the owner replaces the registered resume
    And BotHunter evaluates the vacancy again
    Then the owner can see an updated match evaluation result

  # --- Unclear evaluation ---

  Scenario: Request owner intervention for unclear match evaluation
    Given BotHunter cannot determine a reliable match evaluation within configured rules
    When BotHunter evaluates the vacancy
    Then the owner is notified that the evaluation requires intervention
    And the vacancy is not automatically prepared for application

  # --- Automation state ---

  Scenario: Do not evaluate vacancies while automation is paused
    Given automation is paused
    When a vacancy becomes available for further processing
    Then BotHunter does not evaluate the vacancy
