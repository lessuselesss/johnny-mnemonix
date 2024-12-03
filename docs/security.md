# Security Guidelines

This document outlines security considerations and best practices for using Johnny-Mnemonix.

## File System Security

### Directory Permissions

Default permissions are set to ensure proper security:

```nix
{
  johnny-mnemonix = {
    security = {
      defaultPermissions = "0750";  # rwxr-x---
      baseDirectoryPermissions = "0755";  # rwxr-xr-x
      sensitiveDirectoryPermissions = "0700";  # rwx------
    };
  };
}
```

### Sensitive Data Handling

Mark directories containing sensitive data:

```nix
{
  areas = {
    "10-19" = {
      name = "Personal";
      categories = {
        "11" = {
          name = "Finance";
          sensitive = true;  # Applies stricter permissions
          items = {
            "11.01" = "Tax Returns";
          };
        };
      };
    };
  };
}
```

## Access Control

### User Permissions

```nix
{
  johnny-mnemonix = {
    security = {
      users = {
        alice = {
          areas = [ "10-19" "20-29" ];
          permissions = "rw";
        };
        bob = {
          areas = [ "20-29" ];
          permissions = "r";
        };
      };
    };
  };
}
```

### Group Management

```nix
{
  security = {
    groups = {
      finance = {
        members = [ "alice" "bob" ];
        areas = [ "10-19" ];
        permissions = "r";
      };
      projects = {
        members = [ "alice" "charlie" ];
        areas = [ "20-29" ];
        permissions = "rw";
      };
    };
  };
}
```

## Encryption

### Directory Encryption

Using LUKS encryption for sensitive areas:

```nix
{
  johnny-mnemonix = {
    security = {
      encryption = {
        enable = true;
        areas = [ "10-19" ];  # Encrypt personal data
        method = "luks";
        keyFile = "/run/secrets/documents.key";
      };
    };
  };
}
```

### File-Level Encryption

Using age for file-level encryption:

```nix
{
  security = {
    fileEncryption = {
      enable = true;
      categories = [ "11" ];  # Encrypt finance category
      method = "age";
      publicKey = "age1...";
      recipientFile = "/etc/johnny-mnemonix/recipients.txt";
    };
  };
}
```

## Audit and Logging

### Access Logging

```nix
{
  johnny-mnemonix = {
    security = {
      audit = {
        enable = true;
        logAccess = true;
        logFile = "/var/log/johnny-mnemonix/access.log";
        retention = "30d";
      };
    };
  };
}
```

### Change Tracking

```nix
{
  security = {
    audit = {
      trackChanges = true;
      changeLog = "/var/log/johnny-mnemonix/changes.log";
      notifyChanges = true;
      notificationMethod = "email";
      notificationRecipient = "admin@example.com";
    };
  };
}
```

## Backup Security

### Secure Backups

```nix
{
  johnny-mnemonix = {
    security = {
      backup = {
        encryption = true;
        encryptionKey = "/run/secrets/backup.key";
        compressBackups = true;
        signBackups = true;
        signingKey = "/run/secrets/backup-signing.key";
      };
    };
  };
}
```

### Backup Verification

```nix
{
  security = {
    backup = {
      verifyBackups = true;
      verificationSchedule = "daily";
      keepVerificationLogs = true;
      verificationLogRetention = "90d";
    };
  };
}
```

## Network Security

### Remote Access

```nix
{
  johnny-mnemonix = {
    security = {
      network = {
        enableRemoteAccess = false;
        allowedIPs = [ "192.168.1.0/24" ];
        requireVPN = true;
        sshOnly = true;
      };
    };
  };
}
```

### Sync Security

```nix
{
  security = {
    sync = {
      encryptTransfer = true;
      verifyPeers = true;
      requireAuthentication = true;
      allowedProtocols = [ "sftp" "rsync+ssh" ];
    };
  };
}
```

## Best Practices

### 1. File System Security
- Use appropriate permissions
- Encrypt sensitive data
- Regularly audit permissions

### 2. Access Control
- Follow principle of least privilege
- Regularly review access
- Use strong authentication

### 3. Data Protection
- Encrypt sensitive data
- Secure backups
- Regular security audits

### 4. Network Security
- Limit remote access
- Use secure protocols
- Encrypt network traffic

## Security Checklist

### Initial Setup
- [ ] Configure base directory permissions
- [ ] Set up user/group permissions
- [ ] Enable encryption for sensitive data
- [ ] Configure audit logging
- [ ] Set up secure backups

### Regular Maintenance
- [ ] Review access logs
- [ ] Verify backup integrity
- [ ] Update encryption keys
- [ ] Audit permissions
- [ ] Check security settings

### Incident Response
1. Detect security events
2. Log all incidents
3. Notify administrators
4. Take corrective action
5. Update security measures

## Reporting Security Issues

If you discover a security vulnerability:

1. **Do Not** disclose publicly
2. Email security@johnny-mnemonix.example
3. Include detailed description
4. Await acknowledgment

## Security Updates

Stay informed about security updates:
- Subscribe to security notifications
- Monitor project releases
- Follow security advisories 