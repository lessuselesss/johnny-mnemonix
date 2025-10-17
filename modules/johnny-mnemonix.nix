{
  config,
  lib,
  pkgs,
  typix ? null,
  managedPathNames ? [],
  jdAreasFromModules ? {},
  jdModuleSources ? {},
  jdSyntaxConfig ? null,
  ...
}:
with lib; let
  cfg = config.johnny-mnemonix;

  # Get effective syntax config (from flake or fallback to defaults)
  syntaxConfig =
    if jdSyntaxConfig != null
    then jdSyntaxConfig
    else {
      # Default syntax configuration
      areaRangeEncapsulator = {open = "{"; close = "}";};
      categoryNumEncapsulator = {open = "("; close = ")";};
      idNumEncapsulator = {open = "["; close = "]";};
      numeralNameSeparator = cfg.spacer;  # Use spacer as fallback
      areaCategorySeparator = "__";
      categoryItemSeparator = "__";
    };

  # Effective numeral-name separator (syntax config takes precedence, then cfg.spacer)
  effectiveSpacer =
    if jdSyntaxConfig != null
    then syntaxConfig.numeralNameSeparator
    else cfg.spacer;

  # Merge module-generated areas with user-provided areas
  # User config takes precedence
  mergedAreas = lib.recursiveUpdate jdAreasFromModules cfg.areas;

  # Expand managed path names to full paths
  managedPaths = map (name: "${config.home.homeDirectory}/${name}") managedPathNames;

  # Sanitize function to remove special characters and limit length
  sanitizeName = name: let
    # Remove special characters, replace spaces with underscores
    cleaned =
      builtins.replaceStrings
      [" " "/" "\\" ":" "*" "?" "\"" "<" ">" "|"]
      ["_" "_" "_" "_" "_" "_" "_" "_" "_" "_"]
      name;
    # Truncate to a reasonable length if needed
    truncated =
      if builtins.stringLength cleaned > 50
      then builtins.substring 0 50 cleaned
      else cleaned;
  in
    truncated;

  # Modify path generation to be more robust
  mkSafePath = base: id: spacer: name: let
    sanitizedId = builtins.replaceStrings [" "] ["_"] id;
    sanitizedName = sanitizeName name;
  in "${base}/${sanitizedId}${spacer}${sanitizedName}";

  # Helper to check if a path conflicts with managed paths
  pathConflicts = path: any (managed: path == managed || hasPrefix "${managed}/" path) managedPaths;

  # Collect all item paths for conflict detection
  collectItemPaths = areas: let
    mkItemPath = areaId: areaConfig: categoryId: categoryConfig: itemId: itemConfig: let
      areaPath = mkSafePath cfg.baseDir areaId effectiveSpacer areaConfig.name;
      categoryPath = mkSafePath areaPath categoryId effectiveSpacer categoryConfig.name;
      itemPath = mkSafePath categoryPath itemId effectiveSpacer (
        if isString itemConfig
        then sanitizeName itemConfig
        else sanitizeName itemConfig.name
      );
    in itemPath;

    collectCategory = areaId: areaConfig: categoryId: categoryConfig:
      map (itemId: mkItemPath areaId areaConfig categoryId categoryConfig itemId categoryConfig.items.${itemId})
      (attrNames categoryConfig.items);

    collectArea = areaId: areaConfig:
      concatLists (map (categoryId: collectCategory areaId areaConfig categoryId areaConfig.categories.${categoryId})
        (attrNames areaConfig.categories));
  in
    concatLists (map (areaId: collectArea areaId areas.${areaId}) (attrNames areas));

  # Find all conflicting paths
  allItemPaths = if mergedAreas != {} then collectItemPaths mergedAreas else [];
  conflictingPaths = filter pathConflicts allItemPaths;

  # Create warnings for conflicts
  conflictWarnings = map (path: let
    matchedModule = findFirst (managed: path == managed || hasPrefix "${managed}/" path) null managedPaths;
    moduleName = if matchedModule != null then removePrefix "${config.home.homeDirectory}/" matchedModule else "unknown";
  in "johnny-mnemonix: Path '${path}' conflicts with module '${moduleName}.nix' - skipping johnny-mnemonix operations") conflictingPaths;

  # Create directories based on configuration
  mkAreaDirs = areas: let
    mkCategoryDirs = areaId: areaConfig: categoryId: categoryConfig: let
      areaPath = mkSafePath cfg.baseDir areaId effectiveSpacer areaConfig.name;
      categoryPath = mkSafePath areaPath categoryId effectiveSpacer categoryConfig.name;

      mkItemDir = itemId: itemDef: let
        itemConfig =
          if isString itemDef
          then {name = itemDef;}
          else itemDef;

        name = sanitizeName itemConfig.name;
        newPath = mkSafePath categoryPath itemId effectiveSpacer name;
      in
        # Determine the actual storage path (either newPath or target)
        let
          storagePath =
            if itemConfig ? target && itemConfig.target != null
            then itemConfig.target
            else newPath;

          # Check if this path conflicts with a managed module path
          isConflicting = pathConflicts newPath;
        in ''
          # Create directory for ${itemId}
          ${
            if isConflicting
            then
              # Skip operations for conflicting paths
              ''
                echo "Skipping ${newPath} (managed by flake-parts module)"
              ''
            else if itemConfig ? url && itemConfig.url != null && itemConfig ? target && itemConfig.target != null
            then
              # Git + Symlink: Clone to target, symlink from newPath to target
              ''
                # Clone or update git repo at target location
                if [ ! -d "${storagePath}/.git" ]; then
                  ${mkBackupCmd storagePath}
                  mkdir -p "$(dirname "${storagePath}")"
                  GIT_SSH_COMMAND="ssh -o 'AddKeysToAgent yes'" git clone ${
                if itemConfig ? ref && itemConfig.ref != null
                then "-b ${itemConfig.ref}"
                else ""
              } ${itemConfig.url} "${storagePath}"
                else
                  cd "${storagePath}"
                  GIT_SSH_COMMAND="ssh -o 'AddKeysToAgent yes'" git fetch
                  git checkout ${
                if itemConfig ? ref && itemConfig.ref != null
                then itemConfig.ref
                else "main"
              }
                  GIT_SSH_COMMAND="ssh -o 'AddKeysToAgent yes'" git pull
                fi
                ${
                if itemConfig ? sparse && itemConfig.sparse != []
                then ''
                  cd "${storagePath}"
                  git config core.sparseCheckout true
                  mkdir -p .git/info
                  printf "%s\n" ${builtins.concatStringsSep " " (map (pattern: "\"${pattern}\"") itemConfig.sparse)} > .git/info/sparse-checkout
                  git read-tree -mu HEAD
                ''
                else ""
              }

                # Create symlink from Johnny Decimal path to storage location
                ${mkBackupCmd newPath}
                mkdir -p "$(dirname "${newPath}")"
                ln -sfn "${storagePath}" "${newPath}"
              ''
            else if itemConfig ? url && itemConfig.url != null
            then
              # Git only: Clone to newPath
              ''
                if [ ! -d "${newPath}/.git" ]; then
                  ${mkBackupCmd newPath}
                  GIT_SSH_COMMAND="ssh -o 'AddKeysToAgent yes'" git clone ${
                if itemConfig ? ref && itemConfig.ref != null
                then "-b ${itemConfig.ref}"
                else ""
              } ${itemConfig.url} "${newPath}"
                else
                  cd "${newPath}"
                  GIT_SSH_COMMAND="ssh -o 'AddKeysToAgent yes'" git fetch
                  git checkout ${
                if itemConfig ? ref && itemConfig.ref != null
                then itemConfig.ref
                else "main"
              }
                  GIT_SSH_COMMAND="ssh -o 'AddKeysToAgent yes'" git pull
                fi
                ${
                if itemConfig ? sparse && itemConfig.sparse != []
                then ''
                  cd "${newPath}"
                  git config core.sparseCheckout true
                  mkdir -p .git/info
                  printf "%s\n" ${builtins.concatStringsSep " " (map (pattern: "\"${pattern}\"") itemConfig.sparse)} > .git/info/sparse-checkout
                  git read-tree -mu HEAD
                ''
                else ""
              }
              ''
            else if itemConfig ? target && itemConfig.target != null
            then
              # Symlink only: Link from newPath to target
              ''
                ${mkBackupCmd newPath}
                mkdir -p "$(dirname "${newPath}")"
                ln -sfn "${itemConfig.target}" "${newPath}"
              ''
            else
              # Regular directory
              ''
                mkdir -p "${newPath}"
              ''
          }
        '';
    in
      concatMapStrings (itemId: mkItemDir itemId categoryConfig.items.${itemId})
      (attrNames categoryConfig.items);

    mkAreaDir = areaId: areaConfig:
      concatMapStrings (
        categoryId:
          mkCategoryDirs areaId areaConfig categoryId areaConfig.categories.${categoryId}
      ) (attrNames areaConfig.categories);
  in ''
    set -e
    # Ensure base directory exists
    mkdir -p "${cfg.baseDir}"

    # Create area directories
    ${concatMapStrings (areaId: mkAreaDir areaId mergedAreas.${areaId}) (attrNames mergedAreas)}
  '';

  # XDG paths
  xdgStateHome = cfg.xdg.stateHome or "${config.home.homeDirectory}/.local/state";
  xdgCacheHome = cfg.xdg.cacheHome or "${config.home.homeDirectory}/.cache";
  xdgConfigHome = cfg.xdg.configHome or "${config.home.homeDirectory}/.config";
  xdgDataHome = "${config.home.homeDirectory}/.local/share";

  # Directory locations
  stateDir = "${xdgStateHome}/johnny-mnemonix";
  cacheDir = "${xdgCacheHome}/johnny-mnemonix";
  configDir = "${xdgConfigHome}/johnny-mnemonix";

  stateFile = "${stateDir}/state.json";
  changesFile = "${stateDir}/structure-changes.log";
  cacheFile = "${cacheDir}/cache.json";

  # Backup configuration
  # Determine the effective backup setting
  backupEnabled =
    if cfg.backup.enable == null
    then config.home-manager.backupFileExtension or null != null
    else cfg.backup.enable;

  # Determine the backup extension to use
  backupExt =
    if cfg.backup.enable == null
    then config.home-manager.backupFileExtension or "jm-backup"
    else cfg.backup.extension;

  # Helper function to generate backup command
  mkBackupCmd = path: ''
    if [ -e "${path}" ] && [ ! -L "${path}" ]; then
      ${
      if backupEnabled
      then ''mv "${path}" "${path}.${backupExt}-$(date +%Y%m%d-%H%M%S)"''
      else ''echo "Error: Path exists and backups are disabled: ${path}"; exit 1''
    }
    fi
  '';

  # Typix compilation script
  typixLogFile = "${stateDir}/typix.log";
  compileTypstScript =
    if cfg.typix.enable && typix != null
    then
      pkgs.writeShellScript "compile-typst-documents" ''
        set -e

        # Ensure log directory exists
        mkdir -p "${stateDir}"

        # Log compilation start
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Typst compilation..." >> "${typixLogFile}"

        # Find all .typ files in the document structure
        find "${cfg.baseDir}" -type f -name "*.typ" | while read -r typfile; do
          # Get directory and filename
          typdir=$(dirname "$typfile")
          typname=$(basename "$typfile" .typ)
          pdffile="$typdir/$typname.pdf"

          echo "[$(date '+%Y-%m-%d %H:%M:%S')] Compiling $typfile..." >> "${typixLogFile}"

          # Compile the document
          if ${pkgs.typst}/bin/typst compile "$typfile" "$pdffile" 2>> "${typixLogFile}"; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Successfully compiled $typfile -> $pdffile" >> "${typixLogFile}"
          else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Failed to compile $typfile" >> "${typixLogFile}"
          fi
        done

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Typst compilation finished." >> "${typixLogFile}"
      ''
    else "";

  # Index generation functions
  # Generate metadata string for an item if enhanced mode is enabled
  mkItemMetadata = areaId: categoryId: itemId: itemConfig: format:
    if !cfg.index.enhanced then ""
    else let
      isGit = itemConfig ? url && itemConfig.url != null;
      isSymlink = itemConfig ? target && itemConfig.target != null;
      hasGitAndSymlink = isGit && isSymlink;

      # Look up module source using composite key
      moduleKey = "${areaId}.${categoryId}.${itemId}";
      moduleSource = jdModuleSources.${moduleKey} or null;

      formatMeta = meta:
        if format == "typ" then " #text(fill: gray)[${meta}]"
        else if format == "md" then " _${meta}_"
        else if format == "txt" then " (${meta})"
        else " (${meta})";

      # Build metadata parts
      gitMeta = if isGit then "git: ${itemConfig.url}" else null;
      symlinkMeta = if isSymlink then "symlink to: ${itemConfig.target}" else null;
      moduleMeta = if moduleSource != null then "module: ${moduleSource}" else null;

      # Combine non-null metadata parts
      metaParts = builtins.filter (x: x != null) [gitMeta symlinkMeta moduleMeta];
      metaString = builtins.concatStringsSep ", " metaParts;
    in
      if metaString != "" then formatMeta metaString else "";

  # Generate tree-like index content in the specified format
  generateIndexContent = format: let
    # Format-specific header
    header =
      if format == "typ" then ''
        #set page(margin: 1in)
        #set text(font: "Liberation Sans", size: 11pt)

        = Johnny Decimal Workspace Index

        Generated: #datetime.today().display()

        Base Directory: `${cfg.baseDir}`

        ---

      ''
      else if format == "md" then ''
        # Johnny Decimal Workspace Index

        **Generated:** $(date '+%Y-%m-%d %H:%M:%S')

        **Base Directory:** `${cfg.baseDir}`

        ---

      ''
      else if format == "txt" then ''
        ========================================
        Johnny Decimal Workspace Index
        ========================================

        Generated: $(date '+%Y-%m-%d %H:%M:%S')
        Base Directory: ${cfg.baseDir}

        ----------------------------------------

      ''
      else "";

    # Tree symbols based on format
    treeChars =
      if format == "typ" then {
        branch = "├──";
        last = "└──";
        pipe = "│  ";
        space = "   ";
      }
      else {
        branch = "├──";
        last = "└──";
        pipe = "│  ";
        space = "   ";
      };

    # Generate item line with metadata
    mkItemLine = areaId: categoryId: itemId: itemConfig: indent: isLast:
      let
        itemDef = if isString itemConfig then {name = itemConfig;} else itemConfig;
        itemName = sanitizeName itemDef.name;
        fullId = itemId;
        prefix = if isLast then treeChars.last else treeChars.branch;
        metadata = mkItemMetadata areaId categoryId itemId itemDef format;

        line = "${indent}${prefix} ${fullId}${effectiveSpacer}${itemName}${metadata}";
      in
        if format == "typ" then "#text(font: \"Liberation Mono\")[${line}]\n"
        else "${line}\n";

    # Generate category section
    mkCategorySection = areaId: areaConfig: categoryId: categoryConfig: indent: isLastCat:
      let
        categoryName = categoryConfig.name;
        fullId = categoryId;
        prefix = if isLastCat then treeChars.last else treeChars.branch;
        nextIndent = indent + (if isLastCat then treeChars.space else treeChars.pipe);

        itemIds = attrNames categoryConfig.items;
        numItems = length itemIds;

        itemLines = concatStrings (
          imap0 (idx: itemId:
            mkItemLine areaId categoryId itemId categoryConfig.items.${itemId} nextIndent (idx == numItems - 1)
          ) itemIds
        );

        categoryLine =
          if format == "typ" then "#text(font: \"Liberation Mono\", weight: \"bold\")[${indent}${prefix} ${fullId}${effectiveSpacer}${categoryName}]\n"
          else if format == "md" then "${indent}${prefix} **${fullId}${effectiveSpacer}${categoryName}**\n"
          else "${indent}${prefix} ${fullId}${effectiveSpacer}${categoryName}\n";
      in
        categoryLine + itemLines;

    # Generate area section
    mkAreaSection = areaId: areaConfig: isLastArea:
      let
        areaName = areaConfig.name;
        fullId = areaId;

        categoryIds = attrNames areaConfig.categories;
        numCategories = length categoryIds;

        categoryLines = concatStrings (
          imap0 (idx: categoryId:
            mkCategorySection areaId areaConfig categoryId areaConfig.categories.${categoryId}
              treeChars.pipe (idx == numCategories - 1)
          ) categoryIds
        );

        areaLine =
          if format == "typ" then "#text(font: \"Liberation Mono\", weight: \"bold\", size: 12pt)[${fullId}${effectiveSpacer}${areaName}]\n"
          else if format == "md" then "### ${fullId}${effectiveSpacer}${areaName}\n\n"
          else "${fullId}${effectiveSpacer}${areaName}\n";
      in
        areaLine + categoryLines + "\n";

    # Generate all areas
    areaIds = attrNames mergedAreas;
    numAreas = length areaIds;

    areasContent = concatStrings (
      imap0 (idx: areaId:
        mkAreaSection areaId mergedAreas.${areaId} (idx == numAreas - 1)
      ) areaIds
    );
  in
    header + areasContent;

  # Index file paths and generation script
  indexSourceFormat = if cfg.index.format == "pdf" then "typ" else cfg.index.format;
  indexSourceFile = "${stateDir}/__INDEX__.${indexSourceFormat}";
  indexSymlink = "${cfg.baseDir}/__INDEX__.${cfg.index.format}";
  indexLogFile = "${stateDir}/index.log";

  generateIndexScript =
    if cfg.index.enable
    then
      pkgs.writeShellScript "generate-index" ''
        set -e

        # Ensure state directory exists
        mkdir -p "${stateDir}"

        # Log generation start
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Generating workspace index..." >> "${indexLogFile}"

        # Generate index content
        cat > "${indexSourceFile}" <<'INDEX_EOF'
        ${generateIndexContent indexSourceFormat}
        INDEX_EOF

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Index content written to ${indexSourceFile}" >> "${indexLogFile}"

        ${
          if cfg.index.format == "pdf"
          then
            if cfg.typix.enable && typix != null
            then ''
              # Compile Typst to PDF
              echo "[$(date '+%Y-%m-%d %H:%M:%S')] Compiling index to PDF..." >> "${indexLogFile}"
              if ${pkgs.typst}/bin/typst compile "${indexSourceFile}" "${stateDir}/__INDEX__.pdf" 2>> "${indexLogFile}"; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Successfully compiled PDF index" >> "${indexLogFile}"
              else
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Failed to compile PDF index" >> "${indexLogFile}"
                exit 1
              fi
            ''
            else ''
              echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: PDF format requires typix.enable = true" >> "${indexLogFile}"
              exit 1
            ''
          else ""
        }

        # Create symlink from base directory to state file
        mkdir -p "${cfg.baseDir}"
        ${
          if cfg.index.format == "pdf"
          then ''ln -sfn "${stateDir}/__INDEX__.pdf" "${indexSymlink}"''
          else ''ln -sfn "${indexSourceFile}" "${indexSymlink}"''
        }

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Index symlink created at ${indexSymlink}" >> "${indexLogFile}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Index generation complete" >> "${indexLogFile}"
      ''
    else "";

  # Type definitions
  itemOptionsType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Directory name for the item";
        example = "My Directory";
      };
      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional Git repository URL";
      };
      ref = mkOption {
        type = types.str;
        default = "main";
        description = "Git reference (branch, tag, or commit)";
      };
      sparse = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Sparse checkout patterns (empty for full checkout)";
      };
      target = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Optional symlink destination path. When used alone, creates a symlink to an existing location.
          When combined with 'url', the git repository will be cloned to this location,
          and a symlink will be created from the Johnny Decimal path to this location.
        '';
      };
    };
  };

  categoryOptionsType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Name of the category";
      };
      items = mkOption {
        type = types.attrsOf (types.either types.str itemOptionsType);
        default = {};
        description = "Items in this category";
      };
    };
  };

  areaOptionsType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Name of the area";
      };
      categories = mkOption {
        type = types.attrsOf categoryOptionsType;
        default = {};
        description = "Categories in this area";
      };
    };
  };
