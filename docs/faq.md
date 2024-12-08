# Frequently Asked Questions

## Directory Management

### Q: What happens when I rename a category?
A: Johnny-Mnemonix uses content hashing to detect renames:
1. Generates hash of directory contents
2. Compares with known directory hashes
3. If a match is found, moves content to new location
4. Updates state tracking file
5. Logs change in `.structure-changes`

### Q: Are my files ever deleted?
A: No. Johnny-Mnemonix follows a non-destructive approach:
- Existing files are never deleted
- Directories are moved or merged, not removed
- All changes are logged for audit purposes

### Q: How does conflict resolution work?
A: When conflicts occur (same name, different content):
1. Both directories are preserved
2. Content hashes are compared
3. Different hashes indicate unique content
4. Changes are logged for manual resolution

## Configuration

### Q: Can I change my directory structure after initial setup?
A: Yes! The system is designed for evolution:
- Rename categories safely
- Move items between categories
- Add new areas and categories
- All while preserving existing content

### Q: What's the recommended way to handle temporary files?
A: We recommend using a dedicated temporary area:
```nix
areas = {
  "90-99" = {
    name = "Temporary";
    categories = {
      "91" = {
        name = "Drafts";
        items = {
          "91.01" = "Current";
          "91.02" = "Archive";
        };
      };
    };
  };
};
```

### Q: Can I use custom separators instead of spaces?
A: Yes, configure the spacer option:
```nix
johnny-mnemonix = {
  enable = true;
  spacer = "-";  # Results in: 10-19-Personal
};
```

## Shell Integration

### Q: How do I customize the shell command prefix?
A: Set the prefix in your configuration:
```nix
johnny-mnemonix.shell = {
  enable = true;
  prefix = "jd";  # Changes commands to: jd, jdls, jdfind
};
```

### Q: Why aren't shell completions working?
A: Ensure you have:
1. Enabled shell integration:
   ```nix
   johnny-mnemonix.shell.enable = true;
   ```
2. Enabled your shell's completion system:
   ```nix
   programs.zsh.enableCompletion = true;
   # or
   programs.bash.enableCompletion = true;
   ```
3. Rebuilt your configuration:
   ```bash
   home-manager switch
   ```

## Git Integration

### Q: How do I exclude certain directories from Git?
A: Use category-specific `.gitignore` files:
```gitignore
# In 10-19 Personal/.gitignore
11 Finance/**/*.pdf
12 Health/**/*.private
```

### Q: Can I use different Git repositories for different areas?
A: Yes, configure Git repositories per item:
```nix
items = {
  "11.01" = {
    name = "Budget";
    url = "git@github.com:user/budget.git";
  };
};
```

### Q: How does Git integration work with sparse checkouts?
A: Johnny-Mnemonix supports Git's sparse-checkout feature:
```nix
items = {
  "11.01" = {
    name = "Repository";
    url = "https://github.com/user/repo.git";
    sparse = [
      "docs/**/*.md"    # Only markdown files in docs/
      "src/core/**"     # Only core module files
      "!tests/**"       # Exclude test files
    ];
  };
};
```

## Performance

### Q: Will this slow down my shell startup?
A: No, Johnny-Mnemonix is designed for minimal impact:
- Shell functions are lazy-loaded
- Completions are cached
- State tracking is incremental

### Q: How does it handle large directories?
A: Several optimizations are in place:
- Content hashing is done incrementally
- Sparse checkouts for Git repositories
- State caching for faster lookups

## Troubleshooting

### Q: Why did my directory structure not update after rebuilding?
A: Check these common issues:
1. Ensure configuration was applied:
   ```bash
   home-manager generations
   ```
2. Look for errors in the state file:
   ```bash
   cat ~/.johnny-mnemonix-state.json
   ```
3. Check the structure changes log:
   ```bash
   cat .structure-changes
   ```

### Q: How do I reset the state tracking?
A: You can safely remove the state files:
```bash
rm .johnny-mnemonix-state.json
rm .structure-changes
home-manager switch  # Regenerates state
```

## Best Practices

### Q: What's the recommended way to organize documents?
A: Follow these guidelines:
1. Use clear, descriptive names
2. Keep areas focused and distinct
3. Limit categories to related items
4. Use consistent naming conventions

### Q: Should I version control my entire document structure?
A: Consider a hybrid approach:
1. Version control configuration
2. Selectively git-ignore sensitive data
3. Use sparse checkouts for large repositories
4. Maintain separate backups for critical data

### Q: How should I handle shared directories?
A: Options include:
1. Symlinks to shared locations
2. Git submodules for versioned content
3. Dedicated sync areas for collaborative work
