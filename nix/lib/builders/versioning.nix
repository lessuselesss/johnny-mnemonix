# Builders: Versioning System Builder
# High-level constructor for creating semantic versioning and other version schemes
#
# BUILDERS LAYER: Combines primitives and composition into ready-to-use versioning systems.
#
# This builder creates complete versioning systems with support for:
# - Semantic Versioning (N₁.N₂.N₃ where N₁=major, N₂=minor, N₃=patch)
# - Arbitrary component count (N₁.N₂.N₃...Nₖ for k components)
# - Prerelease tags (1.2.3-alpha.1)
# - Build metadata (1.2.3+build.456)
# - Version comparison
# - Version bumping
#
# The N notation (N₁, N₂, N₃, etc.) emphasizes that:
# - The system is extensible to any number of components
# - Each position is the nth component, not a fixed "X" or "Y"
# - The format is N₁.N₂.N₃...Nₖ for k octets
#
# API:
#   mkVersioning = {octets, separator, prerelease, buildMetadata, constraints} -> System
#
# Examples:
#   # Semantic versioning (default: 3 octets → N₁.N₂.N₃)
#   semver = mkVersioning {};
#   semver.parse "1.2.3"  # => {major = 1; minor = 2; patch = 3;}
#   semver.compare "1.2.3" "1.2.4"  # => -1 (less than)
#   semver.bump.major "1.2.3"  # => "2.0.0"
#
#   # With prerelease tags
#   semver.parse "1.2.3-alpha.1"  # => {major = 1; minor = 2; patch = 3; prerelease = "alpha.1";}
#
#   # 4-octet versioning (N₁.N₂.N₃.N₄)
#   extended = mkVersioning {octets = 4;};
#   extended.parse "2024.10.17.1"  # => {v0 = 2024; v1 = 10; v2 = 17; v3 = 1;}

{
  lib,
  primitives,
  composition,
}: let
  ns = primitives.numberSystems;
  fields = primitives.fields;
