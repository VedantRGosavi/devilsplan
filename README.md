# The Devil's Plan Games- webapp/ios-app

## Season 1 Games

Based on comprehensive research from Wikipedia and other sources, here is a detailed breakdown of all games from Season 1 of "The Devil's Plan".

### Main Matches

#### Day 1: The Virus Game
- **Type**: Social deduction game
- **Rules**:
  - Players randomly select a number dictating the order they select a card from twelve laid out inside the dealer room
  - Each card has a role: Terrorist (2), Fanatic (1), Officer (1), Ordinary Citizen (5), Researcher (2), Journalist (1)
  - **Terrorist**: Has one bullet to kill a player and one virus to infect a player (virus spreads through number order)
  - **Fanatic**: Tries to get killed by terrorists or virus; receives pieces based on how early they die
  - **Officer**: Gets one bullet each round to kill terrorists
  - **Ordinary Citizen**: One contains an antidote to the virus without knowing
  - **Researcher**: Tries to develop antidote by choosing one person each round
  - **Journalist**: Can investigate one player each round to discover their identity
- **Outcome**: Terrorists win if they kill all citizens; Citizens win if researchers develop the cure

#### Day 2: Rules Race
- **Type**: Board game with custom rules
- **Rules**:
  - Players create specific personal rules for themselves in a board game
  - Players roll a die with sides depicting one, one, two, three, prison and escape prison
  - Four offices scattered throughout the board grant benefits (escape prison card, roll again, change group rule)
  - First player to cross finish line receives three pieces, second two, third one
  - 10th player loses one piece, 11th loses three pieces, 12th loses five pieces
- **Strategy**: Players split into factions with different strategies; accumulating Escape Tickets proved crucial

#### Day 3: Secret Number
- **Type**: Deduction game
- **Rules**:
  - Each player has a secret number between 1 and 100
  - Players gain clues by joining private rooms and submitting tickets
  - Points awarded for accurately guessing others' numbers and keeping your own number secret
  - Player with least points is eliminated

#### Day 4: Zoo
- **Type**: Auction and pattern matching
- **Rules**:
  - Players fill a 5x5 grid with animal tiles
  - Each player has a secret sequence of three animals out of five possible
  - Each player has a condition card specifying one animal must appear more times than another
  - Players bid with chips during auctions to place tiles on the grid
  - Success depends on fulfilling personal winning conditions

#### Day 5: Laying Grass
- **Type**: Territory control with polyominos
- **Rules**:
  - Played on a 30x30 grid
  - Players take turns selecting polyominos to add to their territory
  - Each piece must touch one of their existing pieces
  - Players who surround key squares gain beneficial actions
  - Pieces awarded or deducted based on largest complete square within player's territory

#### Day 6: Equation High-Low
- **Type**: Mathematical bidding game
- **Rules**:
  - Players use number and mathematical operator cards to form equations
  - Players bid on whether they can form a result closest to 20 or closest to 1
  - All players' pieces are converted to chips before the game
  - Players are eliminated when they run out of chips until three players remain

### Prize Matches

#### Day 1: Cooperative Puzzle
- **Type**: Collaborative puzzle solving
- **Rules**:
  - Players stand on a roundabout that spins for three minutes
  - Each player stands in front of a puzzle for five seconds per rotation
  - Puzzles show empty geometrical shapes with pieces that must be correctly placed
  - If players complete all ten rounds, money is added to prize pot
  - If a player solves a puzzle twice, they receive one piece for every next puzzle solved

#### Day 2: Fragments of Memory
- **Type**: Memory and observation
- **Rules**:
  - Players observe a hospital scene and answer questions about it
  - Players enter the Dealer Room one at a time to answer questions
  - Players can pass (exit the game) or answer (continue to next question if correct)
  - All ten questions must be answered correctly to win prize money

#### Day 3: Word Tower
- **Type**: Word building
- **Rules**:
  - Group is given a tower of wooden letter blocks and a category
  - Players must use blocks to assemble as many English words in the category as there are players
  - All blocks must be used
  - Prize match succeeds if all words are formed

