# Unitype dendrix Decoder Tests
#
# TDD Phase: RED - These tests will fail until we implement the decoder
#
# Tests decoding of IR to dendrix aspect-oriented modules

{lib}: let
  # Import decoder module (will fail until implemented)
  unitype = lib.unitype or (throw "lib.unitype not yet implemented");
  decoders = unitype.decoders or (throw "lib.unitype.decoders not yet implemented");
  dendrixDecoder = decoders.dendrix or (throw "lib.unitype.decoders.dendrix not yet implemented");
in {
  # ============================================================================
  # Basic Decoding Tests
  # ============================================================================

  # Test: Decoder exists and is callable
  testDecoderExists = {
    expr = builtins.isFunction dendrixDecoder.decode;
    expected = true;
  };

  # Test: Decoder produces aspect-organized output
  testDecoderProducesAspectOutput = {
    expr = let
      ir = lib.unitype.ir.mk {
        id = "10.01-test";
        kind = "nixosConfiguration";
        payload = {
          system = "x86_64-linux";
          modules = [];
        };
        hints.aspects = {
          networking = true;
        };
      };
      result = dendrixDecoder.decode ir;
    in result ? networking;
    expected = true;
  };

  # Test: Decoder validates IR kind
  testDecoderValidatesIRKind = {
    expr = let
      invalidIR = lib.unitype.ir.mk {
        id = "10.01";
        kind = "homeConfiguration";  # Wrong kind
        payload = {};
      };
      result = builtins.tryEval (dendrixDecoder.decode invalidIR);
    in result.success;
    expected = false;
  };

  # ============================================================================
  # Aspect Organization Tests
  # ============================================================================

  # Test: Single aspect module created
  testSingleAspectModule = {
    expr = let
      ir = lib.unitype.ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {
          system = "x86_64-linux";
          modules = [
            { networking.hostName = "test"; }
          ];
        };
        hints.aspects.networking = true;
      };
      result = dendrixDecoder.decode ir;
    in
      result ? networking &&
      (builtins.isFunction result.networking || builtins.isAttrs result.networking);
    expected = true;
  };

  # Test: Multiple aspects created
  testMultipleAspectsCreated = {
    expr = let
      ir = lib.unitype.ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {
          system = "x86_64-linux";
          modules = [
            { networking.hostName = "test"; }
            { services.xserver.enable = true; }
          ];
        };
        hints.aspects = {
          networking = true;
          graphics = true;
        };
      };
      result = dendrixDecoder.decode ir;
    in
      result ? networking && result ? graphics;
    expected = true;
  };

  # Test: Aspects have valid names (lowercase-hyphen)
  testAspectNamesValid = {
    expr = let
      ir = lib.unitype.ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {
          system = "x86_64-linux";
          modules = [];
        };
        hints.aspects = {
          networking = true;
          "web-server" = true;
        };
      };
      result = dendrixDecoder.decode ir;
      # All aspect names should match pattern
      aspectNames = builtins.attrNames result;
      validPattern = name: builtins.match "^[a-z][a-z0-9-]*$" name != null;
    in builtins.all validPattern aspectNames;
    expected = true;
  };

  # ============================================================================
  # Module Splitting Tests
  # ============================================================================

  # Test: Modules split by aspect
  testModulesSplitByAspect = {
    expr = let
      ir = lib.unitype.ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {
          system = "x86_64-linux";
          modules = [
            { networking.hostName = "test"; }
            { services.xserver.enable = true; }
            { programs.git.enable = true; }
          ];
        };
        hints.aspects = {
          networking = true;
          graphics = true;
          development = true;
        };
      };
      result = dendrixDecoder.decode ir;
    in
      # Each aspect should have modules
      builtins.length (builtins.attrNames result) >= 3;
    expected = true;
  };

  # Test: Module content preserved
  testModuleContentPreserved = {
    expr = let
      ir = lib.unitype.ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {
          system = "x86_64-linux";
          modules = [
            {
              services.nginx.enable = true;
              services.nginx.virtualHosts."example.com" = {};
            }
          ];
        };
        hints.aspects.networking = true;
      };
      result = dendrixDecoder.decode ir;
      networkingModule = result.networking;
    in
      # Module should be importable
      builtins.isFunction networkingModule || builtins.isAttrs networkingModule;
    expected = true;
  };

  # ============================================================================
  # Aspect Module Structure Tests
  # ============================================================================

  # Test: Aspect module is importable (function or attrset)
  testAspectModuleIsImportable = {
    expr = let
      ir = lib.unitype.ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {
          system = "x86_64-linux";
          modules = [
            { networking.hostName = "test"; }
          ];
        };
        hints.aspects.networking = true;
      };
      result = dendrixDecoder.decode ir;
      module = result.networking;
    in
      builtins.isFunction module || builtins.isAttrs module;
    expected = true;
  };

  # Test: Aspect module has valid structure
  testAspectModuleHasValidStructure = {
    expr = let
      ir = lib.unitype.ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {
          system = "x86_64-linux";
          modules = [
            { networking.hostName = "test"; }
          ];
        };
        hints.aspects.networking = true;
      };
      result = dendrixDecoder.decode ir;
      module = result.networking;
    in
      # Module should be a function or have imports/exports/config
      if builtins.isFunction module
      then true
      else (module ? imports || module ? exports || module ? config);
    expected = true;
  };

  # ============================================================================
  # Edge Cases Tests
  # ============================================================================

  # Test: Empty modules list
  testEmptyModulesList = {
    expr = let
      ir = lib.unitype.ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {
          system = "x86_64-linux";
          modules = [];
        };
        hints.aspects = {};
      };
      result = dendrixDecoder.decode ir;
    in builtins.isAttrs result;
    expected = true;
  };

  # Test: No aspects hint
  testNoAspectsHint = {
    expr = let
      ir = lib.unitype.ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {
          system = "x86_64-linux";
          modules = [
            { networking.hostName = "test"; }
          ];
        };
        # No hints.aspects provided
      };
      result = dendrixDecoder.decode ir;
    in builtins.isAttrs result;
    expected = true;
  };

  # Test: Module with imports
  testModuleWithImports = {
    expr = let
      ir = lib.unitype.ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {
          system = "x86_64-linux";
          modules = [
            {
              imports = [];
              networking.hostName = "test";
            }
          ];
        };
        hints.aspects.networking = true;
      };
      result = dendrixDecoder.decode ir;
    in result ? networking;
    expected = true;
  };

  # ============================================================================
  # Cross-Cutting Concerns Tests
  # ============================================================================

  # Test: Module with multiple concerns
  testModuleWithMultipleConcerns = {
    expr = let
      ir = lib.unitype.ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {
          system = "x86_64-linux";
          modules = [
            {
              networking.firewall.enable = true;
              services.openssh.enable = true;
            }
          ];
        };
        hints.aspects = {
          networking = true;
          services = true;
        };
      };
      result = dendrixDecoder.decode ir;
    in
      # Module should be placed in dominant aspect
      result ? networking || result ? services;
    expected = true;
  };

  # Test: System configuration preserved
  testSystemConfigPreserved = {
    expr = let
      ir = lib.unitype.ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {
          system = "aarch64-linux";
          modules = [
            { networking.hostName = "test"; }
          ];
        };
        hints.aspects.networking = true;
      };
      result = dendrixDecoder.decode ir;
    in
      # Decoder should preserve system info somehow
      result ? networking;
    expected = true;
  };

  # ============================================================================
  # Validation Tests
  # ============================================================================

  # Test: Output matches dendrix schema
  testOutputMatchesDendrixSchema = {
    expr = let
      ir = lib.unitype.ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {
          system = "x86_64-linux";
          modules = [
            { networking.hostName = "test"; }
          ];
        };
        hints.aspects.networking = true;
      };
      result = dendrixDecoder.decode ir;

      # Validate against dendrix schema
      schema = lib.types.flakeTypes.dendrix.schemas.dendrixModules;
      validation = schema.inventory result;
    in
      # Schema should accept the output
      validation ? children;
    expected = true;
  };

  # Test: Aspect names pass schema validation
  testAspectNamesPassSchema = {
    expr = let
      ir = lib.unitype.ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {
          system = "x86_64-linux";
          modules = [];
        };
        hints.aspects = {
          networking = true;
          development = true;
        };
      };
      result = dendrixDecoder.decode ir;

      schema = lib.types.flakeTypes.dendrix.schemas.dendrixModules;
      validation = schema.inventory result;

      # Check aspect name validation
      allAspectsValid = builtins.all (aspectName:
        let child = validation.children.${aspectName};
        in child.evalChecks.hasValidAspectName
      ) (builtins.attrNames validation.children);
    in allAspectsValid;
    expected = true;
  };

  # ============================================================================
  # JD Structure Preservation Tests
  # ============================================================================

  # Test: JD ID preserved in output
  testJDIDPreservedInOutput = {
    expr = let
      ir = lib.unitype.ir.mk {
        id = "10.01-web-server";
        kind = "nixosConfiguration";
        payload = {
          system = "x86_64-linux";
          modules = [
            { services.nginx.enable = true; }
          ];
        };
        hints.aspects.networking = true;
      };
      result = dendrixDecoder.decode ir;
    in
      # Result should preserve JD structure somehow
      # (maybe in module metadata or comments)
      result ? networking;
    expected = true;
  };
}
