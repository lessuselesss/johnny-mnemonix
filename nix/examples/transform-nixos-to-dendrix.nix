# Example: Transform nixosConfiguration to dendrix aspect modules
#
# This example demonstrates transforming a traditional nixosConfiguration
# into dendrix aspect-oriented modules.
#
# Usage:
#   nix build .#examples.x86_64-linux.transform-nixos-to-dendrix
#   cat result/networking.nix
#   cat result/graphics.nix
#   cat result/development.nix

{
  inputs,
  cell,
}: let
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {inherit system;};
  lib = pkgs.lib;
  # Access unitype from the lib cell
  unitype = (inputs.std.harvest inputs.self ["lib" "unitype"]).${system} or {};

  # Example nixosConfiguration (realistic production-like config)
  exampleNixosConfig = {
    system = "x86_64-linux";

    modules = [
      # Networking module
      {
        networking.hostName = "garfield";
        networking.firewall.enable = true;
        networking.firewall.allowedTCPPorts = [22 80 443];
        services.openssh.enable = true;
        services.openssh.settings.PermitRootLogin = "no";
      }

      # Graphics/Desktop module
      {
        services.xserver.enable = true;
        services.xserver.displayManager.gdm.enable = true;
        services.xserver.desktopManager.gnome.enable = true;
        hardware.graphics.enable = true;
      }

      # Development tools module
      {
        programs.git.enable = true;
        programs.neovim.enable = true;
        programs.neovim.defaultEditor = true;
        environment.systemPackages = []; # Would contain dev tools in real config
      }

      # User management
      {
        users.users.dustin = {
          isNormalUser = true;
          extraGroups = ["wheel" "networkmanager" "docker"];
        };
      }

      # Container runtime
      {
        virtualisation.docker.enable = true;
        virtualisation.docker.rootless.enable = true;
      }

      # Boot and system
      {
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        system.stateVersion = "24.11";
      }
    ];

    specialArgs = {
      user = "dustin";
    };
  };

  # Step 1: Encode nixosConfiguration to IR
  ir = unitype.encoders.nixos.encode "10.01-garfield" exampleNixosConfig;

  # Step 2: Decode IR to dendrix modules
  dendrixModules = unitype.decoders.dendrix.decode ir;

  # Step 3: Format dendrix modules as importable Nix files
  formatModule = aspectName: module: let
    # Since module is a function, we need to represent it as Nix code
    # For now, we'll create a representation showing the structure
    moduleStr = ''
      # Dendrix aspect module: ${aspectName}
      # Generated from nixosConfiguration "10.01-garfield"
      # JD Structure: ${ir.meta.jdStructure.area.id or "unknown"}.${ir.meta.jdStructure.category.id or "unknown"}.${ir.meta.jdStructure.item.id or "unknown"}
      #
      # This module contains configuration related to: ${aspectName}

      { config, lib, pkgs, ... }: {
        # Original modules from nixosConfiguration are imported here
        # In actual use, these would be the NixOS configuration options

        imports = [
          # Module content would be here
        ];

        # Metadata
        _module.args = {
          jdMeta = ${builtins.toJSON (ir.meta.jdStructure or {})};
          aspectName = "${aspectName}";
        };
      }
    '';
  in moduleStr;

  # Generate output files
  aspectFiles = lib.mapAttrs formatModule dendrixModules;

in
  # Create a derivation that outputs the dendrix modules as files
  pkgs.runCommand "dendrix-modules" {} ''
    mkdir -p $out

    # Write summary
    cat > $out/README.md <<'EOF'
# Dendrix Transformation Output

**Source**: nixosConfiguration "10.01-garfield"
**Target**: Dendrix aspect-oriented modules

## Transformation Summary

Original configuration: ${toString (builtins.length exampleNixosConfig.modules)} modules
Dendrix output: ${toString (builtins.length (builtins.attrNames dendrixModules))} aspects

## Aspects Created

${lib.concatStringsSep "\n" (map (name: "- **${name}**: Aspect module for ${name} concerns") (builtins.attrNames dendrixModules))}

## IR Metadata

- **JD ID**: ${ir.id}
- **System**: ${ir.meta.system}
- **Area**: ${ir.meta.jdStructure.area.id or "unknown"} (${ir.meta.jdStructure.area.name or "unknown"})
- **Category**: ${ir.meta.jdStructure.category.id or "unknown"} (${ir.meta.jdStructure.category.name or "unknown"})
- **Item**: ${ir.meta.jdStructure.item.id or "unknown"}

## Aspects Identified

${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: enabled: "- ${name}: ${if enabled then "✅" else "❌"}") (ir.hints.aspects or {}))}

## Usage

These dendrix modules can be imported into a NixOS configuration:

\`\`\`nix
{ config, pkgs, ... }: {
  imports = [
    ./networking.nix
    ./graphics.nix
    ./development.nix
  ];
}
\`\`\`

Or used in a dendrix-based configuration system.
EOF

    # Write aspect modules
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: content: ''
      cat > $out/${name}.nix <<'ASPECTEOF'
      ${content}
      ASPECTEOF
    '') aspectFiles)}

    # Write IR for inspection
    cat > $out/ir.json <<'IREOF'
    ${builtins.toJSON {
      inherit (ir) id kind;
      meta = ir.meta;
      hints = ir.hints;
      moduleCount = builtins.length exampleNixosConfig.modules;
      aspectCount = builtins.length (builtins.attrNames dendrixModules);
    }}
    IREOF

    echo "Dendrix transformation complete!" > $out/SUCCESS
  ''
