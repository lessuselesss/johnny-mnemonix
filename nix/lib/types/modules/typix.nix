# Typix Module Types
#
# Pure module option types for Typix: deterministic Typst document compilation with Nix.
# Supports watch mode, build outputs, and project organization.

{lib}: {
  # ===== Typix-Specific Types =====

  # Typst source file path
  typstSource = lib.types.path;

  # Typst package (fonts, templates, etc.)
  typstPackage = lib.types.package;

  # Complete Typix project configuration
  typixProject = lib.types.submodule {
    options = {
      src = lib.mkOption {
        type = lib.types.path;
        description = "Source directory containing .typ files";
      };

      entrypoint = lib.mkOption {
        type = lib.types.str;
        default = "main.typ";
        description = "Main Typst file to compile";
      };

      watch = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable watch mode for live recompilation";
      };

      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
        description = "Typst packages (fonts, templates) to make available";
      };

      output = lib.mkOption {
        type = lib.types.enum ["pdf" "png" "svg"];
        default = "pdf";
        description = "Output format";
      };

      name = lib.mkOption {
        type = lib.types.str;
        description = "Project name";
        example = "my-document";
      };
    };
  };

  # Typix build configuration
  typixBuild = lib.types.submodule {
    options = {
      project = lib.mkOption {
        type = lib.types.submodule {
          options = {
            src = lib.mkOption { type = lib.types.path; };
            entrypoint = lib.mkOption { type = lib.types.str; default = "main.typ"; };
            packages = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = [];
            };
          };
        };
        description = "Typix project to build";
      };

      name = lib.mkOption {
        type = lib.types.str;
        description = "Output derivation name";
      };
    };
  };

  # Typix watch service configuration
  typixWatch = lib.types.submodule {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable watch mode service";
      };

      interval = lib.mkOption {
        type = lib.types.ints.positive;
        default = 2;
        description = "Debounce interval in seconds";
      };

      project = lib.mkOption {
        type = lib.types.submodule {
          options = {
            src = lib.mkOption { type = lib.types.path; };
            entrypoint = lib.mkOption { type = lib.types.str; };
          };
        };
        description = "Project to watch";
      };
    };
  };
}
