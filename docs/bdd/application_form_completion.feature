Feature: Application form completion
  As the BotHunter owner
  I want BotHunter to complete application form fields using my resume and configured preferences
  So that scripted application flows can handle non-standard questions without improvising beyond my data

  Background:
    Given BotHunter is running locally for the owner
    And the owner has registered a resume
    And the owner has configured search preferences
    And BotHunter is submitting an application for a vacancy

  # --- Completing form fields ---

  Scenario: Complete application form fields using registered resume context
    Given the application form contains fields answerable from the registered resume
    When BotHunter completes the application form
    Then the owner can see that the form fields were completed using resume context
    And the owner can see which fields were completed

  Scenario: Use configured compensation range for salary form fields
    Given the application form contains a salary or compensation field
    When BotHunter completes the application form
    Then the owner can see that the compensation range from search preferences was used

  Scenario: Complete non-standard application form fields from candidate context
    Given the application form contains a field not covered by a scripted workflow
    And the field can be answered from registered resume context within configured rules
    When BotHunter completes the application form
    Then the owner can see that the non-standard field was completed
    And the owner can see which resume context supported the answer

  # --- Restrictions and intervention ---

  Scenario: Request owner intervention when form completion cannot be determined safely
    Given the application form contains a field that cannot be answered safely within configured rules
    When BotHunter completes the application form
    Then the owner is notified that form completion requires intervention
    And the application is not submitted with improvised answers

  Scenario: Request owner intervention when form requires leaving the vacancy platform
    Given the application form requires leaving the vacancy platform to continue
    When BotHunter completes the application form
    Then the owner is notified that the application requires intervention
    And the application is not submitted automatically

  Scenario: Do not complete form fields using information outside resume and configured preferences
    When BotHunter completes the application form
    Then the owner can see that answers were based only on registered resume context and configured preferences

  # --- Submission integration ---

  Scenario: Submit application only after required form fields are completed
    Given the application form contains required fields answerable from registered resume context
    When BotHunter completes and submits the application
    Then the owner can see that required form fields were completed before submission
    And the owner can see that the application was submitted
