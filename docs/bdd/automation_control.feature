Feature: Automation control
  As the BotHunter owner
  I want to start, pause, and resume job search automation
  So that I can run automation when ready and stop it immediately at any time

  Background:
    Given BotHunter is running locally for the owner

  # --- Automation status ---

  Scenario: View automation status when idle and ready
    Given the owner has completed automation setup
    And full automation is enabled
    And automation is not running
    When the owner views the automation status
    Then the owner sees that automation is idle and ready to start

  Scenario: View automation status while running
    Given automation is running
    When the owner views the automation status
    Then the owner sees that automation is running

  Scenario: View automation status while paused
    Given automation is paused
    When the owner views the automation status
    Then the owner sees that automation is paused

  Scenario: View automation status when the worker is unavailable
    Given the automation worker is unavailable
    When the owner views the automation status
    Then the owner sees that automation is unavailable
    And the owner sees that automatic external actions are not being performed

  # --- Start automation ---

  Scenario: Start automation when ready
    Given the owner has completed automation setup
    And full automation is enabled
    And automation is not running
    When the owner starts automation
    Then the owner sees that automation is running

  Scenario: Cannot start automation when full automation is disabled
    Given the owner has completed automation setup
    And full automation is disabled
    When the owner attempts to start automation
    Then automation does not start
    And the owner is informed that full automation must be enabled first

  Scenario: Cannot start automation when setup is incomplete
    Given automation setup is incomplete
    When the owner attempts to start automation
    Then automation does not start
    And the owner is informed that automation is not ready

  Scenario: Cannot start automation while paused without resuming
    Given automation is paused
    When the owner attempts to start automation
    Then automation remains paused
    And the owner is informed that automation must be resumed first

  # --- Pause automation ---

  Scenario: Pause running automation
    Given automation is running
    When the owner requests pause
    Then the owner sees that automation is paused

  Scenario: No new automatic external actions while paused
    Given automation is paused
    When automation would otherwise perform a new automatic external action
    Then no new automatic external action is started

  Scenario: Pause does not cancel an external action already in progress
    Given automation is running
    And an automatic external action is already in progress
    When the owner requests pause
    Then the owner sees that automation is paused
    And the owner can see that the in-progress external action may still complete

  Scenario: Pause takes effect before the next automatic external action
    Given automation is running
    And automation is about to perform a new automatic external action
    When the owner requests pause
    Then the owner sees that automation is paused
    And no new automatic external action is started

  # --- Resume automation ---

  Scenario: Resume paused automation
    Given the owner has completed automation setup
    And full automation is enabled
    And automation is paused
    When the owner resumes automation
    Then the owner sees that automation is running

  Scenario: Cannot resume automation when full automation was disabled while paused
    Given automation is paused
    And full automation is disabled
    When the owner attempts to resume automation
    Then automation remains paused
    And the owner is informed that full automation must be enabled first

  # --- Persistence ---

  Scenario: Paused automation remains paused after restart
    Given automation is paused
    When BotHunter is restarted
    Then the owner sees that automation is still paused

  Scenario: Running automation is safely stopped after restart
    Given automation was running
    When BotHunter is restarted
    Then the owner sees that automation is not running
    And the owner can see whether automation requires attention before restart
