# Configuration Types Cell - Johnny Declarative Decimal
#
# This file defines kiro.dev-style specifications for all configuration types
# that johnny-declarative-decimal can manage. Each type represents a different
# scope/domain where JD organization can be applied.
#
# Format: Phase 1 (Requirements) → Phase 2 (Design) → Phase 3 (Implementation/TDD)

{
  /*
  ═══════════════════════════════════════════════════════════════════════════
  CONFIGURATION TYPE 1: nixos
  ═══════════════════════════════════════════════════════════════════════════
  */

  nixos = {
    # Phase 1: Requirements
    requirements = {
      name = "nixos";
      purpose = "Organize NixOS system configuration using Johnny Decimal";
      baseDir = "/etc/nixos";

      userStories = {
        US-NIXOS-1 = {
          title = "JD-Organized System Config";
          as_a = "system administrator";
          i_want = "to organize NixOS configuration using JD structure";
          so_that = "system config is discoverable and maintainable";

          acceptance = [
            "JD structure maps to module imports"
            "Configuration files follow JD naming"
            "Validation ensures correct structure"
            "Self-documenting system config"
          ];
        };

        US-NIXOS-2 = {
          title = "Module Auto-Discovery";
          as_a = "system administrator";
          i_want = "modules automatically discovered from JD structure";
          so_that = "I don't manually maintain import lists";

          acceptance = [
            "Scan /etc/nixos for JD-named modules"
            "Parse filenames to determine category"
            "Auto-import modules in correct order"
            "Detect and report conflicts"
          ];
        };
      };

      constraints = {
        nixVersion = "2.18+";
        nixosVersion = "23.11+";
        mustNotBreak = "existing non-JD configs";
        performance = "module discovery < 1s";
      };
    };

    # Phase 2: Design
    design = {
      structure = ''
        /etc/nixos/
        ├── 10-19 System/
        │   ├── 10 Boot/
        │   │   ├── 10.01 Bootloader.nix
        │   │   └── 10.02 Kernel.nix
        │   └── 11 Hardware/
        │       ├── 11.01 GPU.nix
        │       └── 11.02 Audio.nix
        ├── 20-29 Services/
        │   ├── 20 Network/
        │   │   ├── 20.01 SSH.nix
        │   │   └── 20.02 Firewall.nix
        │   └── 21 Docker/
        │       └── 21.01 Daemon.nix
        └── 30-39 Users/
            └── 30 Admins/
                ├── 30.01 Root.nix
                └── 30.02 Admin-User.nix
      '';

      api = {
        enable = "bool";
        baseDir = "path";
        autoDiscovery = "bool";
        validationLevel = "enum [strict permissive warn-only]";

        areas = "attrset of area definitions";
        moduleImportOrder = "list of priorities";

        hooks = {
          preImport = "function";
          postImport = "function";
          onConflict = "function";
        };
      };

      moduleFormat = ''
        File: /etc/nixos/20-29 Services/20 Network/20.01 SSH.nix

        {config, pkgs, ...}: {
          # Standard NixOS module
          services.openssh = {
            enable = true;
            settings.PermitRootLogin = "no";
          };
        }
      '';

      integration = {
        nixosModules = "Auto-import from JD structure";
        validation = "Parse filenames, validate JD compliance";
        documentation = "Generate config index from structure";
      };
    };

    # Phase 3: Implementation (TDD)
    implementation = {
      testStrategy = "RED → GREEN → REFACTOR";

      tests = {
        # RED: Parse NixOS module filename
        test_nixos_parse_filename = {
          red = ''
            testParseNixOSFilename = {
              expr = parseNixOSFilename "20.01 SSH.nix";
              expected = {category = 20; item = 1; name = "SSH";};
            };
          '';
          green = ''
            parseNixOSFilename = filename: let
              match = builtins.match "([0-9]{2})\\.([0-9]{2}) ([^.]+)\\.nix" filename;
            in {
              category = lib.toInt (builtins.elemAt match 0);
              item = lib.toInt (builtins.elemAt match 1);
              name = builtins.elemAt match 2;
            };
          '';
        };

        # RED: Discover modules in directory
        test_nixos_discover_modules = {
          red = ''
            testDiscoverModules = {
              expr = builtins.length (discoverNixOSModules "/etc/nixos");
              expected = 8;  # Example: 8 modules found
            };
          '';
          green = ''
            discoverNixOSModules = baseDir: let
              files = lib.filesystem.listFilesRecursive baseDir;
              nixFiles = builtins.filter (f: lib.hasSuffix ".nix" f) files;
              jdFiles = builtins.filter (f: isJDCompliant f) nixFiles;
            in jdFiles;
          '';
        };

        # RED: Import modules in order
        test_nixos_import_order = {
          red = ''
            testImportOrder = let
              modules = discoverNixOSModules "/etc/nixos";
              ordered = orderByJD modules;
            in {
              expr = builtins.head ordered;
              expected = "/etc/nixos/10-19 System/10 Boot/10.01 Bootloader.nix";
            };
          '';
          green = ''
            orderByJD = modules: let
              parsed = map (m: {path = m; jd = parseNixOSFilename m;}) modules;
              sorted = lib.sort (a: b: compareJD a.jd b.jd) parsed;
            in map (m: m.path) sorted;
          '';
        };

        # RED: Validate JD compliance
        test_nixos_validate_compliance = {
          red = ''
            testValidateCompliance = {
              expr = validateJDCompliance "/etc/nixos/20.01 SSH.nix";
              expected = true;
            };
          '';
          green = ''
            validateJDCompliance = path: let
              filename = baseNameOf path;
              pattern = "^[0-9]{2}\\.[0-9]{2} [A-Za-z0-9-]+\\.nix$";
            in builtins.match pattern filename != null;
          '';
        };
      };

      phases = [
        "Implement filename parsing (4 tests)"
        "Implement module discovery (3 tests)"
        "Implement import ordering (5 tests)"
        "Implement validation (6 tests)"
        "Integration with NixOS modules system (8 tests)"
      ];
    };
  };

  /*
  ═══════════════════════════════════════════════════════════════════════════
  CONFIGURATION TYPE 2: nixos-dendrix
  ═══════════════════════════════════════════════════════════════════════════
  */

  nixos-dendrix = {
    requirements = {
      name = "nixos-dendrix";
      purpose = "Organize NixOS using divnix/std cells with JD naming";
      baseDir = "nix/";

      userStories = {
        US-DENDRIX-1 = {
          title = "Cell-Based NixOS Config";
          as_a = "system architect";
          i_want = "to organize NixOS config in divnix/std cells";
          so_that = "configuration scales with project complexity";

          acceptance = [
            "Cells organized by JD areas"
            "Blocks organized by JD categories"
            "Filename parsing creates structure"
            "Two-pass validation ensures consistency"
          ];
        };

        US-DENDRIX-2 = {
          title = "Filename-Driven Structure";
          as_a = "developer";
          i_want = "JD structure derived from filenames";
          so_that = "structure and code stay synchronized";

          acceptance = [
            "Parse [XX.YY]{area}__(cat)__[YY name].nix format"
            "Validate category/item consistency"
            "Auto-generate directory structure"
            "Merge with explicit configuration"
          ];
        };
      };
    };

    design = {
      structure = ''
        modules/
        ├── [10.01]{10-19 System}__(10 Boot)__[01 Bootloader].nix
        ├── [10.02]{10-19 System}__(10 Boot)__[02 Kernel].nix
        ├── [20.01]{20-29 Services}__(20 Network)__[01 SSH].nix
        └── [30.01]{30-39 Users}__(30 Admins)__[01 Root].nix

        Generated:
        /etc/nixos/
        ├── 10-19 System/
        │   └── 10 Boot/
        │       ├── 01 Bootloader/
        │       └── 02 Kernel/
        ├── 20-29 Services/
        │   └── 20 Network/
        │       └── 01 SSH/
        └── 30-39 Users/
            └── 30 Admins/
                └── 01 Root/
      '';

      filenameFormat = {
        pattern = "[XX.YY]{AA-BB Area-Name}__(XX Category-Name)__[YY Item-Name].nix";
        components = {
          fullId = "[XX.YY]";
          areaRange = "{AA-BB Area-Name}";
          category = "(XX Category-Name)";
          item = "[YY Item-Name]";
        };
        validation = [
          "Category in [XX.YY] must match (XX ...)"
          "Item in [XX.YY] must match [YY ...]"
          "Category XX must fall within AA-BB range"
        ];
      };
    };

    implementation = {
      tests = {
        test_dendrix_parse_filename = {
          red = ''
            testParseDendrixFilename = {
              expr = parseDendrixFilename "[10.01]{10-19 System}__(10 Boot)__[01 Bootloader].nix";
              expected = {
                fullId = {category = 10; item = 1;};
                area = {range = {start = 10; end = 19;}; name = "System";};
                category = {id = 10; name = "Boot";};
                item = {id = 1; name = "Bootloader";};
              };
            };
          '';
        };

        test_dendrix_validate_consistency = {
          red = ''
            testValidateConsistency = {
              expr = validateDendrixFilename "[10.01]{10-19 System}__(10 Boot)__[01 Bootloader].nix";
              expected = true;
            };

            testValidateInconsistent = {
              expr = validateDendrixFilename "[10.01]{20-29 Services}__(10 Boot)__[01 Bootloader].nix";
              expected = false;  # Category 10 not in range 20-29
            };
          '';
        };
      };

      phases = [
        "Parse complex JD filename format (8 tests)"
        "Validate internal consistency (10 tests)"
        "Generate directory structure from filenames (6 tests)"
        "Merge with explicit config (5 tests)"
        "Two-pass validation (7 tests)"
      ];
    };
  };

  /*
  ═══════════════════════════════════════════════════════════════════════════
  CONFIGURATION TYPE 3: nixos-darwin
  ═══════════════════════════════════════════════════════════════════════════
  */

  nixos-darwin = {
    requirements = {
      name = "nixos-darwin";
      purpose = "Organize nix-darwin system configuration";
      baseDir = "$HOME/.nixpkgs";

      userStories = {
        US-DARWIN-1 = {
          title = "macOS System Config with JD";
          as_a = "macOS user";
          i_want = "nix-darwin config organized by JD";
          so_that = "macOS system config is as organized as NixOS";

          acceptance = [
            "Similar structure to nixos type"
            "Support for darwin-specific modules"
            "Homebrew integration in JD structure"
            "LaunchAgents/Daemons organized by JD"
          ];
        };
      };
    };

    design = {
      structure = ''
        ~/.nixpkgs/
        ├── 10-19 System/
        │   ├── 10 Homebrew/
        │   │   ├── 10.01 Taps.nix
        │   │   └── 10.02 Casks.nix
        │   └── 11 LaunchAgents/
        │       └── 11.01 Services.nix
        └── 20-29 Services/
            └── 20 Daemons/
                └── 20.01 Background-Tasks.nix
      '';
    };

    implementation = {
      tests = {
        test_darwin_module_import = {
          red = ''
            testDarwinModuleImport = {
              expr = importDarwinModules ~/.nixpkgs;
              expected = [ /* list of darwin modules */ ];
            };
          '';
        };
      };

      phases = [
        "Adapt nixos implementation for darwin (10 tests)"
        "Homebrew-specific handling (5 tests)"
        "LaunchAgent integration (4 tests)"
      ];
    };
  };

  /*
  ═══════════════════════════════════════════════════════════════════════════
  CONFIGURATION TYPE 4: home-manager
  ═══════════════════════════════════════════════════════════════════════════
  */

  home-manager = {
    requirements = {
      name = "home-manager";
      purpose = "Organize home-manager user environment (CURRENT IMPLEMENTATION)";
      baseDir = "$HOME";
      status = "✅ Implemented (johnny-mnemonix.nix)";

      userStories = {
        US-HM-1 = {
          title = "Declarative Directory Management";
          as_a = "home-manager user";
          i_want = "declarative directory structure with JD";
          so_that = "workspace is reproducible and organized";

          acceptance = [
            "Directory creation from JD config"
            "Git repository management"
            "Symlink support"
            "Index generation (Markdown/Typst/JSON)"
          ];
        };
      };
    };

    design = {
      structure = ''
        ~/
        ├── 10-19 Projects/
        │   ├── 10 Code/
        │   │   ├── 10.01 Web-App/
        │   │   └── 10.02 CLI-Tool/
        │   └── 11 Scripts/
        │       └── 11.01 Deploy/
        └── 20-29 Documents/
            └── 20 Reports/
                └── 20.01 Quarterly/
      '';

      features = [
        "✅ Directory creation"
        "✅ Git repo cloning/updating"
        "✅ Symlink management"
        "✅ Sparse checkout"
        "✅ Index generation"
        "✅ Typix integration"
        "✅ XDG compliance"
      ];
    };

    implementation = {
      status = "Complete - johnny-mnemonix.nix module";
      refactorPlan = "Use johnny-declarative-decimal library for validation/parsing";

      tests = {
        existing = "tests/home-manager/*.nix";
        coverage = "Good (multiple integration tests)";
      };

      phases = [
        "✅ Current implementation functional"
        "⏳ Refactor to use library (Phase 2)"
        "⏳ Enhanced validation with composition layer"
        "⏳ Better error messages with validators"
      ];
    };
  };

  /*
  ═══════════════════════════════════════════════════════════════════════════
  CONFIGURATION TYPE 5: hm-dirs
  ═══════════════════════════════════════════════════════════════════════════
  */

  hm-dirs = {
    requirements = {
      name = "hm-dirs";
      purpose = "Declarative directory structures with per-area base directories";
      baseDir = "Configurable per area";

      userStories = {
        US-HMDIRS-1 = {
          title = "Multiple Base Directories";
          as_a = "organized user";
          i_want = "different areas in different base directories";
          so_that = "Projects, Documents, etc. can be separate";

          acceptance = [
            "Override baseDir per area"
            "Support XDG directories"
            "Maintain JD structure within each base"
            "Validate across all bases"
          ];
        };
      };
    };

    design = {
      structure = ''
        Config:
          hm-dirs.areas = {
            "10-19 Projects" = {
              baseDir = "~/Projects";
              categories = { ... };
            };
            "20-29 Documents" = {
              baseDir = "~/Documents";
              categories = { ... };
            };
          };

        Result:
          ~/Projects/
          ├── 10 Personal/
          └── 11 Work/

          ~/Documents/
          ├── 20 Reports/
          └── 21 Notes/
      '';

      api = {
        areas = {
          _type = "attrsOf areaDefinition";
          fields = {
            baseDir = "Overrides global baseDir for this area";
            categories = "Standard category definitions";
            xdgIntegration = "Map to XDG directories";
          };
        };
      };
    };

    implementation = {
      tests = {
        test_hmdirs_multiple_bases = {
          red = ''
            testMultipleBases = let
              cfg = {
                areas."10-19 Projects".baseDir = "~/Projects";
                areas."20-29 Documents".baseDir = "~/Documents";
              };
            in {
              expr = generateAllDirs cfg;
              expected = {
                "~/Projects/10-19 Projects" = { ... };
                "~/Documents/20-29 Documents" = { ... };
              };
            };
          '';
        };
      };

      phases = [
        "Per-area baseDir override (6 tests)"
        "XDG directory integration (8 tests)"
        "Validation across multiple bases (5 tests)"
        "Path conflict detection (4 tests)"
      ];
    };
  };

  /*
  ═══════════════════════════════════════════════════════════════════════════
  CONFIGURATION TYPE 6: jd-office
  ═══════════════════════════════════════════════════════════════════════════
  */

  jd-office = {
    requirements = {
      name = "jd-office";
      purpose = "Declarative office workspace with document management";
      baseDir = "$OFFICE";

      userStories = {
        US-OFFICE-1 = {
          title = "Dedicated Office Workspace";
          as_a = "knowledge worker";
          i_want = "dedicated office directory with JD structure";
          so_that = "work documents are separate from home files";

          acceptance = [
            "OFFICE environment variable support"
            "Document templates"
            "Meeting notes organization"
            "Project documentation structure"
          ];
        };

        US-OFFICE-2 = {
          title = "Filename-Driven or Config-Driven";
          as_a = "user";
          i_want = "choose between filename parsing or explicit config";
          so_that = "I can use flake-parts or standard flake";

          acceptance = [
            "type = 'flake-parts' for filename parsing"
            "type = 'standard' for explicit config"
            "Both support same features"
            "Clear migration path between modes"
          ];
        };
      };
    };

    design = {
      structure = ''
        $OFFICE/
        ├── 10-19 Projects/
        │   ├── 10 Active/
        │   │   ├── 10.01 Project-Alpha/
        │   │   └── 10.02 Project-Beta/
        │   └── 11 Planning/
        │       └── 11.01 Roadmap/
        ├── 20-29 Meetings/
        │   ├── 20 Team/
        │   │   ├── 20.01 Standup-Notes/
        │   │   └── 20.02 Retrospectives/
        │   └── 21 Client/
        │       └── 21.01 Status-Meetings/
        └── 30-39 Documentation/
            ├── 30 Technical/
            │   ├── 30.01 Architecture/
            │   └── 30.02 API-Docs/
            └── 31 Process/
                └── 31.01 Onboarding/
      '';

      modes = {
        flake-parts = {
          description = "Filename parsing mode";
          moduleLocation = "modules/[XX.YY]{...}__.nix";
          benefits = [ "Auto-structure from filenames" "DRY config" ];
        };

        standard = {
          description = "Explicit configuration mode";
          moduleLocation = "config/*.nix";
          benefits = [ "Explicit control" "Simpler for small setups" ];
        };
      };

      templates = {
        project = "Template for project documentation";
        meeting = "Template for meeting notes";
        technical = "Template for technical docs";
        process = "Template for process documentation";
      };
    };

    implementation = {
      tests = {
        test_office_flake_parts_mode = {
          red = ''
            testFlaKeyPartsMode = {
              expr = jd-office.type == "flake-parts"
                && hasFilenameParsing jd-office;
              expected = true;
            };
          '';
        };

        test_office_standard_mode = {
          red = ''
            testStandardMode = {
              expr = jd-office.type == "standard"
                && hasExplicitConfig jd-office;
              expected = true;
            };
          '';
        };

        test_office_templates = {
          red = ''
            testApplyTemplate = {
              expr = applyTemplate "project" "30.01 New-Project";
              expected = {
                path = "$OFFICE/.../30.01 New-Project";
                files = ["README.md" "PLAN.md" "NOTES.md"];
              };
            };
          '';
        };
      };

      phases = [
        "Mode selection (flake-parts vs standard) (4 tests)"
        "Template system (8 tests)"
        "Document organization (6 tests)"
        "Integration with typix (5 tests)"
        "Filename parsing (if flake-parts mode) (10 tests)"
      ];
    };
  };

  /*
  ═══════════════════════════════════════════════════════════════════════════
  CONFIGURATION TYPE 7: typix
  ═══════════════════════════════════════════════════════════════════════════
  */

  typix = {
    requirements = {
      name = "typix";
      purpose = "Generate and organize Typst documents using JD structure";
      baseDir = "$OFFICE or configurable";

      userStories = {
        US-TYPIX-1 = {
          title = "JD-Organized Typst Documents";
          as_a = "technical writer";
          i_want = "Typst documents organized by JD";
          so_that = "documentation scales with complexity";

          acceptance = [
            "Auto-generate __INDEX__.typ"
            "Template system for document types"
            "Watch mode for auto-compilation"
            "Integration with jd-office"
          ];
        };

        US-TYPIX-2 = {
          title = "Hierarchical Index Generation";
          as_a = "user";
          i_want = "automatic hierarchical index in Typst";
          so_that = "document structure is always current";

          acceptance = [
            "Scan JD structure"
            "Generate Typst index with tree"
            "Include metadata (git, symlinks)"
            "Auto-update on changes"
          ];
        };
      };
    };

    design = {
      structure = ''
        $OFFICE/10-19 Documents/
        ├── __INDEX__.typ              # Auto-generated
        ├── 10 Reports/
        │   ├── 10.01 Quarterly.typ
        │   └── 10.02 Annual.typ
        └── 11 Proposals/
            └── 11.01 Project-Plan.typ
      '';

      indexFormat = ''
        // __INDEX__.typ (auto-generated)
        #heading("10-19 Documents")

        #tree([
          10 Reports
          #tree([
            10.01 Quarterly
            10.02 Annual
          ])
          11 Proposals
          #tree([
            11.01 Project-Plan
          ])
        ])
      '';

      templates = {
        project-plan = "Structured project plan template";
        requirements-doc = "Requirements document template";
        technical-spec = "Technical specification template";
        meeting-notes = "Meeting notes template";
      };
    };

    implementation = {
      tests = {
        test_typix_scan_structure = {
          red = ''
            testScanTypstFiles = {
              expr = scanTypstFiles "$OFFICE/10-19 Documents";
              expected = [
                "10 Reports/10.01 Quarterly.typ"
                "10 Reports/10.02 Annual.typ"
                "11 Proposals/11.01 Project-Plan.typ"
              ];
            };
          '';
        };

        test_typix_generate_index = {
          red = ''
            testGenerateTypstIndex = {
              expr = generateTypstIndex (scanTypstFiles "$OFFICE/10-19 Documents");
              expected = /* Typst tree structure */;
            };
          '';
        };

        test_typix_watch_mode = {
          red = ''
            testWatchMode = {
              expr = watchTypstFiles {
                baseDir = "$OFFICE";
                interval = 5;
                onChangeAction = "recompile";
              };
              expected = /* systemd service config */;
            };
          '';
        };
      };

      phases = [
        "Typst file scanning (5 tests)"
        "Index generation in Typst format (8 tests)"
        "Template system (6 tests)"
        "Watch mode with inotify (7 tests)"
        "Auto-compilation (5 tests)"
        "Integration with jd-office (4 tests)"
      ];
    };
  };

  /*
  ═══════════════════════════════════════════════════════════════════════════
  CONFIGURATION TYPE 8: permanence
  ═══════════════════════════════════════════════════════════════════════════
  */

  permanence = {
    requirements = {
      name = "permanence";
      purpose = "Configuration reconciliation for impermanence";
      baseDir = "All configured base-dirs";

      userStories = {
        US-PERM-1 = {
          title = "Config-Reality Reconciliation";
          as_a = "impermanence user";
          i_want = "detect differences between config and filesystem";
          so_that = "manual directory creation doesn't cause drift";

          acceptance = [
            "Diff declared structure vs actual filesystem"
            "Detect new directories not in config"
            "Detect missing directories that should exist"
            "Report persistence status (ephemeral vs persisted)"
          ];
        };

        US-PERM-2 = {
          title = "Smart Configuration Suggestions";
          as_a = "user";
          i_want = "proposed config additions for new items";
          so_that = "I don't manually write config for discovered items";

          acceptance = [
            "Parse existing directory names"
            "Infer JD structure from filesystem"
            "Generate proposed Nix config"
            "Suggest persistence rules"
          ];
        };

        US-PERM-3 = {
          title = "Impermanence Integration";
          as_a = "impermanence user";
          i_want = "understand what's persisted vs ephemeral";
          so_that = "I can audit persistence configuration";

          acceptance = [
            "Parse environment.persistence config"
            "Cross-reference JD items with persistence"
            "Suggest additions to persistence config"
            "Warn about conflicts"
          ];
        };
      };
    };

    design = {
      diffEngine = {
        description = "Compare declared vs actual structure";

        operations = [
          "Walk filesystem recursively"
          "Parse directory names using library"
          "Compare against declared configuration"
          "Generate diff report (additions/deletions/modifications)"
        ];

        output = {
          additions = "Directories that exist but aren't in config";
          deletions = "Configured directories that don't exist";
          modifications = "Name mismatches between config and filesystem";
          compliance = "Non-JD compliant directories";
        };
      };

      suggestionEngine = {
        description = "Generate config proposals";

        features = [
          "Infer area/category/item from directory structure"
          "Suggest JD-compliant names for non-compliant dirs"
          "Recommend hierarchy placement"
          "Learn patterns from existing config"
          "Generate Nix code for additions"
        ];
      };

      impermanenceIntegration = {
        description = "Understand and suggest persistence rules";

        features = [
          "Parse environment.persistence declarations"
          "Cross-reference with JD structure"
          "Identify ephemeral vs persisted items"
          "Suggest which items should be persisted"
          "Warn about conflicts"
        ];
      };

      cli = {
        commands = {
          "jd-reconcile" = "Show diff between config and filesystem";
          "jd-reconcile --check" = "Validate only (exit code for CI)";
          "jd-reconcile --suggest" = "Generate config suggestions";
          "jd-reconcile --apply" = "Interactive application of suggestions";
          "jd-reconcile --audit-persistence" = "Persistence status report";
          "jd-reconcile --fix-names" = "Suggest JD-compliant renames";
        };
      };
    };

    implementation = {
      tests = {
        test_perm_diff_engine = {
          red = ''
            testDiffEngine = let
              config = /* declared structure */;
              filesystem = /* actual directories */;
            in {
              expr = diffEngine config filesystem;
              expected = {
                additions = ["~/Documents/30-39 Finance/30 Taxes/30.01 2024"];
                deletions = [];
                modifications = [{
                  path = "10.05";
                  config = "My-Project";
                  filesystem = "Old-Project-Name";
                }];
              };
            };
          '';
        };

        test_perm_suggest_config = {
          red = ''
            testSuggestConfig = let
              discovered = "~/Documents/30-39 Finance/30 Taxes/30.01 2024";
            in {
              expr = suggestConfig discovered;
              expected = {
                nix = ''
                  areas."30-39 Finance".categories."30 Taxes".items."30.01" = {
                    name = "2024";
                  };
                '';
                persistence = ''
                  environment.persistence."/persist".directories = [
                    "~/Documents/30-39 Finance/30 Taxes/30.01 2024"
                  ];
                '';
              };
            };
          '';
        };

        test_perm_validate_compliance = {
          red = ''
            testValidateCompliance = {
              expr = validateJDCompliance "random-folder";
              expected = {
                compliant = false;
                suggestions = [
                  "90-99 Archive/90 Unsorted/90.01 Random-Folder"
                  "80-89 References/80 Misc/80.01 Random-Folder"
                ];
              };
            };
          '';
        };

        test_perm_audit_persistence = {
          red = ''
            testAuditPersistence = let
              structure = /* JD structure */;
              persistenceConfig = /* environment.persistence */;
            in {
              expr = auditPersistence structure persistenceConfig;
              expected = {
                "10-19 Projects" = {
                  persisted = true;
                  items = {
                    "10.01 Website" = {persisted = true;};
                    "10.02 CLI-Tool" = {persisted = false; recommend = true;};
                  };
                };
                "20-29 Documents" = {
                  persisted = false;
                  recommend = true;
                };
              };
            };
          '';
        };
      };

      phases = [
        "Filesystem walker with JD parsing (8 tests)"
        "Diff algorithm (config vs reality) (10 tests)"
        "Suggestion engine (12 tests)"
        "Impermanence config parser (6 tests)"
        "Persistence audit (8 tests)"
        "CLI interface (10 tests)"
        "Safe application of suggestions (8 tests)"
      ];

      safety = [
        "Never modify filesystem without confirmation"
        "Never modify config without confirmation"
        "Dry-run mode by default"
        "Backup before any changes"
        "Idempotent operations"
      ];
    };
  };

  /*
  ═══════════════════════════════════════════════════════════════════════════
  CONFIGURATION TYPE 9: fuse
  ═══════════════════════════════════════════════════════════════════════════
  */

  fuse = {
    requirements = {
      name = "fuse";
      purpose = "Virtual filesystem layer for dynamic JD views";
      baseDir = "Various mount points";
      status = "⏳ Exploratory (Phase 7+)";

      userStories = {
        US-FUSE-1 = {
          title = "Virtual Views of Same Content";
          as_a = "power user";
          i_want = "multiple organizational views of same files";
          so_that = "I can access content by date, type, tag, or JD structure";

          acceptance = [
            "Mount point for date-based view"
            "Mount point for type-based view"
            "Mount point for tag-based view"
            "All show same underlying files"
            "Read-only by default"
          ];
        };

        US-FUSE-2 = {
          title = "Auto-Categorization";
          as_a = "user";
          i_want = "filesystem that suggests JD placement";
          so_that = "new files are automatically organized";

          acceptance = [
            "Analyze file content/metadata"
            "Suggest JD category based on rules/ML"
            "Interactive prompts for ambiguous cases"
            "Learn from user corrections"
          ];
        };

        US-FUSE-3 = {
          title = "Union/Overlay Filesystem";
          as_a = "distributed work user";
          i_want = "unified view of multiple storage locations";
          so_that = "local, git, SSH, S3 all appear as one hierarchy";

          acceptance = [
            "Combine local filesystem paths"
            "Include git repositories"
            "Mount SSH/SFTP remotes"
            "Integrate cloud storage (S3, etc.)"
            "Transparent access regardless of backend"
            "Write operations route to appropriate backend"
          ];
        };

        US-FUSE-4 = {
          title = "Enhanced Navigation";
          as_a = "user";
          i_want = "JD-aware filesystem semantics";
          so_that = "navigation is smarter than standard filesystem";

          acceptance = [
            "Special virtual directories (.search/, .recent/, .tags/)"
            "Breadcrumb navigation support"
            "Auto-generated indexes at each level"
            "Symlinks to related items"
            "Smart path completion"
          ];
        };
      };
    };

    design = {
      useCases = {
        virtual-views = {
          description = "Same content, multiple organizations";
          example = ''
            ~/JD/                      # Physical
            ~/JD-by-date/              # Virtual: by date
            ~/JD-by-type/              # Virtual: by file type
            ~/JD-by-tag/work/          # Virtual: by tag
          '';
        };

        auto-categorization = {
          description = "Smart file organization";
          features = [
            "Content analysis (text extraction)"
            "Metadata analysis"
            "Rule-based placement"
            "ML-based categorization"
            "Interactive prompts"
            "Learning from corrections"
          ];
        };

        union-overlay = {
          description = "Unified view of distributed content";
          sources = [
            "Local filesystem paths"
            "Git repositories"
            "SSH/SFTP remotes"
            "Cloud storage (S3, GCS, Azure)"
            "Archive files (tar, zip)"
          ];
        };

        enhanced-navigation = {
          description = "JD-aware filesystem";
          virtualDirs = {
            ".search/keyword/" = "Full-text search results";
            ".recent/" = "Recently modified files";
            ".uncommitted/" = "Git uncommitted changes";
            ".tags/work/" = "All work-tagged items";
            ".type/pdf/" = "All PDF files";
            ".breadcrumb/10/11/11.05/" = "Breadcrumb navigation";
          };
        };
      };

      accessModes = {
        read-only = {
          description = "Safest mode - no writes propagate";
          use = "Exploration, search, alternate views";
        };

        read-write = {
          description = "Changes propagate to underlying storage";
          features = [
            "Maintains JD structure constraints"
            "Validates writes"
            "Atomic operations with rollback"
          ];
        };

        hybrid = {
          description = "Structure read-only, content read-write";
          features = [
            "JD hierarchy is read-only"
            "Files within categories can be modified"
            "Prevents structure corruption"
          ];
        };
      };

      technologyOptions = {
        rust = {
          library = "fuser";
          pros = ["Performance" "Safety" "Modern"];
          cons = ["Steeper learning curve"];
        };

        go = {
          library = "bazil/fuse";
          pros = ["Good concurrency" "Simpler than Rust"];
          cons = ["Less type safety"];
        };

        python = {
          library = "fusepy";
          pros = ["Rapid prototyping" "Easier to modify"];
          cons = ["Performance" "Not as robust"];
        };
      };
    };

    implementation = {
      status = "Exploratory - not yet started";

      prerequisites = [
        "Core library stable (Phase 1 complete)"
        "Multiple config types working (Phase 4 complete)"
        "Real user demand validated"
        "FUSE expertise available"
        "Clear focused use case identified"
      ];

      approach = [
        "Start small: Read-only, single-source, simple view"
        "Validate usefulness with real users"
        "Iterate based on usage patterns"
        "Consider alternatives (shell scripts, utilities)"
        "Gather community input before heavy investment"
      ];

      experiments = [
        "PoC: Simple read-only FUSE mount"
        "Prototype: Date-based reorganization"
        "Test: Search integration (dynamic .search/ directory)"
        "Test: Git integration (virtual .uncommitted/)"
        "Test: Union of local + one git repo"
        "Test: Auto-categorization with rules"
      ];

      risks = [
        "Complexity: FUSE development is non-trivial"
        "Performance: Can be slow without caching"
        "Stability: Bugs can cause hangs, crashes, data loss"
        "Portability: Behavior varies across Linux/macOS/Windows"
        "Maintenance: Kernel/FUSE API changes"
        "UX: Virtual filesystems can confuse users"
      ];

      tests = {
        note = "Tests written after PoC validates approach";

        test_fuse_read_only_mount = {
          red = ''
            testReadOnlyMount = {
              expr = mountFUSE {
                source = "$HOME/Documents";
                mountPoint = "$HOME/JD-readonly";
                mode = "read-only";
              };
              expected = /* successful mount */;
            };
          '';
        };

        test_fuse_virtual_view = {
          red = ''
            testVirtualDateView = {
              expr = listDirectory "$HOME/JD-by-date/2024/10/";
              expected = /* files from Documents modified in Oct 2024 */;
            };
          '';
        };
      };

      phases = [
        "Phase 7.1: PoC - Read-only mount (validation)"
        "Phase 7.2: Virtual views (by-date, by-type) (if PoC succeeds)"
        "Phase 7.3: Search integration (if views succeed)"
        "Phase 7.4: Union filesystem (if demand exists)"
        "Phase 7.5: Auto-categorization (if foundation solid)"
      ];
    };
  };

  /*
  ═══════════════════════════════════════════════════════════════════════════
  METADATA: Configuration Type System
  ═══════════════════════════════════════════════════════════════════════════
  */

  _meta = {
    version = "1.0.0-alpha";
    lastUpdated = "2025-10-17";

    overview = ''
      This file defines kiro.dev-style specifications for all configuration
      types that johnny-declarative-decimal can manage. Each type follows
      the three-phase format:

      - Phase 1: Requirements (user stories, constraints)
      - Phase 2: Design (structure, API, integration)
      - Phase 3: Implementation (TDD with RED-to-GREEN assertions)
    '';

    tddMethodology = ''
      All implementations follow strict TDD:

      1. 🔴 RED: Write failing test first
         - Proves test works
         - Clarifies requirements
         - Defines API contract

      2. 🟢 GREEN: Minimal implementation to pass
         - Simplest code that works
         - No over-engineering
         - Focus on making test pass

      3. 🔵 REFACTOR: Improve while keeping tests green
         - Clean up code
         - Remove duplication
         - Optimize if needed
         - Tests stay green throughout
    '';

    implementationOrder = [
      "1. nixos (System config - foundational)"
      "2. nixos-dendrix (Extends nixos with divnix/std)"
      "3. nixos-darwin (macOS variant of nixos)"
      "4. home-manager (Refactor existing - already works)"
      "5. hm-dirs (Extends home-manager)"
      "6. jd-office (New workspace type)"
      "7. typix (Extends jd-office + existing typix support)"
      "8. permanence (Advanced reconciliation tool)"
      "9. fuse (Exploratory - if demand validated)"
    ];

    testCoverage = {
      nixos = "26 tests";
      nixos-dendrix = "36 tests";
      nixos-darwin = "19 tests";
      home-manager = "Existing (refactor to use library)";
      hm-dirs = "23 tests";
      jd-office = "33 tests";
      typix = "35 tests";
      permanence = "62 tests";
      fuse = "TBD (exploratory)";

      total = "234+ tests (excluding fuse)";
    };
  };
}
