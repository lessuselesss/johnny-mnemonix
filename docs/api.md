# API Documentation

## State Management

Johnny-Mnemonix maintains state using a JSON-based tracking system:

```json
{
  "/path/to/directory": {
    "hash": "sha256-hash-of-contents",
    "timestamp": "2024-03-14T12:00:00Z"
  }
}
```

### State File Location
- Default: `${baseDir}/.johnny-mnemonix-state.json`
- Tracks directory content hashes and metadata
- Used for detecting renames and moves

### Directory Changes
Changes are tracked in `${baseDir}/.structure-changes`:
```
# Renamed: /old/path -> /new/path
# Moved: /source/path -> /target/path
# Deprecated: /old/path - reason for deprecation
```
