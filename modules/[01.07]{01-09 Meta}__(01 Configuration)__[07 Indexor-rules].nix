# Johnny Declarative Decimal - Index Generation Rules Configuration
#
# This module defines rules for generating index files that visualize
# the johnny-declarative-decimal directory structure.
#
# Configures:
# - Output formats (tree, markdown, Typst, plain text)
# - Sorting and grouping rules
# - Metadata inclusion (git status, symlinks, module sources)
# - Index file locations and naming
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.johnny-declarative-decimal.indexor-rules = with lib; {
    # Enable index generation
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to generate index files";
    };

    # Output formats to generate
    formats = mkOption {
      type = types.listOf (types.enum ["tree" "markdown" "typst" "txt" "json"]);
      default = ["tree" "typst"];
      description = ''
        Formats to generate:

        - tree: Tree-style text output (uses tree command style)
        - markdown: Markdown formatted index
        - typst: Typst formatted index for documentation
        - txt: Plain text listing
        - json: Machine-readable JSON structure
      '';
    };

    # Index file locations
    output_paths = mkOption {
      type = types.submodule {
        options = {
          tree = mkOption {
            type = types.str;
            default = "index.tree";
            description = "Path for tree format index";
          };
          markdown = mkOption {
            type = types.str;
            default = "INDEX.md";
            description = "Path for markdown format index";
          };
          typst = mkOption {
            type = types.str;
            default = "index.typ";
            description = "Path for Typst format index";
          };
          txt = mkOption {
            type = types.str;
            default = "index.txt";
            description = "Path for plain text index";
          };
          json = mkOption {
            type = types.str;
            default = "index.json";
            description = "Path for JSON format index";
          };
        };
      };
      default = {
        tree = "index.tree";
        markdown = "INDEX.md";
        typst = "index.typ";
        txt = "index.txt";
        json = "index.json";
      };
      description = "Output file paths for each format";
    };

    # Sorting and organization
    sorting = mkOption {
      type = types.submodule {
        options = {
          sort_by = mkOption {
            type = types.enum ["id" "name" "modified" "created"];
            default = "id";
            description = ''
              How to sort items in the index:

              - id: By johnny-decimal ID (10.01, 10.02, etc.)
              - name: Alphabetically by name
              - modified: By last modification time
              - created: By creation time
            '';
          };

          group_by_area = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to group items by area";
          };

          group_by_category = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to group items by category within areas";
          };
        };
      };
      default = {
        sort_by = "id";
        group_by_area = true;
        group_by_category = true;
      };
      description = "Rules for sorting and grouping in index";
    };

    # Metadata inclusion
    metadata = mkOption {
      type = types.submodule {
        options = {
          include_module_sources = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to include source module information";
          };

          include_git_info = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to include git repository URLs for git-backed items";
          };

          include_symlink_targets = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to include symlink target paths";
          };

          include_descriptions = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to include item descriptions if available";
          };

          include_statistics = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to include statistics (total items, categories, etc.)";
          };
        };
      };
      default = {
        include_module_sources = true;
        include_git_info = true;
        include_symlink_targets = true;
        include_descriptions = true;
        include_statistics = true;
      };
      description = "Rules for including metadata in index";
    };

    # Display customization
    display = mkOption {
      type = types.submodule {
        options = {
          show_ids = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to show johnny-decimal IDs in output";
          };

          show_full_paths = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to show full paths or relative names";
          };

          tree_chars = mkOption {
            type = types.submodule {
              options = {
                vertical = mkOption {
                  type = types.str;
                  default = "│";
                  description = "Vertical line character";
                };
                branch = mkOption {
                  type = types.str;
                  default = "├──";
                  description = "Branch connector character";
                };
                last = mkOption {
                  type = types.str;
                  default = "└──";
                  description = "Last item connector character";
                };
              };
            };
            default = {
              vertical = "│";
              branch = "├──";
              last = "└──";
            };
            description = "Characters for tree drawing";
          };
        };
      };
      default = {
        show_ids = true;
        show_full_paths = false;
        tree_chars = {
          vertical = "│";
          branch = "├──";
          last = "└──";
        };
      };
      description = "Display customization options";
    };
  };

  config.johnny-declarative-decimal.indexor-rules = {
    # Default configuration validates itself:
    # This module defines how to generate indices showing all modules
    # including this one at [01.07] Indexor-rules
  };

  # Expose configuration via flake outputs
  flake.johnny-declarative-decimal.config.indexor-rules =
    config.johnny-declarative-decimal.indexor-rules;
}
