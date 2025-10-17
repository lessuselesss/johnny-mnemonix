# Typix Package Types
#
# Package structure types for typix: deterministic Typst document compilation.
# These define the configuration structure for typix derivations.
#
# Based on https://github.com/loqusion/typix

{lib}: let
  inherit (lib) mkOption types;
in {
  # ===== Virtual Path Type =====

  virtualPath = types.submodule {
    options = {
      src = mkOption {
        type = types.path;
        description = "Source path to map";
      };

      dest = mkOption {
        type = types.str;
        description = "Destination path within Typst compilation";
      };
    };
  };

  # ===== mkTypstDerivation Configuration =====

  mkTypstDerivationConfig = types.submodule {
    options = {
      # Required
      buildPhaseTypstCommand = mkOption {
        type = types.str;
        description = "Command to execute during build phase";
        example = "typst compile main.typ $out";
      };

      # Typix-specific options
      emojiFont = mkOption {
        type = types.str;
        default = "default";
        description = "Emoji font configuration";
      };

      fontPaths = mkOption {
        type = types.listOf types.path;
        default = [];
        description = "Additional font directory paths";
        example = [ ./fonts ./vendor/fonts ];
      };

      virtualPaths = mkOption {
        type = types.listOf (types.either types.path (types.submodule {
          options = {
            src = mkOption { type = types.path; };
            dest = mkOption { type = types.str; };
          };
        }));
        default = [];
        description = "Virtual path mappings for dependencies";
        example = [
          { src = ./data; dest = "data"; }
          { src = ./images; dest = "assets/images"; }
        ];
      };

      unstable_typstPackages = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Typst packages to fetch and cache";
        example = [ "preview/charged-ieee" "preview/tablex" ];
      };

      installPhaseCommand = mkOption {
        type = types.str;
        default = "";
        description = "Custom installation phase command";
      };

      # Standard derivation attributes
      name = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Derivation name";
      };

      pname = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Package name";
      };

      version = mkOption {
        type = types.str;
        default = "0.1.0";
        description = "Package version";
      };

      src = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Source directory";
      };

      nativeBuildInputs = mkOption {
        type = types.listOf types.package;
        default = [];
        description = "Native build dependencies";
      };

      buildPhase = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Custom build phase";
      };

      installPhase = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Custom install phase";
      };
    };
  };

  # ===== buildTypstProject Configuration =====

  buildTypstProjectConfig = types.submodule {
    options = {
      # Project source
      src = mkOption {
        type = types.path;
        description = "Source directory containing .typ files";
      };

      typstSource = mkOption {
        type = types.str;
        default = "main.typ";
        description = "Main Typst file to compile";
        example = "document.typ";
      };

      # Compilation options
      typstCompileCommand = mkOption {
        type = types.str;
        default = "typst compile";
        description = "Typst compilation command";
      };

      # Typix options (passed to mkTypstDerivation)
      fontPaths = mkOption {
        type = types.listOf types.path;
        default = [];
        description = "Font directory paths";
      };

      virtualPaths = mkOption {
        type = types.listOf (types.either types.path (types.submodule {
          options = {
            src = mkOption { type = types.path; };
            dest = mkOption { type = types.str; };
          };
        }));
        default = [];
        description = "Virtual path mappings";
      };

      typstPackages = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Typst packages to fetch (using unstable API)";
      };

      # Derivation attributes
      name = mkOption {
        type = types.str;
        description = "Derivation name";
      };

      version = mkOption {
        type = types.str;
        default = "0.1.0";
        description = "Package version";
      };
    };
  };

  # ===== watchTypstProject Configuration =====

  watchTypstProjectConfig = types.submodule {
    options = {
      src = mkOption {
        type = types.path;
        description = "Source directory to watch";
      };

      typstSource = mkOption {
        type = types.str;
        default = "main.typ";
        description = "Main Typst file";
      };

      # Watch-specific options
      open = mkOption {
        type = types.bool;
        default = false;
        description = "Open PDF after building";
      };

      command = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Command to open PDF (e.g., 'zathura', 'evince')";
        example = "zathura";
      };

      debounce = mkOption {
        type = types.ints.positive;
        default = 2;
        description = "Debounce interval in seconds";
      };

      # Compilation options
      fontPaths = mkOption {
        type = types.listOf types.path;
        default = [];
        description = "Font directory paths";
      };

      virtualPaths = mkOption {
        type = types.listOf (types.either types.path (types.submodule {
          options = {
            src = mkOption { type = types.path; };
            dest = mkOption { type = types.str; };
          };
        }));
        default = [];
        description = "Virtual path mappings";
      };

      typstPackages = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Typst packages to fetch";
      };
    };
  };

  # ===== Typst Package Definition =====

  typstPackage = types.submodule {
    options = {
      namespace = mkOption {
        type = types.str;
        description = "Package namespace (e.g., 'preview')";
        example = "preview";
      };

      name = mkOption {
        type = types.str;
        description = "Package name";
        example = "charged-ieee";
      };

      version = mkOption {
        type = types.str;
        description = "Package version (semver)";
        example = "0.1.0";
      };

      entrypoint = mkOption {
        type = types.str;
        default = "lib.typ";
        description = "Package entrypoint file";
      };

      src = mkOption {
        type = types.path;
        description = "Package source directory";
      };
    };
  };
}
