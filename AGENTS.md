# AGENTS.md

## Purpose

This repository follows a **test-driven, behavior-focused development workflow**.

These instructions apply to coding agents working on Flutter applications for:

- Android
- iOS
- Windows
- macOS
- Linux

The goal is not to maximize test count. The goal is to use tests to drive reliable implementation, reduce regressions, and keep behavior explicit.

Agents should prefer small, verifiable changes over broad rewrites.

---

# Core Development Principle

For tasks that affect application behavior, use:

> **RED → GREEN → REFACTOR**

Meaning:

1. **RED** — write a test that describes the required behavior and confirm it fails for the expected reason.
2. **GREEN** — implement the smallest reasonable production change that makes the test pass.
3. **REFACTOR** — improve the implementation without changing behavior, then run the tests again.

Do not treat tests as an afterthought added after implementation.

---

# General Agent Rules

Before editing code:

1. Read the task carefully.
2. Inspect relevant code, tests, architecture, and conventions.
3. Identify the smallest observable behavior required.
4. Determine the appropriate test level.
5. Start with the test when the task is suitable for TDD.

Do not:

- rewrite unrelated code
- introduce new dependencies without a clear need
- modify architecture unnecessarily
- weaken tests to make implementation pass
- delete failing tests unless they are demonstrably obsolete or incorrect
- change public behavior that is outside the task
- assume mobile-only behavior when desktop platforms are supported
- assume desktop-only behavior when mobile platforms are supported

Prefer existing project patterns unless they are the source of the problem being fixed.

---

# TDD Workflow

## 1. RED

Write the smallest test that expresses the required behavior.

Then run that test.

A valid RED phase means the test fails because the requested behavior is missing or incorrect.

### Valid RED examples

- expected value differs from actual value
- expected widget is missing
- expected navigation does not occur
- expected validation error is not returned
- expected state transition does not happen
- expected persistence result is absent
- regression test reproduces an existing bug

### Invalid RED examples

These do **not** count as a successful RED phase:

- syntax error
- malformed test
- missing import caused by the test itself
- missing fixture or broken test setup
- unrelated compilation failure
- dependency resolution failure
- test runner misconfiguration
- platform tooling failure unrelated to the requested behavior

Fix the test environment first, then confirm a meaningful failure.

---

## 2. GREEN

Once RED is confirmed:

1. Keep the failing test as the specification.
2. Modify production code.
3. Implement the smallest reasonable change that satisfies the behavior.
4. Run the targeted test again.
5. Stop expanding scope once the test passes.

Do not solve hypothetical future requirements unless necessary for correctness.

Do not modify a correct test merely to match the implementation.

---

## 3. REFACTOR

After GREEN:

Refactor only when it materially improves:

- readability
- duplication
- naming
- cohesion
- testability
- state ownership
- platform abstraction
- maintainability

Do not alter behavior during refactoring.

Run the affected tests again after every meaningful refactor.

---

# Incremental Development

Prefer one behavior per TDD cycle.

Example:

```text
Behavior 1
RED → GREEN → REFACTOR

Behavior 2
RED → GREEN → REFACTOR

Behavior 3
RED → GREEN → REFACTOR
```

Avoid implementing an entire feature and then writing all tests afterward.

For a larger feature, break requirements into observable behaviors first.

Example:

```text
Feature: Save a note

Behavior 1:
Given valid input
When Save is pressed
Then a note is created

Behavior 2:
Given empty required input
When Save is pressed
Then validation is shown

Behavior 3:
Given storage failure
When Save is attempted
Then the user sees an error

Behavior 4:
Given a successful save
Then the screen returns to the expected state
```

---

# Flutter Test Strategy

Use the lowest test level that adequately verifies the behavior.

Preferred order:

1. Pure Dart unit test
2. Flutter widget test
3. Integration test
4. Platform-specific test when necessary

Do not use an integration test when a unit or widget test can prove the same behavior reliably.

---

# Unit Tests

Use unit tests for logic that does not require rendering Flutter widgets.

Typical targets:

- business rules
- validation
- calculations
- parsers
- formatters
- state reducers
- controllers
- use cases
- repositories with replaceable dependencies
- domain models
- state transitions
- mapping logic
- synchronization rules

Examples:

```dart
test('rejects negative quantity', () {
  expect(
    () => cart.add(product, quantity: -1),
    throwsArgumentError,
  );
});
```

Prefer deterministic pure-Dart tests whenever possible.

---

# Widget Tests

Use widget tests for Flutter UI behavior.

Typical targets:

- rendering based on state
- validation messages
- loading states
- empty states
- error states
- button behavior
- form interaction
- dialogs
- navigation triggers
- enabled/disabled controls
- responsive widget behavior

Test behavior visible to the user rather than internal widget structure.

Prefer:

