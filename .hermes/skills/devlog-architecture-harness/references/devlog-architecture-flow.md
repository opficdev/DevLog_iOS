# DevLog Architecture Flow

## Purpose

This reference defines the DevLog-specific harness flow for AI-assisted architecture work.

The goal is not to make the AI decide more architecture policy. The goal is to make the AI stop before it makes project-specific architecture decisions that should be confirmed by the user.

Use this reference with `AGENTS.md` and `.hermes/skills/devlog-architecture-harness/SKILL.md`.

This repository is a Tuist-generated, workspace-based modular iOS app. There is no root `Package.swift`; module projects are generated from `Workspace.swift` and each module's `Project.swift`.

## High-level harness flow

```mermaid
flowchart TD
	Request["User request"]
	LoadRules["Load DevLog rules"]
	LoadContext["Inspect current repository context"]
	Classify["Classify change type"]
	Boundary["Check layer boundary"]
	Ambiguous{"Architecture boundary ambiguous?"}
	Ask["Ask user before editing"]
	Plan["Prepare narrow edit plan"]
	Edit["Apply scoped change"]
	Verify["Verify build or docs state"]
	Diff["Inspect final diff scope"]
	Record["Report decision and result"]

	Request --> LoadRules
	LoadRules --> LoadContext
	LoadContext --> Classify
	Classify --> Boundary
	Boundary --> Ambiguous
	Ambiguous -->|Yes| Ask
	Ask --> Boundary
	Ambiguous -->|No| Plan
	Plan --> Edit
	Edit --> Verify
	Verify --> Diff
	Diff --> Record
```

## Change classification

```mermaid
flowchart TD
	Change["Requested change"]
	ImportOnly{"Only import/access fallout?"}
	BoundaryMove{"Moves ownership or dependency?"}
	SDKPlacement{"Changes external SDK placement?"}
	DIChange{"Changes assembler or DI ownership?"}
	WidgetFlow{"Changes widget data flow?"}
	Mechanical["Mechanical change"]
	Architecture["Architecture change"]
	Ambiguous["Ambiguous change"]

	Change --> ImportOnly
	ImportOnly -->|Yes| Mechanical
	ImportOnly -->|No| BoundaryMove
	BoundaryMove -->|Yes| Architecture
	BoundaryMove -->|No| SDKPlacement
	SDKPlacement -->|Yes| Architecture
	SDKPlacement -->|No| DIChange
	DIChange -->|Yes| Architecture
	DIChange -->|No| WidgetFlow
	WidgetFlow -->|Yes| Architecture
	WidgetFlow -->|No| Ambiguous
```

## DevLog layer map

```mermaid
flowchart TD
	App["DevLogApp\nComposition root\nApp lifecycle\nAssembler wiring"]
	Presentation["DevLogPresentation\nSwiftUI views\nViewModels\nCoordinators\nUI state"]
	Domain["DevLogDomain\nEntities\nRepository protocols\nUse cases"]
	Data["DevLogData\nRepository implementations\nDTOs\nMappers\nService/store protocols"]
	Infra["DevLogInfra\nFirebase\nSocial login\nNetwork\nLink metadata\nMessaging"]
	Persistence["DevLogPersistence\nUserDefaults\nImage store\nNon-widget app persistence"]
	Widget["DevLogWidget\nApp-side widget bridge\nSync/session handlers\nSnapshot update orchestration\nWidgetKit reload bridge"]
	Core["DevLogCore\nDI\nLogger\nShared value/query types\nLightweight widget values"]
	WidgetCore["DevLogWidgetCore\nWidget snapshot models\nFactories\nApp Group constants"]
	WidgetExtension["DevLogWidgetExtension\nWidgetKit UI\nProviders\nTimelines"]

	App --> Presentation
	App --> Domain
	App --> Data
	App --> Infra
	App --> Persistence
	App --> Core
	App --> Widget
	App --> WidgetCore
	App -.-> WidgetExtension

	Presentation --> Domain
	Presentation --> Core

	Domain --> Core

	Data --> Domain
	Data --> Core

	Infra --> Data
	Infra --> Core

	Persistence --> Data
	Persistence --> Core

	Widget --> Data
	Widget --> Core
	Widget --> WidgetCore

	WidgetExtension --> WidgetCore
	WidgetCore --> Core
```

## Boundary rules

