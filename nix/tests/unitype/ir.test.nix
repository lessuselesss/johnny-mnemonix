# Unitype IR (Intermediate Representation) Tests
#
# TDD Phase: RED - These tests will fail until we implement the IR
#
# Tests the canonical intermediate representation that all types encode to
# and decode from. The IR is the "Rosetta Stone" of the unitype system.

{lib}: let
  # Import IR module (will fail until implemented)
  unitype = lib.unitype or (throw "lib.unitype not yet implemented");
  ir = unitype.ir or (throw "lib.unitype.ir not yet implemented");
in {
  # ============================================================================
  # Basic Structure Tests
  # ============================================================================

  # Test: IR has all required top-level fields
  testIRHasRequiredFields = {
    expr = let
      result = ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {};
      };
    in
      result ? id &&
      result ? kind &&
      result ? meta &&
      result ? payload &&
      result ? hints &&
      result ? structure &&
      result ? provenance;
    expected = true;
  };

  # Test: IR preserves provided id
  testIRPreservesId = {
    expr = let
      result = ir.mk {
        id = "10.01-web-server";
        kind = "nixosConfiguration";
        payload = {};
      };
    in result.id;
    expected = "10.01-web-server";
  };

  # Test: IR preserves provided kind
  testIRPreservesKind = {
    expr = let
      result = ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {};
      };
    in result.kind;
    expected = "nixosConfiguration";
  };

  # Test: IR preserves provided payload
  testIRPreservesPayload = {
    expr = let
      testPayload = {
        system = "x86_64-linux";
        modules = [ ];
      };
      result = ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = testPayload;
      };
    in result.payload;
    expected = {
      system = "x86_64-linux";
      modules = [ ];
    };
  };

  # ============================================================================
  # Metadata Tests
  # ============================================================================

  # Test: IR adds default system when not provided
  testIRAddsDefaultSystem = {
    expr = let
      result = ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {};
      };
    in result.meta.system;
    expected = "x86_64-linux";
  };

  # Test: IR preserves provided system
  testIRPreservesProvidedSystem = {
    expr = let
      result = ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {};
        meta.system = "aarch64-linux";
      };
    in result.meta.system;
    expected = "aarch64-linux";
  };

  # Test: IR adds empty tags list when not provided
  testIRAddsEmptyTagsList = {
    expr = let
      result = ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {};
      };
    in result.meta.tags;
    expected = [ ];
  };

  # Test: IR preserves provided tags
  testIRPreservesProvidedTags = {
    expr = let
      result = ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {};
        meta.tags = ["production" "web"];
      };
    in result.meta.tags;
    expected = ["production" "web"];
  };

  # Test: IR extracts JD structure from simple id
  testIRExtractsJDStructureSimple = {
    expr = let
      result = ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {};
      };
    in
      result.meta.jdStructure.area.id == "10-19" &&
      result.meta.jdStructure.category.id == "10" &&
      result.meta.jdStructure.item.id == "01";
    expected = true;
  };

  # Test: IR extracts JD structure from id with name
  testIRExtractsJDStructureWithName = {
    expr = let
      result = ir.mk {
        id = "10.01-web-server";
        kind = "nixosConfiguration";
        payload = {};
      };
    in
      result.meta.jdStructure.area.id == "10-19" &&
      result.meta.jdStructure.category.id == "10" &&
      result.meta.jdStructure.item.id == "01" &&
      result.meta.jdStructure.item.name == "web-server";
    expected = true;
  };

  # ============================================================================
  # Hints Tests
  # ============================================================================

  # Test: IR adds empty canTransformTo list when not provided
  testIRAddsEmptyCanTransformToList = {
    expr = let
      result = ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {};
      };
    in result.hints.canTransformTo;
    expected = [ ];
  };

  # Test: IR preserves provided canTransformTo
  testIRPreservesCanTransformTo = {
    expr = let
      result = ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {};
        hints.canTransformTo = ["dendrix" "iso" "vmware"];
      };
    in result.hints.canTransformTo;
    expected = ["dendrix" "iso" "vmware"];
  };

  # Test: IR adds default requiresValidation
  testIRAddsDefaultRequiresValidation = {
    expr = let
      result = ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {};
      };
    in result.hints.requiresValidation;
    expected = true;
  };

  # Test: IR adds default hasSecrets
  testIRAddsDefaultHasSecrets = {
    expr = let
      result = ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {};
      };
    in result.hints.hasSecrets;
    expected = false;
  };

  # Test: IR adds empty aspects when not provided
  testIRAddsEmptyAspects = {
    expr = let
      result = ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {};
      };
    in result.hints.aspects;
    expected = {};
  };

  # Test: IR preserves provided aspects
  testIRPreservesProvidedAspects = {
    expr = let
      result = ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {};
        hints.aspects = {
          networking = true;
          development = true;
        };
      };
    in result.hints.aspects;
    expected = {
      networking = true;
      development = true;
    };
  };

  # ============================================================================
  # Provenance Tests
  # ============================================================================

  # Test: IR records original type in provenance
  testIRRecordsOriginalType = {
    expr = let
      result = ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {};
      };
    in result.provenance.originalType;
    expected = "nixosConfiguration";
  };

  # Test: IR initializes empty transformation chain
  testIRInitializesEmptyChain = {
    expr = let
      result = ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {};
      };
    in result.provenance.transformationChain;
    expected = [ ];
  };

  # Test: IR records timestamp
  testIRRecordsTimestamp = {
    expr = let
      result = ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {};
      };
    in result.provenance ? timestamp;
    expected = true;
  };

  # ============================================================================
  # Validation Tests
  # ============================================================================

  # Test: IR validation catches missing id
  testIRValidationCatchesMissingId = {
    expr = let
      invalidIR = {
        kind = "nixosConfiguration";
        payload = {};
      };
      result = builtins.tryEval (ir.validate invalidIR);
    in result.success;
    expected = false;
  };

  # Test: IR validation catches missing kind
  testIRValidationCatchesMissingKind = {
    expr = let
      invalidIR = {
        id = "10.01";
        payload = {};
      };
      result = builtins.tryEval (ir.validate invalidIR);
    in result.success;
    expected = false;
  };

  # Test: IR validation catches missing payload
  testIRValidationCatchesMissingPayload = {
    expr = let
      invalidIR = {
        id = "10.01";
        kind = "nixosConfiguration";
      };
      result = builtins.tryEval (ir.validate invalidIR);
    in result.success;
    expected = false;
  };

  # Test: IR validation accepts valid IR
  testIRValidationAcceptsValid = {
    expr = let
      validIR = ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {};
      };
      result = ir.validate validIR;
    in result.valid;
    expected = true;
  };

  # ============================================================================
  # Structure Building Tests
  # ============================================================================

  # Test: IR builds hierarchical structure from JD id
  testIRBuildsHierarchicalStructure = {
    expr = let
      result = ir.mk {
        id = "10.01-web-server";
        kind = "nixosConfiguration";
        payload = {
          config = "test";
        };
      };
    in
      result.structure ? "10-19" &&
      result.structure."10-19" ? "10" &&
      result.structure."10-19"."10" ? "10.01";
    expected = true;
  };

  # Test: IR structure contains payload at leaf
  testIRStructureContainsPayload = {
    expr = let
      testPayload = {
        system = "x86_64-linux";
        config = "test";
      };
      result = ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = testPayload;
      };
      leaf = result.structure."10-19"."10"."10.01";
    in leaf.data;
    expected = {
      system = "x86_64-linux";
      config = "test";
    };
  };

  # Test: IR structure includes names from JD parsing
  testIRStructureIncludesNames = {
    expr = let
      result = ir.mk {
        id = "10.01-web-server";
        kind = "nixosConfiguration";
        payload = {};
      };
    in
      result.structure."10-19".name or "" != "" &&
      result.structure."10-19"."10".name or "" != "" &&
      result.structure."10-19"."10"."10.01".name == "web-server";
    expected = true;
  };
}