```dart
expect(find.text('Invalid email'), findsOneWidget);
```

over assertions tightly coupled to implementation details such as internal private widget types.

---

# Integration Tests

Use integration tests for important cross-layer flows.

Examples:

- onboarding
- authentication
- checkout
- create/edit/delete flows
- persistence across screens
- file import/export
- database-backed workflows
- navigation across several screens
- plugin-backed behavior that cannot be represented adequately in widget tests

Integration tests should focus on high-value workflows.

Do not duplicate every unit and widget test at the integration level.

---

# Regression Tests

For bug fixes:

1. Reproduce the bug with a failing test whenever technically practical.
2. Confirm the test fails for the reported behavior.
3. Fix the bug.
4. Confirm the test passes.
5. Keep the test permanently to prevent regression.

Preferred workflow:

```text
bug report
→ failing regression test
→ fix
→ passing regression test
```

A bug fix without a regression test should be the exception, not the default.

If a reliable automated regression test is not practical, explain why.

---

# Mobile and Desktop Platform Awareness

Flutter code may run differently across:

- Android
- iOS
- Windows
- macOS
- Linux

Agents must consider platform differences when touching platform-sensitive functionality.

Common areas include:

- filesystem paths
- permissions
- notifications
- app lifecycle
- keyboard input
- mouse input
- hover behavior
- drag and drop
- window sizing
- multi-window behavior
- system tray
- clipboard
- URL launching
- file pickers
- camera
- media
- background execution
- startup behavior
- platform channels
- native plugins

Do not hard-code mobile assumptions into shared code.

Do not hard-code desktop assumptions into shared code.

Use platform abstraction when behavior genuinely differs.

---

# Responsive and Adaptive UI

When modifying UI that supports both mobile and desktop, consider:

- narrow phone layouts
- large phone layouts
- tablets
- resizable desktop windows
- keyboard navigation
- mouse interaction
- touch interaction

Do not rely only on a single fixed screen size.

Where practical, test behavior at multiple logical sizes.

Example:

```dart
await tester.binding.setSurfaceSize(const Size(390, 844));
```

and for desktop-like layouts:

```dart
await tester.binding.setSurfaceSize(const Size(1440, 900));
```

Reset any modified test surface size after the test.

Tests should validate meaningful layout behavior, not arbitrary pixel-perfect implementation details unless exact dimensions are part of the requirement.

---

# Input Methods

Desktop applications may use:

- mouse
- keyboard
- trackpad
- shortcuts

Mobile applications primarily use:

- touch
- software keyboard
- gestures

When relevant, verify that features remain usable using appropriate input methods.

Examples:

- Enter submits a form where intended
- Escape closes a dialog where intended
- keyboard shortcuts do not conflict with text input
- hover-only actions have accessible alternatives where needed
- tap targets remain usable on mobile
- scroll behavior works with touch and mouse

---

# State Management

Follow the state-management approach already used by the repository.

Examples may include:

- StatefulWidget
- ValueNotifier
- ChangeNotifier
- Provider
- Riverpod
- Bloc/Cubit
- Redux
- custom architecture

Do not introduce a new state-management library solely to implement a small task.

Test observable state behavior rather than package internals.

For example, test:

```text
loading → success
```

instead of testing whether a private method was called.

---

# Dependencies and Mocking

Prefer dependency injection through existing project patterns.

Use:

- fakes
- in-memory implementations
- simple stubs

when they provide clearer tests than mocks.

Use mocks mainly for boundaries such as:

- network APIs
- external services
- platform integrations
- analytics
- storage engines
- plugin wrappers

Avoid mocking your own internal implementation excessively.

A test that knows too much about internal method calls becomes fragile during refactoring.

Prefer:

```text
When save succeeds, the note appears in the repository
```

over:

```text
saveInternal() was called exactly once
```

unless the interaction itself is the required behavior.

---

# Flutter Plugins and Platform Channels

Plugins often behave differently in tests and across platforms.

When code depends on plugins:

1. isolate plugin access behind an application-owned abstraction where practical
2. unit test application behavior against a fake implementation
3. use integration/platform testing only for behavior that genuinely requires the plugin

Examples:

```text
NotificationService
FilePickerService
ClipboardService
WindowService
CameraService
ShareService
```

Avoid spreading direct plugin calls throughout business logic.

---

# Persistence

For persistence features, test important behaviors such as:

- create
- read
- update
- delete
- migrations
- serialization
- deserialization
- corrupted data handling
- version compatibility where relevant

When testing persistence logic, prefer temporary or in-memory storage if supported.

Do not let automated tests modify real user data.

---

# Networked Features

For API-driven features, cover relevant states:

```text
loading
success
empty
validation error
authentication error
server error
network failure
timeout
malformed response
```