in {
  options.johnny-mnemonix = {
    enable = mkEnableOption "johnny-mnemonix";

    baseDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/Declaritive Office";
      description = "Base directory for document structure";
    };

    spacer = mkOption {
      type = types.str;
      default = " ";
      description = "Spacer between ID and name";
    };

    areas = mkOption {
      type = types.attrsOf areaOptionsType;
      default = {};
      description = "Areas in the structure";
    };

    xdg = {
      stateHome = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "XDG state home directory";
      };

      cacheHome = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "XDG cache home directory";
      };

      configHome = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "XDG config home directory";
      };
    };

    typix = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Typix integration for Typst document compilation";
      };

      autoCompileOnActivation = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically compile Typst documents during Home Manager activation";
      };

      watch = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable systemd service to watch for Typst file changes and auto-compile";
        };

        interval = mkOption {
          type = types.int;
          default = 5;
          description = "Watch interval in seconds for file change detection";
        };
      };
    };

    backup = {
      enable = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Enable backups when conflicts occur.
          - null: Follow home-manager.backupFileExtension setting (default)
          - true: Enable backups with johnny-mnemonix.backup.extension
          - false: Fail on conflicts (no backups)
        '';
      };

      extension = mkOption {
        type = types.str;
        default = "jm-backup";
        description = "Backup file extension when backups are enabled";
      };
    };

    index = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable automatic generation of workspace index file";
      };

      format = mkOption {
        type = types.enum ["typ" "md" "pdf" "txt"];
        default = "md";
        description = ''
          Output format for the index file:
          - typ: Typst markup (requires typix.enable for PDF compilation)
          - md: Markdown
          - pdf: PDF (requires typix.enable, compiles from Typst)
          - txt: Plain text
        '';
      };

      enhanced = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Include enhanced metadata in the index:
          - Item types (git repository, symlink, regular directory)
          - Git repository URLs
          - Symlink targets
        '';
      };

      watch = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable systemd service to watch for directory changes and regenerate index";
        };

        interval = mkOption {
          type = types.int;
          default = 2;
          description = "Watch interval in seconds for file change detection";
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Add warnings for conflicting paths
      warnings = conflictWarnings;

      home.activation.createJohnnyMnemonixDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
        export PATH="${lib.makeBinPath [
          pkgs.git
          pkgs.openssh
          pkgs.coreutils
          pkgs.gnused
          pkgs.findutils
        ]}:$PATH"

        ${mkAreaDirs mergedAreas}
      '';
    }

    # Index generation
    (mkIf (cfg.index.enable && generateIndexScript != "") {
      # Add index generation to activation after directory creation
      home.activation.generateWorkspaceIndex =
        lib.hm.dag.entryAfter ["createJohnnyMnemonixDirs"] ''
          echo "Generating workspace index..."
          ${generateIndexScript}
        '';

      # Add manual index regeneration command
      home.packages = [
        (pkgs.writeShellScriptBin "jm-regenerate-index" ''
          echo "Manually regenerating workspace index..."
          ${generateIndexScript}
          echo "Index regeneration complete. Check ${indexLogFile} for details."
        '')
      ];

      # Systemd watch service for automatic index regeneration
      systemd.user.services.johnny-mnemonix-index-watch = mkIf cfg.index.watch.enable {
        Unit = {
          Description = "Johnny-Mnemonix Index Regeneration Watcher";
          After = ["graphical-session.target"];
        };

        Service = {
          Type = "simple";
          ExecStart = pkgs.writeShellScript "index-watch-service" ''
            set -e

            # Log service start
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Index watch service started" >> "${indexLogFile}"

            # Watch for directory structure changes
            ${pkgs.inotify-tools}/bin/inotifywait -m -r -e create,delete,moved_to,moved_from \
              --exclude '(__INDEX__|\.git/)' \
              "${cfg.baseDir}" \
              --timefmt '%Y-%m-%d %H:%M:%S' --format '%T %w%f %e' |
            while read -r timestamp file event; do
              # Debounce: wait for the watch interval before regenerating
              sleep ${toString cfg.index.watch.interval}

              echo "[$(date '+%Y-%m-%d %H:%M:%S')] Detected structure change, regenerating index..." >> "${indexLogFile}"

              # Regenerate index
              if ${generateIndexScript} 2>> "${indexLogFile}"; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Index regenerated successfully" >> "${indexLogFile}"
              else
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Index regeneration failed" >> "${indexLogFile}"
              fi
            done
          '';
          Restart = "on-failure";
          RestartSec = "10s";
        };

        Install = {
          WantedBy = ["default.target"];
        };
      };
    })

    # Typix integration
    (mkIf (cfg.typix.enable && compileTypstScript != "") {
      # Add Typst compilation to activation if enabled
      home.activation.compileTypstDocuments =
        mkIf cfg.typix.autoCompileOnActivation
        (lib.hm.dag.entryAfter ["createJohnnyMnemonixDirs"] ''
          echo "Compiling Typst documents..."
          ${compileTypstScript}
        '');

      # Add manual build command
      home.packages = [
        (pkgs.writeShellScriptBin "jm-compile-typst" ''
          echo "Manually compiling Typst documents in ${cfg.baseDir}..."
          ${compileTypstScript}
          echo "Compilation complete. Check ${typixLogFile} for details."
        '')
      ];

      # Systemd watch service
      systemd.user.services.johnny-mnemonix-typst-watch = mkIf cfg.typix.watch.enable {
        Unit = {
          Description = "Johnny-Mnemonix Typst Document Watcher";
          After = ["graphical-session.target"];
        };

        Service = {
          Type = "simple";
          ExecStart = pkgs.writeShellScript "typst-watch-service" ''
            set -e

            # Log service start
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Typst watch service started" >> "${typixLogFile}"

            # Function to compile a single file
            compile_file() {
              typfile="$1"
              typdir=$(dirname "$typfile")
              typname=$(basename "$typfile" .typ)
              pdffile="$typdir/$typname.pdf"

              echo "[$(date '+%Y-%m-%d %H:%M:%S')] Detected change in $typfile, recompiling..." >> "${typixLogFile}"

              if ${pkgs.typst}/bin/typst compile "$typfile" "$pdffile" 2>> "${typixLogFile}"; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Successfully compiled $typfile -> $pdffile" >> "${typixLogFile}"
              else
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Failed to compile $typfile" >> "${typixLogFile}"
              fi
            }

            # Export function for use in subshells
            export -f compile_file

            # Watch for changes
            ${pkgs.inotify-tools}/bin/inotifywait -m -r -e modify,create,move \
              --include '\.typ$' \
              "${cfg.baseDir}" \
              --timefmt '%Y-%m-%d %H:%M:%S' --format '%T %w%f %e' |
            while read -r timestamp file event; do
              # Debounce: wait for the watch interval before compiling
              sleep ${toString cfg.typix.watch.interval}
              if [ -f "$file" ]; then
                compile_file "$file"
              fi
            done
          '';
          Restart = "on-failure";
          RestartSec = "10s";
        };

        Install = {
          WantedBy = ["default.target"];
        };
      };
    })
  ]);
}
