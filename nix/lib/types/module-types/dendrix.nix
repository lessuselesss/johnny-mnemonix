# Dendrix Module Types
#
# Pure module option types for dendrix dendritic aspect-oriented configuration.
# Based on https://vic.github.io/dendrix/
#
# Dendrix organizes flakes via flake.modules.<class>.<aspect> where:
# - class: e.g., nixos, home-manager, etc.
# - aspect: semantic organization (networking, graphics, development, etc.)

{lib}: {
  # ===== Dendrix-Specific Types =====

  # Aspect name must be lowercase with hyphens
  aspectName = lib.types.strMatching "^[a-z][a-z0-9-]*$";

  # Dendrix aspect module
  aspectModule = lib.types.submodule {
    options = {
      imports = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [];
        description = "List of module files to import for this aspect";
      };

      exports = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
        description = "Exports from this aspect module";
      };

      description = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Human-readable description of this aspect";
      };
    };
  };

  # Repository import from dendrix community distribution
  repositoryImport = lib.types.submodule {
    options = {
      repo = lib.mkOption {
        type = lib.types.str;
        description = "Repository name in dendrix distribution";
        example = "vic/home";
      };

      aspect = lib.mkOption {
        type = lib.types.nullOr (lib.types.strMatching "^[a-z][a-z0-9-]*$");
        default = null;
        description = "Optional specific aspect to import";
        example = "neovim";
      };

      rev = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Optional git revision to use";
      };
    };
  };

  # Dendrix tree structure: class -> aspect -> modules
  dendrixTree = lib.types.attrsOf (
    lib.types.attrsOf (
      lib.types.either
      lib.types.path
      (lib.types.listOf lib.types.path)
    )
  );
}
