# Troubleshooting Guide

This guide helps you resolve common issues when using Johnny-Mnemonix.

## Common Issues

### Configuration Errors

#### Invalid Area ID Format
```
error: Area ID '1019' must be in format 'XX-YY' (e.g., '10-19')
```

**Solution:**
- Ensure area IDs use the format `XX-YY`
- Example: `"10-19"` not `"1019"`
```nix
areas = {
  "10-19" = {  # Correct
    name = "Personal";
  };
};
```

#### Invalid Category ID
```
error: Category ID '1' must be two digits (e.g., '11')
```

**Solution:**
- Use two-digit category IDs
- Example: `"11"` not `"1"`
```nix
categories = {
  "11" = {  # Correct
    name = "Finance";
  };
};
```

#### Invalid Item ID
```
error: Item ID '11.1' must be in format 'XX.YY' (e.g., '11.01')
```

**Solution:**
- Use format `XX.YY` for item IDs
- Example: `"11.01"` not `"11.1"`
```nix
items = {
  "11.01" = "Budget";  # Correct
};
```

### Directory Issues

#### Directories Not Created
**Symptoms:**
- Structure defined but directories missing
- No error messages

**Solutions:**
1. Verify module is enabled:
```nix
johnny-mnemonix.enable = true;
```

2. Check permissions:
```bash
ls -la ~/Documents
```

3. Run home-manager switch with verbose output:
```bash
home-manager switch -v
```

#### Permission Denied
**Symptoms:**
- Error creating directories
- Permission errors in home-manager output

**Solutions:**
1. Check directory ownership:
```bash
ls -la ~/Documents
```

2. Fix permissions:
```bash
chmod 755 ~/Documents
```

3. Verify user has write access to baseDir

### Integration Issues

#### Shell Alias Not Working
**Symptoms:**
- `jd` command not found
- Cannot navigate to document directory

**Solutions:**
1. Verify shell configuration:
```bash
echo $SHELL
```

2. Reload shell configuration:
```bash
# For bash
source ~/.bashrc

# For zsh
source ~/.zshrc
```

3. Check alias definition:
```bash
alias | grep jd
```

## Validation Errors

### Area Validation
```
error: The option `johnny-mnemonix.areas."invalid-id"' in ... is not of type `string matching pattern "^[0-9]{2}-[0-9]{2}$"'
```

**Solution:**
- Use correct area ID format
- Check for typos
- Verify hyphen usage

### Category Validation
```
error: The option `johnny-mnemonix.areas."10-19".categories."invalid"' in ... is not of type `string matching pattern "^[0-9]{2}$"'
```

**Solution:**
- Use two-digit category IDs
- Ensure numbers only
- Check for leading zeros

### Item Validation
```
error: The option `johnny-mnemonix.areas."10-19".categories."11".items."invalid"' in ... is not of type `string matching pattern "^[0-9]{2}[.][0-9]{2}$"'
```

**Solution:**
- Use correct item ID format
- Check decimal point placement
- Verify all digits present

## Best Practices

### Preventing Issues
1. **Use Version Control**
   - Track configuration changes
   - Roll back problematic changes
   - Share configurations safely

2. **Test Changes**
   - Use `home-manager build` before switching
   - Check configuration syntax
   - Verify directory structure

3. **Maintain Backups**
   - Backup important documents
   - Document directory structure
   - Keep configuration backups

### Debugging Steps
1. **Enable Verbose Output**
```bash
home-manager switch -v
```

2. **Check Logs**
```bash
journalctl -xe
```

3. **Verify Configuration**
```bash
home-manager check
```

## Getting Help

1. **Documentation**
   - Read the configuration guide
   - Check example configurations
   - Review troubleshooting steps

2. **Issue Reporting**
   - Provide configuration snippet
   - Include error messages
   - Describe expected behavior

3. **Community Support**
   - Use GitHub issues
   - Follow contribution guidelines
   - Be specific about problems 