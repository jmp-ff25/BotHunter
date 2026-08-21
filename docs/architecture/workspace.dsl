workspace "BotHunter" "Architecture of the local-first job search automation system." {

    model {
        owner = person "Owner" "Configures and controls the personal BotHunter installation."

        hh = softwareSystem "HH" "Provides vacancies, applications, and employer messages." "External System"
        telegram = softwareSystem "Telegram" "Delivers notifications and intervention requests." "External System"
        aiProvider = softwareSystem "AI Provider" "Analyzes text and generates personalized materials." "External System"

        bothunter = softwareSystem "BotHunter" "Local-first personal job search automation system." {
            web = container "Web/API Process" "Serves the loopback-only web UI and API, manages configuration, submits durable commands, and exposes status and statistics." "Python" {
                webDelivery = component "Local Web Delivery" "Serves the web UI and local HTTP API." "Python component" "Delivery"
                configurationControl = component "Configuration and Control" "Manages profile, policies, limits, pause, and resume." "Python component" "Application Component"
                commandSubmission = component "Command Submission" "Creates durable commands atomically." "Python component" "Application Component"
                queryReporting = component "Query and Reporting" "Reads operational state, audit history, and statistics." "Python component" "Application Component"
                webDomain = component "Domain Model" "Shared business concepts and invariants used by Web/API." "Shared Python module" "Domain Component"
                webRepositoryPort = component "Web Repository Ports" "Application contracts for configuration, durable commands, and query data." "Application contract" "Application Port"
                workerSignalPort = component "Worker Signal Port" "Application contract for signalling a committed command." "Application contract" "Application Port"
                workerSignaler = component "Worker Signaler" "Sends localhost signals and handles acknowledgements." "HTTP client" "Infrastructure Adapter"
                webPersistence = component "Web Persistence Adapters" "Implements repositories used by Web/API." "SQLite adapter" "Infrastructure Adapter"
            }

            worker = container "Automation Worker Process" "Runs schedules and automation workflows, integrates with external systems, and recovers incomplete work." "Python" {
                triggerRecovery = component "Trigger and Recovery Coordinator" "Handles schedules, signals, recovery scans, command leases, and heartbeat." "Python component" "Application Component"
                automationOrchestrator = component "Automation Orchestrator" "Coordinates vacancy search, analysis, applications, activity index maintenance, and notifications." "Python component" "Application Component"
                activityIndexMaintenance = component "Activity Index Maintenance" "Periodically maintains HH activity index through read/click workflows without custom employer messages." "Python component" "Application Component"
                externalActionExecutor = component "External Action Executor" "Executes every irreversible vacancy-platform action through a consistent snapshot, domain safety check, and conditional intent commit." "Python component" "Application Component"
                safetyGuard = component "Safety and Policy Guard" "Enforces policies, limits, pause checkpoints, idempotency, and safe side effects." "Shared Python module" "Domain Component"
                workerDomain = component "Domain Model" "Shared vacancy, matching, policy, and workflow concepts used by the Worker." "Shared Python module" "Domain Component"
                vacancyQueryPort = component "Vacancy Query Port" "Application boundary for reading vacancies and observable source state." "Application contract" "Application Port"
                externalActionPort = component "External Action Port" "Application boundary for allowed application submissions." "Application contract" "Application Port"
                candidateContextPort = component "Candidate Context Port" "Application boundary for retrieving relevant candidate experience." "Application contract" "Application Port"
                aiPort = component "AI Port" "Application boundary for analysis and content generation." "Application contract" "Application Port"
                notificationPort = component "Notification Port" "Application boundary for owner notifications." "Application contract" "Application Port"
                operationalRepositoryPort = component "Operational Repository Ports" "Application contracts for commands, workflow state, heartbeat, audit, and outcomes." "Application contract" "Application Port"
                actionUnitOfWorkPort = component "Action Unit of Work Port" "Provides a consistent snapshot and conditional atomic commit of reservation, idempotency, and intent." "Application contract" "Application Port"
                workerPersistence = component "Operational Persistence Adapters" "Persists commands, workflow state, intents, outcomes, audit records, heartbeat, and idempotency." "SQLite adapter" "Infrastructure Adapter"
                hhAdapter = component "HH Adapter" "Implements vacancy query and external action contracts with Playwright workflows for HH." "Playwright" "Infrastructure Adapter"
                aiAdapter = component "AI Provider Adapter" "Implements the AI Port for a configured provider." "Provider client" "Infrastructure Adapter"
                telegramAdapter = component "Telegram Adapter" "Implements the Notification Port using Telegram." "Telegram Bot API client" "Infrastructure Adapter"
                candidateContextAdapter = component "Candidate Context Adapter" "Retrieves candidate context without exposing retrieval technology to Application." "Local retrieval adapter" "Infrastructure Adapter"
            }

            operationalStore = container "Operational Store" "Authoritative local store for configuration, durable commands, workflow state, idempotency, audit, and statistics." "SQLite" "Database"
            candidateDocuments = container "Candidate Document Store" "Local source documents owned by the candidate." "Local filesystem" "Database"
            browserRuntime = container "Managed Browser Runtime" "Browser processes controlled by the Worker through Playwright." "Playwright-managed browser"
        }

        owner -> bothunter "Configures, controls, and reviews job search automation"
        bothunter -> hh "Searches vacancies, submits applications, and maintains HH activity index"
        bothunter -> telegram "Sends notifications and intervention requests"
        bothunter -> aiProvider "Requests analysis and personalized content"

        owner -> web "Uses" "HTTPS/HTTP on loopback"
        owner -> webDelivery "Uses the local web interface" "HTTPS/HTTP on loopback"
        web -> operationalStore "Reads and writes configuration, commands, and query data" "SQLite"
        web -> worker "Signals durable commands and receives acknowledgements" "HTTP on loopback"
        worker -> operationalStore "Claims commands and stores intents, outcomes, workflow state, heartbeat, audit, and results" "SQLite"
        worker -> candidateDocuments "Reads candidate source documents" "Local filesystem"
        worker -> browserRuntime "Controls" "Playwright"
        browserRuntime -> hh "Reads observable state and performs allowed actions" "HTTPS"
        worker -> telegram "Sends notifications" "Telegram Bot API"
        worker -> aiProvider "Requests analysis and generation through a provider adapter" "Provider API"

        webDelivery -> configurationControl "Invokes configuration and control use cases"
        webDelivery -> commandSubmission "Requests automation commands"
        webDelivery -> queryReporting "Requests status, history, and statistics"
        configurationControl -> webDomain "Applies business rules"
        commandSubmission -> webDomain "Validates command invariants"
        configurationControl -> webRepositoryPort "Persists configuration and desired state"
        commandSubmission -> webRepositoryPort "Persists durable commands"
        commandSubmission -> workerSignalPort "Requests an immediate wake-up after commit"
        queryReporting -> webRepositoryPort "Reads operational views"
        webPersistence -> webRepositoryPort "Implements"
        workerSignaler -> workerSignalPort "Implements"
        webPersistence -> operationalStore "Reads and writes" "SQLite"
        workerSignaler -> triggerRecovery "Signals a committed command" "HTTP on loopback"

        triggerRecovery -> operationalRepositoryPort "Claims commands, maintains leases, and records heartbeat"
        triggerRecovery -> automationOrchestrator "Starts or reconciles workflows"
        triggerRecovery -> activityIndexMaintenance "Schedules activity index maintenance"
        activityIndexMaintenance -> workerDomain "Applies activity index policies"
        activityIndexMaintenance -> safetyGuard "Checks pause-state and limits"
        activityIndexMaintenance -> hhAdapter "Runs HH activity index workflows"
        activityIndexMaintenance -> operationalRepositoryPort "Records activity index runs and audit events"
        automationOrchestrator -> activityIndexMaintenance "May delegate scheduled maintenance"
        automationOrchestrator -> workerDomain "Applies vacancy and workflow rules"
        automationOrchestrator -> vacancyQueryPort "Reads vacancies and observable source state"
        automationOrchestrator -> candidateContextPort "Requests relevant candidate context"
        automationOrchestrator -> aiPort "Requests analysis and personalized content"
        automationOrchestrator -> notificationPort "Requests owner notifications"
        automationOrchestrator -> externalActionExecutor "Requests an irreversible action"
        automationOrchestrator -> operationalRepositoryPort "Stores workflow decisions and non-side-effect results"
        externalActionExecutor -> actionUnitOfWorkPort "Reads a consistent snapshot and conditionally commits reservation and intent"
        externalActionExecutor -> safetyGuard "Validates policy, limits, pause-state, and idempotency"
        externalActionExecutor -> externalActionPort "Executes an action only after intent commit"
        externalActionExecutor -> operationalRepositoryPort "Stores observed or unknown outcome"
        safetyGuard -> workerDomain "Evaluates domain policies"
        workerPersistence -> operationalRepositoryPort "Implements"
        workerPersistence -> actionUnitOfWorkPort "Implements"
        workerPersistence -> operationalStore "Reads and writes" "SQLite"

        hhAdapter -> vacancyQueryPort "Implements"
        hhAdapter -> externalActionPort "Implements"
        candidateContextAdapter -> candidateContextPort "Implements"
        aiAdapter -> aiPort "Implements"
        telegramAdapter -> notificationPort "Implements"
        candidateContextAdapter -> candidateDocuments "Reads source documents" "Local filesystem"
        candidateContextAdapter -> operationalStore "Reads document metadata and retrieval state" "SQLite"
        hhAdapter -> browserRuntime "Executes browser workflows" "Playwright"
        aiAdapter -> aiProvider "Calls" "Provider API"
        telegramAdapter -> telegram "Sends messages" "Telegram Bot API"

        deploymentEnvironment "Local" {
            deploymentNode "Owner Device" "The single owner's computer." "Windows, Linux, or macOS" {
                launcherInstance = infrastructureNode "Python Launcher" "Starts and stops both BotHunter processes without business logic." "Python"
                webInstance = containerInstance web
                workerInstance = containerInstance worker
                operationalStoreInstance = containerInstance operationalStore
                candidateDocumentsInstance = containerInstance candidateDocuments
                browserRuntimeInstance = containerInstance browserRuntime
                launcherInstance -> webInstance "Starts and stops"
                launcherInstance -> workerInstance "Starts and stops"
            }
        }
    }

    views {
        systemContext bothunter "SystemContext" "BotHunter system context." {
            include *
            autoLayout lr
        }

        container bothunter "Containers" "BotHunter runtime containers and local data stores." {
            include *
            autoLayout lr
        }

        component web "WebApiComponents" "Components of the loopback-only Web/API process." {
            include *
            autoLayout lr
        }

        component worker "AutomationWorkerComponents" "Components of the Automation Worker process." {
            include *
            autoLayout lr
        }

        dynamic bothunter "CommandExecution" "Durable command and safe external action at container level." {
            owner -> web "Submits an automation command"
            web -> operationalStore "Commits the durable command"
            web -> worker "Signals the committed command"
            worker -> operationalStore "Claims the command under a lease"
            worker -> operationalStore "Atomically reserves limits and stores intent"
            worker -> browserRuntime "Executes the configured source adapter after intent commit"
            browserRuntime -> hh "Performs the allowed action"
            worker -> operationalStore "Stores the observed outcome"
            autoLayout lr
        }

        dynamic bothunter "UnknownOutcomeRecovery" "Reconciliation after an interrupted external action." {
            worker -> operationalStore "Finds an expired lease or incomplete intent"
            worker -> browserRuntime "Requests observable-state verification"
            browserRuntime -> hh "Checks the external action result"
            worker -> operationalStore "Stores confirmed or unknown outcome"
            worker -> telegram "Requests owner intervention when unresolved"
            autoLayout lr
        }

        dynamic bothunter "PauseFlow" "Durable pause and safe Worker reaction." {
            owner -> web "Requests pause"
            web -> operationalStore "Commits durable pause-state"
            web -> worker "Signals the state change"
            worker -> operationalStore "Checks pause-state immediately before the next side effect"
            worker -> operationalStore "Stores the paused workflow state"
            autoLayout lr
        }

        deployment bothunter "Local" "LocalDeployment" "Cross-platform local deployment." {
            include *
            autoLayout lr
        }

        styles {
            element "Person" {
                shape Person
            }
            element "Database" {
                shape Cylinder
            }
            element "External System" {
                shape RoundedBox
            }
            element "Application Port" {
                shape Hexagon
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
