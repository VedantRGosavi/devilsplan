# TheDevilsPlanGames Architecture Description

This document provides a comprehensive overview of each file in the application structure, explaining its role, responsibilities, and how it interacts with other components.

## Overall Architecture

TheDevilsPlanGames uses the MVVM (Model-View-ViewModel) architecture pattern combined with the Coordinator pattern for navigation. This provides clean separation of concerns while maintaining testable and maintainable code. The app is organized into modules reflecting individual games from "The Devil's Plan" series.

## App Directory

### TheDevilsPlanGamesApp.swift
- **Role**: Entry point for the SwiftUI application
- **Responsibilities**:
  - Initializes the app's environment and dependencies
  - Sets up the initial view hierarchy
  - Configures global app appearance
  - Initializes the main coordinator

### AppState.swift
- **Role**: Global state container for the application
- **Responsibilities**:
  - Maintains user session information
  - Tracks currently active game
  - Manages global app settings
  - Provides observable state using Combine framework

### AppCoordinator.swift
- **Role**: Main coordinator for the application
- **Responsibilities**:
  - Manages navigation flow between main app sections
  - Initializes and passes dependencies to child coordinators
  - Handles deep linking and universal links
  - Manages app lifecycle events

## Core Directory

### Navigation/MainCoordinator.swift
- **Role**: Primary navigation controller for game modules
- **Responsibilities**:
  - Manages transitions between game modules
  - Controls the flow from home screen to individual games
  - Handles back navigation and game completion
  - Sets up navigation patterns (push, modal, tab-based)

### DataPersistence/PersistenceController.swift
- **Role**: Core Data stack manager
- **Responsibilities**:
  - Initializes and configures Core Data persistent container
  - Provides context for database operations
  - Handles data migration when schema changes
  - Implements save/retrieve operations for game states

### DataPersistence/TheDevilsPlanGames.xcdatamodeld
- **Role**: Core Data model definition
- **Responsibilities**:
  - Defines entity schemas for data persistence
  - Models relationships between entities
  - Specifies attributes and types for game data
  - Contains versioning information for migrations

### Networking/APIService.swift
- **Role**: Network communication manager
- **Responsibilities**:
  - Handles API requests to backend services
  - Implements error handling for network operations
  - Manages authentication for secure endpoints
  - Provides data parsing for API responses

### Multiplayer/MultiplayerService.swift
- **Role**: Protocol defining multiplayer functionality
- **Responsibilities**:
  - Defines standard interface for multiplayer implementations
  - Specifies methods for player connections
  - Outlines data synchronization requirements
  - Establishes error handling patterns

### Multiplayer/GameKitService.swift
- **Role**: GameKit implementation of multiplayer service
- **Responsibilities**:
  - Implements GameKit integration for peer-to-peer gameplay
  - Manages matchmaking and player discovery
  - Handles turn-based game states
  - Synchronizes game data across devices

### Multiplayer/FirebaseService.swift
- **Role**: Firebase implementation of multiplayer service
- **Responsibilities**:
  - Implements Firebase Realtime Database for multiplayer
  - Manages real-time synchronization of game states
  - Handles authentication and player profiles
  - Provides fallback when GameKit is unavailable

### Utilities/Extensions.swift
- **Role**: Swift language and framework extensions
- **Responsibilities**:
  - Extends standard types with app-specific functionality
  - Provides convenience methods for common operations
  - Implements reusable UI helpers
  - Offers utility functions for data formatting

### Utilities/Constants.swift
- **Role**: Application-wide constant definitions
- **Responsibilities**:
  - Defines string constants to avoid magic strings
  - Establishes numeric constants for animations and timing
  - Provides configuration values
  - Centralizes feature flags

## UI Directory

### MainView.swift
- **Role**: Primary container view for the application
- **Responsibilities**:
  - Implements the main navigation container (TabView/NavigationView)
  - Sets up the root view hierarchy
  - Manages transitions between main app sections
  - Handles top-level UI state

### Components/GameCardView.swift
- **Role**: Reusable game selection card component
- **Responsibilities**:
  - Presents game information in a consistent card format
  - Handles tap interactions for game selection
  - Displays game thumbnail, title, and description
  - Adapts to different screen sizes and orientations

### Theme/Colors.swift
- **Role**: Color palette definition for the application
- **Responsibilities**:
  - Defines the black and neon purple brand colors
  - Provides semantic color constants (primary, secondary, etc.)
  - Implements light/dark mode adaptations
  - Ensures color accessibility compliance

### Theme/Fonts.swift
- **Role**: Typography system for the application
- **Responsibilities**:
  - Registers and loads custom fonts
  - Defines text styles for different UI elements
  - Establishes font scaling for accessibility
  - Provides consistent typography across the app

### Resources/Assets.xcassets
- **Role**: Image and icon asset catalog
- **Responsibilities**:
  - Contains app icons in various sizes
  - Stores game icons and illustrations
  - Manages image assets with appropriate resolutions
  - Organizes visual elements by categories

### Resources/Sounds
- **Role**: Audio asset directory
- **Responsibilities**:
  - Contains game sound effects and music
  - Organizes audio files by game and type
  - Stores sounds in appropriate formats
  - Includes accessibility audio cues

## Modules Directory

### Home/HomeView.swift
- **Role**: Main game selection screen
- **Responsibilities**:
  - Displays available games in a grid or list
  - Implements search and filtering functionality
  - Handles navigation to selected games
  - Shows player stats and achievements

### Home/HomeViewModel.swift
- **Role**: View model for the home screen
- **Responsibilities**:
  - Provides data for the home view
  - Manages game filtering and sorting logic
  - Handles user interactions and navigation requests
  - Fetches game metadata and player progress

