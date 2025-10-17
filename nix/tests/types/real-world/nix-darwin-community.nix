# Real-World Tests: nix-darwin Community Modules
#
# Tests that our nix-darwin module types correctly validate patterns from
# real-world community flakes.

{
  lib,
  types,
  schemas,
  self,
}: let
  # Helper: Validate schema against output
  validateSchema = schema: output:
    if schema != null && output != null
    then
      let
        result = builtins.tryEval (schema.inventory output);
      in result.success
    else false;
in {
  # ===== Darwin Modules Structure =====

  # Test: darwinModules schema validates simple module
  testDarwinModulesValidatesSimpleModule = {
    expr = let
      schema = schemas.darwinModules or null;
      testOutput = {
        default = { config, lib, pkgs, ... }: {
          options = {};
          config = {};
        };
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # Test: darwinModules supports multiple named modules
  testDarwinModulesMultipleModules = {
    expr = let
      schema = schemas.darwinModules or null;
      testOutput = {
        default = { ... }: {};
        system = { ... }: {};
        homebrew = { ... }: {};
        services = { ... }: {};
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # Test: darwinModules with Johnny Decimal naming
  testDarwinModulesJohnnyDecimalNaming = {
    expr = let
      schema = schemas.darwinModules or null;
      testOutput = {
        "10.01-system-defaults" = { ... }: {};
        "10.02-homebrew-packages" = { ... }: {};
        "20.01-security-config" = { ... }: {};
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # ===== Darwin Configurations Structure =====

  # Test: darwinConfigurations schema validates basic config
  testDarwinConfigurationsValidatesBasicConfig = {
    expr = let
      schema = schemas.darwinConfigurations or null;
      testOutput = {
        mymac = {
          system = "aarch64-darwin";
          modules = [];
        };
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # Test: darwinConfigurations multiple hosts
  testDarwinConfigurationsMultipleHosts = {
    expr = let
      schema = schemas.darwinConfigurations or null;
      testOutput = {
        macbook = { system = "aarch64-darwin"; modules = []; };
        imac = { system = "x86_64-darwin"; modules = []; };
        mac-mini = { system = "aarch64-darwin"; modules = []; };
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # Test: darwinConfigurations with Johnny Decimal naming
  testDarwinConfigurationsJohnnyDecimalNaming = {
    expr = let
      schema = schemas.darwinConfigurations or null;
      testOutput = {
        "10.01-macbook-pro" = { system = "aarch64-darwin"; modules = []; };
        "10.02-imac" = { system = "x86_64-darwin"; modules = []; };
        "20.01-mac-mini-server" = { system = "aarch64-darwin"; modules = []; };
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # ===== Common Community Patterns =====

  # Test: Pattern - modules organized by macOS subsystem
  testDarwinModulesSubsystemPattern = {
    expr = let
      schema = schemas.darwinModules or null;
      # Common pattern in nix-darwin configs
      testOutput = {
        # System settings
        system-defaults = { ... }: {};
        finder = { ... }: {};
        dock = { ... }: {};
        # Package management
        homebrew = { ... }: {};
        nix-packages = { ... }: {};
        # Services
        nix-daemon = { ... }: {};
        yabai = { ... }: {};
        skhd = { ... }: {};
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # Test: Pattern - configurations for different Mac types
  testDarwinConfigurationsMacTypePattern = {
    expr = let
      schema = schemas.darwinConfigurations or null;
      testOutput = {
        # M1/M2 Macs
        "macbook-air-m1" = { system = "aarch64-darwin"; modules = []; };
        "macbook-pro-m2" = { system = "aarch64-darwin"; modules = []; };
        # Intel Macs
        "macbook-pro-intel" = { system = "x86_64-darwin"; modules = []; };
        "imac-intel" = { system = "x86_64-darwin"; modules = []; };
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # Test: Pattern - modules for window managers
  testDarwinModulesWindowManagerPattern = {
    expr = let
      schema = schemas.darwinModules or null;
      testOutput = {
        yabai = { ... }: {};
        skhd = { ... }: {};
        "yabai-rules" = { ... }: {};
        "skhd-keybindings" = { ... }: {};
        aerospace = { ... }: {};
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # ===== Edge Cases =====

  # Test: Empty modules output is valid
  testDarwinModulesEmpty = {
    expr = let
      schema = schemas.darwinModules or null;
      testOutput = {};
    in validateSchema schema testOutput;
    expected = true;
  };

  # Test: Empty configurations output is valid
  testDarwinConfigurationsEmpty = {
    expr = let
      schema = schemas.darwinConfigurations or null;
      testOutput = {};
    in validateSchema schema testOutput;
    expected = true;
  };

  # Test: Single module
  testDarwinModulesSingle = {
    expr = let
      schema = schemas.darwinModules or null;
      testOutput = {
        default = { ... }: {};
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # Test: Single configuration
  testDarwinConfigurationsSingle = {
    expr = let
      schema = schemas.darwinConfigurations or null;
      testOutput = {
        mymac = { system = "aarch64-darwin"; modules = []; };
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # ===== Mixed Architecture Support =====

  # Test: Configurations with both Intel and ARM
  testDarwinConfigurationsMixedArchitecture = {
    expr = let
      schema = schemas.darwinConfigurations or null;
      testOutput = {
        # ARM Macs
        "m1-macbook" = { system = "aarch64-darwin"; modules = []; };
        "m2-mac-studio" = { system = "aarch64-darwin"; modules = []; };
        # Intel Macs
        "intel-macbook" = { system = "x86_64-darwin"; modules = []; };
        "intel-imac" = { system = "x86_64-darwin"; modules = []; };
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # ===== Schema Properties =====

  # Test: darwinModules schema has required properties
  testDarwinModulesSchemaProperties = {
    expr = let
      schema = schemas.darwinModules or null;
    in
      if schema != null
      then schema ? version && schema ? inventory && builtins.isFunction schema.inventory
      else false;
    expected = true;
  };

  # Test: darwinConfigurations schema has required properties
  testDarwinConfigurationsSchemaProperties = {
    expr = let
      schema = schemas.darwinConfigurations or null;
    in
      if schema != null
      then schema ? version && schema ? inventory && builtins.isFunction schema.inventory
      else false;
    expected = true;
  };
}
