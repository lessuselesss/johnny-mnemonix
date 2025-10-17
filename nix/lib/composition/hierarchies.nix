# Composition: Hierarchies
# Defines multi-level identifier structures with navigation
#
# COMPOSITION LAYER: Builds on identifiers to create tree structures.
#
# Hierarchies represent multi-level organizational structures where each
# level has progressively more components. This is perfect for systems like:
# - Johnny Decimal: Area (XX) → Category (XX.YY) → Item (XX.YY.ZZ)
# - File paths: Volume → Directory → Subdirectory → File
# - Organizations: Division → Department → Team → Individual
#
# Each level has its own identifier definition, allowing different formatting
# at each level of the tree.
#
# API:
#   mk = {levels, levelNames} -> Hierarchy
#   level = Hierarchy -> Path -> Int (which level is this path at?)
#   parent = Hierarchy -> Path -> Path | Null (navigate up one level)
#   path = Hierarchy -> Path -> String (formatted path string)
#   validate = Hierarchy -> Path -> Bool (is path valid for this hierarchy?)
#
# Examples:
#   # Johnny Decimal: Area → Category → Item
#   jd = hierarchies.mk {
#     levels = [
#       areaIdentifier    # Formats as "10"
#       categoryIdentifier # Formats as "10.05"
#       itemIdentifier    # Formats as "10.05.03"
#     ];
#     levelNames = ["area" "category" "item"];
#   };
#
#   hierarchies.level jd [10 5 3]        # => 2 (item level)
#   hierarchies.parent jd [10 5 3]       # => [10 5] (go to category)
#   hierarchies.path jd [10 5 3]         # => "10 / 10.05 / 10.05.03"
#   hierarchies.validate jd [10 5 3]     # => true

{
  lib,
  primitives,
}: let
  identifiers = lib.composition.identifiers;
in {
  # Create a multi-level hierarchy definition
  #
  # Defines a tree structure with multiple levels, where each level has
  # progressively more identifier components. The number of components in
  # a path determines which level it represents.
  #
  # Parameters:
  #   - levels: List of Identifier definitions (from identifiers.mk)
  #     Each level should have one more field than the previous level
  #     Example: [areaId (1 field), catId (2 fields), itemId (3 fields)]
  #   - levelNames: List of human-readable level names
  #     Must have same length as levels
  #     Example: ["area", "category", "item"]
  #
  # Returns: Hierarchy object for use with level/parent/path/validate
  #
  # Example:
  #   mk {
  #     levels = [level0Def level1Def level2Def];
  #     levelNames = ["division" "department" "team"];
  #   }
  mk = {
    levels,
    levelNames,
  }: {
    inherit levels levelNames;
  };

  # Detect which level a path is at
  #
  # Determines the level by counting path components. A path with N components
  # is at level N-1 (0-indexed).
  #
  # Algorithm:
  #   - Path length 1 → Level 0 (e.g., [10] is area level)
  #   - Path length 2 → Level 1 (e.g., [10 5] is category level)
  #   - Path length 3 → Level 2 (e.g., [10 5 3] is item level)
  #
  # Returns: Level index (0-based), or null if path length is invalid
  #
  # Examples:
  #   level jdHierarchy [10]       # => 0 (area)
  #   level jdHierarchy [10 5]     # => 1 (category)
  #   level jdHierarchy [10 5 3]   # => 2 (item)
  #   level jdHierarchy []         # => null (empty)
  #   level jdHierarchy [10 5 3 7] # => null (too deep)
  level = hierarchy: path: let
    pathLen = builtins.length path;
    numLevels = builtins.length hierarchy.levels;
  in
    # Path length determines level (1 element = level 0, 2 = level 1, etc.)
    if pathLen > 0 && pathLen <= numLevels
    then pathLen - 1
    else null;

  # Navigate to parent level
  #
  # Moves up one level in the hierarchy by dropping the last component.
  # This is the inverse of drilling down into children.
  #
  # Algorithm:
  #   - Remove last element from path
  #   - Return null if path has only 1 element (already at root)
  #
  # Returns: Parent path (one level up), or null if already at root
  #
  # Examples:
  #   parent jdHierarchy [10 5 3]  # => [10 5] (item → category)
  #   parent jdHierarchy [10 5]    # => [10] (category → area)
  #   parent jdHierarchy [10]      # => null (area is root)
  parent = hierarchy: path: let
    pathLen = builtins.length path;
  in
    if pathLen <= 1
    then null # Already at root or invalid
    else
      # Drop last element
      lib.take (pathLen - 1) path;

  # Generate formatted path string
  #
  # Formats each level of the path using its corresponding identifier
  # definition, then joins all levels with " / " separator. This creates
  # a human-readable breadcrumb trail through the hierarchy.
  #
  # Algorithm:
  #   1. For each level from 0 to path length:
  #      - Take components for that level (e.g., [10] for level 0, [10 5] for level 1)
  #      - Format using that level's identifier definition
  #   2. Join all formatted levels with " / "
  #
  # Returns: Formatted path string showing full breadcrumb trail
  #
  # Examples:
  #   path jdHierarchy [10 5 3]  # => "10 / 10.05 / 10.05.03"
  #   path jdHierarchy [10 5]    # => "10 / 10.05"
  #   path jdHierarchy [10]      # => "10"
  #
  # This is useful for:
  #   - Breadcrumb navigation in UIs
  #   - Index file generation
  #   - Logging and debugging
  path = hierarchy: pathValues: let
    levels = hierarchy.levels;
    pathLen = builtins.length pathValues;

    # Format each level
    formatLevel = idx: let
      level = builtins.elemAt levels idx;
      # Take components for this level (e.g., level 0 takes [10], level 1 takes [10 5])
      levelValues = lib.take (idx + 1) pathValues;
    in
      identifiers.format level levelValues;

    # Format all levels up to path length
    formatted = lib.genList formatLevel pathLen;

    # Filter out any nulls (failed formatting)
    validFormatted = builtins.filter (f: f != null) formatted;
  in
    builtins.concatStringsSep " / " validFormatted;

  # Validate that a path is valid for the hierarchy
  #
  # Checks if a path has valid length for the hierarchy. A valid path must:
  #   - Not be empty
  #   - Not exceed the number of levels in the hierarchy
  #
  # This is a structural validation only - it doesn't check if the actual
  # values are valid according to each level's identifier constraints.
  # For that, use the identifier validation on each level.
  #
  # Returns: true if path length is valid, false otherwise
  #
  # Examples:
  #   validate jdHierarchy [10 5 3]     # => true (3 levels, hierarchy has 3)
  #   validate jdHierarchy [10 5]       # => true (2 levels, within bounds)
  #   validate jdHierarchy [10]         # => true (1 level, within bounds)
  #   validate jdHierarchy []           # => false (empty path)
  #   validate jdHierarchy [10 5 3 7]   # => false (4 levels, hierarchy only has 3)
  validate = hierarchy: path: let
    pathLen = builtins.length path;
    numLevels = builtins.length hierarchy.levels;
  in
    pathLen > 0 && pathLen <= numLevels;
}
