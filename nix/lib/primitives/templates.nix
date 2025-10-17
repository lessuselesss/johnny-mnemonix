# Primitives: Templates
# Provides template parsing, rendering, and extraction
#
# Templates are strings with placeholders like "{name}" or "{name:width}"
# that can be rendered with values or used to extract values from strings.
#
# API:
#   parse = String -> Template
#   render = Template -> AttrSet -> String | Null
#   extract = Template -> String -> AttrSet | Null
#
# Examples:
#   template = templates.parse "{dept:3}-{year:2}-{seq:3}";
#   templates.render template {dept = "ENG"; year = "24"; seq = "001";}
#     => "ENG-24-001"
#   templates.extract template "ENG-24-001"
#     => {dept = "ENG"; year = "24"; seq = "001";}

{lib}: let
  # Split a template string into literal and placeholder parts
  # Uses builtins.split with regex to identify {name} or {name:width} patterns
  #
  # Example: "{dept:3}-{year}" -> ["" [["dept" ":3"]] "-" [["year" null]] ""]
  #
  # Returns: Raw split result from builtins.split
  splitTemplate = str: let
    # Regex pattern matches:
    # - \{ - Opening brace (escaped)
    # - ([a-zA-Z][a-zA-Z0-9]*) - Capture group 1: name (starts with letter)
    # - (:[0-9]+)? - Capture group 2: optional ":width" (colon + digits)
    # - \} - Closing brace (escaped)
    parts = builtins.split "\\{([a-zA-Z][a-zA-Z0-9]*)(:[0-9]+)?\\}" str;
  in
    parts;

  # Parse a placeholder from regex match groups
  # Takes the match list from builtins.split and extracts name and width
  #
  # Input: ["dept" ":3"] or ["year" null]
  # Output: {name = "dept"; width = 3;} or {name = "year"; width = null;}
  parsePlaceholder = match: let
    name = builtins.elemAt match 0; # First capture group
    widthStr = builtins.elemAt match 1; # Second capture group (":N" or null)
    width =
      if widthStr == null
      then null
      else let
        # Strip the leading ":" from ":3" -> "3"
        digitStr = builtins.substring 1 (builtins.stringLength widthStr) widthStr;
      in
        lib.toInt digitStr;
  in {
    inherit name width;
  };

  # Convert builtins.split result to structured parts list
  # Alternates between strings (literals) and lists (placeholders)
  #
  # Example:
  #   Input:  ["" [["dept" ":3"]] "-" [["year" null]] ""]
  #   Output: [{type="placeholder"; value={name="dept"; width=3;}}
  #            {type="literal"; value="-";}
  #            {type="placeholder"; value={name="year"; width=null;}}]
  partsFromSplit = split: let
    go = idx: parts:
      if idx >= builtins.length split
      then []
      else let
        part = builtins.elemAt split idx;
        isString = builtins.isString part;
        rest = go (idx + 1) parts;
      in
        if isString
        then
          # Literal text between placeholders
          if part == ""
          then rest # Skip empty strings
          else [{type = "literal"; value = part;}] ++ rest
        else
          # Placeholder (list from regex capture groups)
          [{type = "placeholder"; value = parsePlaceholder part;}] ++ rest;
  in
    go 0 split;