#### Day 4: Scale Game
- **Type**: Collaborative weight estimation
- **Rules**:
  - Players separated into groups of 2-3 in different rooms
  - Must jointly determine the mass of five differently colored blocks (1g-20g)
  - Each room may add cubes to virtual scales
  - All rooms see whether actions result in scale tilting one way, the other, or being balanced
  - When scale is balanced, players guess the five weights

#### Day 5: Montage
- **Type**: Pattern recognition
- **Rules**:
  - Players watch a slideshow of portrait photos, each shown for 3 seconds
  - When a duplicate photo appears, at least one player must buzz in
  - Limited number of erroneous buzzes allowed before failure
  - Success requires identifying all duplicates without exceeding error limit

#### Day 6: Four Player Three in a Row
- **Type**: Strategic game
- **Rules**:
  - Players separated into individual rooms
  - Play a three-in-a-row game against each other and an unknown fourth player
  - Colors assigned based on a set procedure not shared with players
  - Players succeed when they prevent the unknown fourth player from winning
  - Two players with most pieces proceed to final

### Special Games

#### Secret Chamber (Gomoku variant)
- **Type**: Memory-based abstract strategy
- **Rules**:
  - Hidden in prison with a 4-digit code (2024)
  - Blind gomoku where tiles are one-sided and placed face down
  - Player must memorize which tiles are theirs and which are opponent's
  - Winner receives 10-11 additional pieces
  - Loser is eliminated from the game

#### Final Match
- **Type**: Best of three 1:1 games
- **Rules**:
  - Three 1:1 games between the final two contestants
  - First player to win two games becomes the winner of Devil's Plan
  - Specific games not detailed in the source

## Season 2: Death Room (2025)

Season 2 is titled "The Devil's Plan: Death Room" and is set to premiere on Netflix on May 6, 2025. According to limited information available:

- There are more contestants (14) compared to Season 1's 12
- The format appears to follow a similar structure with main matches and prize matches
- Specific games and rules are not yet detailed in the sources

**Note**: As Season 2 is upcoming at the time of research, detailed information about the specific games and their rules is not yet available. Additional research will be needed once the season premieres or when official details are released.

## Visual Elements and Game Mechanics for iOS Implementation

For faithful replication in an iOS app, the following visual elements and mechanics should be considered:

1. **Social Deduction Games (Virus Game)**
   - Role cards with distinct visuals
   - Infection tracking system
   - Bullet/action allocation interface
   - Turn-based player interaction

2. **Board Games (Rules Race)**
   - Virtual dice with custom faces
   - Board visualization with offices and paths
   - Custom rule creation and display interface
   - Player position tracking

3. **Number Games (Secret Number)**
   - Number selection interface
   - Private room joining mechanism
   - Clue sharing system
   - Point calculation display

4. **Grid-Based Games (Zoo, Laying Grass)**
   - Interactive grid systems (5x5, 30x30)
   - Tile/polyomino selection and placement
   - Territory visualization
   - Auction/bidding interface

5. **Mathematical Games (Equation High-Low)**
   - Card selection interface
   - Equation building mechanism
   - Bidding system
   - Result calculation and comparison

6. **Memory Games (Fragments of Memory, Montage)**
   - Scene/image display system
   - Timed viewing mechanism
   - Question/answer interface
   - Buzz-in functionality

7. **Collaborative Games (Scale Game, Word Tower)**
   - Shared workspace visualization
   - Real-time or turn-based collaboration
   - Weight/balance visualization
   - Word building interface with letter blocks

8. **Abstract Strategy Games (Secret Chamber/Gomoku)**
   - Hidden information management
   - Memory-based gameplay
   - Turn tracking
   - Win condition verification

These elements will need to be designed with the black and neon purple theme specified by the client, ensuring both faithful replication of the games and an engaging user experience.


# iOS Game Adaptation Analysis for "The Devil's Plan"

## Overview
This document analyzes the suitability and technical requirements for adapting games from "The Devil's Plan" into an iOS application. Each game is evaluated based on complexity, visual requirements, multiplayer capabilities, and technical implementation considerations.

## Season 1 Games Analysis

### 1. The Virus Game (Day 1 Main Match)
**Suitability for iOS**: ★★★★☆ (4/5)
- **Complexity**: Medium-High
- **Key Technical Requirements**:
  - Role assignment system with hidden information
  - Turn-based action system (bullets, virus infection)
  - Visual representation of infection spread
  - Timer for rounds
