# Library Patterns: Multiple Levels of Abstraction
**Author**: Tomas Petricek  
**Source**: https://tomasp.net/blog/2015/library-layers/  
**Date**: 2015

---

## Overview

Tomas Petricek explores a fundamental design pattern for creating effective functional libraries: organizing functionality across multiple abstraction levels to serve diverse user needs.

## Core Design Principles

Petricek identifies four key library design principles:

1. **Iterative Design** - Begin with script files before formalizing into projects
2. **Composability** - Enable users to build complex behaviors from simpler components
3. **Avoid Callbacks** - Prevent structural constraints that limit flexibility
4. **Levels of Abstraction** - Provide tiered APIs serving different use cases

## The Levels of Abstraction Pattern

The pattern addresses a fundamental challenge: "how can we expose simple API that is simple to use and can be used in multiple different ways?"

The solution involves stratified APIs where:
- **High-level (80%)**: Single function calls handle typical scenarios
- **Medium-level (15%)**: Lower-level APIs enable customization
- **Low-level (4%)**: Direct access to underlying primitives
- **Edge cases (1%)**: Require community contributions

## Practical Examples

### Functional Lists

Higher-order functions like `List.map` and `List.filter` provide intuitive list processing. When specialized operations are needed—such as splitting lists at sign changes—users can access recursive pattern matching, then potentially abstract their solution back into reusable functions.

### 3D Graphics Library

The library demonstrates progression from "building castles" with four lines of code, through composing 3D objects with transformations, down to direct OpenGL rendering calls.

### Documentation Generation (F# Formatting)

The library offers:
- **High-level**: `ProcessDirectory` for batch operations
- **Medium-level**: `ProcessMarkdown` for individual file handling
- **Low-level**: Direct access to parsed document structures for custom transformations

## Key Benefits

This approach enables users to:
- Accomplish common tasks effortlessly
- Explore implementation details progressively
- Customize behavior without framework constraints
- Discover new patterns by combining lower-level primitives

## Contrast with Alternative Approaches

Petricek critiques interface-based designs (like Jekyll plugins or Rx's operator implementation) that impose "inversion of control," restricting users to predefined extension points rather than enabling free composition.

## Relevance to johnny-declarative-decimal

Our library architecture directly applies this pattern:

- **Layer 4 (Frameworks)**: 80% use case - `mkJohnnyDecimal {}` creates complete system
- **Layer 3 (Builders)**: 15% use case - Customize with parameters
- **Layer 2 (Composition)**: 4% use case - Build custom identifiers from fields
- **Layer 1 (Primitives)**: 1% use case - Direct number system manipulation

Users can start with high-level builders and progressively drop down to primitives when needed, exactly as Petricek recommends.
