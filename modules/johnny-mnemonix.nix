{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.johnny-mnemonix;

  # Type for a single item (ID + name)
  itemType = types.attrsOf types.str;

  # Type for a category
  categoryType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Name of the category";
        example = "Finance";
      };
      items = mkOption {
        type = itemType;
        description = "Map of Johnny Decimal IDs to item names";
        example = {
          "11.01" = "Budget";
          "11.02" = "Investments";
        };
      };
    };
  };

  # Type for an area
  areaType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Name of the area";
        example = "Personal";
      };
      categories = mkOption {
        type = types.attrsOf categoryType;
        description = "Map of category IDs to category configurations";
      };
    };
  };

  # New options for directory permissions
  permissionsType = types.submodule {
    options = {
      dirMode = mkOption {
        type = types.str;
        default = "0755";
        description = "Permissions for created directories (octal string)";
        example = "0700";
      };
      user = mkOption {
        type = types.str;
        default = config.home.username;
        description = "Owner of the directories";
      };
      group = mkOption {
        type = types.str;
        default = "users";
        description = "Group owner of the directories";
      };
    };
  };

  # Helper function to create directory paths
  mkDirPath = _: area: _: category: id: name: "${cfg.baseDir}/${area.name}/${category.name}/${id} ${name}";

  # Helper function to create directory entries for a single item
  mkItemDir = areaId: area: catId: category: id: name: {
    "${mkDirPath areaId area catId category id name}" = {
      source = null;
      inherit (cfg.permissions) dirMode user group;
    };
  };

  # Helper function to process all items in a category
  mkCategoryDirs = areaId: area: catId: category:
    mapAttrsToList
    (id: name: mkItemDir areaId area catId category id name)
    category.items;

  # Helper function to process all categories in an area
  mkAreaDirs = areaId: area:
    concatLists
    (mapAttrsToList
      (catId: category: mkCategoryDirs areaId area catId category)
      area.categories);

  # Create all directory entries
  mkDirs =
    foldAttrs
    (x: _: x)
    {}
    (concatLists (mapAttrsToList mkAreaDirs cfg.areas));

  # Enhanced domain type to support custom paths
  domainType = with types;
    oneOf [
      (enum [
        "documents"
        "pictures"
        "videos"
        "music"
        "downloads"
        "desktop"
        "public"
      ])
      (strMatching "[^/].*") # Custom path (must be relative to $HOME)
    ];

  # Helper to get the base directory for a domain
  getDomainPath = domain:
    if
      builtins.elem domain [
        "documents"
        "pictures"
        "videos"
        "music"
        "downloads"
        "desktop"
        "public"
      ]
    then "${config.home.homeDirectory}/${toUpper domain}"
    else "${config.home.homeDirectory}/${domain}";

  # Default system structure
  defaultSystemStructure = {
    "00-09" = {
      name = "System";
      categories = {
        "01" = {
          name = "User Directories";
          items = {
            "01.01" = "Documents";
            "01.02" = "Downloads";
            "01.03" = "Pictures";
            "01.04" = "Videos";
            "01.05" = "Music";
            "01.06" = "Desktop";
            "01.07" = "Public";
            "01.08" = "Templates";
          };
        };
      };
    };
  };

  # Shell integration options
  shellIntegrationType = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable shell integration";
      };

      prefix = mkOption {
        type = types.str;
        default = "jm";
        description = "Prefix for shell aliases (defaults to 'jm' to avoid conflicts)";
      };

      aliases = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to create shell aliases";
      };

      functions = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to create shell functions";
      };
    };
  };

  # Shell aliases with proper string concatenation
  mkShellAliases = prefix: {
    "${prefix}" = "cd ${cfg.baseDir}";
    "${prefix}l" = "${prefix}ls";
    "${prefix}ll" = "ls -l ${cfg.baseDir}";
    "${prefix}la" = "ls -la ${cfg.baseDir}";
    "${prefix}-up" = "cd ..";
    "${prefix}-up2" = "cd ../..";
  };

  # Shell functions with proper string interpolation
  mkShellFunctions = prefix: ''
    # Go to Johnny Mnemonix area/category/item
    function ${prefix}() {
      local base="${cfg.baseDir}"
      local target="$1"

      # No args = go to base directory
      if [ -z "$target" ]; then
        cd "$base" || return 1
        return
      }

      # Full path = direct navigation
      if [ -d "$base/$target" ]; then
        cd "$base/$target" || return 1
        return
      }

      # Number only = find matching directory
      if [[ "$target" =~ ^[0-9.]+$ ]]; then
        local found
        found=$(find "$base" -maxdepth 3 -type d -name "*$target*" | head -n 1)
        if [ -n "$found" ]; then
          cd "$found" || return 1
          return
        fi
      fi

      echo "No matching directory found for: $target"
      return 1
    }

    # List Johnny Mnemonix structure
    function ${prefix}ls() {
      local base="${cfg.baseDir}"
      local target="$1"

      if [ -z "$target" ]; then
        # No args = list areas
        find "$base" -maxdepth 1 -type d -name "[0-9]*" | sort
      else
        # With path = list specific location
        find "$base/$target" -maxdepth 1 -type d -name "[0-9]*" | sort
      fi
    }

    # Find in Johnny Mnemonix structure
    function ${prefix}find() {
      local base="${cfg.baseDir}"
      local pattern="$1"

      if [ -z "$pattern" ]; then
        echo "Usage: ${prefix}find <pattern>"
        return 1
      fi

      find "$base" -type d -name "*$pattern*"
    }
  '';
