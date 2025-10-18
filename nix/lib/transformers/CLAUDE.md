# Transformers Layer - Bidirectional Cryptographic Transforms

**Layer**: 5 (Transformers)
**Purpose**: Bidirectional cryptographic transformations between config definitions and physical outputs
**Location**: `nix/lib/transformers/`
**Status**: 🔮 Placeholder - Future implementation
**Dependencies**: sodiumoxide (Rust), age, sops-nix

---

## Phase 1: Requirements

### Layer Overview

The transformers layer provides **bidirectional cryptographic transforms** that operate between two layers:

```
Config Definition (Nix) ←→ Transformer ←→ Physical Output (Filesystem)
```

**Key Insight**: Transforms can flow in EITHER direction:
- **Forward**: Plaintext config → Encrypted output (files encrypted at rest)
- **Reverse**: Encrypted config → Plaintext output (sops-nix style)
- **Hybrid**: Both encrypted (defense in depth)

### Transform Categories

The transformers layer provides **three categories** of transformations:

1. **Cryptographic Transforms**: Encryption, signing, hashing (security-focused)
2. **Semantic Transforms**: Primitive types → Domain abstractions (meaning-focused)
3. **Bidirectional**: All transforms work both directions

### User Stories

#### US-TRANS-0: Semantic Type Transforms
**As a** user organizing color palettes
**I want** hex identifiers to map to color names
**So that** `01.A5.60` becomes both a JD identifier AND "Malachite Green"

**Acceptance Criteria**:
- Primitive types (hex, decimal) transform to semantic types (colors, dates, coords)
- Bidirectional: name ↔ identifier
- Multiple domains: colors, dates, geographic coords, musical notes, etc.
- Custom mappings supported

**Example**:
```nix
# Identifier as hex color
colorPalette = mkSemanticJohnnyDecimal {
  levels = 3;
  levelConfigs = [
    { base = 16; chars = 2; }  # Red: 00-FF
    { base = 16; chars = 2; }  # Green: 00-FF
    { base = 16; chars = 2; }  # Blue: 00-FF
  ];

  transform.semantic = {
    type = "color";
    format = "hex";  # #RRGGBB
    naming = "css3";  # CSS3 color names
  };
};

# Usage
color = colorPalette.parse "01.A5.60";
# => {
#   red = 1; green = 165; blue = 96;
#   hex = "#01A560";
#   name = "Medium Sea Green";  # Closest CSS3 name
#   rgb = "rgb(1, 165, 96)";
#   hsl = "hsl(154, 99%, 33%)";
# }

# Reverse: name → identifier
colorPalette.fromName "Medium Sea Green"
# => "01.A5.60"
```

#### US-TRANS-1: Forward Transform (Encrypt Outputs)
**As a** user with sensitive files
**I want** my config to be public (in git) but my files encrypted on disk
**So that** I can version control my organization without exposing private data

**Acceptance Criteria**:
- Config files are plaintext Nix expressions
- Filesystem outputs are encrypted with age/gpg
- Per-area or per-level encryption granularity
- Metadata stored for decryption (recipients, nonces)

#### US-TRANS-2: Reverse Transform (Encrypt Config)
**As a** user sharing my dotfiles publicly
**I want** my sensitive config encrypted but my files plaintext
**So that** I can share my setup without exposing secrets

**Acceptance Criteria**:
- Config encrypted with sops-nix
- Decrypted during home-manager activation
- Filesystem outputs are normal directories
- Integration with existing sops workflow

#### US-TRANS-3: Hybrid Transform (Both Encrypted)
**As a** paranoid user
**I want** both config AND outputs encrypted
**So that** maximum security with minimal exposure

**Acceptance Criteria**:
- Config encrypted in git (sops)
- Outputs encrypted on disk (age)
- Only decrypted in memory during access
- Clear security boundaries

#### US-TRANS-4: Content-Addressed IDs
**As a** user organizing large media libraries
**I want** files organized by content hash
**So that** I get automatic deduplication and integrity verification

**Acceptance Criteria**:
- Hash function selection (blake2b, sha256)
- Hash → JD identifier mapping
- Verification on access
- Optional encryption of hash index

#### US-TRANS-5: Signed Hierarchies
**As a** team lead
**I want** to cryptographically sign our JD structure
**So that** team members can verify integrity before deployment

**Acceptance Criteria**:
- Ed25519 signatures on config
- Verification before activation
- Per-section signatures (collaborative)
- Public key distribution

---

