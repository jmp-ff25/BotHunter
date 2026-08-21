Feature: HH activity index maintenance
  As the BotHunter owner
  I want a dedicated activity index module to maintain my HH resume visibility
  So that my resume benefits from platform activity signals without custom employer messaging

  Background:
    Given BotHunter is running locally for the owner
    And the owner has registered a resume
    And the HH activity index module is enabled

  # --- Module schedule ---

  Scenario: Configure activity index maintenance interval
    When the owner sets the activity index maintenance interval to every 4 hours
    And the owner saves the activity index settings
    Then the owner can see the maintenance interval is every 4 hours

  Scenario: Activity index module runs on schedule
    Given the activity index maintenance interval is every 4 hours
    And the activity index module is waiting for the next run
    When the scheduled maintenance time is reached
    Then the activity index module starts a maintenance run
    And the owner can see that a maintenance run has started

  Scenario: Activity index module sleeps until the next scheduled run
    Given the activity index module completed a maintenance run
    When the maintenance run finishes
    Then the activity index module is waiting for the next scheduled run
    And the owner can see when the next maintenance run is expected

  Scenario: Activity index module can run after applications complete
    Given the activity index module is configured to run after applications complete
    And BotHunter has completed a batch of vacancy applications
    When the application batch finishes
    Then the activity index module starts a maintenance run

  Scenario: Activity index module can run in parallel with applications
    Given the activity index module is configured to run in parallel with applications
    And automation is running vacancy applications
    When the scheduled maintenance time is reached
    Then the activity index module starts a maintenance run
    And vacancy applications may continue according to the automation policy

  # --- Activity index actions ---

  Scenario: View vacancies for activity index maintenance
    Given a maintenance run is in progress
    When the activity index module views vacancies on HH
    Then the owner can see that vacancy viewing actions were performed for activity index maintenance

  Scenario: Raise resume in search for activity index maintenance
    Given a maintenance run is in progress
    When the activity index module raises the resume in search on HH
    Then the owner can see that the resume was raised in search

  Scenario: Maintain resume completed-action phrasing for activity index
    Given a maintenance run is in progress
    When the activity index module updates the HH resume with completed-action phrasing
    Then the owner can see that completed-action phrasing was maintained on the resume

  Scenario: Maintain resume achievement statements for activity index
    Given a maintenance run is in progress
    When the activity index module updates the HH resume with verifiable achievement statements
    Then the owner can see that achievement statements were maintained on the resume

  Scenario: Click HH suggested chat buttons without custom messages
    Given a maintenance run is in progress
    And an employer chat on HH offers suggested question buttons
    When the activity index module clicks an HH suggested question button
    Then the owner can see that the suggested button was clicked
    And the owner can see that no custom message was sent to the employer

  Scenario: Activity index module never sends custom employer messages
    Given a maintenance run is in progress
    When the activity index module interacts with employer chats on HH
    Then the owner can see that no custom messages were sent to employers

  # --- Control and visibility ---

  Scenario: Review activity index maintenance history
    Given the activity index module has completed maintenance runs
    When the owner reviews activity index maintenance history
    Then the owner can see which maintenance actions were performed
    And the owner can see when each maintenance run occurred

  Scenario: Do not run activity index maintenance while automation is paused
    Given automation is paused
    When the scheduled maintenance time is reached
    Then the activity index module does not start a maintenance run

  Scenario: Disable activity index maintenance
    Given the HH activity index module is enabled
    When the owner disables the HH activity index module
    Then the owner can see that activity index maintenance is disabled
    And scheduled maintenance runs do not start
