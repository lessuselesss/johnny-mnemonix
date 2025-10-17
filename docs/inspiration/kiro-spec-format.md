# Kiro.dev Specification Format
**Source**: https://kiro.dev/docs/specs/concepts/  
**Purpose**: Spec-driven development workflow for AI-assisted coding

---

## Overview

Kiro generates three foundational files for each specification that bridge conceptual requirements and technical implementation:

1. **requirements.md** - User stories with acceptance criteria in EARS notation
2. **design.md** - Technical architecture, sequence diagrams, and implementation considerations
3. **tasks.md** - Detailed implementation plan with discrete, trackable tasks

## Three-Phase Workflow Structure

The specification process follows a logical progression:

### Phase 1: Requirements
Define user stories and acceptance criteria using structured EARS notation.

**Output**: `requirements.md`

**Contents**:
- User stories in "As a... I want... So that..." format
- Acceptance criteria in EARS notation
- Business context and constraints

### Phase 2: Design
Document technical architecture, sequence diagrams, and implementation considerations.

**Output**: `design.md`

**Contents**:
- System architecture overview
- Component diagrams
- Data models and interfaces
- Sequence diagrams showing interactions
- Error handling strategy
- Testing strategy
- Implementation considerations

### Phase 3: Implementation Planning
Break work into discrete, trackable tasks with clear descriptions and outcomes.

**Output**: `tasks.md`

**Contents**:
- Checklist of coding tasks
- Task dependencies
- Status tracking (pending/in-progress/completed)
- Clear outcomes for each task

### Phase 4: Execution
Track progress as tasks are completed with ability to update and refine specs.

**Workflow**:
- Mark tasks in-progress
- Complete implementation
- Mark tasks completed
- Update specs if requirements change

## EARS Notation Format

EARS (Easy Approach to Requirements Syntax) provides structured requirement writing.

### Pattern

```
WHEN [condition/event]
THE SYSTEM SHALL [expected behavior]
```

### Example

```
WHEN a user submits a form with invalid data
THE SYSTEM SHALL display validation errors next to the relevant fields
```

### Benefits

1. **Clarity**: Unambiguous language removes interpretation
2. **Testability**: Enables direct translation to test cases
3. **Traceability**: Track individual requirements through implementation
4. **Completeness**: Encourages thorough condition analysis

### Additional Forms

**Ubiquitous Requirements** (always true):
```
THE SYSTEM SHALL [behavior]
```

**Event-driven Requirements**:
```
WHEN [event occurs]
THE SYSTEM SHALL [response]
```

**State-driven Requirements**:
```
WHILE [in state]
THE SYSTEM SHALL [behavior]
```

**Optional Feature Requirements**:
```
WHERE [feature is included]
THE SYSTEM SHALL [behavior]
```

## Design Documentation Structure

### Components Section
- High-level architecture
- Component responsibilities
- Component interactions

### Data Models Section
- Entity definitions
- Relationships
- Data constraints

### Interfaces Section
- API contracts
- Function signatures
- Input/output specifications

### Sequence Diagrams
- User flows
- System interactions
- Error scenarios

### Error Handling
- Error types
- Recovery strategies
- User feedback

### Testing Strategy
- Unit test approach
- Integration test approach
- E2E test approach

## Task Execution Interface

### Task Structure

```markdown
## Phase 1: Foundation
- [ ] Task 1: Brief description
  - Outcome: What success looks like
- [ ] Task 2: Another task
  - Outcome: Expected result
```

### Status Tracking

Tasks progress through states:
- `[ ]` - Pending
- `[~]` or in-progress marker - In Progress
- `[x]` - Completed

### Real-time Updates

The tasks.md file provides real-time status tracking, allowing teams to mark tasks as in-progress or completed while maintaining an updated development status view.

## Integration with Our Project

### How We Adapted Kiro Format

Our CLAUDE.md files follow the three-phase structure:

#### Phase 1: Requirements
- User stories: "As a library user I want..."
- Acceptance criteria in list format (similar to EARS)
- System constraints and dependencies

#### Phase 2: Design
- **divnix/std Integration** section (added for our context)
- Component structure
- API contracts
- Data flow diagrams

#### Phase 3: Implementation
- **TDD Strategy** section
- Test-first approach (RED → GREEN → REFACTOR)
- Complete test specifications before implementation
- Implementation order with time estimates
- Success criteria

### Key Differences

**Kiro**:
- Separate files (requirements.md, design.md, tasks.md)
- EARS notation for all requirements
- Task-based execution tracking

**Our Adaptation**:
- Single CLAUDE.md per component
- User stories + acceptance criteria lists
- TDD test specifications (tests ARE the tasks)
- divnix/std integration documentation

### Why We Adapted

1. **Single Source of Truth**: One file per component is easier to maintain
2. **TDD Focus**: Tests serve as both specification and tasks
3. **Nix Context**: Need to document std integration patterns
4. **Library vs. Application**: Library specs need API contracts more than user flows

## Example: Our Format vs. Kiro Format

### Kiro Format

**requirements.md**:
```markdown
## US-1: Parse Numbers
As a user
I want to parse strings into numbers
So that I can work with numeric data

### Acceptance Criteria
WHEN a user provides a valid decimal string
THE SYSTEM SHALL return the integer value

WHEN a user provides an invalid string
THE SYSTEM SHALL return null
```

**design.md**:
```markdown
## Architecture
Parser component with validation

## API
- parse(system, string) -> int | null
```

**tasks.md**:
```markdown
- [ ] Implement parse function
- [ ] Add validation logic
- [ ] Write tests
```

### Our Format

**CLAUDE.md** (all in one):
```markdown
## Phase 1: Requirements

### US-PRIM-1: Number System Operations
**As a** library user
**I want** to parse strings to numbers
**So that** I can work with different bases

**Acceptance Criteria**:
- Parse valid strings to integers
- Return null for invalid input

## Phase 2: Design

### API Contract
```nix
parse = NumberSystem -> String -> Int | Null;
```

## Phase 3: Implementation (TDD)

### Tests (act as tasks)
```nix
# 🔴 RED: Parse valid string
testParse = {
  expr = parse decimal "42";
  expected = 42;
};

# 🔴 RED: Invalid returns null
testParseInvalid = {
  expr = parse decimal "invalid";
  expected = null;
};
```
```

## Resources

- **Kiro Docs**: https://kiro.dev/docs/specs/concepts/
- **EARS Notation**: Industry standard for requirements
- **Our Implementation**: See nix/lib/*/CLAUDE.md files