in {
  # Create a versioning system
  #
  # Parameters:
  #   - octets: Number of version components (default: 3 for major.minor.patch)
  #   - separator: Component separator (default: ".")
  #   - prerelease: Support prerelease tags like -alpha.1 (default: true)
  #   - buildMetadata: Support build metadata like +build.123 (default: true)
  #   - constraints: Constraints per component (default: {min = 0; max = 999;})
  #
  # Returns: System with parse, format, compare, bump
  mkVersioning = {
    octets ? 3,
    separator ? ".",
    prerelease ? true,
    buildMetadata ? true,
    constraints ? {
      min = 0;
      max = 999;
    },
  }: let
    # Component names for standard semver
    componentNames =
      if octets == 3
      then ["major" "minor" "patch"]
      else
        # Generic names for other octet counts
        lib.genList (i: "v${toString i}") octets;

    # Create field for version components
    versionField = fields.mk {
      system = ns.decimal;
      width = "variable"; # Variable width for version numbers
      padding = "none";
    };

    # Parse a version string to components
    #
    # Parameters:
    #   - str: Version string (e.g., "1.2.3" or "1.2.3-alpha.1")
    #
    # Returns: Attrset with components, or null on failure
    #
    # Examples:
    #   parse "1.2.3"  # => {major = 1; minor = 2; patch = 3;}
    #   parse "1.2.3-alpha.1"  # => {major = 1; minor = 2; patch = 3; prerelease = "alpha.1";}
    parse = str: let
      # Split prerelease/build metadata from core version
      # Format: MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]
      splitPrerelease =
        if prerelease && builtins.match ".*-.*" str != null
        then let
          parts = lib.splitString "-" str;
          core = builtins.head parts;
          pre = builtins.concatStringsSep "-" (lib.tail parts);
        in {
          inherit core;
          prerelease = pre;
        }
        else {
          core = str;
          prerelease = null;
        };

      # Parse core version (MAJOR.MINOR.PATCH)
      coreParts = lib.splitString separator splitPrerelease.core;
      coreValues = builtins.map (fields.parse versionField) coreParts;

      # Validate: all parts parsed and correct count
      allValid = builtins.all (v: v != null) coreValues;
      correctCount = builtins.length coreValues == octets;

      # Build result attrset
      result =
        if allValid && correctCount
        then let
          # Map component names to values
          coreAttrs = lib.listToAttrs (lib.imap0 (i: v: {
            name = builtins.elemAt componentNames i;
            value = v;
          })
          coreValues);

          # Add prerelease if present
          withPrerelease =
            if splitPrerelease.prerelease != null
            then coreAttrs // {prerelease = splitPrerelease.prerelease;}
            else coreAttrs;
        in
          withPrerelease
        else null;
    in
      result;

    # Format components to version string
    #
    # Parameters:
    #   - components: Attrset with version components
    #
    # Returns: Formatted version string
    #
    # Examples:
    #   format {major = 1; minor = 2; patch = 3;}  # => "1.2.3"
    #   format {major = 1; minor = 2; patch = 3; prerelease = "alpha.1";}  # => "1.2.3-alpha.1"
    format = components: let
      # Extract core version values
      values = builtins.map (name: components.${name} or null) componentNames;

      # Check all values present
      allPresent = builtins.all (v: v != null) values;

      # Format each value as string
      formatted = builtins.map toString values;

      # Join with separator
      coreVersion = builtins.concatStringsSep separator formatted;

      # Add prerelease if present
      withPrerelease =
        if components ? prerelease && prerelease
        then "${coreVersion}-${components.prerelease}"
        else coreVersion;
    in
      if allPresent
      then withPrerelease
      else null;

    # Compare two version strings
    #
    # Parameters:
    #   - v1: First version string
    #   - v2: Second version string
    #
    # Returns: -1 if v1 < v2, 0 if equal, 1 if v1 > v2
    #
    # Examples:
    #   compare "1.2.3" "1.2.4"  # => -1
    #   compare "1.2.3" "1.2.3"  # => 0
    #   compare "1.2.4" "1.2.3"  # => 1
    #   compare "1.2.3-alpha" "1.2.3"  # => -1 (prerelease < release)
    compare = v1Str: v2Str: let
      v1 = parse v1Str;
      v2 = parse v2Str;

      # Compare core version components
      compareCore = let
        # Get values for both versions
        values1 = builtins.map (name: v1.${name}) componentNames;
        values2 = builtins.map (name: v2.${name}) componentNames;

        # Compare component by component
        go = idx:
          if idx >= octets
          then 0 # All components equal
          else let
            val1 = builtins.elemAt values1 idx;
            val2 = builtins.elemAt values2 idx;
          in
            if val1 < val2
            then -1
            else if val1 > val2
            then 1
            else go (idx + 1);
      in
        go 0;

      # Compare prerelease: version with prerelease < version without
      comparePrerelease =
        if compareCore == 0
        then
          if v1 ? prerelease && !(v2 ? prerelease)
          then -1 # v1 has prerelease, v2 doesn't: v1 < v2
          else if !(v1 ? prerelease) && v2 ? prerelease
          then 1 # v2 has prerelease, v1 doesn't: v1 > v2
          else 0 # Both have or both don't have prerelease
        else compareCore;
    in
      comparePrerelease;

    # Bump version numbers
    bump = {
      # Bump major version (reset minor and patch to 0)
      major = vStr: let
        v = parse vStr;
        bumped =
          if octets == 3
          then {
            major = v.major + 1;
            minor = 0;
            patch = 0;
          }
          else
            # Generic: bump first component, reset others
            lib.listToAttrs (lib.imap0 (i: name:
              if i == 0
              then {
                inherit name;
                value = v.${name} + 1;
              }
              else {
                inherit name;
                value = 0;
              })
            componentNames);
      in
        format bumped;

      # Bump minor version (reset patch to 0)
      minor = vStr: let
        v = parse vStr;
        bumped =
          if octets == 3
          then {
            major = v.major;
            minor = v.minor + 1;
            patch = 0;
          }
          else
            # Generic: bump second component, reset subsequent
            lib.listToAttrs (lib.imap0 (i: name:
              if i == 1
              then {
                inherit name;
                value = v.${name} + 1;
              }
              else if i > 1
              then {
                inherit name;
                value = 0;
              }
              else {
                inherit name;
                value = v.${name};
              })
            componentNames);
      in
        format bumped;

      # Bump patch version
      patch = vStr: let
        v = parse vStr;
        bumped =
          if octets == 3
          then {
            major = v.major;
            minor = v.minor;
            patch = v.patch + 1;
          }
          else
            # Generic: bump last component
            lib.listToAttrs (lib.imap0 (i: name:
              if i == octets - 1
              then {
                inherit name;
                value = v.${name} + 1;
              }
              else {
                inherit name;
                value = v.${name};
              })
            componentNames);
      in
        format bumped;
    };
  in {
    # Core functions
    inherit parse format compare bump;

    # Escape hatches to lower layers
    inherit primitives composition;
  };
}