- **UI Components Needed**:
  - Role cards with animations for reveal
  - Player status indicators (infected, killed, etc.)
  - Action buttons for role-specific abilities
  - Information panel showing game state
- **Multiplayer Considerations**:
  - Requires real-time or turn-based multiplayer
  - Server must maintain game state and role information
  - Hidden information management crucial
- **Implementation Approach**:
  - SwiftUI for UI components
  - Core Data for local game state
  - Firebase/custom backend for multiplayer
  - State machine pattern for game flow

### 2. Rules Race (Day 2 Main Match)
**Suitability for iOS**: ★★★★★ (5/5)
- **Complexity**: Medium
- **Key Technical Requirements**:
  - Virtual board game system
  - Custom rule creation interface
  - Dice rolling mechanics
  - Player movement tracking
- **UI Components Needed**:
  - Interactive game board with path visualization
  - Animated dice
  - Rule creation form with validation
  - Player tokens with position tracking
- **Multiplayer Considerations**:
  - Turn-based multiplayer suitable
  - Shared board state synchronization
  - Rule validation on server side
- **Implementation Approach**:
  - SpriteKit for board and animations
  - UIKit/SwiftUI for rule creation interface
  - State-based game progression
  - JSON for rule serialization

### 3. Secret Number (Day 3 Main Match)
**Suitability for iOS**: ★★★★★ (5/5)
- **Complexity**: Low-Medium
- **Key Technical Requirements**:
  - Number selection interface
  - Private room joining mechanism
  - Clue sharing system
  - Point calculation algorithm
- **UI Components Needed**:
  - Number selection wheel/pad
  - Private room UI with join/create options
  - Clue display area
  - Scoreboard with real-time updates
- **Multiplayer Considerations**:
  - Requires secure number storage
  - Private messaging between players
  - Server validation for guesses
- **Implementation Approach**:
  - SwiftUI for responsive interface
  - Secure enclave for number storage
  - WebSockets for real-time updates
  - Leaderboard using CloudKit

### 4. Zoo (Day 4 Main Match)
**Suitability for iOS**: ★★★★☆ (4/5)
- **Complexity**: High
- **Key Technical Requirements**:
  - 5x5 grid system
  - Animal tile placement mechanics
  - Auction system for bidding
  - Condition validation logic
- **UI Components Needed**:
  - Interactive grid with drag-drop support
  - Animal tiles with distinct visuals
  - Bidding interface with chip count
  - Condition card display
- **Multiplayer Considerations**:
  - Real-time auction system
  - Synchronized grid state
  - Hidden condition cards
- **Implementation Approach**:
  - UICollectionView for grid
  - Custom animations for tile placement
  - Timer-based auction rounds
  - Core Animation for visual effects

### 5. Laying Grass (Day 5 Main Match)
**Suitability for iOS**: ★★★☆☆ (3/5)
- **Complexity**: High
- **Key Technical Requirements**:
  - 30x30 grid system (challenging on smaller screens)
  - Polyomino selection and placement
  - Territory tracking and visualization
  - Square completion detection algorithm
- **UI Components Needed**:
  - Zoomable grid interface
  - Polyomino selection palette
  - Territory highlighting with different colors
  - Score display with territory size
- **Multiplayer Considerations**:
  - Turn-based with timeout
  - Large state synchronization
  - Move validation on server
- **Implementation Approach**:
  - Custom grid renderer with CATiledLayer
  - Gesture recognizers for placement
  - Efficient territory tracking algorithm
  - Optimized for iPad with scaled version for iPhone

### 6. Equation High-Low (Day 6 Main Match)
**Suitability for iOS**: ★★★★★ (5/5)
- **Complexity**: Medium
- **Key Technical Requirements**:
  - Card-based equation building
  - Mathematical expression evaluation
  - Bidding system
  - Elimination tracking
- **UI Components Needed**:
  - Card deck interface with math symbols
  - Equation building area
  - Bidding controls
  - Results comparison view
- **Multiplayer Considerations**:
  - Turn-based bidding
  - Equation validation
  - Synchronized elimination
- **Implementation Approach**:
  - SwiftUI for card interface
  - Expression parser for equation validation
  - Drag-and-drop for card arrangement
  - Animations for card dealing and results

