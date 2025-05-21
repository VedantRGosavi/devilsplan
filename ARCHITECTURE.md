# EquationHighLow Game Architecture

## 1. Introduction

This document outlines the current architecture of the "EquationHighLow" game within the DevilsPlan application. It covers the main components, key architectural decisions made during development, successful changes, known limitations, and outstanding technical debt, much of which is a result of tool limitations encountered during development.

## 2. High-Level Architecture

The "EquationHighLow" game follows a structure that separates UI, presentation logic, game logic, data models, and services.

*   **`EquationHighLowView.swift` (UI)**:
    *   Responsible for rendering the game interface, displaying game state (cards, scores, player info), and capturing user input.
    *   Observes the `EquationHighLowEngine` for state changes to update the UI.

*   **`EquationHighLowViewModel.swift` (Presentation Logic - Partially Deprecated)**:
    *   Initially intended for presentation logic and UI-specific state management.
    *   Much of its responsibility for core game logic and state has been consolidated into `EquationHighLowEngine` to make the engine the single source of truth. Some UI-specific formatting or minor view state might still reside here, but core game data flows from the engine.

*   **`EquationHighLowEngine.swift` (Game Logic & State)**:
    *   The central component for game logic, acting as the single source of truth for the game state.
    *   Manages game lifecycle (hosting, joining, starting, ending rounds, game completion).
    *   Handles player actions (card selection, bidding), validates moves, and updates the game state accordingly.
    *   Contains the core equation calculation logic.
    *   Communicates with `EquationHighLowGameService` for multiplayer actions.
    *   Communicates with `GameProgressService` (via `ConvexClient`) for saving/loading game progress.

*   **`EquationHighLowModels.swift` (Data Structures)**:
    *   Defines all core data structures used by the game, including `GameState`, `Player`, `EquationCard`, `EquationGameData` (for network transmission), `EquationMove`, etc.
    *   Consolidates these models into a single file for clarity and ease of management.

*   **`EquationHighLowGameService.swift` (Multiplayer Networking)**:
    *   Handles the game-specific multiplayer communication using Multipeer Connectivity.
    *   Conforms to the `GameNetworkingService` protocol.
    *   Responsible for advertising, browsing, session management, and sending/receiving game data (state and moves) between peers.
    *   Interacts with the `EquationHighLowEngine` to relay network events and data.

*   **`ConvexClient.swift` & `GameProgressService.swift` (Backend API Communication)**:
    *   `ConvexClient` provides a generic interface for communicating with the Convex backend.
    *   `GameProgressService` (conceptually, though the implementation uses `ConvexClient` directly from the engine) is responsible for abstracting the saving and loading of game progress using `ConvexClient`.

## 3. Key Architectural Decisions & Changes Made

During development, several key architectural decisions and refactorings were implemented:

*   **Game State Management:** The `EquationHighLowEngine` was established as the primary owner and single source of truth for all game-related state. This centralized logic that was previously distributed, aiming for better consistency and easier state management.
*   **Data Models:** Core data models for the game were consolidated into `Views/Games/EquationHighLow/EquationHighLowModels.swift`.
*   **Multiplayer Networking:**
    *   `EquationHighLowGameService` was confirmed as the dedicated service for this game's multiplayer needs, utilizing Multipeer Connectivity.
    *   The generic `MultiplayerGameService` is not used by "EquationHighLow".
*   **Configuration:**
    *   The `gameId` is dynamically passed to the `EquationHighLowEngine` upon instantiation, allowing for flexible game session management.
    *   `ConvexClient`'s `baseURL` is configured via `Info.plist` (using the `CONVEX_URL` key), with fallback behavior for DEBUG builds (to `http://localhost:8000`) and a fatal error for misconfiguration in RELEASE builds.
    *   The multiplayer `serviceType` (e.g., "eqn-high-low") is a centralized constant within `EquationHighLowModels.swift`.
*   **Error Handling & Logging:**
    *   `AppLogger.swift` was introduced and integrated for structured, consistent logging across components, replacing most `print()` statements.
    *   `ConvexClient.swift` was updated to use a specific `ConvexError` enum (`networkError`, `decodingError`, `invalidResponse`) for more precise error reporting from backend interactions.
*   **Equation Logic:**
    *   The evaluation order for equations in `EquationHighLowEngine`'s `calculateEquationValue(from:)` function is explicitly documented as **sequential (left-to-right)**, not following standard mathematical operator precedence (PEMDAS/BODMAS).

