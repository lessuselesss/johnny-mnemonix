# Johnny-Mnemonix Flake Type
#
# Complete flake type definition for Johnny-Mnemonix: dogfooding our own
# johnny-declarative-decimal library as a complete flake type.

{lib}: let
  inherit (lib) mkOption types;
in {
  # ===== Part 1: Module Input Structure =====

  moduleInput = {
    description = "Johnny-Mnemonix Johnny Decimal organization modules";
    moduleType = types.deferredModule;
    dogfood = true;
    example = ''
      # Declarative Johnny Decimal workspace
      flake.modules.jm.workspace = {
        baseDir = "\${config.home.homeDirectory}/Documents";
        areas = {
          "10-19" = {
            name = "Projects";
            categories = {
              "10" = {
                name = "Code";
                items = {
                  "10.01" = "Website";
                  "10.02" = {
                    name = "CLI-Tool";
                    url = "git@github.com:user/cli-tool.git";
                  };
                };
              };
            };
          };
        };
      };

      # Self-documenting Johnny Decimal filenames
      flake.modules.jm."[10.05]{10-19 Projects}__(10 Code)__[05 Library]" = {
        # Automatically creates: ~/Documents/10-19 Projects/10 Code/10.05 Library/
      };
    '';
    schema = {
      configurations = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            enable = mkOption { type = types.bool; default = true; };
            baseDir = mkOption { type = types.path; };
            areas = mkOption {
              type = types.attrsOf types.anything;
              default = {};
            };
            syntax = mkOption { type = types.anything; default = {}; };
          };
        });
      };
    };
  };

  # ===== Part 2: Output Schemas =====

  schemas = {
    # Schema for jmModules output
    jmModules = {
      version = 1;
      doc = ''
        Johnny-Mnemonix modules for Johnny Decimal organization.

        Provides declarative directory structure management with JD convention.

        Example:
          outputs.jmModules.workspace = {
            baseDir = "~/Documents";
            areas = {
              "10-19" = {
                name = "Projects";
                categories = { /* ... */ };
              };
            };
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (name: config: {
          what = "johnny-mnemonix configuration";
          evalChecks = {
            isConfig = builtins.isAttrs config;
            hasBaseDir = config ? baseDir;
            hasAreas = config ? areas;

            # Check if filename follows JD format
            hasJDFilename =
              let match = builtins.match "\\[([0-9]{2})\\.([0-9]{2})\\]\\{.*\\}__\\(.*\\)__\\[.*\\]" name;
              in match != null;

            # Validate area ranges if present
            areasAreValid =
              if config ? areas
              then builtins.all (area:
                builtins.match "[0-9]{2}-[0-9]{2}" area != null
              ) (builtins.attrNames config.areas)
              else true;
          };
        }) output;
      };
    };

    # Alias for jmConfigurations
    jmConfigurations = {
      version = 1;
      doc = "Alias for jmModules";
      inventory = output: {
        children = builtins.mapAttrs (name: config: {
          what = "johnny-mnemonix configuration";
          evalChecks = {
            isConfig = builtins.isAttrs config;
          };
        }) output;
      };
    };
  };
}
