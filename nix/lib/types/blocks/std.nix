# std Block Types
#
# Standard block type definitions from divnix/std.
# These define what std blocks can export and what actions are available.
#
# Based on https://std.divnix.com/reference/blocktypes.html

{lib}: let
  inherit (lib) mkOption types;
in {
  # ===== Container & Orchestration =====

  arion = {
    name = "arion";
    type = "arionCompose";
    description = "Docker Compose job management via Arion";
    exports = types.attrsOf types.anything;
    actions = {
      up = "Start docker-compose services";
      ps = "List running containers";
      stop = "Stop services";
      rm = "Remove containers";
      config = "Show docker-compose configuration";
      arion = "Run arion command";
    };
  };

  containers = {
    name = "containers";
    type = "containers";
    description = "OCI container images via nix2container";
    exports = types.attrsOf (types.submodule {
      options = {
        image = mkOption {
          type = types.package;
          description = "Container image derivation";
        };
        name = mkOption {
          type = types.str;
          description = "Image name";
        };
        tag = mkOption {
          type = types.str;
          default = "latest";
          description = "Image tag";
        };
      };
    });
    actions = {
      print-image = "Print image name and tag";
      publish = "Publish image to registry";
      load = "Load image into local docker daemon";
    };
  };

  microvms = {
    name = "microvms";
    type = "microvm";
    description = "MicroVM configurations via microvm.nix";
    exports = types.attrsOf types.anything;
    actions = {
      run = "Run microVM";
      console = "Open VM console";
      microvm = "Execute microvm command";
    };
  };

  # ===== Kubernetes =====

  kubectl = {
    name = "kubectl";
    type = "k8sManifests";
    description = "Kubernetes manifest rendering and deployment";
    exports = types.attrsOf types.anything;
    actions = {
      render = "Render Kubernetes manifests";
      diff = "Show diff with cluster state";
      apply = "Apply manifests to cluster";
      explore = "Explore rendered manifests";
    };
  };

  nomad = {
    name = "nomad";
    type = "nomadJob";
    description = "Nomad job scheduler manifests";
    exports = types.attrsOf types.anything;
    actions = {
      render = "Render Nomad job description";
      deploy = "Deploy job to Nomad";
      explore = "Explore rendered job";
    };
  };

  # ===== Infrastructure as Code =====

  terra = {
    name = "terra";
    type = "terraform";
    description = "Terraform/Terranix infrastructure management";
    exports = types.attrsOf types.anything;
    actions = {
      init = "Initialize Terraform";
      plan = "Show execution plan";
      apply = "Apply infrastructure changes";
      state = "Show Terraform state";
      refresh = "Refresh state";
      destroy = "Destroy infrastructure";
    };
  };

  # ===== Development Environments =====

  devshells = {
    name = "devshells";
    type = "devshell";
    description = "Development shell environments";
    exports = types.attrsOf types.package;
    actions = {
      build = "Build devshell";
      enter = "Enter development shell";
    };
  };

  # ===== Executables & Packages =====

  runnables = {
    name = "runnables";
    type = "runnables";
    description = "Executable targets accessible via run action";
    exports = types.attrsOf types.package;
    actions = {
      build = "Build runnable";
      run = "Execute runnable";
    };
  };

  installables = {
    name = "installables";
    type = "installables";
    description = "Packages that can be installed to user profile";
    exports = types.attrsOf types.package;
    actions = {
      install = "Install to user profile";
      upgrade = "Upgrade package";
      remove = "Remove from profile";
      build = "Build package";
      bundle = "Bundle as executable";
      bundleImage = "Bundle as OCI image";
      bundleAppImage = "Bundle as AppImage";
    };
  };

  pkgs = {
    name = "pkgs";
    type = "pkgs";
    description = "Custom nixpkgs instances with overlays (excluded from CLI/TUI)";
    exports = types.raw;
    actions = {};  # No CLI actions - performance optimization
  };

  # ===== Configuration & Data =====

  nixago = {
    name = "nixago";
    type = "nixago";
    description = "Repository dotfile and configuration management";
    exports = types.attrsOf types.anything;
    actions = {
      populate = "Generate configuration files";
      explore = "Explore generated configs";
    };
  };

  data = {
    name = "data";
    type = "data";
    description = "JSON-serializable data";
    exports = types.attrsOf types.anything;
    actions = {
      write = "Write data to file";
      explore = "Explore data structure";
    };
  };

  files = {
    name = "files";
    type = "files";
    description = "Text files for exploration";
    exports = types.attrsOf types.str;
    actions = {
      explore = "Explore file contents via bat";
    };
  };

  # ===== Testing =====

  namaka = {
    name = "namaka";
    type = "namaka";
    description = "Snapshot testing framework";
    exports = types.attrsOf types.anything;
    actions = {
      eval = "Evaluate snapshot tests";
      check = "Run snapshot tests";
      review = "Review snapshot diffs";
      clean = "Clean snapshot artifacts";
    };
  };

  nixostests = {
    name = "nixostests";
    type = "nixosTest";
    description = "NixOS VM-based integration testing";
    exports = types.attrsOf types.anything;
    actions = {
      run = "Run NixOS test";
      audit-script = "Show test script";
      run-vm = "Run test VM";
      "run-vm+" = "Run test VM with additional options";
    };
  };

  # ===== Package Management =====

  nvfetcher = {
    name = "nvfetcher";
    type = "nvfetcher";
    description = "Package source version tracking and updates";
    exports = types.attrsOf types.anything;
    actions = {
      fetch = "Fetch and update package sources";
    };
  };

  # ===== Generic Types =====

  functions = {
    name = "functions";
    type = "functions";
    description = "Reusable Nix functions and modules (no CLI actions)";
    exports = types.attrsOf types.anything;
    actions = {};  # Pure library code
  };

  anything = {
    name = "anything";
    type = "anything";
    description = "Fallback block type without specific actions";
    exports = types.anything;
    actions = {};
  };
}
