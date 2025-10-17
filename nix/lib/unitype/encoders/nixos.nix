# Unitype nixosConfiguration Encoder
#
# Encodes nixosConfiguration flake outputs to canonical IR
#
# Input: id (string), config ({ system, modules, specialArgs? })
# Output: IR

{lib}: let
  inherit (lib) optional optionals;

  # Analyze a module to extract top-level config keys
  # Returns: { networking, services, programs, boot, users, ... }
  analyzeModule = module: let
    # Extract config keys from module
    # Module can be a path, function, or attrset
    configKeys =
      if builtins.isAttrs module
      then builtins.attrNames module
      else [];  # Can't analyze functions/paths without evaluation
  in configKeys;

  # Classify modules into aspects based on their configuration
  # Returns: { networking = bool; graphics = bool; ... }
  classifyModules = modules: let
    # Analyze all modules
    allKeys = lib.flatten (map analyzeModule modules);

    # Helper to check if any key matches a pattern
    hasKey = key: builtins.elem key allKeys;
    hasPrefix = prefix: builtins.any (k: lib.hasPrefix prefix k) allKeys;

    # Aspect detection rules
    aspects = {
      networking = hasKey "networking";

      graphics =
        hasKey "services" && (
          builtins.any (k:
            lib.hasInfix "xserver" k ||
            lib.hasInfix "wayland" k ||
            lib.hasInfix "plasma" k ||
            lib.hasInfix "gnome" k
          ) allKeys
        );

      development =
        hasKey "programs" && (
          builtins.any (k:
            lib.hasInfix "git" k ||
            lib.hasInfix "neovim" k ||
            lib.hasInfix "vim" k ||
            lib.hasInfix "vscode" k ||
            lib.hasInfix "emacs" k
          ) allKeys
        );

      boot = hasKey "boot";

      users = hasKey "users";

      services = hasKey "services";

      virtualisation = hasKey "virtualisation";

      hardware = hasKey "hardware";

      security = hasKey "security";

      environment = hasKey "environment";

      systemd = hasKey "systemd";

      nix = hasKey "nix";
    };

    # Return only aspects that are present
    presentAspects = lib.filterAttrs (_: v: v) aspects;
  in presentAspects;

  # Detect if modules contain secrets configuration
  detectSecrets = modules: let
    allKeys = lib.flatten (map analyzeModule modules);

    # Check for common secret management tools
    hasSecrets =
      builtins.any (k:
        lib.hasPrefix "age.secrets" k ||
        lib.hasPrefix "sops" k ||
        lib.hasPrefix "secrets" k
      ) allKeys;
  in hasSecrets;

  # Valid NixOS systems
  validSystems = [
    "x86_64-linux"
    "aarch64-linux"
    "i686-linux"
    "armv7l-linux"
    "riscv64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  # Validate system architecture
  validateSystem = system:
    if builtins.elem system validSystems
    then system
    else throw "Invalid system: ${system}. Must be one of: ${lib.concatStringsSep ", " validSystems}";

in {
  # Encode nixosConfiguration to IR
  # encode :: String -> Config -> IR
  encode = id: config: let
    # Validate inputs
    system = validateSystem (config.system or "x86_64-linux");
    modules = config.modules or [];
    specialArgs = config.specialArgs or {};

    # Extract metadata from specialArgs
    description = specialArgs.description or "";
    tags = specialArgs.tags or [];

    # Analyze modules
    aspects = classifyModules modules;
    hasSecrets = detectSecrets modules;

    # Build payload (preserve original config structure)
    payload = {
      inherit system modules;
    } // lib.optionalAttrs (specialArgs != {}) {
      inherit specialArgs;
    };

    # Determine possible transformation targets
    # nixosConfiguration can be transformed to:
    # - dendrix (aspect-oriented modules)
    # - iso (bootable image)
    # - vmware (VM image)
    # - docker (container)
    # - Any other nixos-generators format
    canTransformTo = [
      "dendrix"
      "iso"
      "vmware"
      "virtualbox"
      "docker"
      "install-iso"
      "qcow"
      "amazon"
      "azure"
      "gce"
    ];

    # Build IR using ir.mk
    ir = lib.unitype.ir.mk {
      inherit id;
      kind = "nixosConfiguration";
      inherit payload;

      meta = {
        inherit system description tags;
      };

      hints = {
        inherit canTransformTo aspects;
        requiresValidation = true;
        hasSecrets = hasSecrets;
      };
    };

    # Validate IR before returning
    validation = lib.unitype.ir.validate ir;

  in
    if validation.valid
    then ir
    else throw "Generated invalid IR: ${builtins.toJSON validation.errors}";
}
