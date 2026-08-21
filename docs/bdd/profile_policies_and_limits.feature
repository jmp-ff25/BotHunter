Feature: Resume, search preferences, policies and limits
  As the BotHunter owner
  I want to register my resume, define search preferences outside the resume, and configure automation policies and limits
  So that automated job search uses my CV and follows my boundaries

  Background:
    Given BotHunter is running locally for the owner

  # --- Resume ---

  Scenario: View automation readiness before initial setup
    Given no owner resume has been registered
    And search preferences have not been configured
    When the owner opens the automation settings
    Then the owner sees that automation is not ready
    And the owner sees which required setup items are still missing

  Scenario: Register owner resume
    Given the owner has a resume document
    When the owner registers the resume with BotHunter
    Then the owner can see that a resume is registered
    And the owner can see which resume document is active

  Scenario: Replace registered owner resume
    Given the owner has a registered resume
    When the owner registers a new resume document with BotHunter
    Then the owner can see that the new resume document is active

  # --- Search preferences outside the resume ---

  Scenario: Configure vacancy search preferences
    When the owner sets a desired compensation range
    And the owner sets vacancy exclusion words for titles and descriptions
    And the owner sets required vacancy words for titles and descriptions
    And the owner saves the search preferences
    Then the owner can see the active compensation range
    And the owner can see the active exclusion words
    And the owner can see the active required words

  Scenario: Update vacancy search preferences
    Given the owner has saved search preferences
    When the owner updates the compensation range
    And the owner updates the exclusion words
    And the owner updates the required words
    And the owner saves the search preferences
    Then the owner sees the updated compensation range
    And the owner sees the updated exclusion words
    And the owner sees the updated required words

  # --- Full automation policy ---

  Scenario: Full automation remains disabled until explicitly enabled
    Given the owner has not enabled full automation
    When the owner views the automation policy
    Then full automation is shown as disabled
    And automatic vacancy applications are not permitted

  Scenario: Enable full automation with complete configuration
    Given the owner has registered a resume
    And the owner has configured search preferences
    And the owner has configured a daily application limit
    And the owner has configured application preparation rules
    And the owner has configured situations that require owner intervention
    When the owner explicitly enables full automation
    Then full automation is shown as enabled
    And automatic vacancy applications are permitted

  Scenario: Cannot enable full automation without a registered resume
    Given no owner resume has been registered
    And the owner has configured search preferences
    And the owner has configured a daily application limit
    And the owner has configured application preparation rules
    And the owner has configured situations that require owner intervention
    When the owner attempts to enable full automation
    Then full automation remains disabled
    And the owner is informed that a registered resume is required

  Scenario: Cannot enable full automation without search preferences
    Given the owner has registered a resume
    And search preferences have not been configured
    And the owner has configured a daily application limit
    And the owner has configured application preparation rules
    And the owner has configured situations that require owner intervention
    When the owner attempts to enable full automation
    Then full automation remains disabled
    And the owner is informed that search preferences are required

  Scenario: Disable full automation
    Given full automation is enabled
    When the owner disables full automation
    Then full automation is shown as disabled
    And automatic vacancy applications are not permitted

  # --- Application limits ---

  Scenario: Configure daily application limit
    When the owner sets a daily limit of 10 vacancy applications
    And the owner saves the automation policy
    Then the owner can see a daily application limit of 10

  Scenario: Update daily application limit
    Given the owner has configured a daily application limit of 10
    When the owner changes the daily application limit to 3
    And the owner saves the automation policy
    Then the owner can see a daily application limit of 3

  # --- Preparation and intervention rules ---

  Scenario: Configure application preparation rules
    When the owner defines rules for preparing vacancy applications
    And the owner saves the automation policy
    Then the owner can review the active application preparation rules

  Scenario: Configure situations that require owner intervention
    When the owner defines that unclear application situations require owner intervention
    And the owner saves the automation policy
    Then the owner can see that unclear application situations require owner intervention

  Scenario: Employer communication remains manual
    When the owner reviews the automation policy
    Then the owner can see that employer communication is not automated
    And the owner can see that only the owner may communicate with employers

  # --- Application statistics notifications ---

  Scenario: Receive daily application count notification
    Given the owner has enabled application statistics notifications
    And BotHunter has submitted vacancy applications today
    When the daily application statistics notification is sent
    Then the owner receives the number of applications submitted today

  Scenario: Receive notification when rejections are present
    Given the owner has enabled application statistics notifications
    And BotHunter has recorded application rejections
    When the application statistics notification is sent
    Then the owner is informed that rejections are present

  Scenario: View total application count for the recent month
    Given BotHunter has recorded application history for the recent month
    When the owner reviews application statistics
    Then the owner can see the total number of applications for the recent month

  # --- Policy visibility and persistence ---

  Scenario: Review active automation policy summary
    Given the owner has registered a resume
    And the owner has configured search preferences
    And the owner has enabled full automation
    And the owner has configured a daily application limit
    And the owner has configured application preparation rules
    And the owner has configured situations that require owner intervention
    When the owner reviews the automation policy summary
    Then the owner sees whether full automation is enabled
    And the owner sees the active resume registration
    And the owner sees the active search preferences
    And the owner sees the configured daily application limit
    And the owner sees key preparation and intervention rules
    And the owner sees that employer communication is not automated

  Scenario: Saved resume, search preferences, and policies remain available after restart
    Given the owner has registered a resume
    And the owner has saved search preferences
    And the owner has saved an automation policy
    When BotHunter is restarted
    Then the owner sees the same active resume registration
    And the owner sees the same search preferences
    And the owner sees the same automation policy configuration
