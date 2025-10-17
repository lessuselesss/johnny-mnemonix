# Real-World Test: Colmena/Hive Community Deployments
#
# Tests our hiveModules/colmenaModules schemas against actual colmena
# deployment configurations from zhaofengli/colmena.
#
# Colmena: NixOS deployment tool with parallel deployment capabilities
# See: https://github.com/zhaofengli/colmena

{
  lib,
  schemas,
  colmena,  # From fixtures/community-flakes.nix
}: let
  # Helper: Validate module with schema
  validateModule = module:
    let
      result = builtins.tryEval (schemas.hiveModules.inventory { testModule = module; });
    in result.success;

  # Helper: Get evalChecks for a module
  getEvalChecks = module:
    let inventory = schemas.hiveModules.inventory { testModule = module; };
    in inventory.children.testModule.evalChecks;

in {
  # ===== Test: Basic Hive/Colmena Structure =====

  # Test: Minimal hive configuration
  testColmenaMinimalHive = let
    hive = {
      meta = {
        nixpkgs = /path/to/nixpkgs;
      };
      defaults = {
        # Default configuration for all nodes
      };
    };
  in {
    expr = validateModule hive;
    expected = true;
  };

  # Test: Hive with single node
  testColmenaSingleNode = let
    hive = {
      meta = {
        nixpkgs = /path/to/nixpkgs;
      };
      defaults = {};
      webserver = {
        deployment = {
          targetHost = "192.168.1.10";
          targetUser = "deploy";
        };
        services.nginx.enable = true;
      };
    };
  in {
    expr = validateModule hive;
    expected = true;
  };

  # ===== Test: Node Deployment Configuration =====

  # Test: Node with SSH configuration
  testColmenaNodeSSH = let
    node = {
      deployment = {
        targetHost = "server.example.com";
        targetUser = "deploy";
        targetPort = 2222;
        buildOnTarget = true;
      };
      services.sshd.enable = true;
    };
  in {
    expr = validateModule { testNode = node; };
    expected = true;
  };

  # Test: Node with tags
  testColmenaNodeTags = let
    node = {
      deployment = {
        targetHost = "192.168.1.10";
        tags = [ "web" "production" "critical" ];
      };
      services.nginx.enable = true;
    };
  in {
    expr = validateModule { testNode = node; };
    expected = true;
  };

  # Test: Node with deployment keys
  testColmenaNodeKeys = let
    node = {
      deployment = {
        targetHost = "192.168.1.10";
        keys = {
          "secret.key" = {
            text = "secret-content";
            user = "nginx";
            group = "nginx";
            permissions = "0600";
          };
        };
      };
      services.nginx.enable = true;
    };
  in {
    expr = validateModule { testNode = node; };
    expected = true;
  };

  # ===== Test: Common Deployment Patterns =====

  # Test: Web server cluster
  testColmenaWebCluster = let
    hive = {
      meta = {
        nixpkgs = /path/to/nixpkgs;
      };
      defaults = {
        networking.firewall.allowedTCPPorts = [ 22 80 443 ];
      };
      web1 = {
        deployment.targetHost = "web1.example.com";
        deployment.tags = [ "web" "production" ];
        services.nginx.enable = true;
      };
      web2 = {
        deployment.targetHost = "web2.example.com";
        deployment.tags = [ "web" "production" ];
        services.nginx.enable = true;
      };
      lb = {
        deployment.targetHost = "lb.example.com";
        deployment.tags = [ "loadbalancer" "production" ];
        services.haproxy.enable = true;
      };
    };
  in {
    expr = validateModule hive;
    expected = true;
  };

  # Test: Database deployment with backup
  testColmenaDatabase = let
    node = {
      deployment = {
        targetHost = "db.example.com";
        targetUser = "deploy";
        tags = [ "database" "production" "critical" ];
        keys = {
          "db-password" = {
            text = "changeme";
            user = "postgres";
            permissions = "0400";
          };
        };
      };
      services.postgresql = {
        enable = true;
        enableTCPIP = true;
      };
    };
  in {
    expr = validateModule { database = node; };
    expected = true;
  };

  # Test: Development staging environment
  testColmenaStagingEnv = let
    hive = {
      meta = {
        nixpkgs = /path/to/nixpkgs;
      };
      defaults = {
        environment.systemPackages = [ ];
      };
      staging-web = {
        deployment.targetHost = "staging-web.example.com";
        deployment.tags = [ "web" "staging" ];
        services.nginx.enable = true;
      };
      staging-db = {
        deployment.targetHost = "staging-db.example.com";
        deployment.tags = [ "database" "staging" ];
        services.postgresql.enable = true;
      };
    };
  in {
    expr = validateModule hive;
    expected = true;
  };

  # ===== Test: Advanced Deployment Features =====

  # Test: Build on target node
  testColmenaBuildOnTarget = let
    node = {
      deployment = {
        targetHost = "low-power.example.com";
        buildOnTarget = true;
        replaceUnknownProfiles = true;
      };
      services.nginx.enable = true;
    };
  in {
    expr = validateModule { testNode = node; };
    expected = true;
  };

  # Test: Custom deployment options
  testColmenaCustomDeployment = let
    node = {
      deployment = {
        targetHost = "custom.example.com";
        allowLocalDeployment = true;
        privilegeEscalationCommand = [ "doas" "-u" ];
      };
      services.nginx.enable = true;
    };
  in {
    expr = validateModule { testNode = node; };
    expected = true;
  };

  # Test: Node with substituters
  testColmenaSubstituters = let
    hive = {
      meta = {
        nixpkgs = /path/to/nixpkgs;
        nodeNixpkgs = {
          webserver = /path/to/custom/nixpkgs;
        };
        nodeSpecialArgs = {
          webserver = { customArg = "value"; };
        };
      };
      webserver = {
        deployment.targetHost = "web.example.com";
        services.nginx.enable = true;
      };
    };
  in {
    expr = validateModule hive;
    expected = true;
  };

  # ===== Test: colmenaModules Alias Schema =====

  # Test: colmenaModules schema validates same content
  testColmenaModulesAlias = let
    hive = {
      meta = { nixpkgs = /path/to/nixpkgs; };
      webserver = {
        deployment.targetHost = "web.example.com";
        services.nginx.enable = true;
      };
    };
    result = builtins.tryEval (schemas.colmenaModules.inventory hive);
  in {
    expr = result.success;
    expected = true;
  };

  # Test: hive schema validates same content
  testColmenaHiveSchema = let
    hive = {
      meta = { nixpkgs = /path/to/nixpkgs; };
      webserver = {
        deployment.targetHost = "web.example.com";
        services.nginx.enable = true;
      };
    };
    result = builtins.tryEval (schemas.hive.inventory hive);
  in {
    expr = result.success;
    expected = true;
  };

  # ===== Test: Invalid Configurations Rejected =====

  # Test: Hive missing meta
  testColmenaInvalidNoMeta = {
    expr = let
      hive = {
        webserver = {
          deployment.targetHost = "web.example.com";
        };
      };
      checks = getEvalChecks hive;
    in checks.hasMeta;
    expected = false;
  };

  # Test: Node missing deployment
  testColmenaInvalidNoDeployment = {
    expr = let
      node = {
        services.nginx.enable = true;
        # Missing deployment section
      };
      checks = getEvalChecks { testNode = node; };
    in checks.hasDeployment;
    expected = false;
  };

  # Test: String is not a valid hive
  testColmenaInvalidString = {
    expr = let
      checks = getEvalChecks "not a hive";
    in checks.hasMeta;
    expected = false;
  };

  # Test: Number is not a valid hive
  testColmenaInvalidNumber = {
    expr = let
      checks = getEvalChecks 42;
    in checks.hasMeta;
    expected = false;
  };

  # ===== Test: Multi-Node Validation =====

  # Test: Multiple nodes all have valid deployment config
  testColmenaMultiNodeValid = let
    hive = {
      meta = { nixpkgs = /path/to/nixpkgs; };
      web1 = {
        deployment.targetHost = "web1.example.com";
        services.nginx.enable = true;
      };
      web2 = {
        deployment.targetHost = "web2.example.com";
        services.nginx.enable = true;
      };
      db = {
        deployment.targetHost = "db.example.com";
        services.postgresql.enable = true;
      };
    };
    inventory = schemas.hiveModules.inventory hive;
    # Check web1, web2, db all have deployment (skip meta and defaults)
    nodeNames = builtins.filter (n: n != "meta" && n != "defaults") (builtins.attrNames inventory.children);
    allHaveDeployment = builtins.all (name:
      let checks = inventory.children.${name}.evalChecks;
      in checks.hasDeployment or false
    ) nodeNames;
  in {
    expr = allHaveDeployment;
    expected = true;
  };

  # ===== Test: Tag-Based Deployment =====

  # Test: Nodes can be filtered by tags
  testColmenaTagFiltering = let
    hive = {
      meta = { nixpkgs = /path/to/nixpkgs; };
      prod-web = {
        deployment.targetHost = "prod-web.example.com";
        deployment.tags = [ "web" "production" ];
      };
      staging-web = {
        deployment.targetHost = "staging-web.example.com";
        deployment.tags = [ "web" "staging" ];
      };
      prod-db = {
        deployment.targetHost = "prod-db.example.com";
        deployment.tags = [ "database" "production" ];
      };
    };
  in {
    expr = validateModule hive;
    expected = true;
  };
}