Not every endpoint requires every case, but failure behavior must be considered.

Avoid relying on live external APIs in unit or widget tests.

Use controlled test doubles.

Live-service testing belongs in dedicated integration or end-to-end environments.

---

# Async Code

Flutter contains substantial asynchronous behavior.

Tests must account for:

- Futures
- Streams
- timers
- animations
- debounce
- delayed state updates

Prefer deterministic waiting.

Use:

```dart
await tester.pump();
```

or:

```dart
await tester.pumpAndSettle();
```

when appropriate.

Do not use arbitrary real-time delays unless unavoidable.

Avoid tests that depend on machine speed.

---

# Navigation

Test navigation as user-observable behavior.

Examples:

- successful login opens the home screen
- Cancel returns to the previous screen
- selecting an item opens its detail page
- protected routes redirect unauthenticated users

Do not over-test routing library internals.

---

# Error Handling

Expected failures should have explicit behavior.

Depending on context, errors may appear as:

- validation text
- SnackBar
- dialog
- error page
- retry state
- logged recoverable failure

Tests should verify the user- or system-visible outcome.

Do not silently swallow exceptions unless intentionally required.

---

# Test Naming

Test names should describe behavior.

Prefer:

```dart
test('returns false when token is expired', () {});
```

or:

```dart
testWidgets(
  'shows validation message when email is empty',
  (tester) async {},
);
```

Avoid vague names such as:

```text
test1
works
button test
service test
```

A reader should understand the requirement from the test name.

---

# Test Structure

Prefer a clear structure:

```text
Arrange
Act
Assert
```

Example:

```dart
test('removes purchased quantity from stock', () {
  // Arrange
  final inventory = Inventory(stock: 10);

  // Act
  inventory.purchase(3);

  // Assert
  expect(inventory.stock, 7);
});
```

Do not force comments when the test is already obvious.

---

# Test Independence

Tests must not depend on execution order.

Each test should initialize the state it needs.

Avoid shared mutable global state.

Clean up:

- temporary files
- database state
- streams
- controllers
- timers
- overridden bindings
- modified window/test sizes

when needed.

---

# Golden Tests

Golden tests are optional.

Use them when visual appearance itself is a requirement, such as:

- custom rendering
- highly stable components
- design-system primitives
- visual regression for critical layouts

Do not use golden tests as the default UI testing strategy.

They can be brittle across:

- Flutter versions
- fonts
- operating systems
- rendering engines
- pixel-density settings

Behavioral widget tests are usually preferred.

---

# Code Generation

If the project uses code generation, such as:

- build_runner
- freezed
- json_serializable
- Drift generation
- Riverpod generation

run the appropriate generator after modifying source definitions.

Do not manually edit generated files unless the project explicitly requires it.

Generated output should remain consistent with source definitions.

---

# Static Analysis

After relevant implementation work, run static analysis.

Usually:

```bash
flutter analyze
```

Do not ignore newly introduced analyzer errors.

Treat warnings according to repository policy.

Do not perform large unrelated lint cleanups during a focused task.

---

# Formatting

Use the project formatter.

Normally:

```bash
dart format .
```

For focused changes, formatting only affected files is acceptable.

Do not create formatting-only changes across unrelated files unless explicitly requested.

---

# Preferred Test Execution Order

During a TDD cycle:

```bash
flutter test path/to/target_test.dart
```

or run a specific test where practical.

After the targeted test passes:

```bash
flutter test path/to/relevant/tests
```

Before finishing a meaningful feature:

```bash
flutter test
```

Also run:

```bash
flutter analyze
```

when appropriate.

If the repository has custom commands, scripts, Melos, Make, task runners, or CI commands, prefer those documented by the project.

---

# Handling Existing Failing Tests

If unrelated tests already fail:

1. identify that they were failing independently of the current change when possible
2. do not modify unrelated code merely to force the entire suite green
3. continue with targeted validation if the requested work can still be verified
4. report the unrelated failure clearly

Do not claim the entire suite passes when it does not.

---

# When TDD Is Required

TDD should normally be used for:

- business logic
- calculations
- validation
- state transitions
- persistence behavior
- API behavior
- repository behavior
- permissions
- authentication logic
- bug fixes
- regressions
- synchronization logic
- domain rules
- non-trivial controller behavior

---

# When Strict TDD May Be Optional

Strict test-first development may be unnecessary for:

- exploratory prototypes
- visual-only tweaks
- copy changes
- trivial styling
- generated boilerplate
- build configuration changes
- dependency upgrades
- platform configuration
- signing configuration
- CI configuration

Even when test-first is not appropriate, existing tests must still be run when relevant.

If a configuration or dependency change fixes a regression that can be tested automatically, add a regression test where practical.

---

# Agent Decision Rule

Before implementation, classify the task internally as one of:

```text
TDD_REQUIRED
TDD_RECOMMENDED
TDD_NOT_APPLICABLE
```

Do not create files or metadata just for this classification unless the repository already uses such a workflow.

General guidance:

```text
behavior/business rule/bug
→ TDD_REQUIRED

UI interaction/stateful feature
→ TDD_RECOMMENDED or REQUIRED

purely visual/configuration/tooling task
→ TDD_NOT_APPLICABLE
```

When uncertain, prefer writing a useful behavioral test.

---

# Do Not Game Tests

Agents must never make tests meaningless merely to achieve GREEN.

Forbidden patterns include:

- replacing exact expectations with broad permissive assertions
- deleting assertions that expose a bug
- adding unconditional success paths
- catching all exceptions solely to make tests pass
- skipping failing tests without justification
- marking tests ignored without justification
- changing expected values to match incorrect production behavior

Example of a weak assertion:

```dart
expect(response.statusCode, anyOf(200, 400, 500));
```

when the requirement specifically expects success.

Tests must remain capable of detecting the missing or broken behavior they were created for.

---

# Scope Control

Keep changes focused.

Before changing a file, ask:

```text
Is this file necessary to satisfy the tested behavior?
```

If not, avoid changing it.

Do not perform opportunistic refactors unrelated to the task.

If a larger refactor appears necessary, explain the reason before expanding scope.

---

# Architecture

Respect the repository's current architecture.

Possible structures include:

```text
feature-first
layered
clean architecture
MVVM
MVC
Bloc-based
Riverpod-based
custom architecture
```

Do not impose a preferred architecture from another project.

When adding new code:

- place behavior near similar existing behavior
- follow existing naming conventions
- follow dependency direction already established
- avoid creating abstractions with only hypothetical future value

---

# Platform-Specific Production Code

Use platform-specific code only where behavior genuinely differs.

Prefer shared Dart code for shared behavior.

Possible techniques include:

- platform abstraction interfaces
- conditional imports
- platform implementations
- plugin wrappers

Avoid scattered checks such as:

```dart
if (Platform.isWindows) ...
```

throughout unrelated business logic when an existing abstraction can contain the difference.

---

# Native Code

Flutter repositories may contain native code under:

```text
android/
ios/
windows/
macos/
linux/
```

When modifying native code:

- minimize changes
- preserve generated/project-managed files where appropriate
- follow platform conventions
- validate the affected platform where tooling permits
- do not assume success on all platforms because one platform builds

If local tooling cannot validate a platform, state that limitation.

---

# Build Validation

Where relevant, validate affected targets.

Examples:

```bash
flutter build apk
flutter build appbundle
flutter build windows
flutter build linux
flutter build macos
flutter build ios --no-codesign
```

Do not run every platform build for every small task.

Choose builds based on the area changed and supported local tooling.

---

# Definition of Done

A task is complete when:

- required behavior is implemented
- meaningful tests exist where appropriate
- RED was confirmed for TDD work
- targeted tests pass
- relevant regression tests pass
- static analysis has no newly introduced errors
- code is formatted
- no unrelated changes were introduced
- platform-specific implications were considered
- unresolved limitations are reported

---

# Final Agent Report

At task completion, summarize concisely:

```text
Implemented:
- ...

Tests added/changed:
- ...

TDD result:
- RED: ...
- GREEN: ...
- REFACTOR: ...

Validation:
- flutter test ...
- flutter analyze ...
- platform/build validation ...

Notes:
- ...
```

Do not claim commands were run if they were not actually run.

If validation was impossible, state exactly what was not validated and why.

---

# Review Checklist

Before finishing, verify:

## TDD

- [ ] Was the behavior tested before implementation when applicable?
- [ ] Did the new test fail for the intended reason?
- [ ] Would the test fail again if the new behavior were removed?
- [ ] Was the smallest reasonable implementation used?
- [ ] Were tests kept meaningful?

## Flutter

- [ ] Is the chosen test level appropriate?
- [ ] Are async tests deterministic?
- [ ] Are widgets tested through observable behavior?
- [ ] Are plugin/platform dependencies isolated where useful?
- [ ] Were mobile and desktop implications considered?
- [ ] Does responsive behavior remain sensible?

## Quality

- [ ] Are changes focused?
- [ ] Are existing conventions followed?
- [ ] Are unrelated files untouched?
- [ ] Are analyzer issues avoided?
- [ ] Is code formatted?
- [ ] Are regressions covered?

---

# Guiding Principle

Tests are executable requirements.

Prefer:

```text
requirement
→ failing test
→ minimal implementation
→ passing test
→ safe refactor
```

over:

```text
large implementation
→ tests added afterward
```

The objective is not strict ceremony.

The objective is to make every meaningful behavior change small, explicit, verifiable, and difficult to regress.
