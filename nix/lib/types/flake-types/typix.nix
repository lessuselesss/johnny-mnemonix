# Typix Flake Type
#
# Complete flake type definition for Typix: deterministic Typst document
# compilation with Nix.

{lib}: let
  inherit (lib) mkOption types;
in {
  # ===== Part 1: Module Input Structure =====

  moduleInput = {
    description = "Typix Typst document project configuration modules";
    moduleType = types.deferredModule;
    example = ''
      flake.modules.typix.my-document = {
        src = ./documents/report;
        entrypoint = "main.typ";
        watch = true;
        packages = with typstPackages; [ fontawesome roboto ];
      };

      flake.modules.typix.thesis = {
        src = ./documents/thesis;
        entrypoint = "main.typ";
        output = "pdf";
        watch = false;
      };
    '';
    schema = {
      projects = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            src = mkOption {
              type = types.path;
              description = "Source directory";
            };
            entrypoint = mkOption {
              type = types.str;
              default = "main.typ";
            };
            watch = mkOption {
              type = types.bool;
              default = false;
            };
            packages = mkOption {
              type = types.listOf types.package;
              default = [];
            };
            output = mkOption {
              type = types.enum ["pdf" "png" "svg"];
              default = "pdf";
            };
          };
        });
      };
    };
  };

  # ===== Part 2: Output Schemas =====

  schemas = {
    # Schema for typixModules output
    typixModules = {
      version = 1;
      doc = ''
        Typix Typst document project configurations.

        Example:
          outputs.typixModules.my-doc = {
            src = ./docs;
            entrypoint = "main.typ";
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (name: project: {
          what = "typix project: ${name}";
          evalChecks = {
            hasSrc = project ? src;
            hasEntrypoint = project ? entrypoint;
            srcExists = builtins.pathExists project.src;
            entrypointIsString = builtins.isString project.entrypoint;
          };
        }) output;
      };
    };

    # Alias for typixProjects
    typixProjects = {
      version = 1;
      doc = "Alias for typixModules";
      inventory = output: {
        children = builtins.mapAttrs (name: project: {
          what = "typix project";
          evalChecks = {
            hasSrc = project ? src;
          };
        }) output;
      };
    };
  };
}
