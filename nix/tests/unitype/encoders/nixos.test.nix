# Unitype nixosConfiguration Encoder Tests
#
# TDD Phase: RED - These tests will fail until we implement the encoder
#
# Tests encoding of nixosConfiguration flake outputs to IR

{lib}: let
  # Import encoder module (will fail until implemented)
  unitype = lib.unitype or (throw "lib.unitype not yet implemented");
  encoders = unitype.encoders or (throw "lib.unitype.encoders not yet implemented");
  nixosEncoder = encoders.nixos or (throw "lib.unitype.encoders.nixos not yet implemented");
in {
  # ============================================================================
  # Basic Encoding Tests
  # ============================================================================

  # Test: Encoder exists and is callable
  testEncoderExists = {
    expr = builtins.isFunction nixosEncoder.encode;
    expected = true;
  };

  # Test: Minimal nixosConfiguration encodes successfully
  testEncodesMinimalConfig = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [ ];
      };
      result = nixosEncoder.encode "10.01-test-server" config;
    in result ? id && result ? kind && result ? payload;
    expected = true;
  };

  # Test: Encoded IR has correct kind
  testEncodedKindIsNixOS = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [ ];
      };
      result = nixosEncoder.encode "10.01-test-server" config;
    in result.kind;
    expected = "nixosConfiguration";
  };

  # Test: Encoded IR preserves ID
  testEncodedIRPreservesId = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [ ];
      };
      result = nixosEncoder.encode "10.01-test-server" config;
    in result.id;
    expected = "10.01-test-server";
  };

  # Test: Encoded IR extracts system from config
  testEncodedIRExtractsSystem = {
    expr = let
      config = {
        system = "aarch64-linux";
        modules = [ ];
      };
      result = nixosEncoder.encode "10.01-test-server" config;
    in result.meta.system;
    expected = "aarch64-linux";
  };

  # ============================================================================
  # Module Classification Tests
  # ============================================================================

  # Test: Encoder classifies networking modules
  testClassifiesNetworkingModules = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [
          { networking.hostName = "test"; }
          { networking.firewall.enable = true; }
        ];
      };
      result = nixosEncoder.encode "10.01-test-server" config;
    in result.hints.aspects.networking or false;
    expected = true;
  };

  # Test: Encoder classifies graphics modules
  testClassifiesGraphicsModules = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [
          { services.xserver.enable = true; }
        ];
      };
      result = nixosEncoder.encode "10.01-desktop" config;
    in result.hints.aspects.graphics or false;
    expected = true;
  };

  # Test: Encoder classifies development modules
  testClassifiesDevelopmentModules = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [
          { programs.git.enable = true; }
          { programs.neovim.enable = true; }
        ];
      };
      result = nixosEncoder.encode "10.01-devbox" config;
    in result.hints.aspects.development or false;
    expected = true;
  };

  # Test: Encoder classifies multiple aspects
  testClassifiesMultipleAspects = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [
          { networking.hostName = "test"; }
          { services.xserver.enable = true; }
          { programs.git.enable = true; }
        ];
      };
      result = nixosEncoder.encode "10.01-workstation" config;
      aspects = result.hints.aspects;
    in
      (aspects.networking or false) &&
      (aspects.graphics or false) &&
      (aspects.development or false);
    expected = true;
  };

  # ============================================================================
  # Payload Preservation Tests
  # ============================================================================

  # Test: Payload preserves modules list
  testPayloadPreservesModules = {
    expr = let
      testModules = [
        { networking.hostName = "test"; }
        { services.openssh.enable = true; }
      ];
      config = {
        system = "x86_64-linux";
        modules = testModules;
      };
      result = nixosEncoder.encode "10.01-test" config;
    in builtins.length result.payload.modules;
    expected = 2;
  };

  # Test: Payload preserves specialArgs
  testPayloadPreservesSpecialArgs = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [ ];
        specialArgs = { myArg = "value"; };
      };
      result = nixosEncoder.encode "10.01-test" config;
    in result.payload.specialArgs.myArg;
    expected = "value";
  };

  # Test: Payload preserves system
  testPayloadPreservesSystem = {
    expr = let
      config = {
        system = "aarch64-darwin";
        modules = [ ];
      };
      result = nixosEncoder.encode "10.01-test" config;
    in result.payload.system;
    expected = "aarch64-darwin";
  };

  # ============================================================================
  # Transformation Hints Tests
  # ============================================================================

  # Test: Hints include dendrix as possible target
  testHintsIncludeDendrix = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [ ];
      };
      result = nixosEncoder.encode "10.01-test" config;
    in builtins.elem "dendrix" result.hints.canTransformTo;
    expected = true;
  };

  # Test: Hints include ISO as possible target
  testHintsIncludeISO = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [ ];
      };
      result = nixosEncoder.encode "10.01-test" config;
    in builtins.elem "iso" result.hints.canTransformTo;
    expected = true;
  };

  # Test: Hints mark config as requiring validation
  testHintsRequireValidation = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [ ];
      };
      result = nixosEncoder.encode "10.01-test" config;
    in result.hints.requiresValidation;
    expected = true;
  };

  # ============================================================================
  # Module Content Analysis Tests
  # ============================================================================

  # Test: Detects secrets in module config
  testDetectsSecretsInModules = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [
          { age.secrets.mySecret = { }; }
        ];
      };
      result = nixosEncoder.encode "10.01-test" config;
    in result.hints.hasSecrets;
    expected = true;
  };

  # Test: No secrets by default
  testNoSecretsByDefault = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [
          { networking.hostName = "test"; }
        ];
      };
      result = nixosEncoder.encode "10.01-test" config;
    in result.hints.hasSecrets;
    expected = false;
  };

  # Test: Detects boot configuration
  testDetectsBootConfig = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [
          { boot.loader.systemd-boot.enable = true; }
        ];
      };
      result = nixosEncoder.encode "10.01-test" config;
    in result.hints.aspects.boot or false;
    expected = true;
  };

  # Test: Detects users configuration
  testDetectsUsersConfig = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [
          { users.users.alice = { }; }
        ];
      };
      result = nixosEncoder.encode "10.01-test" config;
    in result.hints.aspects.users or false;
    expected = true;
  };

  # Test: Detects services configuration
  testDetectsServicesConfig = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [
          { services.nginx.enable = true; }
          { services.postgresql.enable = true; }
        ];
      };
      result = nixosEncoder.encode "10.01-test" config;
    in result.hints.aspects.services or false;
    expected = true;
  };

  # ============================================================================
  # Validation Tests
  # ============================================================================

  # Test: Encoder validates IR before returning
  testEncoderValidatesIR = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [ ];
      };
      result = nixosEncoder.encode "10.01-test" config;
      # If encoder didn't validate, IR might be malformed
      ir = lib.unitype.ir;
      validation = ir.validate result;
    in validation.valid;
    expected = true;
  };

  # Test: Encoder rejects invalid system
  testEncoderRejectsInvalidSystem = {
    expr = let
      config = {
        system = "invalid-system";
        modules = [ ];
      };
      result = builtins.tryEval (nixosEncoder.encode "10.01-test" config);
    in result.success;
    expected = false;
  };

  # ============================================================================
  # Metadata Extraction Tests
  # ============================================================================

  # Test: Extracts description from specialArgs
  testExtractsDescriptionFromSpecialArgs = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [ ];
        specialArgs = { description = "Test server"; };
      };
      result = nixosEncoder.encode "10.01-test" config;
    in result.meta.description;
    expected = "Test server";
  };

  # Test: Extracts tags from specialArgs
  testExtractsTagsFromSpecialArgs = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [ ];
        specialArgs = { tags = ["production" "web"]; };
      };
      result = nixosEncoder.encode "10.01-test" config;
    in result.meta.tags;
    expected = ["production" "web"];
  };

  # ============================================================================
  # Edge Cases Tests
  # ============================================================================

  # Test: Handles empty modules list
  testHandlesEmptyModules = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [ ];
      };
      result = nixosEncoder.encode "10.01-test" config;
    in builtins.length result.payload.modules;
    expected = 0;
  };

  # Test: Handles missing specialArgs
  testHandlesMissingSpecialArgs = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [ ];
      };
      result = nixosEncoder.encode "10.01-test" config;
    in result.payload ? specialArgs;
    expected = true;
  };

  # Test: Handles module with imports
  testHandlesModuleWithImports = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [
          {
            imports = [ ];
            networking.hostName = "test";
          }
        ];
      };
      result = nixosEncoder.encode "10.01-test" config;
    in result ? payload;
    expected = true;
  };
}