## 4. Unit Tests

*   Unit tests for `ConvexClient.swift` have been created and are located in `DevilsPlanTests/ConvexClientTests.swift`.
*   These tests utilize a custom `MockURLProtocol` to simulate network responses and verify the client's behavior under various conditions (success, network errors, invalid HTTP responses, decoding errors).

## 5. Significant Known Issues & Technical Debt (Due to Tool Limitations)

Several critical areas of the "EquationHighLow" game could not be fully addressed or implemented due to persistent tool limitations, primarily the inability to reliably apply code modifications (`replace_with_git_merge_diff` tool failures). This has resulted in significant technical debt and impacts the game's production readiness.

*   **Multiplayer Edge Cases & Robustness (in `EquationHighLowEngine.swift`):**
    *   **Host Disconnection:** While initial logging was added, the full client-side logic to gracefully handle an abrupt host disconnection (e.g., transitioning to an error state, clearing game data) could not be reliably implemented. The `hostPlayerId` property and its propagation were intended to facilitate this.
    *   **Atomic Bid Operations:** The removal of client-side optimistic UI updates for chip deduction in `placeBid()` (to ensure bids are only confirmed by the host's authoritative state) was not completed.
    *   **Race Conditions & Move Sequencing:** Advanced handling for move sequencing or potential race conditions in multiplayer interactions was not implemented.
    *   **Reason:** Repeated failures to apply diffs to `EquationHighLowEngine.swift` prevented these critical robustness improvements.

*   **Invalid Equation Feedback (in `EquationHighLowEngine.swift` & `EquationHighLowModels.swift`):**
    *   The plan was to implement robust error handling for equation calculations (e.g., division by zero, malformed equations) by having `calculateEquationValue` throw specific `EquationError`s.
    *   An `EquationError` enum (conforming to `LocalizedError`) was intended to be added to `EquationHighLowModels.swift`.
    *   `EquationHighLowEngine` would then catch these errors, update an `@Published var equationError: String?` property, which the `EquationHighLowView` would display to the user.
    *   **Reason:** The inability to modify `EquationHighLowModels.swift` to add the `EquationError` enum blocked all subsequent changes in the engine and view for this feature.

*   **Multiplayer Progress Loading (in `EquationHighLowView.swift`):**
    *   The TODO comment in `loadGameProgress()` regarding the limitations of the current progress loading mechanism in a multiplayer context was updated.
    *   However, a more robust solution (e.g., disabling local progress loading if joining a multiplayer game, or more sophisticated sync logic) could not be implemented.
    *   **Reason:** Failures in applying diffs to `EquationHighLowView.swift` for even minor changes.

*   **Production Readiness:**
    *   Due to the unresolved issues above, especially concerning multiplayer stability, host disconnection, and lack of comprehensive error feedback for invalid game actions, the "EquationHighLow" game is **not considered fully production-ready**.

## 6. Future Work (If Tool Limitations are Overcome)

If the tool limitations preventing reliable code modification are addressed, the following areas should be prioritized:

*   **Complete Multiplayer Robustness:**
    *   Fully implement client-side handling of host disconnections in `EquationHighLowEngine`.
    *   Ensure bid operations are atomic by removing client-side optimistic updates in `EquationHighLowEngine`.
    *   Investigate and implement further measures to prevent race conditions if necessary.
*   **Implement Invalid Equation Feedback:**
    *   Successfully add the `EquationError` enum to `EquationHighLowModels.swift`.
    *   Refactor `calculateEquationValue` in `EquationHighLowEngine.swift` to throw these errors.
    *   Update `EquationHighLowEngine` and `EquationHighLowView` to display user-friendly error messages for issues like division by zero or malformed equations.
*   **Multiplayer Game Rejoin/Progress Sync:**
    *   Design and implement a robust system for players rejoining active multiplayer sessions that correctly syncs their progress with the authoritative host state, rather than relying on potentially stale local progress.
*   **Comprehensive Unit Testing:**
    *   Add extensive unit tests for `EquationHighLowEngine.swift`, covering all game logic, state transitions, move processing, and edge cases.
    *   Add unit tests for `EquationHighLowGameService.swift` if possible (may require further mocking capabilities for Multipeer Connectivity).

This document reflects the state as of the last development turn. The listed technical debt is critical for the game's stability and user experience.