| Layer | Owns | Allowed direction | Ask before |
| --- | --- | --- | --- |
| `DevLogCore` | DI primitives, logger, shared value/query types, display options, activity kinds, lightweight widget bridge values | No DevLog layer dependency | Moving domain entities into Core |
| `DevLogDomain` | entities, repository protocols, use cases | Core only | Adding Data, Infra, Persistence, Presentation, App, Widget UI, or SDK dependency |
| `DevLogData` | repository implementations, DTOs, mappers, data protocols, widget repository/updater/sync contracts | Domain, Core | Adding concrete Firebase, GoogleSignIn, WidgetKit, storage, WidgetCore snapshot model/factory usage, or platform implementation details; moving concrete widget handlers into Data |
| `DevLogInfra` | Firebase, social login, network, metadata, messaging implementations | Data, Core | Moving SDK-specific behavior out of Infra; adding any Domain dependency, source import, or SDK service contract coupling |
| `DevLogPersistence` | local stores, image cache, non-widget app persistence | Data, Core | Adding WidgetCore, WidgetKit reload, DevLogWidget, widget snapshot generation, or widget bridge ownership |
| `DevLogPresentation` | UI, view models, coordinators, presentation state, narrow presentation-scoped platform side effects | Domain, Core | Adding Data, Infra, Persistence, or App dependency; expanding platform service ownership beyond UI-side effects |
| `DevLogWidget` | app-side widget bridge, sync bus implementation, sync/session handlers, snapshot generation/persistence orchestration, WidgetKit reload bridge, widget assembler | Data, Core, WidgetCore | Adding Domain, Infra, Persistence, Presentation, or App dependency |
| `DevLogApp` | composition root, lifecycle, assembler wiring, app target ownership for widget extension embedding | Concrete app layers | Moving feature logic into App |
| `DevLogWidgetCore` | widget snapshot models, factories, app-group keys/defaults store, deep links, pure snapshot logic | Core | Adding Domain, Data, Infra, Persistence, Presentation, App, or DevLogWidget dependency |
| `DevLogWidgetExtension` | WidgetKit rendering and timeline plumbing | WidgetCore | Calling app/domain services directly |

## Layer-internal dependency injection

Do not inject dependencies between types that belong to the same layer.

This rule covers initializer injection, stored-property injection, environment injection, and resolving same-layer types through `DIContainer`.

The only allowed exception is a SwiftUI `View` file in `Application/DevLogPresentation` receiving same-layer presentation objects such as a ViewModel, Coordinator, or Store for UI composition.

That exception does not apply to non-View files in Presentation, and does not apply to Core, Domain, Data, Infra, Persistence, Widget, App, WidgetCore, WidgetExtension, or Firebase functions.

## Presentation StorePattern flow

```mermaid
flowchart LR
	View["SwiftUI View"]
	ViewModel["ViewModel / StorePattern"]
	Send["send(Action)"]
	Reduce["reduce(with:)"]
	State["State update"]
	SideEffect["SideEffect"]
	Run["run(SideEffect)"]
	Service["Injected use case or service"]

	View --> ViewModel
	ViewModel --> Send
	Send --> Reduce
	Reduce --> State
	Reduce --> SideEffect
	SideEffect --> Run
	Run --> Service
	Service --> Send
```

Preserve this flow unless the user explicitly asks to change the Presentation architecture. Reducers compute state and return side effects. I/O belongs in `run` or injected services.

## Ambiguity gate

The AI must stop and ask the user when it reaches any of these points.

```mermaid
flowchart TD
	Check["Architecture decision needed"]
	CoreDomain{"Core vs Domain ownership?"}
	Shared{"Moved only because shared?"}
	NewDependency{"New module dependency?"}
	SameLayerDI{"Same-layer dependency injection?"}
	ExternalSDK{"External SDK crosses layer?"}
	WidgetBoundary{"Widget sync ownership or WidgetCore boundary changes?"}
	BuildShortcut{"Build fix relaxes boundary?"}
	ScopeDrift{"Outside current task scope?"}
	Ask["Ask user before editing"]
	Proceed["Proceed with scoped edit"]

	Check --> CoreDomain
	CoreDomain -->|Yes| Ask
	CoreDomain -->|No| Shared
	Shared -->|Yes| Ask
	Shared -->|No| NewDependency
	NewDependency -->|Yes| Ask
	NewDependency -->|No| SameLayerDI
	SameLayerDI -->|Presentation View file| ExternalSDK
	SameLayerDI -->|No| ExternalSDK
	SameLayerDI -->|Other| Ask
	ExternalSDK -->|Yes| Ask
	ExternalSDK -->|No| WidgetBoundary
	WidgetBoundary -->|Yes| Ask
	WidgetBoundary -->|No| BuildShortcut
	BuildShortcut -->|Yes| Ask
	BuildShortcut -->|No| ScopeDrift
	ScopeDrift -->|Yes| Ask
	ScopeDrift -->|No| Proceed
```

## Core vs Domain decision flow

Use this flow when deciding whether a type belongs in Core or Domain.

```mermaid
flowchart TD
	Type["Type under review"]
	DomainMeaning{"Represents business/domain meaning?"}
	QueryOrPrimitive{"Generic query, option, logger, DI, or shared primitive?"}
	UsedByWidget{"Needed by WidgetCore snapshot contract?"}
	OnlyShared{"Only reason is multiple modules need it?"}
	Domain["Keep or place in DevLogDomain"]
	Core["Keep or place in DevLogCore"]
	Ask["Ask user"]

	Type --> DomainMeaning
	DomainMeaning -->|Yes| Domain
	DomainMeaning -->|No| QueryOrPrimitive
	QueryOrPrimitive -->|Yes| Core
	QueryOrPrimitive -->|No| UsedByWidget
	UsedByWidget -->|Yes| Core
	UsedByWidget -->|No| OnlyShared
	OnlyShared -->|Yes| Ask
	OnlyShared -->|No| Ask
```

