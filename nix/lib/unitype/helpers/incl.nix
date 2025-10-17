# Unitype Helpers - incl Integration
#
# Provides file filtering with inclusion semantics for transformed outputs.
# Useful when generating flakes that need selective file inclusion.

{
  lib,
  incl,
}: {
  # Filter source to include only specified paths
  # Usage: filterSource self [ ./file1.nix ./dir1 ]
  filterSource = src: includes:
    incl src includes;

  # Filter with debug output enabled
  # Helpful for troubleshooting what files are included
  filterSourceDebug = src: includes:
    (incl // {debug = true;}) src includes;

  # Filter source based on IR metadata
  # Includes only files relevant to the transformation
  filterFromIR = ir: src: let
    # Determine which files to include based on IR
    relevantFiles =
      if ir.hints ? relevantPaths
      then ir.hints.relevantPaths
      else []; # Include all if not specified
  in
    if relevantFiles == []
    then src # No filtering
    else incl src relevantFiles;

  # Create filtered source for aspect-organized output
  # Includes aspect modules and metadata files
  filterForAspects = src: aspects: let
    aspectFiles = map (a: ./modules + "/${a}.nix") aspects;
    metaFiles = [./flake.nix ./README.md];
  in
    incl src (aspectFiles ++ metaFiles);

  # Create filtered source for transformed flake output
  # Includes generated modules, flake.nix, and documentation
  filterForTransformedOutput = src: {
    modules ? [],
    includeFlake ? true,
    includeDocs ? true,
    extraPaths ? [],
  }: let
    modulePaths = map (m: ./modules + "/${m}") modules;
    flakePaths =
      lib.optional includeFlake ./flake.nix
      ++ lib.optional includeDocs ./README.md;
  in
    incl src (modulePaths ++ flakePaths ++ extraPaths);

  # Helper: Include only Nix files from a directory
  # Automatically filters for .nix extension
  includeNixFiles = src: dir: let
    allFiles = builtins.readDir (src + "/${dir}");
    nixFiles =
      lib.filterAttrs
      (name: type: type == "regular" && lib.hasSuffix ".nix" name)
      allFiles;
    paths = map (name: (src + "/${dir}/${name}")) (builtins.attrNames nixFiles);
  in
    incl src paths;

  # Access to raw incl for advanced use
  raw = incl;
}
