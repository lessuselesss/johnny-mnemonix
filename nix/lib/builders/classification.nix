# Builders: Classification System Builder
# High-level constructor for creating hierarchical classification systems
#
# BUILDERS LAYER: Combines primitives and composition into ready-to-use classification systems.
#
# This builder creates complete hierarchical classification systems with support for:
# - Variable depth hierarchies (N₁, N₁.N₂, N₁.N₂.N₃, ..., N₁.N₂...Nₖ)
# - Different bases per level (decimal, hex, etc.)
# - Different digit counts per level
# - Hierarchical navigation (parent, ancestors, siblings)
# - Path generation and validation
#
# The N notation emphasizes extensibility:
# - N₁: 1 level (single component)
# - N₁.N₂: 2 levels (e.g., category.item)
# - N₁.N₂.N₃: 3 levels (e.g., area.category.item)
# - N₁.N₂...Nₖ: k levels (arbitrary depth)
#
# API:
#   mkClassification = {depth, digits_per_level, base, separators, levelNames} -> System
#
# Examples:
#   # 3-level classification (N₁.N₂.N₃)
#   cls = mkClassification {depth = 3;};
#   cls.path [10 5 2]  # => "10 / 10.05 / 10.05.02"
#   cls.navigate.parent [10 5 2]  # => [10 5]
#   cls.navigate.ancestors [10 5 2]  # => [[10] [10 5]]
#
#   # Dewey Decimal-style
#   dewey = mkClassification {
#     depth = 3;
#     levelNames = ["class" "division" "section"];
#   };

{
  lib,
  primitives,
  composition,
}: let
  ns = primitives.numberSystems;
  fields = primitives.fields;
  hierarchies = composition.hierarchies;
  identifiers = composition.identifiers;
in {
  # Create a classification system
  #
  # Parameters:
  #   - depth: Number of hierarchy levels (default: 3)
  #   - digits_per_level: Digits at each level (default: 2)
  #   - base: Number base (default: 10 for decimal)
  #   - separators: List of separators between levels (default: ["."])
  #   - levelNames: Names for each level (default: ["level0", "level1", ...])
  #
  # Returns: System with hierarchy, navigate, validate, path
  mkClassification = {
    depth ? 3,
    digits_per_level ? 2,
    base ? 10,
    separators ? ["."],
    levelNames ? lib.genList (i: "level${toString i}") depth,
  }: let
    # Create number system for the specified base
    numberSystem =
      if base == 10
      then ns.decimal
      else if base == 16
      then ns.hex
      else if base == 2
      then ns.binary
      else
        throw "Unsupported base: ${toString base}. Use 2, 10, or 16.";

    # Create a field for classification components
    classField = fields.mk {
      system = numberSystem;
      width = digits_per_level;
      padding = "zeros";
    };

    # Create identifier definitions for each level
    # Using N notation to show progressive depth:
    # Level 0: single field (N₁)
    # Level 1: two fields (N₁.N₂)
    # Level 2: three fields (N₁.N₂.N₃)
    # Level k-1: k fields (N₁.N₂...Nₖ)
    levelDefs = lib.genList (levelIdx: let
      numFields = levelIdx + 1;
      fieldList = lib.genList (_: classField) numFields;
    in
      identifiers.mk {
        fields = fieldList;
        separator = builtins.head separators;
      })
    depth;

    # Create hierarchy definition
    hierarchyDef = hierarchies.mk {
      levels = levelDefs;
      inherit levelNames;
    };

    # Navigation functions
    navigate = {
      # Get parent path (move up one level)
      #
      # Parameters:
      #   - path: Current path (list of components)
      #
      # Returns: Parent path, or null if at root
      #
      # Examples:
      #   parent [10 5 2]  # => [10 5]
      #   parent [10]      # => null
      parent = path: hierarchies.parent hierarchyDef path;

      # Get all ancestors (all paths from root to parent)
      #
      # Parameters:
      #   - path: Current path
      #
      # Returns: List of ancestor paths
      #
      # Examples:
      #   ancestors [10 5 2]  # => [[10] [10 5]]
      #   ancestors [10 5]    # => [[10]]
      #   ancestors [10]      # => []
      ancestors = path: let
        # Recursively build ancestor list
        go = p:
          if p == null || builtins.length p <= 1
          then []
          else let
            parentPath = hierarchies.parent hierarchyDef p;
          in
            if parentPath != null
            then (go parentPath) ++ [parentPath]
            else [];
      in
        go path;

      # Get siblings from a tree structure
      #
      # Parameters:
      #   - tree: Nested attrset representing the hierarchy
      #   - path: Current path
      #
      # Returns: List of sibling paths (excluding self)
      #
      # Examples:
      #   siblings {"10" = {"5" = ["1" "2" "3"];}} [10 5 2]  # => ["1" "3"]
      #
      # Note: This requires a tree structure to know siblings.
      # Returns empty list if parent not in tree or path invalid.
      siblings = tree: path: let
        pathLen = builtins.length path;
        parentPath = hierarchies.parent hierarchyDef path;

        # Navigate to parent in tree to find siblings
        findSiblings =
          if parentPath == null || pathLen < 2
          then []
          else let
            # Convert path components to strings for attrset lookup
            parentKey = toString (builtins.head parentPath);
            # Navigate down the tree
            parentNode =
              if tree ? ${parentKey}
              then
                if pathLen == 2
                then tree.${parentKey} or []
                else let
                  # For deeper paths, navigate through multiple levels
                  # This is simplified - full implementation would recursively navigate
                  categoryKey = toString (builtins.elemAt parentPath 1);
                in
                  if tree.${parentKey} ? ${categoryKey}
                  then tree.${parentKey}.${categoryKey} or []
                  else []
              else [];

            # Get current component to exclude from siblings
            currentComponent = toString (lib.last path);

            # Filter out self
            siblingsList =
              if builtins.isList parentNode
              then builtins.filter (s: s != currentComponent) parentNode
              else [];
          in
            siblingsList;
      in
        findSiblings;
    };

    # Validate a path
    #
    # Parameters:
    #   - path: Path to validate (list of components)
    #
    # Returns: true if valid, false otherwise
    #
    # Examples:
    #   validate [10 5 2]  # => true
    #   validate []        # => false
    validate = path: hierarchies.validate hierarchyDef path;

    # Generate path string with breadcrumb navigation
    #
    # Parameters:
    #   - path: Path components (list of integers)
    #
    # Returns: Formatted path string showing full breadcrumb trail
    #
    # Examples:
    #   path [10 5 2]  # => "10 / 10.05 / 10.05.02"
    #   path [10 5]    # => "10 / 10.05"
    path = pathValues: hierarchies.path hierarchyDef pathValues;
  in {
    # Core functionality
    inherit hierarchy navigate validate path;

    # Expose hierarchy definition
    hierarchy = hierarchyDef;

    # Identifier definitions per level (escape hatch)
    identifiers = levelDefs;

    # Escape hatches to lower layers
    inherit primitives composition;
  };
}
