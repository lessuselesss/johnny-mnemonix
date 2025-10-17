# Johnny Decimal Syntax Configuration
#
# This file defines the syntax rules for Johnny Decimal module naming conventions.
# These rules are used for:
# 1. Parsing flake-parts module filenames
# 2. Validating directory-based module paths
# 3. Creating actual directory structures
{
  # Encapsulation characters for area ranges (e.g., "10-19")
  # Creates: {10-19 Projects}
  areaRangeEncapsulator = {
    open = "{";
    close = "}";
  };

  # Encapsulation characters for category numbers (e.g., "10")
  # Creates: (10 Code)
  categoryNumEncapsulator = {
    open = "(";
    close = ")";
  };

  # Encapsulation characters for item ID numbers (e.g., "10.19")
  # Creates: [10.19 Test-Project]
  idNumEncapsulator = {
    open = "[";
    close = "]";
  };

  # Separator between numerals and names
  # Used in: "10-19 Projects" (space between range and name)
  # Used in: "10 Code" (space between category number and name)
  # Used in: "10.19 Test-Project" (space between ID and name)
  numeralNameSeparator = " ";

  # Separator between Area and Category in hierarchy
  # Creates: {10-19 Projects}__(10 Code)
  # The "__" separates area from category
  areaCategorySeparator = "__";

  # Separator between Category and Item in hierarchy
  # Creates: (10 Code)__[19 Test-Project]
  # The "__" separates category from item
  categoryItemSeparator = "__";

  # EXAMPLES OF RESULTING PATTERNS:
  #
  # Flat self-describing module filename:
  #   [10.19]{10-19 Projects}__(10 Code)__[19 Test-Project].nix
  #   └─┬─┘ └────┬─────────┘  └───┬───┘  └────────┬───────────┘
  #     │        │               │                │
  #     │        │               │                └─ Item: [ID] Name
  #     │        │               └─────────────────── Category: (Num) Name
  #     │        └─────────────────────────────────── Area: {Range} Name
  #     └──────────────────────────────────────────── Full ID upfront
  #
  # Directory-based module path:
  #   modules/A-AC{10-19 Projects}/AC(10 Code)/ID[10.19 Test-Project].nix
  #   └──────┬────────────────────┘  └────┬───────┘  └──────────┬──────────┘
  #          │                            │                    │
  #          └─ Area directory            └─ Category dir      └─ Item module
  #
  # Created directory structure (using this syntax):
  #   ~/Declaritive Office/
  #     10-19 Projects/     ← area range + separator + name
  #       10 Code/          ← category num + separator + name
  #         10.19 Test-Project/  ← item ID + separator + name
  #
  # VALIDATION RULES:
  # 1. Category from [10.19] must match category in (10 ...)
  # 2. Item from [10.19] must match item in [19 ...]
  # 3. Category 10 must fall within area range 10-19
}
