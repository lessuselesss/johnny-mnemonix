# Johnny-Mnemonix Module Types
#
# Module option types for Johnny-Mnemonix: our own johnny-declarative-decimal
# library. This dogfoods our library as a complete flake type.

{
  lib,
  common,
}: {
  # Re-export ALL common JD types (this is our core domain)
  inherit
    (common)
    jdIdentifier
    jdAreaRange
    jdCategory
    jdItem
    jdItemDef
    jdCategoryDef
    jdAreaDef
    jdSyntax
    encapsulator
    ;

  # ===== Johnny-Mnemonix Configuration Type =====

  # Complete Johnny-Mnemonix configuration
  jmConfiguration = lib.types.submodule {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable Johnny-Mnemonix directory management";
      };

      baseDir = lib.mkOption {
        type = lib.types.path;
        description = "Base directory for Johnny Decimal structure";
        example = "\${config.home.homeDirectory}/Documents";
      };

      areas = lib.mkOption {
        type = lib.types.attrsOf common.jdAreaDef;
        default = {};
        description = "Johnny Decimal area definitions";
        example = {
          "10-19" = {
            name = "Projects";
            categories = {
              "10" = {
                name = "Code";
                items = {
                  "10.01" = "Website";
                  "10.02" = "CLI-Tool";
                };
              };
            };
          };
        };
      };

      syntax = lib.mkOption {
        type = common.jdSyntax;
        default = {};
        description = "Syntax configuration for formatting";
      };

      spacer = lib.mkOption {
        type = lib.types.str;
        default = " ";
        description = "Spacer between ID and name in directory paths";
      };

      index = lib.mkOption {
        type = lib.types.submodule {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Generate workspace index";
            };

            format = lib.mkOption {
              type = lib.types.enum ["md" "typ" "pdf" "txt"];
              default = "md";
              description = "Index output format";
            };

            enhanced = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Include metadata (git URLs, symlinks)";
            };

            watch = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  enable = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                  };
                  interval = lib.mkOption {
                    type = lib.types.ints.positive;
                    default = 2;
                  };
                };
              };
              default = {};
              description = "Watch mode configuration";
            };
          };
        };
        default = {};
        description = "Index generation settings";
      };

      typix = lib.mkOption {
        type = lib.types.submodule {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable Typix integration";
            };

            autoCompileOnActivation = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Auto-compile .typ files on activation";
            };

            watch = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  enable = lib.mkOption { type = lib.types.bool; default = false; };
                  interval = lib.mkOption { type = lib.types.ints.positive; default = 5; };
                };
              };
              default = {};
            };
          };
        };
        default = {};
        description = "Typix integration settings";
      };

      backup = lib.mkOption {
        type = lib.types.submodule {
          options = {
            enable = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              description = "Enable backups (null = follow home-manager setting)";
            };

            extension = lib.mkOption {
              type = lib.types.str;
              default = "jm-backup";
              description = "Backup file extension";
            };
          };
        };
        default = {};
        description = "Backup configuration";
      };
    };
  };

  # Johnny-Mnemonix module definition (for organizing flake modules)
  jmModule = lib.types.submodule {
    options = {
      jdId = lib.mkOption {
        type = common.jdIdentifier;
        description = "Johnny Decimal ID for this module";
      };

      area = lib.mkOption {
        type = common.jdAreaRange;
        description = "Area range this module belongs to";
      };

      category = lib.mkOption {
        type = common.jdCategory;
        description = "Category this module belongs to";
      };

      name = lib.mkOption {
        type = lib.types.str;
        description = "Human-readable name";
      };
    };
  };
}