in {
  # Parse a template string into a structured template object
  #
  # Extracts placeholders like {name} or {name:width} and literal text.
  #
  # Returns: {
  #   template = original string;
  #   parts = [{type="literal"|"placeholder"; value=...}, ...];
  #   placeholders = [{name=...; width=...}, ...];
  # }
  #
  # Example:
  #   parse "{dept:3}-{year:2}"
  #   => {
  #     template = "{dept:3}-{year:2}";
  #     parts = [
  #       {type="placeholder"; value={name="dept"; width=3;}}
  #       {type="literal"; value="-";}
  #       {type="placeholder"; value={name="year"; width=2;}}
  #     ];
  #     placeholders = [{name="dept"; width=3;} {name="year"; width=2;}];
  #   }
  parse = str: let
    split = splitTemplate str;
    parts = partsFromSplit split;
    placeholders =
      builtins.filter (p: p.type == "placeholder") parts
      |> map (p: p.value);
  in {
    inherit parts placeholders;
    template = str;
  };

  # Render a template by substituting placeholder values
  #
  # Takes a parsed template and an attrset of values, substitutes each
  # placeholder with its corresponding value. Validates width constraints.
  #
  # Returns: Rendered string, or null if:
  #   - Any required placeholder value is missing from attrset
  #   - Any value violates width constraint (too short/long)
  #
  # Example:
  #   template = parse "{dept:3}-{year:2}";
  #   render template {dept = "ENG"; year = "24";}  => "ENG-24"
  #   render template {dept = "EN"; year = "24";}   => null (dept too short)
  #   render template {dept = "ENG";}               => null (year missing)
  render = template: values: let
    parts = template.parts;

    # Render a single part
    renderPart = part:
      if part.type == "literal"
      then part.value
      else let
        # Placeholder
        ph = part.value;
        name = ph.name;
        width = ph.width;
        value = values.${name} or null;
      in
        if value == null
        then null
        else if width != null && builtins.stringLength value != width
        then null
        else value;

    # Render all parts
    rendered = map renderPart parts;

    # Check if any part failed (returned null)
    hasNull = builtins.any (p: p == null) rendered;
  in
    if hasNull
    then null
    else builtins.concatStringsSep "" rendered;

  # Extract values from a string using a template pattern
  #
  # Builds a regex from the template and extracts captured placeholder values.
  # This is the reverse operation of render.
  #
  # Algorithm:
  #   1. Convert template to regex pattern:
  #      - Literals: Escape special regex chars
  #      - Placeholders with width: Match exactly N chars (.{N})
  #      - Placeholders without width: Match one or more chars (.+)
  #   2. Match string against pattern
  #   3. Zip placeholder names with captured values
  #
  # Returns: Attrset {name = value, ...}, or null if:
  #   - String doesn't match template pattern
  #   - Width constraints not satisfied
  #
  # Example:
  #   template = parse "{dept:3}-{year:2}-{seq:3}";
  #   extract template "ENG-24-001"
  #     => {dept = "ENG"; year = "24"; seq = "001";}
  #   extract template "EN-24-001"
  #     => null (dept should be 3 chars)
  extract = template: str: let
    parts = template.parts;

    # Build a regex pattern from the template
    # For each part: literal -> escape it, placeholder -> capture group
    buildPattern = let
      # Escape special regex characters in literals
      escapeRegex = s:
        builtins.replaceStrings
        ["." "*" "+" "?" "[" "]" "(" ")" "{" "}" "^" "$" "|" "\\"]
        ["\\." "\\*" "\\+" "\\?" "\\[" "\\]" "\\(" "\\)" "\\{" "\\}" "\\^" "\\$" "\\|" "\\\\"]
        s;

      partToPattern = part:
        if part.type == "literal"
        then escapeRegex part.value
        else let
          # Placeholder - create capture group
          ph = part.value;
          width = ph.width;
        in
          if width != null
          then "(.{${toString width}})" # Exactly N characters
          else "(.+)"; # One or more characters (non-greedy would be better but nix regex is limited)
    in
      "^" + (builtins.concatStringsSep "" (map partToPattern parts)) + "$";

    pattern = buildPattern;
    match = builtins.match pattern str;
  in
    if match == null
    then null
    else let
      # Extract placeholder names in order
      placeholderNames = map (p: p.name) template.placeholders;

      # Zip names with captured values
      pairs = lib.zipListsWith (name: value: {inherit name value;}) placeholderNames match;

      # Convert to attrset
      result = builtins.listToAttrs (map (p: {
          name = p.name;
          value = p.value;
        })
        pairs);
    in
      result;
}
