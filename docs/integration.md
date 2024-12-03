# Integration Guide

This guide explains how to integrate Johnny-Mnemonix with other tools and workflows.

## Shell Integration

### Bash/Zsh Functions

Add these helpful functions to your shell configuration:

```bash
# ~/.bashrc or ~/.zshrc

# Quick navigation using Johnny Decimal codes
jj() {
  local code="$1"
  local base_dir="${JOHNNY_MNEMONIX_BASE:-$HOME/Documents}"
  
  # Pattern matching for different code formats
  case "$code" in
    # Area navigation (e.g., 10)
    [0-9][0-9])
      cd "$base_dir"/*"$code-"* 2>/dev/null || echo "Area not found: $code"
      ;;
    # Category navigation (e.g., 11)
    [0-9][0-9].[0-9][0-9])
      cd "$base_dir"/*/*"$code "* 2>/dev/null || echo "Category not found: $code"
      ;;
    # Item navigation (e.g., 11.01)
    [0-9][0-9].[0-9][0-9])
      cd "$base_dir"/*/*/*"$code "* 2>/dev/null || echo "Item not found: $code"
      ;;
    *)
      echo "Invalid Johnny Decimal code format"
      echo "Usage: jj XX (area) or XX.YY (category) or XX.YY (item)"
      ;;
  esac
}

# List structure with tree
jls() {
  tree -L 3 --noreport "${JOHNNY_MNEMONIX_BASE:-$HOME/Documents}" | \
    grep -E "^[│├└].+[0-9]{2}(-[0-9]{2}| [A-Za-z])"
}

# Search within Johnny Decimal structure
jf() {
  local search_term="$1"
  find "${JOHNNY_MNEMONIX_BASE:-$HOME/Documents}" -type f -name "*$search_term*" | \
    grep -E "/[0-9]{2}(-[0-9]{2}|.[0-9]{2})"
}
```

### Fish Functions

```fish
# ~/.config/fish/functions/jj.fish
function jj
  set -l code $argv[1]
  set -l base_dir $JOHNNY_MNEMONIX_BASE; or set base_dir $HOME/Documents
  
  switch $code
    case '[0-9][0-9]'
      cd $base_dir/*$code-* 2>/dev/null; or echo "Area not found: $code"
    case '[0-9][0-9].[0-9][0-9]'
      cd $base_dir/*/*$code* 2>/dev/null; or echo "Category not found: $code"
    case '[0-9][0-9].[0-9][0-9]'
      cd $base_dir/*/*/*$code* 2>/dev/null; or echo "Item not found: $code"
    case '*'
      echo "Invalid Johnny Decimal code format"
      echo "Usage: jj XX (area) or XX.YY (category) or XX.YY (item)"
  end
end
```

## Git Integration

### Git Ignore Template

```gitignore
# ~/.config/johnny-mnemonix/templates/gitignore
# Temporary files
*.tmp
*.temp
.DS_Store

# Build artifacts
*.pdf
*.docx
*.xlsx

# Local configuration
.johnny-local
```

### Git Attributes

```gitattributes
# ~/.config/johnny-mnemonix/templates/gitattributes
# Handle line endings automatically for text files
* text=auto

# Documents
*.md text
*.txt text
*.doc binary
*.docx binary
*.pdf binary
```

## Syncthing Integration

Example Syncthing configuration for your Johnny Decimal structure:

```nix
{
  services.syncthing = {
    enable = true;
    folders = {
      documents = {
        path = "${config.johnny-mnemonix.baseDir}";
        devices = [ "laptop" "desktop" ];
        versioning = {
          type = "simple";
          params.keep = "5";
        };
      };
    };
  };
}
```

## Backup Integration

### Restic Example

```nix
{
  services.restic.backups = {
    documents = {
      paths = [ "${config.johnny-mnemonix.baseDir}" ];
      repository = "rclone:gdrive:backup/documents";
      passwordFile = "/run/secrets/restic-password";
      initialize = true;
      timerConfig = {
        OnCalendar = "daily";
      };
    };
  };
}
```

## Editor Integration

### VS Code Workspace Settings

```jsonc
// .vscode/settings.json
{
  "files.exclude": {
    "**/*.tmp": true,
    "**/*.temp": true
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/bower_components": true
  },
  "files.associations": {
    "*.jd": "markdown" // Johnny Decimal metadata files
  }
}
```

### Neovim Configuration

```lua
-- ~/.config/nvim/after/plugin/johnny.lua
local johnny = {}

-- Quick navigation using telescope
johnny.find_document = function()
  require('telescope.builtin').find_files({
    prompt_title = "Johnny Decimal Documents",
    cwd = os.getenv("JOHNNY_MNEMONIX_BASE") or (os.getenv("HOME") .. "/Documents"),
    file_ignore_patterns = {
      "*.tmp", "*.temp", ".DS_Store"
    }
  })
end

-- Key mappings
vim.keymap.set('n', '<leader>jd', johnny.find_document, {
  desc = "Find in Johnny Decimal structure"
})
```

## CLI Tools Integration

### FZF Integration

```bash
# Quick document fuzzy finding
jfzf() {
  local base_dir="${JOHNNY_MNEMONIX_BASE:-$HOME/Documents}"
  local selected=$(find "$base_dir" -type f | \
    grep -E "/[0-9]{2}(-[0-9]{2}|.[0-9]{2})" | \
    fzf --prompt="Johnny Decimal Documents" --preview="cat {}")
  if [ -n "$selected" ]; then
    nvim "$selected"
  fi
}
``` 