### 7. Cooperative Puzzle (Day 1 Prize Match)
**Suitability for iOS**: ★★★☆☆ (3/5)
- **Complexity**: Medium
- **Key Technical Requirements**:
  - Rotating puzzle display system
  - Timed viewing mechanism
  - Geometric shape recognition
  - Collaborative progress tracking
- **UI Components Needed**:
  - Animated roundabout with player positions
  - Puzzle display with piece placement
  - Timer visualization
  - Progress indicator for all puzzles
- **Multiplayer Considerations**:
  - Synchronized rotation timing
  - Shared puzzle state
  - Individual contribution tracking
- **Implementation Approach**:
  - Core Animation for roundabout effect
  - SpriteKit for puzzle pieces
  - Server-synchronized timers
  - Haptic feedback for time intervals

### 8. Fragments of Memory (Day 2 Prize Match)
**Suitability for iOS**: ★★★★★ (5/5)
- **Complexity**: Medium
- **Key Technical Requirements**:
  - Scene observation interface
  - Question presentation system
  - Pass/answer decision mechanism
  - Sequential player progression
- **UI Components Needed**:
  - Detailed scene viewer with zoom capability
  - Question cards with multiple choice or text input
  - Pass/answer buttons with confirmation
  - Player queue visualization
- **Multiplayer Considerations**:
  - Sequential player turns
  - Question state management
  - Answer validation
- **Implementation Approach**:
  - High-resolution image caching
  - SwiftUI for question interface
  - State machine for player progression
  - Offline mode for practice

### 9. Word Tower (Day 3 Prize Match)
**Suitability for iOS**: ★★★★★ (5/5)
- **Complexity**: Low-Medium
- **Key Technical Requirements**:
  - Letter block visualization
  - Word formation interface
  - Category-based word validation
  - Collaborative progress tracking
- **UI Components Needed**:
  - 3D or 2D representation of letter blocks
  - Word building area with drag-drop
  - Category display and word list
  - Success/failure indicators
- **Multiplayer Considerations**:
  - Shared letter block pool
  - Word validation against dictionary
  - Collaborative input
- **Implementation Approach**:
  - SceneKit for 3D blocks or UIKit for 2D
  - Dictionary API for word validation
  - Haptic feedback for successful word formation
  - Voice announcements for categories

### 10. Scale Game (Day 4 Prize Match)
**Suitability for iOS**: ★★★★☆ (4/5)
- **Complexity**: Medium-High
- **Key Technical Requirements**:
  - Virtual scale visualization
  - Weight estimation mechanics
  - Room-based collaboration
  - Guess submission system
- **UI Components Needed**:
  - Animated scale with tilting physics
  - Colored block selection interface
  - Weight input controls
  - Room communication system
- **Multiplayer Considerations**:
  - Room-based grouping
  - Synchronized scale state
  - Collaborative guessing
- **Implementation Approach**:
  - SpriteKit for physics simulation
  - UIKit for weight controls
  - WebSockets for real-time scale updates
  - Group chat functionality

### 11. Montage (Day 5 Prize Match)
**Suitability for iOS**: ★★★★★ (5/5)
- **Complexity**: Low-Medium
- **Key Technical Requirements**:
  - Slideshow presentation system
  - Timed image display
  - Buzz-in mechanism
  - Error tracking
- **UI Components Needed**:
  - Full-screen image display
  - Timer visualization
  - Large buzz button
  - Error counter
- **Multiplayer Considerations**:
  - Synchronized image timing
  - Buzz-in priority determination
  - Shared error count
- **Implementation Approach**:
  - AVFoundation for timed slideshow
  - Haptic feedback for buzz
  - Image preloading for smooth transitions
  - Sound effects for duplicate detection

### 12. Four Player Three in a Row (Day 6 Prize Match)
**Suitability for iOS**: ★★★★☆ (4/5)
- **Complexity**: Medium
- **Key Technical Requirements**:
  - Three-in-a-row game board
  - Color assignment system
  - AI opponent for fourth player
  - Win condition detection
- **UI Components Needed**:
  - Interactive game board
  - Color selection interface
  - Player status indicators
  - Game progress visualization
- **Multiplayer Considerations**:
  - Three human players plus AI
  - Turn synchronization
  - Hidden color assignment