in {
  options.johnny-mnemonix = {
    enable = mkEnableOption "Johnny Decimal document management";

    domain = mkOption {
      type = domainType;
      default = "documents";
      example = "10_Projects";
      description = mdDoc ''
        The home directory domain where the system will be implemented.
        This can be either:
        - A standard XDG directory ("documents", "pictures", etc.)
        - A custom subdirectory path relative to $HOME (e.g., "10_Projects")

        Custom paths must:
        - Be relative to $HOME
        - Not start with a slash
        - Not contain parent directory references (..)
      '';
    };

    # Changed: baseDir now uses getDomainPath
    baseDir = mkOption {
      type = types.str;
      default = getDomainPath cfg.domain;
      defaultText = literalExpression "getDomainPath domain";
      description = "Base directory for Johnny Decimal structure";
    };

    areas = mkOption {
      type = types.attrsOf areaType;
      default = {};
      description = "Map of area IDs to area configurations";
    };

    permissions = mkOption {
      type = permissionsType;
      default = {};
      description = "Permissions for created directories";
    };

    cleanup = {
      enable = mkEnableOption "Clean up directories when disabled";
      backup = mkOption {
        type = types.bool;
        default = true;
        description = "Create a backup before cleaning up directories";
      };
    };

    useDefaultStructure = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to include the default system structure.
        This adds a "00-09 System" area with standard user directories as items.
      '';
    };

    shell = mkOption {
      type = shellIntegrationType;
      default = {};
      description = "Shell integration options";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Base configuration
    {
      # Validate custom domain paths
      assertions = [
        {
          assertion = !(hasPrefix "/" cfg.domain);
          message = "Custom domain paths must be relative to $HOME (no leading slash)";
        }
        {
          assertion = !(hasInfix ".." cfg.domain);
          message = "Custom domain paths cannot contain parent directory references (..)";
        }
      ];

      # Create the base directory structure with permissions
      home.file =
        (mapAttrs
          (_: _: {
            source = null;
            inherit (cfg.permissions) dirMode user group;
          })
          (mkDirs (
            if cfg.useDefaultStructure
            then defaultSystemStructure // cfg.areas
            else cfg.areas
          )))
        // {
          ${cfg.baseDir} = {
            source = null;
            inherit (cfg.permissions) dirMode user group;
          };
        };

      # XDG compliance only for standard XDG domains
      xdg.userDirs =
        mkIf (builtins.elem cfg.domain [
          "documents"
          "pictures"
          "videos"
          "music"
          "downloads"
          "desktop"
          "public"
        ]) {
          enable = true;
          createDirectories = true;
          ${cfg.domain} = cfg.baseDir;
        };
    }

    # Shell integration
    (mkIf cfg.shell.enable {
      programs.bash = {
        inherit (cfg.shell) enable;
        initExtra = mkIf cfg.shell.functions (mkShellFunctions cfg.shell.prefix);
        shellAliases = mkIf cfg.shell.aliases (mkShellAliases cfg.shell.prefix);
      };

      programs.zsh = {
        inherit (cfg.shell) enable;
        initExtra = mkIf cfg.shell.functions (mkShellFunctions cfg.shell.prefix);
        shellAliases = mkIf cfg.shell.aliases (mkShellAliases cfg.shell.prefix);
      };
    })
  ]);
}