## External dependency flow

Use this flow before introducing or moving imports such as Firebase, GoogleSignIn, AuthenticationServices, UserNotifications, LinkPresentation, Network, or WidgetKit.

```mermaid
flowchart TD
	Import["External framework import"]
	Firebase{"Firebase/Auth/Firestore/Functions/Messaging?"}
	SocialLogin{"GoogleSignIn or AuthenticationServices?"}
	SocialLoginClassification{"Existing presentation/data cancellation/error classification?"}
	NetworkMeta{"Network or LinkPresentation implementation?"}
	UserNotifications{"UserNotifications?"}
	WidgetKit{"WidgetKit?"}
	Infra["Prefer DevLogInfra"]
	ErrorClassification["Keep narrow in DevLogData or DevLogPresentation only when matching the existing cancellation-classification pattern"]
	PresentationBadge["Allow in DevLogPresentation only for established badge/UI side effects"]
	Widget["Allow in DevLogWidget for app-side snapshot update/reload orchestration"]
	WidgetExtension["Allow in DevLogWidgetExtension rendering/timeline code"]
	Ask["Ask user before crossing layer"]

	Import --> Firebase
	Firebase -->|Yes| Infra
	Firebase -->|No| SocialLogin
	SocialLogin -->|Login implementation| Infra
	SocialLogin -->|Presentation/data error classification| SocialLoginClassification
	SocialLoginClassification -->|Matches existing pattern| ErrorClassification
	SocialLoginClassification -->|New or broader behavior| Ask
	SocialLogin -->|No| NetworkMeta
	NetworkMeta -->|Yes| Infra
	NetworkMeta -->|No| UserNotifications
	UserNotifications -->|Badge/UI side effect| PresentationBadge
	UserNotifications -->|Push or messaging service| Infra
	UserNotifications -->|Other| Ask
	UserNotifications -->|No| WidgetKit
	WidgetKit -->|Widget UI| WidgetExtension
	WidgetKit -->|App-side snapshot update/reload| Widget
	WidgetKit -->|Other| Ask
```

## Widget data-flow boundary

```mermaid
flowchart LR
	App["App runtime\nsession and mutation events"]
	WidgetBridge["DevLogWidget\nsync bus implementation\nsync/session handlers"]
	DataContracts["DevLogData\nwidget repository/updater contracts"]
	SnapshotInputs["DevLogData\nsnapshot input repository"]
	Snapshot["DevLogWidget\nsnapshot generation/persistence\nWidgetKit reload bridge"]
	WidgetModels["DevLogWidgetCore\nsnapshot models/factories/store contracts"]
	AppGroup["App Group storage\nShared defaults"]
	WidgetExtension["Widget extension\nWidgetKit UI"]

	App --> WidgetBridge
	WidgetBridge --> DataContracts
	DataContracts --> SnapshotInputs
	DataContracts --> Snapshot
	SnapshotInputs --> WidgetBridge
	Snapshot --> WidgetModels
	WidgetModels --> AppGroup
	AppGroup --> WidgetModels
	WidgetModels --> WidgetExtension
```

Widget UI should consume snapshot data. It should not fetch app services or domain repositories directly.

## Verification flow

```mermaid
flowchart TD
	Changed["Files changed"]
	Swift{"Swift/iOS project code changed?"}
	Docs{"Docs or harness only?"}
	Xcode["Build with Xcode Local MCP"]
	Diff["Inspect git diff scope"]
	NoBuild["No iOS build required"]
	Report["Report verification result"]

	Changed --> Swift
	Swift -->|Yes| Xcode
	Swift -->|No| Docs
	Docs -->|Yes| NoBuild
	Docs -->|No| Diff
	Xcode --> Diff
	NoBuild --> Diff
	Diff --> Report
```

## Required working notes

Before editing architecture code, the AI should be able to answer these questions:

1. What layer owns the changed concept today?
2. What layer should own it after the change?
3. Which imports prove the current dependency direction?
4. Which target dependency will change?
5. Does the change expose an external SDK outside its current boundary?
6. Does the change affect WidgetCore or WidgetExtension boundaries?
7. Is this change inside the current issue or PR scope?
8. Is user confirmation required before editing?

## Completion checklist

- DevLog-specific rules were loaded.
- Current files and imports were inspected.
- Ambiguous architecture decisions were confirmed by the user.
- Swift logic was preserved unless explicitly approved.
- Diff scope was checked.
- Xcode Local MCP build was used for Swift/iOS code changes.
- Docs-only or harness-only changes were reported as such, without claiming app build verification.
