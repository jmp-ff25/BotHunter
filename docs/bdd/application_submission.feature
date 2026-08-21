Feature: Application submission
  As the BotHunter owner
  I want BotHunter to prepare and submit vacancy applications within my automation policy
  So that suitable vacancies receive responses without duplicate or unsafe submissions

  Background:
    Given BotHunter is running locally for the owner
    And the owner has registered a resume
    And full automation is enabled
    And automation is running
    And a vacancy has a completed match evaluation suitable for application

  # --- Successful submission ---

  Scenario: Submit application for a suitable evaluated vacancy
    When BotHunter prepares and submits an application for the vacancy
    Then the owner can see that the application was submitted
    And the owner can see which vacancy received the application

  Scenario: Prepare personalized application materials from registered resume context
    When BotHunter prepares application materials for the vacancy
    Then the owner can see that the materials use relevant resume context
    And the owner can see which vacancy the materials were prepared for

  # --- Policy and limits ---

  Scenario: Do not submit application when daily application limit is reached
    Given the owner has reached the configured daily application limit
    When BotHunter attempts to submit an application for the vacancy
    Then the application is not submitted
    And the owner can see that the daily application limit blocked the submission

  Scenario: Do not submit duplicate application for the same vacancy
    Given BotHunter has already submitted an application for the vacancy
    When BotHunter attempts to submit an application for the same vacancy again
    Then the application is not submitted
    And the owner can see that the vacancy already has a submitted application

  Scenario: Do not submit application when full automation is disabled
    Given full automation is disabled
    When BotHunter attempts to submit an application for the vacancy
    Then the application is not submitted

  Scenario: Do not submit application when match evaluation requires owner intervention
    Given the vacancy match evaluation requires owner intervention
    When BotHunter attempts to submit an application for the vacancy
    Then the application is not submitted
    And the owner can see that owner intervention is required before application

  # --- Pause and irreversible actions ---

  Scenario: Do not submit application while automation is paused
    Given automation is paused
    When BotHunter attempts to submit an application for the vacancy
    Then the application is not submitted

  Scenario: Pause before the next application submission takes effect
    Given automation is running
    And automation is about to submit an application for the vacancy
    When the owner requests pause
    Then the owner sees that automation is paused
    And the application is not submitted

  # --- Unknown outcome ---

  Scenario: Mark application as unknown outcome when submission result cannot be confirmed
    Given BotHunter has started submitting an application for the vacancy
    And the submission result cannot be confirmed
    When BotHunter records the application outcome
    Then the owner can see the application has an unknown outcome
    And the owner can see that the application was not automatically submitted again

  Scenario: Confirm application after unknown outcome when external state is verified
    Given an application for the vacancy has an unknown outcome
    And the external vacancy source shows the application was submitted
    When BotHunter reconciles the application outcome
    Then the owner can see the application was submitted

  Scenario: Request owner intervention after unknown outcome when submission cannot be verified
    Given an application for the vacancy has an unknown outcome
    And the external vacancy source does not confirm the application result
    When BotHunter reconciles the application outcome
    Then the owner is notified that application intervention is required
    And the application is not automatically submitted again

  # --- Application outcomes ---

  Scenario: Record application rejection for statistics
    Given BotHunter submitted an application for the vacancy
    When the vacancy source records a rejection for the application
    Then the owner can see that the application was rejected

  Scenario: Review submitted applications
    Given BotHunter has submitted one or more applications
    When the owner reviews submitted applications
    Then the owner can see which vacancies received applications
    And the owner can see the outcome of each submitted application
