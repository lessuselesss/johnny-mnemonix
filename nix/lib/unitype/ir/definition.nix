# Unitype IR (Intermediate Representation) Definition
#
# The canonical intermediate representation that all types encode to and decode from.
# This is the "Rosetta Stone" of the unitype transformation system.

{lib}: let
  inherit (lib) optionalAttrs;

  # Extract Johnny Decimal structure from an identifier
  # Supports formats: "10.01", "10.01-name", "10.01-multi-word-name"
  extractJDStructure = id: let
    # Parse the ID to extract components
    # Format: AA.BB[-name] where AA is category, BB is item
    parsed = builtins.match "([0-9]{2})\\.([0-9]{2})(-([a-zA-Z0-9-]+))?" id;

    # Extract matched groups
    categoryId = if parsed != null then builtins.elemAt parsed 0 else null;
    itemId = if parsed != null then builtins.elemAt parsed 1 else null;
    itemName = if parsed != null && builtins.elemAt parsed 2 != null
      then builtins.elemAt parsed 3
      else null;

    # Calculate area from category (round down to nearest 10)
    areaStart = if categoryId != null
      then let
        catNum = lib.toInt categoryId;
        areaNum = (catNum / 10) * 10;
        # Pad to 2 digits with leading zero if needed
        numStr = toString areaNum;
      in if builtins.stringLength numStr < 2 then "0${numStr}" else numStr
      else null;

    # Area range is X0-X9
    areaId = if areaStart != null
      then "${areaStart}-${toString ((lib.toInt areaStart) + 9)}"
      else null;

  in
    if parsed == null
    then {
      # Invalid ID - return minimal structure
      area = { id = "unknown"; name = ""; };
      category = { id = "unknown"; name = ""; };
      item = { id = "unknown"; name = ""; };
    }
    else {
      area = {
        id = areaId;
        name = "";  # Names typically come from external config
      };
      category = {
        id = categoryId;
        name = "";
      };
      item = {
        id = itemId;
        name = itemName or "";
      };
    };

  # Build hierarchical JD structure from ID and payload
  # Creates: { "10-19": { "10": { "10.01": { data, name } } } }
  buildJDStructure = id: payload: let
    jd = extractJDStructure id;

    # Extract names from JD structure
    areaId = jd.area.id;
    categoryId = jd.category.id;
    itemId = "${categoryId}.${jd.item.id}";
    itemName = jd.item.name;

  in
    if areaId == "unknown"
    then {}  # Invalid ID, return empty structure
    else {
      ${areaId} = {
        name = jd.area.name;
        ${categoryId} = {
          name = jd.category.name;
          ${itemId} = {
            name = itemName;
            data = payload;
          };
        };
      };
    };

in {
  # Create IR from minimal input
  # mk :: { id, kind, payload, meta?, hints? } -> IR
  mk = {
    id,
    kind,
    payload,
    meta ? {},
    hints ? {},
  }: let
    # Extract JD structure from id
    jdStructure = extractJDStructure id;

    # Build full metadata with defaults
    fullMeta = {
      system = meta.system or "x86_64-linux";
      description = meta.description or "";
      tags = meta.tags or [];
      source = meta.source or null;
      inherit jdStructure;
    } // meta;

    # Build full hints with defaults
    fullHints = {
      canTransformTo = hints.canTransformTo or [];
      requiresValidation = hints.requiresValidation or true;
      hasSecrets = hints.hasSecrets or false;
      aspects = hints.aspects or {};
    } // hints;

  in {
    # Core identity
    inherit id kind payload;

    # Metadata
    meta = fullMeta;

    # Transformation hints
    hints = fullHints;

    # Hierarchical structure (JD-organized)
    structure = buildJDStructure id payload;

    # Provenance tracking
    provenance = {
      originalType = kind;
      transformationChain = [];
      timestamp = builtins.currentTime;
    };
  };

  # Validate IR structure
  # validate :: IR -> { valid: bool, errors: [string] }
  validate = ir: let
    # Check required fields
    hasId = ir ? id;
    hasKind = ir ? kind;
    hasPayload = ir ? payload;
    hasMeta = ir ? meta;
    hasHints = ir ? hints;
    hasStructure = ir ? structure;
    hasProvenance = ir ? provenance;

    # Collect errors
    errors = lib.filter (e: e != null) [
      (if !hasId then "Missing required field: id" else null)
      (if !hasKind then "Missing required field: kind" else null)
      (if !hasPayload then "Missing required field: payload" else null)
      (if !hasMeta then "Missing required field: meta" else null)
      (if !hasHints then "Missing required field: hints" else null)
      (if !hasStructure then "Missing required field: structure" else null)
      (if !hasProvenance then "Missing required field: provenance" else null)
    ];

    # Overall validity
    isValid = hasId && hasKind && hasPayload && hasMeta && hasHints && hasStructure && hasProvenance;

  in {
    valid = isValid;
    inherit errors;
  };

  # Helper: Extract Johnny Decimal structure (exposed for testing)
  inherit extractJDStructure;

  # Helper: Build hierarchical structure (exposed for testing)
  inherit buildJDStructure;
}
