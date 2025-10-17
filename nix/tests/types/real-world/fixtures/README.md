# Real-World Community Flake Fixtures

This directory contains minimal fixture data simulating real-world community flake structures for testing our type system against actual patterns found in the wild.

## Structure

Each subdirectory represents a minimal reproduction of a community flake's structure:

- `nixpkgs/` - Simulates nixpkgs legacyPackages structure
- `home-manager/` - Simulates home-manager module patterns
- `nix-darwin/` - Simulates nix-darwin module patterns
- `popular-config/` - Simulates patterns from popular community configurations

## Purpose

These fixtures allow us to:
1. Test our type schemas against real-world output structures
2. Ensure compatibility with common community patterns
3. Validate edge cases found in actual flakes
4. Demonstrate dogfooding of our own type system

## Testing Approach

Tests use `tryEval` and validation helpers to safely test schema compatibility without requiring the actual remote flakes to be present during build time.
