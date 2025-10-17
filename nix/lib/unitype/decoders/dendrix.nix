# Unitype dendrix Decoder
#
# Transforms canonical IR to dendrix aspect-oriented modules
#
# Input: IR with kind = "nixosConfiguration"
# Output: Attrset of aspect modules
#
# Example:
#   {
#     networking = { config, pkgs, ... }: { /* networking config */ };
#     graphics = { config, pkgs, ... }: { /* graphics config */ };
#     development = { config, pkgs, ... }: { /* development config */ };
#   }

{lib}: let
  # Validate IR is compatible with dendrix decoding
  validateIR = ir:
    if ir.kind or null != "nixosConfiguration"
    then throw "dendrix decoder can only decode nixosConfiguration IR, got: ${ir.kind or "null"}"
    else ir;

  # Extract aspects from IR hints, with fallback to empty attrset
  extractAspects = ir:
    ir.hints.aspects or {};

  # Determine which aspect a module belongs to based on its content
  # Returns the most appropriate aspect name, or "base" as fallback
  determineModuleAspect = module: aspectHints: let
    # Analyze module to extract top-level keys
    moduleKeys =
      if builtins.isFunction module
      then []
      else if builtins.isAttrs module
      then builtins.attrNames (builtins.removeAttrs module ["imports" "config" "options"])
      else [];

    # Check if module has certain keys
    hasKey = key: builtins.elem key moduleKeys;
    hasAnyKey = keys: builtins.any (k: hasKey k) keys;

    # Heuristic classification
    isNetworking = hasAnyKey ["networking" "services"] || (hasKey "services" && module ? services.nginx);
    isGraphics = hasKey "services" && (module ? services.xserver || module ? services.wayland);
    isDevelopment = hasKey "programs" && (module ? programs.git || module ? programs.vim || module ? programs.neovim);
    isServices = hasKey "services" && !(isNetworking || isGraphics);

    # Match to provided aspects
    availableAspects = builtins.attrNames aspectHints;
    hasAspect = aspect: builtins.elem aspect availableAspects;
  in
    if isNetworking && hasAspect "networking"
    then "networking"
    else if isGraphics && hasAspect "graphics"
    then "graphics"
    else if isDevelopment && hasAspect "development"
    then "development"
    else if isServices && hasAspect "services"
    then "services"
    # Fallback to first available aspect or "base"
    else if availableAspects != []
    then builtins.head availableAspects
    else "base";

  # Split modules by aspect
  splitModulesByAspect = modules: aspectHints: let
    # Group modules by their determined aspect
    grouped =
      lib.foldl
      (acc: module: let
        aspect = determineModuleAspect module aspectHints;
      in
        acc
        // {
          ${aspect} = (acc.${aspect} or []) ++ [module];
        })
      {}
      modules;
  in
    grouped;

  # Merge multiple modules into a single dendrix aspect module
  # Returns a NixOS module (function) that imports all the modules
  mergeModules = modules: aspectName: jdStructure:
    {
      config,
      lib,
      pkgs,
      ...
    }: {
      # Import all the aspect's modules
      imports = modules;

      # Add metadata about the aspect
      _module.args = {
        # Preserve JD structure
        jdMeta = jdStructure;
        aspectName = aspectName;
      };
    };

  # Create dendrix aspect modules from grouped modules
  createDendrixModules = groupedModules: jdStructure:
    lib.mapAttrs
    (aspectName: modules:
      mergeModules modules aspectName jdStructure)
    groupedModules;

  # Main decode function
  decode = ir: let
    # 1. Validate IR
    validIR = validateIR ir;

    # 2. Extract aspects from hints
    aspectHints = extractAspects validIR;

    # 3. Get modules from payload
    modules = validIR.payload.modules or [];

    # 4. Extract JD structure for metadata
    jdStructure = validIR.meta.jdStructure or null;

    # 5. Handle empty modules or no aspects
    result =
      if modules == [] || aspectHints == {}
      then
        # Return empty attrset or base aspect
        if aspectHints != {}
        then
          lib.mapAttrs
          (aspectName: _: {
            config,
            lib,
            pkgs,
            ...
          }: {
            imports = [];
            _module.args = {
              jdMeta = jdStructure;
              aspectName = aspectName;
            };
          })
          aspectHints
        else {}
      else let
        # 6. Split modules by aspect
        groupedModules = splitModulesByAspect modules aspectHints;

        # 7. Create dendrix aspect modules
        dendrixModules = createDendrixModules groupedModules jdStructure;
      in
        dendrixModules;
  in
    result;
in {
  inherit decode;

  # Export helpers for testing
  __internal = {
    inherit
      validateIR
      extractAspects
      determineModuleAspect
      splitModulesByAspect
      mergeModules
      createDendrixModules
      ;
  };
}