## Phase 2: Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                  Config Layer (Nix)                  │
│  - Plaintext definitions OR                          │
│  - Encrypted with sops-nix                           │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│               Transform Layer                        │
│                                                      │
│  ┌──────────────────────────────────────────────┐  │
│  │  Transform Specification                     │  │
│  │  - mode: forward | reverse | hybrid          │  │
│  │  - encrypt/decrypt parameters                │  │
│  │  - sign/verify parameters                    │  │
│  │  - hash parameters                           │  │
│  └──────────────────────────────────────────────┘  │
│                                                      │
│  ┌──────────────────────────────────────────────┐  │
│  │  Rust Implementation (sodiumoxide)           │  │
│  │  - BLAKE2b hashing                           │  │
│  │  - Ed25519 signing/verification              │  │
│  │  - XChaCha20-Poly1305 encryption             │  │
│  │  - Key derivation (HKDF)                     │  │
│  └──────────────────────────────────────────────┘  │
│                                                      │
│  ┌──────────────────────────────────────────────┐  │
│  │  Integration Layer                           │  │
│  │  - age integration (file encryption)         │  │
│  │  - sops integration (config encryption)      │  │
│  │  - Metadata management                       │  │
│  └──────────────────────────────────────────────┘  │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│              Physical Output Layer                   │
│  - Plaintext directories/files OR                   │
│  - Encrypted with .enc suffix + metadata            │
└─────────────────────────────────────────────────────┘
```

### Component Structure

```
nix/lib/transformers/
├── CLAUDE.md                    # This file
├── default.nix                  # Main export
├── crypto.nix                   # Crypto primitive wrappers
├── forward.nix                  # Config → Encrypted output
├── reverse.nix                  # Encrypted config → Output
├── hybrid.nix                   # Both directions
├── content-addressed.nix        # Hash-based IDs
├── metadata.nix                 # Encryption metadata management
├── rust/                        # Rust implementation
│   ├── Cargo.toml
│   ├── Cargo.lock
│   ├── default.nix              # Rust package build
│   └── src/
│       ├── lib.rs               # FFI interface
│       ├── hash.rs              # BLAKE2b, SHA256
│       ├── sign.rs              # Ed25519 signatures
│       ├── encrypt.rs           # XChaCha20-Poly1305
│       ├── derive.rs            # HKDF key derivation
│       └── ffi.rs               # Nix FFI bindings
└── tests/
    ├── forward.test.nix         # Forward transform tests
    ├── reverse.test.nix         # Reverse transform tests
    ├── hybrid.test.nix          # Hybrid tests
    ├── content-addressed.test.nix
    └── crypto.test.nix          # Crypto primitive tests
```

### API Surface

```nix
# Main exports
lib.transformers = {
  # Forward transform: Config → Encrypted FS
  forward = {
    encrypt = {
      age = recipients: path: encryptedPath;
      gpg = recipients: path: encryptedPath;
      chacha20 = key: nonce: data: ciphertext;
    };

    sign = {
      ed25519 = secretKey: data: signature;
    };

    hash = {
      blake2b = data: hash;
      sha256 = data: hash;
    };
  };

  # Reverse transform: Encrypted Config → Plaintext FS
  reverse = {
    decrypt = {
      sops = configPath: decryptedData;
      age = identityFile: encryptedPath: decryptedData;
    };
  };

  # Hybrid: Both directions
  hybrid = {
    encryptBoth = configKey: outputRecipients: transformed;
  };

  # Content-addressed
  contentAddressed = {
    hashToId = hash: jdIdentifier;
    idToHash = jdIdentifier: hash;
    verify = path: expectedHash: bool;
  };

  # Metadata management
  metadata = {
    create = { recipients, nonces, method }: metadataFile;
    read = metadataFile: metadata;
    validate = metadata: bool;
  };

  # Low-level crypto (Rust FFI)
  crypto = {
    blake2b = data: bytes;
    ed25519 = {
      sign = secretKey: data: signature;
      verify = publicKey: signature: data: bool;
      keygen = seed: { public, secret };
    };
    xchacha20poly1305 = {
      encrypt = key: nonce: plaintext: ciphertext;
      decrypt = key: nonce: ciphertext: plaintext;
    };
    hkdf = {
      derive = masterKey: info: length: derivedKey;
    };
  };
};
```

---

## Phase 3: Implementation (TDD)

### Transform Modes

#### Mode 1: Forward Transform

```nix
# Input: Plaintext config
config = {
  areas."30-39 Finance" = {
    name = "Finance";
    transform.encrypt = {
      recipients = [ "age-key" ];
    };
  };
};

# Process: Home-manager activation
# 1. Create directory structure (plaintext names)
# 2. For each marked area/category/item:
#    a. Generate encryption metadata (.jd-encryption-metadata)
#    b. Encrypt directory names (if configured)
#    c. Encrypt files within
#    d. Store metadata

# Output: Encrypted filesystem
~/Documents/30-39 Finance.enc/
  ├── .jd-encryption-metadata
  │   {
  │     "version": 1,
  │     "method": "age",
  │     "recipients": ["age1..."],
  │     "encrypted": {
  │       "directories": true,
  │       "files": true
  │     }
  │   }
  ├── 30.enc/
  │   └── 30.01.enc/
  └── __INDEX__.typ.enc
```

#### Mode 2: Reverse Transform

```nix
# Input: Encrypted config
sops.secrets."finance-areas" = {
  sopsFile = ./secrets/finance.yaml;
};

config.johnny-mnemonix.areas =
  builtins.fromJSON (
    builtins.readFile config.sops.secrets."finance-areas".path
  );

