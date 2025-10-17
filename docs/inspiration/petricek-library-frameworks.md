# Library Patterns: Why Frameworks Are Evil
**Author**: Tomas Petricek  
**Source**: https://tomasp.net/blog/2015/library-frameworks/  
**Date**: 2015

---

## Core Argument

Tomas Petricek distinguishes between frameworks and libraries based on control flow:

- **Framework**: The framework is in charge of running the system with extensibility points you must implement
- **Library**: You are in charge of running the system and call library functions as needed

**Key Quote**: "The difference is that you call a library, but framework calls you."

## Three Problems with Frameworks

### 1. Non-composability

Frameworks cannot easily combine because each enforces its own structure. Libraries allow multiple libraries to coexist since you control the orchestration.

**Example**: Two web frameworks with different routing systems cannot be used together. Two libraries with routing functions can be composed by the user.

### 2. Poor explorability

Frameworks resist interactive testing. Petricek demonstrates loading the Suave web library into F# Interactive to experiment with functionality—impossible with framework-based designs that require implementing abstract methods.

**Example**: You can load a library and call `myFunction 42` in a REPL. A framework requires you to create classes, implement interfaces, and run the entire framework lifecycle.

### 3. Structural constraints

Frameworks dictate code organization. His XNA game example shows how inheriting from `Game` and implementing `Initialize()`, `Update()`, and `Draw()` forces an imperative, mutable-state approach rather than functional patterns.

**Example**: Framework forces this structure:
```fsharp
type MyGame() =
  inherit Game()
  override this.Initialize() = // Must use mutation
  override this.Update(time) = // Must use mutation
  override this.Draw(time) = // Must use mutation
```

Library allows this structure:
```fsharp
let gameLoop state =
  let newState = update state
  draw newState
  gameLoop newState
```

## Design Recommendations

### 1. Support interactive exploration

Enable users to load your library and experiment with functions directly, discovering capabilities through autocomplete and trial.

### 2. Use simple callbacks

Higher-order functions are acceptable, but functions accepting multiple callbacks with shared state suggest poor abstraction. Provide explicit alternatives alongside convenient wrappers.

**Bad**: `process(onStart, onUpdate, onEnd, sharedState)`  
**Good**: `map`, `filter`, `fold` - each callback is independent

### 3. Invert control with async/events

Replace virtual methods with events and asynchronous workflows, letting users maintain control over program flow while the library signals when actions are needed.

### 4. Provide multiple abstraction layers

Offer both low-level composable primitives and convenient high-level operations, allowing users to "step under the cover" when needed.

### 5. Design for composition

Expose sufficient type information so other libraries can interoperate, as demonstrated by FsLab's matrix-to-frame conversions through intermediate arrays.

## Relevance to johnny-declarative-decimal

Our architecture follows Petricek's library (not framework) approach:

**✅ We ARE a library:**
- Users call our functions: `identifiers.parse idDef "10.05"`
- No inheritance or abstract methods required
- Functions are pure and composable
- Can be loaded in Nix REPL for exploration

**✅ We provide multiple abstraction layers:**
- High-level: `mkJohnnyDecimal {}`
- Low-level: `numberSystems.parse decimal "42"`
- Users control the flow

**✅ We enable composition:**
- All functions are pure
- Clear input/output types
- No hidden state
- Can be combined with other Nix libraries

**❌ We AVOID framework patterns:**
- No "implement this interface"
- No inversion of control
- No lifecycle methods
- No hidden global state

This is why we chose divnix/std's `functions` blockType (library code) rather than framework-like blockTypes that enforce specific patterns.
