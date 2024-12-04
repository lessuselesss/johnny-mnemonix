# Migration Guide

This guide helps you migrate your existing document structure to Johnny-Mnemonix.

## Planning Your Migration

### 1. Analyze Current Structure

First, analyze your existing document structure:

```bash
# List current directory structure
tree -L 3 ~/Documents > current_structure.txt

# Get file statistics
find ~/Documents -type f | \
  grep -v '^\.' | \
  awk -F/ '{print $(NF-1)}' | \
  sort | uniq -c > file_stats.txt
```

### 2. Map to Johnny Decimal

Create a mapping table:

| Current Directory | Johnny Decimal Code | Description |
|------------------|---------------------|-------------|
| Financial/       | 10-19              | Personal Finance |
| Bills/          | 11                  | Regular Bills |
| Statements/     | 11.01              | Bank Statements |

### 3. Create Configuration

Based on your mapping, create your Johnny-Mnemonix configuration:

```nix
{
  johnny-mnemonix = {
    enable = true;
    areas = {
      "10-19" = {
        name = "Personal Finance";
        categories = {
          "11" = {
            name = "Regular Bills";
            items = {
              "11.01" = "Bank Statements";
            };
          };
        };
      };
    };
  };
}
```

## Migration Strategies

### 1. Gradual Migration

Migrate files gradually while maintaining both structures:

```bash
#!/usr/bin/env bash
# migrate.sh

source_dir="$HOME/Documents/Old"
target_dir="$HOME/Documents"

# Function to migrate a directory
migrate_directory() {
  local source="$1"
  local target="$2"
  local jd_code="$3"
  
  echo "Migrating $source to $target/$jd_code"
  
  # Create target directory if it doesn't exist
  mkdir -p "$target/$jd_code"
  
  # Copy files
  cp -rv "$source/"* "$target/$jd_code/"
  
  # Create migration log
  echo "$(date): Migrated $source to $jd_code" >> migration.log
}

# Example usage
migrate_directory "$source_dir/Financial/Bills" \
                 "$target_dir" \
                 "11 Regular Bills"
```

### 2. Complete Migration

For a one-time complete migration:

```bash
#!/usr/bin/env bash
# full_migrate.sh

source_dir="$HOME/Documents"
backup_dir="$HOME/Documents_Backup_$(date +%Y%m%d)"
target_dir="$HOME/Documents_New"

# Backup existing structure
cp -r "$source_dir" "$backup_dir"

# Create new structure
home-manager switch

# Migrate files according to mapping
while IFS=, read -r old_path jd_code description; do
  # Skip header
  [[ $old_path == "Old Path" ]] && continue
  
  # Create target directory
  mkdir -p "$target_dir/$jd_code"
  
  # Move files
  find "$source_dir/$old_path" -type f -exec mv {} "$target_dir/$jd_code/" \;
  
  echo "Migrated: $old_path → $jd_code"
done < mapping.csv
```

## Post-Migration Tasks

### 1. Verify Migration

```bash
#!/usr/bin/env bash
# verify_migration.sh

# Check file counts
old_count=$(find "$backup_dir" -type f | wc -l)
new_count=$(find "$target_dir" -type f | wc -l)

echo "Old structure: $old_count files"
echo "New structure: $new_count files"

# Check for orphaned files
find "$target_dir" -type f | \
  grep -vE "/[0-9]{2}(-[0-9]{2}|.[0-9]{2})" > orphaned_files.txt

# Verify file integrity
find "$target_dir" -type f -exec md5sum {} \; > new_checksums.txt
```

### 2. Update References

Update any references to the old structure:

```bash
# Find files containing old paths
grep -r "/old/path" "$HOME" > references.txt

# Update shell aliases
sed -i 's|OLD_DOCS=.*|OLD_DOCS='"$target_dir"'|g' ~/.bashrc
```

### 3. Clean Up

```bash
#!/usr/bin/env bash
# cleanup.sh

# Remove empty directories from old structure
find "$source_dir" -type d -empty -delete

# Remove temporary migration files
rm -f migration.log orphaned_files.txt new_checksums.txt

# Keep backup for safety period
echo "Backup stored at: $backup_dir"
echo "Can be removed after verification period"
```

## Best Practices

1. **Backup First**
   - Always create backups before migration
   - Verify backup integrity
   - Keep backups until migration is verified

2. **Document Everything**
   - Create detailed mapping documentation
   - Log all migration steps
   - Document any special cases

3. **Test Migration**
   - Test with a subset of files first
   - Verify file integrity
   - Check permissions and ownership

4. **Handle Edge Cases**
   - Document special file types
   - Note any symlinks or hardlinks
   - Handle hidden files appropriately

## Troubleshooting

### Common Issues

1. **Missing Files**
   ```bash
   # Find files not migrated
   comm -23 \
     <(find "$backup_dir" -type f | sort) \
     <(find "$target_dir" -type f | sort) \
     > missing_files.txt
   ```

2. **Permission Issues**
   ```bash
   # Fix permissions
   chmod -R u+rw "$target_dir"
   chown -R $USER:$USER "$target_dir"
   ```

3. **Broken Links**
   ```bash
   # Find broken symlinks
   find "$target_dir" -type l ! -exec test -e {} \; -print
   ```

### Recovery Steps

1. **Restore from Backup**
   ```bash
   # Restore specific files
   rsync -av --files-from=missing_files.txt \
     "$backup_dir/" "$target_dir/"
   ```

2. **Fix Structure**
   ```bash
   # Reorganize misplaced files
   find "$target_dir" -type f ! -path "*/[0-9][0-9]*/*" \
     -exec mv {} "$target_dir/99 Migration/" \;
   ```

Remember to take your time with the migration and verify each step carefully. 