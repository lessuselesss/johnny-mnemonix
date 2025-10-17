# Common Module Types - Shared Across All Flake Classes
#
# Provides Johnny Decimal primitive types and structured types
# that can be reused by all flake class module types.

{lib}: {
  # ===== Johnny Decimal Primitive Types =====

  # Matches XX.YY format (e.g., "10.05", "42.17")
  jdIdentifier = lib.types.strMatching "[0-9]{2}\\.[0-9]{2}";

  # Matches XX-YY format for area ranges (e.g., "10-19", "20-29")
  jdAreaRange = lib.types.strMatching "[0-9]{2}-[0-9]{2}";

  # Matches XX format for categories (e.g., "10", "42")
  jdCategory = lib.types.strMatching "[0-9]{2}";

  # Matches YY format for items within a category (e.g., "01", "17")
  jdItem = lib.types.strMatching "[0-9]{2}";

  # ===== Johnny Decimal Structured Types =====

  # Individual item configuration
  # Used in areas -> categories -> items hierarchy
  jdItemDef = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Human-readable name for the item";
        example = "Project Documentation";
      };

      url = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Optional git repository URL for this item";
        example = "git@github.com:user/project.git";
      };

      target = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Optional target path (for symlinks or git clones)";
        example = "/mnt/storage/projects/docs";
      };

      ref = lib.mkOption {
        type = lib.types.str;
        default = "main";
        description = "Git branch/ref to use when url is set";
        example = "develop";
      };

      sparse = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Sparse checkout patterns for git repositories";
        example = ["docs/" "*.md"];
      };
    };
  };

  # Category configuration containing items
  jdCategoryDef = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Human-readable name for the category";
        example = "Documentation";
      };

      items = lib.mkOption {
        type = lib.types.attrsOf (lib.types.either lib.types.str (lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Human-readable name for the item";
            };
            url = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            target = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
            };
            ref = lib.mkOption {
              type = lib.types.str;
              default = "main";
            };
            sparse = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
            };
          };
        }));
        default = {};
        description = "Items within this category (XX.YY format keys)";
        example = {
          "10.01" = "Setup Guide";
          "10.02" = {
            name = "API Docs";
            url = "git@github.com:user/api-docs.git";
          };
        };
      };
    };
  };

  # Area configuration containing categories
  jdAreaDef = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Human-readable name for the area";
        example = "Projects";
      };

      categories = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Human-readable name for the category";
            };
            items = lib.mkOption {
              type = lib.types.attrsOf (lib.types.either lib.types.str (lib.types.submodule {
                options = {
                  name = lib.mkOption { type = lib.types.str; };
                  url = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                  };
                  target = lib.mkOption {
                    type = lib.types.nullOr lib.types.path;
                    default = null;
                  };
                  ref = lib.mkOption {
                    type = lib.types.str;
                    default = "main";
                  };
                  sparse = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [];
                  };
                };
              }));
              default = {};
            };
          };
        });
        default = {};
        description = "Categories within this area (XX format keys)";
        example = {
          "10" = {
            name = "Documentation";
            items = {
              "10.01" = "Setup";
              "10.02" = "API Reference";
            };
          };
        };
      };
    };
  };

  # ===== Syntax Configuration Types =====

  # Encapsulator configuration (open/close pairs like [], {}, etc.)
  encapsulator = lib.types.submodule {
    options = {
      open = lib.mkOption {
        type = lib.types.str;
        description = "Opening character/string";
        example = "[";
      };
      close = lib.mkOption {
        type = lib.types.str;
        description = "Closing character/string";
        example = "]";
      };
    };
  };

  # Complete syntax configuration for Johnny Decimal formatting
  jdSyntax = lib.types.submodule {
    options = {
      idNumEncapsulator = lib.mkOption {
        type = lib.types.submodule {
          options = {
            open = lib.mkOption { type = lib.types.str; default = "["; };
            close = lib.mkOption { type = lib.types.str; default = "]"; };
          };
        };
        default = {open = "["; close = "]";};
        description = "Encapsulator for item IDs (e.g., [10.05])";
      };

      areaEncapsulator = lib.mkOption {
        type = lib.types.submodule {
          options = {
            open = lib.mkOption { type = lib.types.str; default = "{"; };
            close = lib.mkOption { type = lib.types.str; default = "}"; };
          };
        };
        default = {open = "{"; close = "}";};
        description = "Encapsulator for area ranges (e.g., {10-19})";
      };

      categoryEncapsulator = lib.mkOption {
        type = lib.types.submodule {
          options = {
            open = lib.mkOption { type = lib.types.str; default = "("; };
            close = lib.mkOption { type = lib.types.str; default = ")"; };
          };
        };
        default = {open = "("; close = ")";};
        description = "Encapsulator for categories (e.g., (10 Code))";
      };

      numeralNameSep = lib.mkOption {
        type = lib.types.str;
        default = " ";
        description = "Separator between number and name";
      };

      hierarchySep = lib.mkOption {
        type = lib.types.str;
        default = "__";
        description = "Separator between hierarchy levels";
      };

      octetSep = lib.mkOption {
        type = lib.types.str;
        default = ".";
        description = "Separator between octets (e.g., XX.YY)";
      };

      rangeSep = lib.mkOption {
        type = lib.types.str;
        default = "-";
        description = "Separator in ranges (e.g., XX-YY)";
      };
    };
  };
}