- **Implementation Approach**:
  - GameplayKit for AI opponent
  - UIKit for game board
  - Color-blind accessible design
  - Minimax algorithm for competitive AI

### 13. Secret Chamber (Gomoku variant)
**Suitability for iOS**: ★★★★☆ (4/5)
- **Complexity**: Medium-High
- **Key Technical Requirements**:
  - Memory-based tile placement
  - Hidden information management
  - Win condition detection
  - High-stakes gameplay mechanics
- **UI Components Needed**:
  - Face-down tile board
  - Placement history tracking
  - Visual cues for own vs. opponent tiles
  - Stakes visualization (pieces at risk)
- **Multiplayer Considerations**:
  - One-on-one gameplay
  - Server-side validation to prevent cheating
  - Hidden information integrity
- **Implementation Approach**:
  - Custom board renderer
  - Subtle visual cues for memory aid
  - Haptic feedback for placement
  - Dramatic animations for high stakes

### 14. Final Match (Best of Three)
**Suitability for iOS**: ★★★★★ (5/5)
- **Complexity**: Varies based on selected games
- **Key Technical Requirements**:
  - Game selection mechanism
  - Best-of-three tracking
  - Victory celebration
  - Game transition system
- **UI Components Needed**:
  - Game selection interface
  - Match score tracker
  - Winner announcement screen
  - Trophy/reward visualization
- **Multiplayer Considerations**:
  - One-on-one final match
  - Game selection agreement
  - Complete match history
- **Implementation Approach**:
  - Modular game loading system
  - Consistent UI framework across games
  - Dramatic win animations
  - Confetti and celebration effects

## Technical Implementation Recommendations

### Core Architecture
1. **Modular Game Framework**
   - Create a base `PlayableGame` protocol (already implemented)
   - Implement game-specific modules that conform to the protocol
   - Use dependency injection for services like networking and storage

2. **State Management**
   - Implement a robust state machine for each game
   - Use Combine framework for reactive state updates
   - Ensure state synchronization across devices

3. **UI/UX Considerations**
   - Maintain black and neon purple theme across all games
   - Implement adaptive layouts for different device sizes
   - Support both portrait and landscape orientations where appropriate
   - Ensure accessibility compliance

4. **Multiplayer Implementation**
   - Use GameKit for peer-to-peer gameplay
   - Implement custom server for more complex games
   - Consider Firebase Realtime Database for state synchronization
   - Implement robust error handling and reconnection logic

5. **Performance Optimization**
   - Use SpriteKit for games requiring physics or complex animations
   - Implement efficient algorithms for grid-based games
   - Optimize memory usage for large state games
   - Use background loading for assets

6. **Testing Strategy**
   - Unit tests for game logic
   - UI tests for interaction flows
   - Performance tests for resource-intensive games
   - Multiplayer simulation testing

## Prioritization for Implementation

### Phase 1 (MVP Games)
1. **Secret Number** - Simple mechanics, high engagement
2. **Equation High-Low** - Mathematical focus, straightforward UI
3. **Word Tower** - Vocabulary-based, collaborative

### Phase 2 (Medium Complexity)
4. **Rules Race** - Board game mechanics
5. **Montage** - Memory and observation
6. **Four Player Three in a Row** - Strategic gameplay

### Phase 3 (High Complexity)
7. **The Virus Game** - Complex social deduction
8. **Zoo** - Grid-based with auctions
9. **Secret Chamber** - Memory-based strategy

### Phase 4 (Technical Challenges)
10. **Laying Grass** - Large grid management
11. **Scale Game** - Physics simulation
12. **Cooperative Puzzle** - Timing and rotation mechanics

## Conclusion
The games from "The Devil's Plan" Season 1 offer a diverse range of mechanics that can be successfully adapted to iOS. While some games present technical challenges, particularly those with complex multiplayer requirements or large grid systems, all are feasible with proper implementation strategies.

The modular architecture already established in the app provides an excellent foundation for adding these games incrementally. By prioritizing implementation based on complexity and user engagement potential, we can deliver a compelling experience that faithfully recreates the high-IQ and strategic elements of the original show.

For Season 2 games, we will need to monitor for official details and adapt our implementation strategy accordingly once specific game mechanics are revealed.

