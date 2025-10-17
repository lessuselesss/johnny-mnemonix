# Community Flakes for Real-World Testing
#
# Fetches actual community flakes to test our type definitions against.
# These are real-world projects that serve as validation targets.

{
  fetchFromGitHub,
  fetchgit,
}: {
  # ===== Meta Framework =====

  flakeParts = fetchFromGitHub {
    owner = "hercules-ci";
    repo = "flake-parts";
    rev = "main";  # Should pin to specific commit in production
    hash = "";  # Will be filled in when fetched
  };

  # ===== Standard Ecosystem =====

  nixpkgs = fetchFromGitHub {
    owner = "nixos";
    repo = "nixpkgs";
    rev = "nixos-unstable";
    hash = "";
  };

  homeManager = fetchFromGitHub {
    owner = "nix-community";
    repo = "home-manager";
    rev = "master";
    hash = "";
  };

  impermanence = fetchFromGitHub {
    owner = "nix-community";
    repo = "impermanence";
    rev = "master";
    hash = "";  # Popular nixosModule to test against
  };

  nixDarwin = fetchFromGitHub {
    owner = "LnL7";
    repo = "nix-darwin";
    rev = "master";
    hash = "";
  };

  # ===== Popular User Configs =====

  # Misterio77's configs - well-structured, popular examples
  misterioNixConfig = fetchFromGitHub {
    owner = "Misterio77";
    repo = "nix-config";
    rev = "main";
    hash = "";
  };

  misterioNixStarters = fetchFromGitHub {
    owner = "Misterio77";
    repo = "nix-starter-configs";
    rev = "main";
    hash = "";
  };

  # dustinlyons - popular darwin config
  dustinNixDarwin = fetchFromGitHub {
    owner = "dustinlyons";
    repo = "nixos-config";
    rev = "main";
    hash = "";
  };

  # ===== Custom Flake Types =====

  # Dendrix - dendritic aspect-oriented configuration
  dendrix = fetchFromGitHub {
    owner = "vic";
    repo = "dendrix";
    rev = "main";
    hash = "";
    # NOTE: May need permission from @vic to use in tests
  };

  # system-manager - NixOS-style config for any Linux
  systemManager = fetchFromGitHub {
    owner = "numtide";
    repo = "system-manager";
    rev = "main";
    hash = "";
  };

  # Typix - deterministic Typst compilation
  typix = fetchFromGitHub {
    owner = "loqusion";
    repo = "typix";
    rev = "main";
    hash = "";
    # NOTE: May want feedback from @loqusion on type definitions
  };

  # divnix/std - cell/block structured flakes
  std = fetchFromGitHub {
    owner = "divnix";
    repo = "std";
    rev = "main";
    hash = "";
  };

  # divnix/hive - std-based NixOS deployment
  hive = fetchFromGitHub {
    owner = "divnix";
    repo = "hive";
    rev = "main";
    hash = "";
  };

  # ===== Dogfooding =====

  # Our own project - critical to test against!
  # Note: This would be the local flake, so we use it directly
  # johnny-mnemonix = ./../../..;  # Reference to root
}
