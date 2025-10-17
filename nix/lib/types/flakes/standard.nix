# Standard Flake Type
#
# Complete flake type definition for standard Nix flake outputs.
# This covers all outputs defined in the Nix flake schema.
#
# Based on: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html

{lib}: let
  inherit (lib) mkOption types;
in {
  # ===== Part 1: Module Input Structure =====

  moduleInput = {
    description = "Standard Nix flake output modules organized by output type";
    moduleType = types.deferredModule;
    example = ''
      # Approach 1: Use perSystem (standard flake-parts pattern)
      perSystem = { config, pkgs, ... }: {
        apps."10.01-build" = {
          type = "app";
          program = "''${config.packages.builder}/bin/build";
        };

        devShells."20.01-rust" = pkgs.mkShell {
          buildInputs = with pkgs; [ rustc cargo ];
        };

        packages."30.01-docs" = pkgs.stdenv.mkDerivation { ... };
      };

      # Approach 2: Use dedicated module classes (auto-merged to perSystem)
      flake.modules.apps."10.01-build" = {
        type = "app";
        program = "...";
      };

      flake.modules.devShells."20.01-rust" = pkgs.mkShell { ... };
      flake.modules.packages."30.01-docs" = pkgs.stdenv.mkDerivation { ... };

      # Both approaches produce the same flake outputs
    '';
    schema = {
      # Module classes for standard outputs
      apps = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            type = mkOption {
              type = types.enum ["app"];
              default = "app";
            };
            program = mkOption {
              type = types.str;
              description = "Path to executable in Nix store";
            };
            meta = mkOption {
              type = types.attrsOf types.anything;
              default = {};
              description = "App metadata (description, etc.)";
            };
          };
        });
        default = {};
        description = "Runnable programs (nix run)";
      };

      devShells = mkOption {
        type = types.attrsOf types.package;
        default = {};
        description = "Development shells (nix develop)";
      };

      packages = mkOption {
        type = types.attrsOf types.package;
        default = {};
        description = "Installable packages (nix build)";
      };

      checks = mkOption {
        type = types.attrsOf types.package;
        default = {};
        description = "Test/check derivations (nix flake check)";
      };

      formatter = mkOption {
        type = types.nullOr types.package;
        default = null;
        description = "Code formatter (nix fmt)";
      };

      overlays = mkOption {
        type = types.attrsOf types.raw;
        default = {};
        description = "Nixpkgs overlays";
      };

      legacyPackages = mkOption {
        type = types.attrsOf types.anything;
        default = {};
        description = "Legacy package sets (not shown in nix search)";
      };

      templates = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            path = mkOption {
              type = types.path;
              description = "Template directory path";
            };
            description = mkOption {
              type = types.str;
              description = "Template description";
            };
            welcomeText = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Welcome message after init";
            };
          };
        });
        default = {};
        description = "Project templates (nix flake init)";
      };
    };
  };

  # ===== Part 2: Output Schemas =====

  schemas = {
    # Apps output schema
    apps = {
      version = 1;
      doc = ''
        Programs runnable with `nix run`.

        Structure: `apps.<system>.<name>`

        Each app must have:
        - `type = "app"`
        - `program`: path to executable in Nix store

        Example:
          apps.x86_64-linux.hello = {
            type = "app";
            program = "''${self.packages.x86_64-linux.hello}/bin/hello";
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (system: systemApps: {
          what = "apps for ${system}";
          children = builtins.mapAttrs (name: app: {
            what = "app: ${name}";
            evalChecks = {
              isAttrs = builtins.isAttrs app;
              hasType = app ? type;
              typeIsApp = if app ? type then app.type == "app" else false;
              hasProgram = app ? program;
              programIsString = if app ? program then builtins.isString app.program else false;
            };
          }) systemApps;
        }) output;
      };
    };

    # DevShells output schema
    devShells = {
      version = 1;
      doc = ''
        Development shells for `nix develop`.

        Structure: `devShells.<system>.<name>`

        Each shell should be a derivation (typically from `pkgs.mkShell`).

        Example:
          devShells.x86_64-linux.default = pkgs.mkShell {
            buildInputs = [ pkgs.rustc pkgs.cargo ];
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (system: shells: {
          what = "devShells for ${system}";
          children = builtins.mapAttrs (name: shell: {
            what = "devShell: ${name}";
            evalChecks = {
              isAttrs = builtins.isAttrs shell;
              isDerivation = builtins.isAttrs shell && shell ? type && shell.type == "derivation";
            };
          }) shells;
        }) output;
      };
    };

    # Packages output schema
    packages = {
      version = 1;
      doc = ''
        Installable packages for `nix build`.

        Structure: `packages.<system>.<name>`

        Each package must be a derivation.

        Example:
          packages.x86_64-linux.myapp = pkgs.stdenv.mkDerivation {
            name = "myapp";
            src = ./src;
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (system: pkgs: {
          what = "packages for ${system}";
          children = builtins.mapAttrs (name: pkg: {
            what = "package: ${name}";
            evalChecks = {
              isAttrs = builtins.isAttrs pkg;
              isDerivation = builtins.isAttrs pkg && pkg ? type && pkg.type == "derivation";
            };
          }) pkgs;
        }) output;
      };
    };

    # Checks output schema
    checks = {
      version = 1;
      doc = ''
        Tests and checks for `nix flake check`.

        Structure: `checks.<system>.<name>`

        Each check must be a derivation that succeeds or fails.

        Example:
          checks.x86_64-linux.test-suite = pkgs.runCommand "tests" {} ''
            ${./run-tests.sh}
            touch $out
          '';
      '';
      inventory = output: {
        children = builtins.mapAttrs (system: checks: {
          what = "checks for ${system}";
          children = builtins.mapAttrs (name: check: {
            what = "check: ${name}";
            evalChecks = {
              isAttrs = builtins.isAttrs check;
              isDerivation = builtins.isAttrs check && check ? type && check.type == "derivation";
            };
          }) checks;
        }) output;
      };
    };

    # Formatter output schema
    formatter = {
      version = 1;
      doc = ''
        Code formatter for `nix fmt`.

        Structure: `formatter.<system>`

        Must be a derivation with a formatting command.

        Example:
          formatter.x86_64-linux = pkgs.alejandra;
      '';
      inventory = output: {
        children = builtins.mapAttrs (system: formatter: {
          what = "formatter for ${system}";
          evalChecks = {
            isAttrs = builtins.isAttrs formatter;
            isDerivation = builtins.isAttrs formatter && formatter ? type && formatter.type == "derivation";
          };
        }) output;
      };
    };

    # Overlays output schema
    overlays = {
      version = 1;
      doc = ''
        Nixpkgs overlays.

        Structure: `overlays.<name>`

        Each overlay is a function: `final: prev: { ... }`

        Example:
          overlays.default = final: prev: {
            myPackage = final.callPackage ./my-package.nix {};
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (name: overlay: {
          what = "overlay: ${name}";
          evalChecks = {
            isFunction = builtins.isFunction overlay;
          };
        }) output;
      };
    };

    # LegacyPackages output schema
    legacyPackages = {
      version = 1;
      doc = ''
        Legacy package sets (not shown in `nix search`).

        Structure: `legacyPackages.<system>.<path>`

        Used for large package sets like nixpkgs itself.

        Example:
          legacyPackages.x86_64-linux = import ./pkgs { system = "x86_64-linux"; };
      '';
      inventory = output: {
        children = builtins.mapAttrs (system: pkgs: {
          what = "legacyPackages for ${system}";
          evalChecks = {
            isAttrs = builtins.isAttrs pkgs;
          };
        }) output;
      };
    };

    # Templates output schema
    templates = {
      version = 1;
      doc = ''
        Project templates for `nix flake init`.

        Structure: `templates.<name>`

        Each template must have:
        - `path`: template directory
        - `description`: template description

        Example:
          templates.rust = {
            path = ./templates/rust;
            description = "Rust project with Nix flake";
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (name: template: {
          what = "template: ${name}";
          evalChecks = {
            isAttrs = builtins.isAttrs template;
            hasPath = template ? path;
            hasDescription = template ? description;
            descriptionIsString = if template ? description then builtins.isString template.description else false;
          };
        }) output;
      };
    };

    # Schemas output schema (meta!)
    schemas = {
      version = 1;
      doc = ''
        Flake output schemas (flake-schemas format).

        Structure: `schemas.<outputName>`

        Defines validation for flake outputs.

        Example:
          schemas.myOutput = {
            version = 1;
            doc = "My custom output";
            inventory = output: { ... };
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (name: schema: {
          what = "schema: ${name}";
          evalChecks = {
            isAttrs = builtins.isAttrs schema;
            hasVersion = schema ? version;
            versionIs1 = if schema ? version then schema.version == 1 else false;
            hasInventory = schema ? inventory;
            inventoryIsFunction = if schema ? inventory then builtins.isFunction schema.inventory else false;
          };
        }) output;
      };
    };

    # HydraJobs output schema
    hydraJobs = {
      version = 1;
      doc = ''
        Hydra CI jobs.

        Structure: `hydraJobs.<job-path>`

        Used by Hydra continuous integration.

        Example:
          hydraJobs.build = self.packages.x86_64-linux.myapp;
      '';
      inventory = output: {
        what = "hydra jobs";
        evalChecks = {
          isAttrs = builtins.isAttrs output;
        };
      };
    };

    # DockerImages output schema
    dockerImages = {
      version = 1;
      doc = ''
        Docker images built with Nix.

        Structure: `dockerImages.<name>`

        Typically built with `pkgs.dockerTools.buildImage`.

        Example:
          dockerImages.myapp = pkgs.dockerTools.buildImage {
            name = "myapp";
            config.Cmd = [ "''${self.packages.x86_64-linux.myapp}/bin/myapp" ];
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (name: image: {
          what = "docker image: ${name}";
          evalChecks = {
            isAttrs = builtins.isAttrs image;
            isDerivation = builtins.isAttrs image && image ? type && image.type == "derivation";
          };
        }) output;
      };
    };
  };
}
