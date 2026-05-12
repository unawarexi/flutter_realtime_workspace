# TeamSpot Frontend Skills Playbook

Purpose
- This document is the required operating guide for all frontend work in this repository.
- Every task must start by checking this file, then following the flow and rules below.
- Primary goals: zero duplication, consistent UI and behavior, stable architecture, predictable user experience.

Mandatory Workflow For Every Task
1. Read this playbook first.
2. Identify the target feature and map it to existing primitives in core and app/components.
3. Reuse existing building blocks components/common, /shapess, /widget, /ui. core/constants and files before creating any new ui, widget, helper, style, animation, or service.
4. If a new utility is truly needed, place it in the correct folder and keep it generic and reusable.
5. Keep API, state, and UI separated.
6. Never put pure logic in our presentation or widgets UI. always put it in the usecase subfolders
7. Validate behavior and style against existing patterns.
8. Run analyzer on changed files and fix only relevant issues.

Architecture Overview
- Frontend foundation lives in lib/core.
- Reusable UI system lives in lib/app/components.
- Motion system source of truth lives in lib/core/animations.
- Domain-specific feature logic should consume core and components, not duplicate them.

Core Folder Guide

core/algo
- Home for generic algorithmic helpers.
- Use for reusable computation logic, not UI or network logic.

core/animations
- Central motion library. Reuse these before creating custom animations.
- page_transitions.dart
	- Route transition utilities.
	- SAnimations.fadeTransition and SAnimations.slideUpTransition are default page transitions.
- screen_animations.dart
	- Controller-based animation presets for full-screen and sequence effects.
	- Includes reveal, cascade, pulse, fade, and exit patterns.
	- Best when lifecycle control (start/reset/dispose) is needed.
- widget_animations.dart
	- Lightweight widget-level effects with minimal setup.
	- Includes fadeIn, scaleIn, slideUp helpers.

core/apis
- endpoints.dart is the single source of truth for backend route paths.
- Never hardcode endpoint strings inside repositories, services, providers, or screens.
- Add or modify API path constants here first when backend changes.

core/auth
- Third-party and local auth helpers.
- Keep auth provider SDK details encapsulated here.

core/config
- base_url.dart and environment.dart define runtime and environment configuration.
- Never scatter base URLs or env switches across features.

core/constants
- Design tokens and app-wide constants.
- Current canonical classes in this folder are T-prefixed (for example TColors, TSizes, TResponsive).
- Keep all spacing, color, size, text constants centralized.
- Do not introduce screen-local magic numbers when a token can be reused.

core/db
- hive.dart is local persistence integration.
- Caching should go through this layer, not direct Hive calls spread everywhere.

core/errors
- Global error types and failure mapping.
- Domain and UI should use these abstractions for consistent error handling.

core/network
- api_client.dart is the canonical HTTP client.
	- Includes connectivity checks, auth token injection, retry strategy, and upload support.
	- Repositories must use ApiClient.instance methods (get, post, put, patch, delete, upload).
- Other files in this folder provide account guard, API exception mapping, retry and connectivity behaviors.

core/services
- Long-lived integrations and runtime services.
- websocket.dart is the real-time transport abstraction.
- notification_service.dart is push and call-notification orchestration.
- storage_service.dart, translator.dart, and geolocation services live here.

core/utils
- Generic helpers and validators.
- Keep this folder pure utility. Avoid feature coupling here.

Components Folder Guide

app/components/common
- Shared flow-level screens and reusable user-facing common states.
- Use for broadly reused screen-level patterns (permissions, auth confirmation, unavailable states).

app/components/shapes
- Visual primitives for custom painters, clippers, and background motifs.
- Use these for consistent decorative language instead of ad-hoc painting per screen.

app/components/ui
- Core reusable UI primitives.
- button.dart
	- Primary button system and icon button patterns.
	- Reuse button variants and sizes before creating custom button widgets.
- input.dart
	- Standardized text input and search bar patterns.
	- Prefer these components for form consistency.
- card.dart, modal.dart, bottom_sheet.dart, skeleton.dart, toast_notifier.dart
	- Canonical containers, overlays, loading states, and feedback patterns.
- activity_indicator.dart, connectivity_toast.dart, dense_widgets.dart
	- Reusable UX helpers for status and compact UI compositions.

app/components/widgets
- Composite reusable widgets (app bars, floating actions, date/time pickers, form fields, spinners).
- app_bar.dart contains reusable top bar patterns for standard and home contexts.

Animation Usage Rules
1. Route transitions: use SAnimations in page_transitions.dart.
2. Screen sequences and multi-step choreography: use classes from screen_animations.dart.
3. Simple in-place widget effects: use SWidgetAnimations from widget_animations.dart.
4. Keep durations and easing aligned with existing presets.
5. Avoid adding animation controllers in feature screens when a preset already exists.

UI Consistency Rules
1. Use centralized tokens from core/constants for spacing, colors, sizing, and breakpoints.
2. Use reusable primitives from app/components/ui first.
3. Use reusable composites from app/components/widgets before creating feature-local variants.
4. Keep typography, corner radii, elevations, and paddings consistent with existing primitives.
5. Use responsive helpers from core/constants/responsive.dart for breakpoint behavior.

Behavior Consistency Rules
1. API calls only in repositories, never directly in widgets.
2. Repositories must call ApiEndpoints and ApiClient only.
3. Real-time events flow through WebSocketService, not ad-hoc socket wiring in UI.
4. Notification and incoming call UX must route through NotificationService.
5. Error handling should map to core/errors patterns, not raw exception dumping in UI.

Anti-Repetition Rules
Never do these
- Hardcode endpoint strings in repositories or providers.
- Duplicate button/input/modal implementations per feature.
- Create new constants inside feature files if equivalent token exists.
- Duplicate animation code if an existing preset can be configured.

Do these instead
- Extend existing primitives via optional params.
- Add new generic variant to shared UI component if multiple features need it.
- Promote repeated screen code into app/components/widgets or app/components/ui.
- Add new design tokens centrally in core/constants.

Folder Placement Decision Tree
1. Is it API path text?
	- Place in core/apis/endpoints.dart.
2. Is it HTTP behavior or transport logic?
	- Place in core/network.
3. Is it app-wide service integration?
	- Place in core/services.
4. Is it design token or layout scale?
	- Place in core/constants.
5. Is it a reusable primitive widget?
	- Place in app/components/ui.
6. Is it a reusable composed widget?
	- Place in app/components/widgets.
7. Is it decorative painter/clipper/background shape?
	- Place in app/components/shapes.
8. Is it screen-level animation preset?
	- Place in core/animations/screen_animations.dart.
9. Is it tiny widget animation utility?
	- Place in core/animations/widget_animations.dart.

Implementation Standards
1. Keep classes small and focused.
2. Prefer composition over inheritance in widgets.
3. Add parameters to shared components instead of cloning files.
4. Keep naming consistent and explicit.
5. Write concise comments only where intent is non-obvious.

PR And Task Checklist
1. Reused existing component/animation/service where possible.
2. Added or changed endpoints only in core/apis/endpoints.dart.
3. Kept design tokens centralized in core/constants.
4. Kept API logic in repository/network layers.
5. Preserved responsive behavior for mobile/tablet/desktop.
6. Validated changed files with analyzer.
7. Avoided introducing duplicate UI patterns.

Always-On Rule For Contributors And Agents
- Before implementing any frontend task, read this file and follow it as the authoritative execution standard.
- If any new pattern is introduced, update this file in the same change so future work stays consistent.