# Process: Home-manager activation
# 1. sops decrypts config during evaluation
# 2. Decrypted config used for directory creation
# 3. Normal plaintext filesystem created

# Output: Plaintext filesystem (config was encrypted)
~/Documents/30-39 Finance/
  ├── 30 Taxes/
  │   └── 30.01 2024/
  └── __INDEX__.typ
```

#### Mode 3: Hybrid Transform

```nix
# Input: Encrypted config + encryption specification
sops.secrets."encrypted-finance" = { /* ... */ };

config.johnny-mnemonix.areas = {
  transform.mode = "hybrid";
  transform.configKey = "encrypted-finance";
  transform.outputRecipients = [ "age-key" ];
};

# Process:
# 1. Decrypt config from sops
# 2. Use decrypted config to create structure
# 3. Encrypt output files/directories
# 4. Store metadata

# Output: Both encrypted (config in git, output on disk)
```

### Implementation Plan

**Week 1: Rust Crypto Primitives**
- Set up Rust project with sodiumoxide
- Implement hash functions (BLAKE2b, SHA256)
- Implement Ed25519 signing/verification
- Implement XChaCha20-Poly1305 encryption
- FFI interface to Nix

**Week 2: Forward Transform**
- Age integration (file/directory encryption)
- Metadata file creation
- Per-level encryption (area/category/item)
- Directory name encryption

**Week 3: Reverse Transform**
- Sops integration
- Config decryption during evaluation
- Integration with home-manager activation

**Week 4: Hybrid + Content-Addressed**
- Hybrid mode implementation
- Hash-based ID generation
- Content verification
- Hash index management

**Week 5: Integration + Testing**
- Home-manager module integration
- End-to-end tests
- Security audit
- Documentation

---

## Security Considerations

### Key Management
- **NEVER** store private keys in Nix store (world-readable!)
- Use age identities in `~/.config/age/` or `~/.ssh/`
- Use sops-nix for encrypted config keys
- Consider HSM integration for high-security scenarios

### Nonce Management
- Unique nonces required for XChaCha20-Poly1305
- Store nonces in metadata file
- Never reuse nonces with same key
- Use XChaCha20 (192-bit nonce) over ChaCha20 (96-bit)

### Metadata Security
- Metadata file contains: recipients, nonces, method
- NOT encrypted (needed for decryption)
- Consider signing metadata to prevent tampering
- Store in `.jd-encryption-metadata` (dotfile)

### Side Channels
- Use sodiumoxide constant-time operations
- Avoid pure Nix implementations for crypto
- Be careful with timing attacks in comparisons

---

## Testing Strategy

### Unit Tests

```nix
# Crypto primitives
testBlake2bDeterministic = {
  expr = crypto.blake2b "test" == crypto.blake2b "test";
  expected = true;
};

testEd25519RoundTrip = {
  expr = let
    keypair = crypto.ed25519.keygen null;
    sig = crypto.ed25519.sign keypair.secret "data";
  in crypto.ed25519.verify keypair.public sig "data";
  expected = true;
};
```

### Integration Tests

```nix
# Forward transform
testForwardEncryptArea = {
  expr = let
    config = { /* ... */ };
    output = forward.encrypt.age ["key"] config;
  in builtins.pathExists "${output}/.jd-encryption-metadata";
  expected = true;
};

# Reverse transform
testReverseDecryptConfig = {
  expr = let
    encrypted = sops.encrypt { /* ... */ };
    decrypted = reverse.decrypt.sops encrypted;
  in decrypted ? areas;
  expected = true;
};
```

### End-to-End Tests

```nix
# Full workflow test
testE2EForwardTransform = {
  # Create config, activate home-manager, verify encryption
  # Decrypt with age, verify contents
};
```

---

## Dependencies

**Rust**:
- sodiumoxide (libsodium bindings)
- age-rust (age encryption)
- serde (serialization)

**Nix**:
- age (CLI tool)
- sops-nix (config encryption)
- libsodium (system library)

**Build**:
- rustPlatform.buildRustPackage
- cargoLock for reproducibility

---

## Timeline

**Phase 1**: Rust crypto primitives (Week 1)
**Phase 2**: Forward transform (Week 2)
**Phase 3**: Reverse transform (Week 3)
**Phase 4**: Hybrid + content-addressed (Week 4)
**Phase 5**: Integration + security audit (Week 5)

**Prerequisites**:
- Library layers 1-4 complete
- Clear security use cases
- Security review resources available

**Status**: 🔮 Placeholder - Not yet implemented

---

## Related Documentation

- **Library Overview**: `../CLAUDE.md`
- **Primitives**: `../primitives/CLAUDE.md`
- **Composition**: `../composition/CLAUDE.md`
- **Builders**: `../builders/CLAUDE.md`
- **TODO**: Root TODO.md for vision

---

**Remember**: This is a placeholder specification. Implementation will follow strict TDD methodology (RED → GREEN → REFACTOR) when the time comes. Security is paramount - all crypto code must be reviewed by experts before production use. 🔐
