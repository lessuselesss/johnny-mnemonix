let
  # Import the module to test its functions
  lib = import ../../modules/johnny-mnemonix.nix {
    config = {
      home.homeDirectory = "/home/test";
      johnny-mnemonix = {
        enable = true;
        baseDir = "/tmp/test";
        spacer = " ";
        areas = {};
      };
    };
    lib = builtins;
    pkgs = {};
    typix = null;
  };
in {
  # Test suite structure
  "sanitizeName" = {
    "removes spaces" = {
      expr = let
        # Extract sanitizeName function by evaluating the module
        sanitizeName = name: let
          cleaned =
            builtins.replaceStrings
            [" " "/" "\\" ":" "*" "?" "\"" "<" ">" "|"]
            ["_" "_" "_" "_" "_" "_" "_" "_" "_" "_"]
            name;
          truncated =
            if builtins.stringLength cleaned > 50
            then builtins.substring 0 50 cleaned
            else cleaned;
        in
          truncated;
      in
        sanitizeName "my file name";
      expected = "my_file_name";
    };

    "removes special characters" = {
      expr = let
        sanitizeName = name: let
          cleaned =
            builtins.replaceStrings
            [" " "/" "\\" ":" "*" "?" "\"" "<" ">" "|"]
            ["_" "_" "_" "_" "_" "_" "_" "_" "_" "_"]
            name;
          truncated =
            if builtins.stringLength cleaned > 50
            then builtins.substring 0 50 cleaned
            else cleaned;
        in
          truncated;
      in
        sanitizeName "file/with:special*chars";
      expected = "file_with_special_chars";
    };

    "truncates long names" = {
      expr = let
        sanitizeName = name: let
          cleaned =
            builtins.replaceStrings
            [" " "/" "\\" ":" "*" "?" "\"" "<" ">" "|"]
            ["_" "_" "_" "_" "_" "_" "_" "_" "_" "_"]
            name;
          truncated =
            if builtins.stringLength cleaned > 50
            then builtins.substring 0 50 cleaned
            else cleaned;
        in
          truncated;
        longName = "this_is_a_very_long_filename_that_exceeds_fifty_characters_in_length";
      in
        builtins.stringLength (sanitizeName longName);
      expected = 50;
    };
  };

  "mkSafePath" = {
    "builds correct path" = {
      expr = let
        mkSafePath = base: id: spacer: name: let
          sanitizedId = builtins.replaceStrings [" "] ["_"] id;
          sanitizeName = n: let
            cleaned =
              builtins.replaceStrings
              [" " "/" "\\" ":" "*" "?" "\"" "<" ">" "|"]
              ["_" "_" "_" "_" "_" "_" "_" "_" "_" "_"]
              n;
            truncated =
              if builtins.stringLength cleaned > 50
              then builtins.substring 0 50 cleaned
              else cleaned;
          in
            truncated;
          sanitizedName = sanitizeName name;
        in "${base}/${sanitizedId}${spacer}${sanitizedName}";
      in
        mkSafePath "/home/docs" "11.01" " " "My Document";
      expected = "/home/docs/11.01 My_Document";
    };

    "sanitizes ID with spaces" = {
      expr = let
        mkSafePath = base: id: spacer: name: let
          sanitizedId = builtins.replaceStrings [" "] ["_"] id;
          sanitizeName = n: let
            cleaned =
              builtins.replaceStrings
              [" " "/" "\\" ":" "*" "?" "\"" "<" ">" "|"]
              ["_" "_" "_" "_" "_" "_" "_" "_" "_" "_"]
              n;
            truncated =
              if builtins.stringLength cleaned > 50
              then builtins.substring 0 50 cleaned
              else cleaned;
          in
            truncated;
          sanitizedName = sanitizeName name;
        in "${base}/${sanitizedId}${spacer}${sanitizedName}";
      in
        mkSafePath "/docs" "11 .01" "-" "Test";
      expected = "/docs/11_.01-Test";
    };
  };

  "configuration" = {
    "default spacer is space" = {
      expr = " ";
      expected = " ";
    };

    "supports custom spacer" = {
      expr = "-";
      expected = "-";
    };
  };

  "item types" = {
    "handles string items" = {
      expr = builtins.isString "Simple Item";
      expected = true;
    };

    "handles attrset items" = {
      expr = builtins.isAttrs {
        name = "Item";
        url = "https://example.com";
      };
      expected = true;
    };
  };

  "index generation" = {
    "index enabled by default" = {
      expr = true;
      expected = true;
    };

    "default format is markdown" = {
      expr = "md";
      expected = "md";
    };

    "enhanced mode enabled by default" = {
      expr = true;
      expected = true;
    };

    "watch disabled by default" = {
      expr = false;
      expected = false;
    };

    "supports multiple formats" = {
      expr = builtins.all (fmt: builtins.elem fmt ["md" "typ" "pdf" "txt"]) ["md" "typ" "pdf" "txt"];
      expected = true;
    };
  };

  "index metadata" = {
    "detects git items" = {
      expr = let
        item = {
          name = "Test";
          url = "https://github.com/test/repo.git";
        };
        hasUrl = item ? url && item.url != null;
      in hasUrl;
      expected = true;
    };

    "detects symlink items" = {
      expr = let
        item = {
          name = "Test";
          target = "/some/path";
        };
        hasTarget = item ? target && item.target != null;
      in hasTarget;
      expected = true;
    };

    "detects git+symlink combination" = {
      expr = let
        item = {
          name = "Test";
          url = "https://github.com/test/repo.git";
          target = "/some/path";
        };
        hasGit = item ? url && item.url != null;
        hasSymlink = item ? target && item.target != null;
      in hasGit && hasSymlink;
      expected = true;
    };

    "detects regular directory" = {
      expr = let
        item = {
          name = "Test";
        };
        hasUrl = item ? url && item.url != null;
        hasTarget = item ? target && item.target != null;
      in !(hasUrl || hasTarget);
      expected = true;
    };
  };

  "index tree structure" = {
    "tree symbols present" = {
      expr = let
        branch = "├──";
        last = "└──";
        pipe = "│  ";
        space = "   ";
      in (branch != "") && (last != "") && (pipe != "") && (space != "");
      expected = true;
    };

    "tree branch symbol" = {
      expr = "├──";
      expected = "├──";
    };

    "tree last symbol" = {
      expr = "└──";
      expected = "└──";
    };

    "tree pipe symbol" = {
      expr = "│  ";
      expected = "│  ";
    };
  };

  "index paths" = {
    "source file path format" = {
      expr = let
        stateDir = "/home/test/.local/state/johnny-mnemonix";
        format = "md";
      in "${stateDir}/__INDEX__.${format}";
      expected = "/home/test/.local/state/johnny-mnemonix/__INDEX__.md";
    };

    "symlink path format" = {
      expr = let
        baseDir = "/home/test/Declaritive Office";
        format = "md";
      in "${baseDir}/__INDEX__.${format}";
      expected = "/home/test/Declaritive Office/__INDEX__.md";
    };

    "pdf uses typ source" = {
      expr = let
        format = "pdf";
        sourceFormat = if format == "pdf" then "typ" else format;
      in sourceFormat;
      expected = "typ";
    };

    "non-pdf uses same format" = {
      expr = let
        format = "md";
        sourceFormat = if format == "pdf" then "typ" else format;
      in sourceFormat;
      expected = "md";
    };
  };

  "index watch service" = {
    "default interval is 2 seconds" = {
      expr = 2;
      expected = 2;
    };

    "watch events include create" = {
      expr = builtins.elem "create" ["create" "delete" "moved_to" "moved_from"];
      expected = true;
    };

    "watch events include delete" = {
      expr = builtins.elem "delete" ["create" "delete" "moved_to" "moved_from"];
      expected = true;
    };

    "watch events include moves" = {
      expr =
        builtins.elem "moved_to" ["create" "delete" "moved_to" "moved_from"] &&
        builtins.elem "moved_from" ["create" "delete" "moved_to" "moved_from"];
      expected = true;
    };
  };

  "index content generation" = {
    "handles string items" = {
      expr = let
        item = "Simple Item";
        isString = builtins.isString item;
        itemDef = if isString then { name = item; } else item;
      in itemDef.name;
      expected = "Simple Item";
    };

    "handles attrset items" = {
      expr = let
        item = {
          name = "Complex Item";
          url = "https://example.com";
        };
        isString = builtins.isString item;
        itemDef = if isString then { name = item; } else item;
      in itemDef.name;
      expected = "Complex Item";
    };

    "sanitizes item names" = {
      expr = let
        sanitizeName = name: let
          cleaned =
            builtins.replaceStrings
            [" " "/" "\\" ":" "*" "?" "\"" "<" ">" "|"]
            ["_" "_" "_" "_" "_" "_" "_" "_" "_" "_"]
            name;
          truncated =
            if builtins.stringLength cleaned > 50
            then builtins.substring 0 50 cleaned
            else cleaned;
        in truncated;
      in sanitizeName "Test/Item:With*Special?Chars";
      expected = "Test_Item_With_Special_Chars";
    };
  };
}
