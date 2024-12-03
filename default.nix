{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.mnemonic;

  # XDG Base Directory specification
  xdgBase = {
    data = "${config.xdg.dataHome}/johnny-mnemonix";
    config = "${config.xdg.configHome}/johnny-mnemonix";
    cache = "${config.xdg.cacheHome}/johnny-mnemonix";
    state = "${config.xdg.stateHome}/johnny-mnemonix";
  };
in {
  options.mnemonic = {
    enable = mkEnableOption "Johnny Mnemonic document management";

    baseDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/Documents";
      description = "Base directory for document structure";
    };

    xdgCompliance = mkOption {
      type = types.bool;
      default = true;
      description = "Enforce XDG Base Directory compliance";
    };
  };

  config = mkIf cfg.enable {
    # Store configuration
    xdg.configFile."johnny-mnemonix/config.toml".text = ''
      base_dir = "${cfg.baseDir}"
      xdg_compliance = ${
        if cfg.xdgCompliance
        then "true"
        else "false"
      }
    '';

    # Store templates for new directory structures
    xdg.dataFile = {
      # Basic template with common areas
      "johnny-mnemonix/templates/basic.toml".text = ''
        [[area]]
        id = "10-19"
        name = "Personal"

        [[category]]
        id = "11"
        name = "Finance"
      '';

      # Template for work-related structure
      "johnny-mnemonix/templates/work.toml".text = ''
        [[area]]
        id = "20-29"
        name = "Work"

        [[category]]
        id = "21"
        name = "Projects"
      '';
    };

    # Create required directories
    home.activation.createJohnnyMnemonixDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Cache directories
      $DRY_RUN_CMD mkdir -p "${xdgBase.cache}/search"  # For search indexes
      $DRY_RUN_CMD mkdir -p "${xdgBase.cache}/temp"    # For temporary operations

      # State directories
      $DRY_RUN_CMD mkdir -p "${xdgBase.state}/history" # Command history
      $DRY_RUN_CMD mkdir -p "${xdgBase.state}/recent"  # Recently accessed paths

      # Data directories
      $DRY_RUN_CMD mkdir -p "${xdgBase.data}/templates"  # User-modified templates
      $DRY_RUN_CMD mkdir -p "${xdgBase.data}/metadata"   # Document metadata
    '';

    # Add shell integration for XDG paths
    programs.bash.initExtra = ''
      export JOHNNY_MNEMONIX_CONFIG="${xdgBase.config}"
      export JOHNNY_MNEMONIX_CACHE="${xdgBase.cache}"
      export JOHNNY_MNEMONIX_DATA="${xdgBase.data}"
      export JOHNNY_MNEMONIX_STATE="${xdgBase.state}"
    '';

    programs.zsh.initExtra = ''
      export JOHNNY_MNEMONIX_CONFIG="${xdgBase.config}"
      export JOHNNY_MNEMONIX_CACHE="${xdgBase.cache}"
      export JOHNNY_MNEMONIX_DATA="${xdgBase.data}"
      export JOHNNY_MNEMONIX_STATE="${xdgBase.state}"
    '';
  };
}
