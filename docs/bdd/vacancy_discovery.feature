Feature: Vacancy discovery
  As the BotHunter owner
  I want BotHunter to discover suitable vacancies from connected sources
  So that only relevant new vacancies move forward in my job search workflow

  Background:
    Given BotHunter is running locally for the owner
    And the owner has configured search preferences
    And automation is running

  # --- Accepting vacancies ---

  Scenario: Discover a vacancy that matches search preferences
    When BotHunter discovers a vacancy that matches the search preferences
    Then the owner can see the vacancy is available for further processing
    And the owner can see why the vacancy was accepted

  Scenario: Do not rediscover an already accepted vacancy
    Given a vacancy was already discovered and accepted for further processing
    When BotHunter discovers the same vacancy again
    Then the owner does not see a duplicate vacancy entry
    And the vacancy is not treated as a new discovery

  # --- Exclusion by search preferences ---

  Scenario: Exclude vacancy with an exclusion word in the title
    Given the owner has configured vacancy exclusion words for titles
    When BotHunter discovers a vacancy whose title contains an exclusion word
    Then the owner can see the vacancy was excluded from further processing
    And the owner can see the exclusion reason references the title

  Scenario: Exclude vacancy with an exclusion word in the description
    Given the owner has configured vacancy exclusion words for descriptions
    When BotHunter discovers a vacancy whose description contains an exclusion word
    Then the owner can see the vacancy was excluded from further processing
    And the owner can see the exclusion reason references the description

  Scenario: Exclude vacancy missing a required word in the title
    Given the owner has configured required vacancy words for titles
    When BotHunter discovers a vacancy whose title does not contain a required word
    Then the owner can see the vacancy was excluded from further processing
    And the owner can see the exclusion reason references the title

  Scenario: Exclude vacancy missing a required word in the description
    Given the owner has configured required vacancy words for descriptions
    When BotHunter discovers a vacancy whose description does not contain a required word
    Then the owner can see the vacancy was excluded from further processing
    And the owner can see the exclusion reason references the description

  Scenario: Exclude vacancy outside the desired compensation range
    Given the owner has configured a desired compensation range
    When BotHunter discovers a vacancy with compensation outside the desired range
    Then the owner can see the vacancy was excluded from further processing
    And the owner can see the exclusion reason references the compensation range

  Scenario: Do not reprocess an already excluded vacancy
    Given a vacancy was already discovered and excluded from further processing
    When BotHunter discovers the same vacancy again
    Then the owner does not see a duplicate vacancy entry
    And the vacancy remains excluded from further processing

  # --- Discovery visibility ---

  Scenario: Review discovered vacancies available for further processing
    Given BotHunter has discovered vacancies available for further processing
    When the owner reviews discovered vacancies
    Then the owner can see which vacancies are available for further processing

  Scenario: Review vacancies excluded by search preferences
    Given BotHunter has discovered vacancies excluded by search preferences
    When the owner reviews excluded vacancies
    Then the owner can see which vacancies were excluded
    And the owner can see why each vacancy was excluded

  # --- Automation state ---

  Scenario: Do not discover vacancies while automation is paused
    Given automation is paused
    When a vacancy becomes available on the connected vacancy source
    Then BotHunter does not discover the vacancy

  Scenario: Do not discover vacancies while automation is not running
    Given automation is not running
    When a vacancy becomes available on the connected vacancy source
    Then BotHunter does not discover the vacancy