### GameCommon/PlayableGame.swift
- **Role**: Protocol defining game module interface
- **Responsibilities**:
  - Establishes standard API for all game implementations
  - Defines lifecycle methods (start, pause, resume, end)
  - Specifies required game state management
  - Outlines player interaction requirements

### GameCommon/GameState.swift
- **Role**: Common game state definitions
- **Responsibilities**:
  - Defines universal game states (not started, in progress, paused, etc.)
  - Provides state transition logic
  - Implements common state persistence
  - Handles state restoration after app restart

### GameCommon/Player.swift
- **Role**: Player model shared across games
- **Responsibilities**:
  - Defines player attributes and capabilities
  - Manages player identification
  - Tracks player statistics and achievements
  - Handles player persistence

### SecretNumberGame/Views/SecretNumberView.swift
- **Role**: Main UI for the Secret Number game (Priority 1)
- **Responsibilities**:
  - Implements the game board and number selection interface
  - Displays clues and player information
  - Provides intuitive number submission controls
  - Shows game progress and results

### SecretNumberGame/ViewModels/SecretNumberViewModel.swift
- **Role**: View model for Secret Number game
- **Responsibilities**:
  - Manages game state and logic
  - Processes player number selections and guesses
  - Calculates scores and determines winners
  - Handles multiplayer synchronization

### SecretNumberGame/Logic/SecretNumberLogicController.swift
- **Role**: Core game logic for Secret Number
- **Responsibilities**:
  - Implements rules for clue generation
  - Validates guesses against secret numbers
  - Calculates point distribution
  - Manages game progression and completion

### SecretNumberGame/Models/SecretNumberModels.swift
- **Role**: Data models for Secret Number game
- **Responsibilities**:
  - Defines game-specific data structures
  - Models player secrets and guesses
  - Represents clues and their relationships
  - Provides serialization for persistence

### EquationHighLowGame/Views/EquationHighLowView.swift
- **Role**: Main UI for the Equation High-Low game (Priority 2)
- **Responsibilities**:
  - Displays mathematical cards and equation building area
  - Implements bidding interface for high/low targets
  - Shows player chips and elimination status
  - Presents equation results and comparisons

### EquationHighLowGame/ViewModels/EquationHighLowViewModel.swift
- **Role**: View model for Equation High-Low game
- **Responsibilities**:
  - Manages equation cards and player hands
  - Processes bidding decisions
  - Calculates equation results
  - Handles player elimination logic

### EquationHighLowGame/Logic/EquationHighLowLogicController.swift
- **Role**: Core game logic for Equation High-Low
- **Responsibilities**:
  - Implements equation evaluation algorithm
  - Validates equation formation rules
  - Determines winners of bidding rounds
  - Manages chip distribution and elimination

### EquationHighLowGame/Models/EquationHighLowModels.swift
- **Role**: Data models for Equation High-Low game
- **Responsibilities**:
  - Defines card types and properties
  - Models equations and their components
  - Represents bids and their criteria
  - Provides serialization for game state

### WordTowerGame/Views/WordTowerView.swift
- **Role**: Main UI for the Word Tower game (Priority 3)
- **Responsibilities**:
  - Displays letter blocks and word formation area
  - Shows category information and word requirements
  - Implements drag-and-drop for letter arrangement
  - Presents validation feedback and results

### WordTowerGame/ViewModels/WordTowerViewModel.swift
- **Role**: View model for Word Tower game
- **Responsibilities**:
  - Manages letter blocks and their arrangement
  - Processes word submissions and validation
  - Tracks category requirements and completion
  - Handles collaborative word building

### WordTowerGame/Logic/WordTowerLogicController.swift
- **Role**: Core game logic for Word Tower
- **Responsibilities**:
  - Implements word validation against dictionaries
  - Generates categories and word requirements
  - Manages block distribution and arrangement rules
  - Determines successful completion criteria

### WordTowerGame/Models/WordTowerModels.swift
- **Role**: Data models for Word Tower game
- **Responsibilities**:
  - Defines letter block properties
  - Models words and their validation status
  - Represents categories and their constraints
  - Provides serialization for word structures

### Profile/ProfileView.swift
- **Role**: Player profile screen (simplified for quick development)
- **Responsibilities**:
  - Displays player information and statistics
  - Shows game achievements and progress
  - Provides settings for player customization
  - Implements profile editing functionality

### Settings/SettingsView.swift
- **Role**: Application settings screen (simplified for quick development)
- **Responsibilities**:
  - Offers controls for sound and music volume
  - Provides accessibility options
  - Manages notification preferences
  - Handles account and privacy settings

## Supporting Files

### Info.plist
- **Role**: Application configuration file
- **Responsibilities**:
  - Defines app capabilities and permissions
  - Specifies supported orientations and devices
  - Configures app transport security settings
  - Contains bundle identifier and version information

## Integration Points

### Navigation Flow
- The AppCoordinator initializes the MainCoordinator
- MainCoordinator presents the HomeView as the initial screen
- HomeView allows selection of games, triggering navigation to game modules
- Each game module handles its internal navigation
- Back navigation returns to HomeView

### Data Flow
- AppState provides global state accessible throughout the app
- ViewModels fetch and update data through services
- Models are passed between components using protocols
- Core Data persistence handled by PersistenceController
- Network data flows through APIService

### Multiplayer Integration
- Games access multiplayer through the MultiplayerService protocol
- Implementation details are abstracted behind the protocol
- GameKit or Firebase implementations can be swapped as needed
- Game modules remain agnostic of the specific multiplayer technology

### UI Consistency
- Theme elements (Colors, Fonts) ensure visual consistency
- Reusable components like GameCardView maintain UI standards
- SwiftUI previews provide visual validation during development
- Adaptive layouts accommodate various device sizes