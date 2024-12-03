# Plugin System

Johnny-Mnemonix supports plugins to extend its functionality. This guide explains how to create, use, and manage plugins.

## Plugin Architecture

### Plugin Structure
```
plugins/
├── my-plugin/
│   ├── default.nix
│   ├── lib/
│   │   └── functions.nix
│   └── module.nix
```

### Basic Plugin Template

```nix
# plugins/my-plugin/default.nix
{ lib, config, ... }:

with lib;
let
  cfg = config.johnny-mnemonix.plugins.my-plugin;
in {
  options.johnny-mnemonix.plugins.my-plugin = {
    enable = mkEnableOption "My Johnny-Mnemonix Plugin";
    
    # Plugin-specific options
    setting = mkOption {
      type = types.str;
      default = "default value";
      description = "Example plugin setting";
    };
  };

  config = mkIf cfg.enable {
    # Plugin implementation
  };
}
```

## Creating Plugins

### 1. Basic Plugin

```nix
# plugins/tags/default.nix
{ lib, config, ... }:

with lib;
let
  cfg = config.johnny-mnemonix.plugins.tags;
in {
  options.johnny-mnemonix.plugins.tags = {
    enable = mkEnableOption "Document tagging support";
    
    tags = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Document tags";
    };
  };

  config = mkIf cfg.enable {
    # Implementation
  };
}
```

### 2. Advanced Plugin

```nix
# plugins/sync/default.nix
{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.johnny-mnemonix.plugins.sync;
in {
  options.johnny-mnemonix.plugins.sync = {
    enable = mkEnableOption "Document synchronization";
    
    provider = mkOption {
      type = types.enum [ "rclone" "syncthing" "rsync" ];
      default = "rclone";
      description = "Sync provider to use";
    };

    target = mkOption {
      type = types.str;
      description = "Sync target location";
    };

    schedule = mkOption {
      type = types.str;
      default = "hourly";
      description = "Sync schedule";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.johnny-sync = {
      Unit = {
        Description = "Johnny-Mnemonix document sync";
      };
      Service = {
        ExecStart = "${pkgs.rclone}/bin/rclone sync ${cfg.source} ${cfg.target}";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
```

## Using Plugins

### Configuration Example

```nix
{
  johnny-mnemonix = {
    enable = true;
    plugins = {
      tags.enable = true;
      sync = {
        enable = true;
        provider = "rclone";
        target = "gdrive:backup";
      };
    };
  };
}
```

## Plugin Categories

### 1. Organization Plugins
- Tagging systems
- Metadata management
- Custom categorization

### 2. Integration Plugins
- Cloud storage sync
- Version control
- Backup solutions

### 3. Utility Plugins
- Search enhancements
- Statistics
- Health checks

## Plugin Development Guidelines

### 1. Best Practices
- Follow Nix coding style
- Provide clear documentation
- Include usage examples
- Add proper error handling

### 2. Testing
```nix
# tests/default.nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.nixosTest {
  name = "my-plugin-test";
  
  nodes.machine = { config, pkgs, ... }: {
    imports = [ ./my-plugin ];
    johnny-mnemonix.plugins.my-plugin.enable = true;
  };
  
  testScript = ''
    machine.wait_for_unit("my-plugin.service")
    machine.succeed("test -d /path/to/expected/directory")
  '';
}
```

### 3. Documentation
```markdown
# Plugin Documentation Template

## Overview
Brief description of the plugin's purpose

## Configuration
Available options and their meanings

## Examples
Usage examples and common patterns

## Troubleshooting
Common issues and solutions
```

## Official Plugins

### Core Plugins
1. **Tags Plugin**
   - Document tagging
   - Tag-based search
   - Tag management

2. **Sync Plugin**
   - Multi-provider sync
   - Scheduled syncing
   - Conflict resolution

3. **Stats Plugin**
   - Usage statistics
   - Storage analysis
   - Health reporting

### Community Plugins

Guidelines for community plugins:
1. Use semantic versioning
2. Provide clear documentation
3. Include test cases
4. Follow security guidelines

## Plugin Security

### Guidelines
1. Validate all inputs
2. Use secure defaults
3. Document security implications
4. Follow principle of least privilege

### Example Security Check
```nix
# Security validation in plugin
validateConfig = config:
  assert config.target != "/";  # Prevent root access
  assert hasPrefix "backup:" config.target;  # Enforce naming
  config;
```

## Plugin Maintenance

### Version Management
```nix
# plugin/version.nix
{
  version = "1.0.0";
  compatibleVersions = [ "0.1.0" "0.2.0" ];
  
  assertCompatible = currentVersion:
    assert builtins.elem currentVersion compatibleVersions;
    true;
}
```

### Update Process
1. Test changes
2. Update version
3. Update documentation
4. Create changelog
5. Submit PR

## Contributing Plugins

1. Fork repository
2. Create plugin directory
3. Add documentation
4. Submit pull request

See [CONTRIBUTING.md](../CONTRIBUTING.md) for detailed guidelines. 