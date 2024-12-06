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
            name = "Finance";
            items = {
              "11.01" = "Budget";
              "11.02" = "Investments";
            };
          };
          "12" = {
            name = "Health";
            items = {
              "12.01" = "Medical Records";
              "12.02" = "Fitness Plans";
            };
          };
        };
      };
      "20-29" = {
        name = "Work";
        categories = {
          "21" = {
            name = "Projects";
            items = {
              "21.01" = "Current Project";
              "21.02" = "Project Archive";
            };
          };
        };
      };
    };
  };
}
