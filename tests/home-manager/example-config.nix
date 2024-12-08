_: {
  # Basic home-manager configuration
  home = {
    username = "test";
    homeDirectory = "/home/test";
    stateVersion = "23.11";
  };

  # Johnny-Mnemonix configuration
  johnny-mnemonix = {
    enable = true;
    areas = {
      "10-19" = {
        name = "Personal";
        categories = {
          "11" = {
            name = "Projects";
            items = {
              "11.01" = {
                name = "Budget";
              };
              "11.02" = {
                name = "Project Repository";
                url = "https://github.com/user/project";
                ref = "main";
              };
              "11.03" = {
                name = "Large Repository";
                url = "https://github.com/user/large-repo";
                ref = "develop";
                sparse = [
                  "docs/*"
                  "src/specific-folder"
                ];
              };
            };
          };
        };
      };
    };
  };
}
