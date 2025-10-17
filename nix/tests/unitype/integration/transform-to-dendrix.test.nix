# Unitype Integration Test - nixosConfiguration to dendrix transformation
#
# This test demonstrates the full transformation pipeline:
# nixosConfiguration → IR → dendrix modules
#
# This serves as both a test and a proof-of-concept for real-world transformations.

{lib}: let
  unitype = lib.unitype;

  # Example nixosConfiguration mimicking dustinlyons/nixos-config structure
  # This is a realistic production-like config with multiple concerns
  exampleNixosConfig = {
    system = "x86_64-linux";

    # Real-world modules organized by concern (like dustinlyons "garfield" host)
    modules = [
      # Networking configuration
      {
        networking.hostName = "garfield";
        networking.firewall.enable = true;
        networking.firewall.allowedTCPPorts = [22 80 443];
        services.openssh.enable = true;
        services.openssh.settings.PermitRootLogin = "no";
      }

      # Graphics/Desktop configuration
      {
        services.xserver.enable = true;
        services.xserver.displayManager.gdm.enable = true;
        services.xserver.desktopManager.gnome.enable = true;
        hardware.graphics.enable = true;
      }

      # Development tools
      {
        programs.git.enable = true;
        programs.neovim.enable = true;
        programs.neovim.defaultEditor = true;
        environment.systemPackages = []; # Would contain dev tools
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

  # ============================================================================
  # Test: Full transformation pipeline
  # ============================================================================

  # Step 1: Encode nixosConfiguration to IR
  irResult = unitype.encoders.nixos.encode "10.01-garfield" exampleNixosConfig;

  # Step 2: Decode IR to dendrix modules
  dendrixResult = unitype.decoders.dendrix.decode irResult;

  # ============================================================================
  # Validation and Assertions
  # ============================================================================

  # Extract test results
  hasNetworkingAspect = dendrixResult ? networking;
  hasGraphicsAspect = dendrixResult ? graphics;
  hasDevelopmentAspect = dendrixResult ? development;

  # Check that aspects are valid NixOS modules (functions)
  networkingIsModule =
    if hasNetworkingAspect
    then builtins.isFunction dendrixResult.networking
    else false;

  graphicsIsModule =
    if hasGraphicsAspect
    then builtins.isFunction dendrixResult.graphics
    else false;

  developmentIsModule =
    if hasDevelopmentAspect
    then builtins.isFunction dendrixResult.development
    else false;

  # Try evaluating a dendrix aspect module
  # (In real use, this would be imported into a NixOS config)
  networkingEvaluated =
    if networkingIsModule
    then
      builtins.tryEval (dendrixResult.networking {
        config = {};
        lib = lib;
        pkgs = {};
      })
    else {success = false;};

in {
  # ============================================================================
  # Test Cases
  # ============================================================================

  # Test: IR encoding succeeded
  testEncodingProducedValidIR = {
    expr = irResult ? id && irResult ? kind && irResult.kind == "nixosConfiguration";
    expected = true;
  };

  # Test: IR captured JD structure
  testIRHasJDStructure = {
    expr =
      irResult.meta.jdStructure.category.id == "10"
      && irResult.meta.jdStructure.item.id == "01";
    expected = true;
  };

  # Test: IR identified aspects correctly
  testIRIdentifiedAspects = {
    expr =
      irResult.hints.aspects.networking == true
      && irResult.hints.aspects.graphics == true
      && irResult.hints.aspects.development == true;
    expected = true;
  };

  # Test: Dendrix decoding produced aspects
  testDendrixHasNetworkingAspect = {
    expr = hasNetworkingAspect;
    expected = true;
  };

  testDendrixHasGraphicsAspect = {
    expr = hasGraphicsAspect;
    expected = true;
  };

  testDendrixHasDevelopmentAspect = {
    expr = hasDevelopmentAspect;
    expected = true;
  };

  # Test: Dendrix aspects are valid NixOS modules
  testDendrixNetworkingIsModule = {
    expr = networkingIsModule;
    expected = true;
  };

  testDendrixGraphicsIsModule = {
    expr = graphicsIsModule;
    expected = true;
  };

  testDendrixDevelopmentIsModule = {
    expr = developmentIsModule;
    expected = true;
  };

  # Test: Dendrix modules can be evaluated
  testDendrixModuleEvaluates = {
    expr = networkingEvaluated.success;
    expected = true;
  };

  # Test: Dendrix module has imports
  testDendrixModuleHasImports = {
    expr = let
      evaluated = networkingEvaluated.value;
    in evaluated ? imports;
    expected = true;
  };

  # Test: Round-trip preserves structure
  testRoundTripPreservesModuleCount = {
    expr = let
      originalModuleCount = builtins.length exampleNixosConfig.modules;
      # Count total modules across all aspects
      dendrixModuleCounts = lib.mapAttrsToList (aspect: module:
        if module ? imports
        then builtins.length module.imports
        else 0
      ) dendrixResult;
      totalDendrixModules = lib.foldl lib.add 0 dendrixModuleCounts;
    in originalModuleCount == totalDendrixModules;
    expected = true;
  };

  # Test: Transformation is deterministic
  testTransformationIsDeterministic = {
    expr = let
      ir1 = unitype.encoders.nixos.encode "10.01-garfield" exampleNixosConfig;
      ir2 = unitype.encoders.nixos.encode "10.01-garfield" exampleNixosConfig;
      dendrix1 = unitype.decoders.dendrix.decode ir1;
      dendrix2 = unitype.decoders.dendrix.decode ir2;
    in
      # Check that aspect names are the same
      (builtins.attrNames dendrix1) == (builtins.attrNames dendrix2);
    expected = true;
  };

  # ============================================================================
  # Output for Inspection
  # ============================================================================

  # These aren't assertions, but data exports for manual inspection
  __meta = {
    description = "Integration test: nixosConfiguration → IR → dendrix";

    # Original config
    originalConfig = exampleNixosConfig;

    # Intermediate IR
    intermediateIR = {
      inherit (irResult) id kind;
      inherit (irResult.meta) jdStructure;
      inherit (irResult.hints) aspects;
    };

    # Final dendrix output
    dendrixOutput = {
      aspectNames = builtins.attrNames dendrixResult;
      aspectTypes = lib.mapAttrs (name: module:
        if builtins.isFunction module then "function" else "attrset"
      ) dendrixResult;
    };

    # Summary
    summary = ''
      Transformation: nixosConfiguration (6 modules) → dendrix (${toString (builtins.length (builtins.attrNames dendrixResult))} aspects)

      Aspects created:
      ${lib.concatStringsSep "\n" (map (name: "  - ${name}") (builtins.attrNames dendrixResult))}

      This demonstrates the complete unitype transformation pipeline working
      on a realistic production-like configuration.
    '';
  };
}
