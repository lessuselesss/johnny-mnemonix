# Johnny-Mnemonix Examples

This document provides practical examples and use cases for organizing your documents with Johnny-Mnemonix.

## Common Structures

### Personal Document Structure
```nix
{
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
              "11.03" = "Tax Returns";
              "11.04" = "Insurance";
            };
          };
          "12" = {
            name = "Health";
            items = {
              "12.01" = "Medical Records";
              "12.02" = "Prescriptions";
              "12.03" = "Fitness Plans";
            };
          };
          "13" = {
            name = "Housing";
            items = {
              "13.01" = "Lease Agreements";
              "13.02" = "Maintenance Records";
              "13.03" = "Utilities";
            };
          };
        };
      };
    };
  };
}
```

### Work Document Structure
```nix
{
  "20-29" = {
    name = "Work";
    categories = {
      "21" = {
        name = "Projects";
        items = {
          "21.01" = "Active Projects";
          "21.02" = "Project Planning";
          "21.03" = "Project Templates";
        };
      };
      "22" = {
        name = "Admin";
        items = {
          "22.01" = "Contracts";
          "22.02" = "HR Documents";
          "22.03" = "Expenses";
        };
      };
      "23" = {
        name = "Client Work";
        items = {
          "23.01" = "Client A";
          "23.02" = "Client B";
          "23.03" = "Client Templates";
        };
      };
    };
  };
}
```

## Use Cases

### Academic Research
```nix
{
  "30-39" = {
    name = "Research";
    categories = {
      "31" = {
        name = "Literature";
        items = {
          "31.01" = "Papers";
          "31.02" = "References";
          "31.03" = "Notes";
        };
      };
      "32" = {
        name = "Data";
        items = {
          "32.01" = "Raw Data";
          "32.02" = "Processed Data";
          "32.03" = "Analysis Scripts";
        };
      };
      "33" = {
        name = "Writing";
        items = {
          "33.01" = "Drafts";
          "33.02" = "Figures";
          "33.03" = "Submissions";
        };
      };
    };
  };
}
```

### Creative Projects
```nix
{
  "40-49" = {
    name = "Creative";
    categories = {
      "41" = {
        name = "Writing";
        items = {
          "41.01" = "Stories";
          "41.02" = "Blog Posts";
          "41.03" = "Ideas";
        };
      };
      "42" = {
        name = "Design";
        items = {
          "42.01" = "Artwork";
          "42.02" = "References";
          "42.03" = "Templates";
        };
      };
    };
  };
}
```

## Tips for Structure Design

1. **Area Planning (XX-YY)**
   - 10-19: Personal
   - 20-29: Work
   - 30-39: Projects
   - 40-49: Creative
   - 90-99: Archive

2. **Category Organization (XX)**
   - Use first digit for broad grouping
   - Leave space for future categories
   - Keep related items together

3. **Item Numbering (XX.YY)**
   - Start with .01 for most important/common items
   - Leave gaps for future additions
   - Use consistent naming patterns

## Migration Strategy

When moving from an existing document structure:

1. **Analysis**
   - List all existing directories
   - Identify natural groupings
   - Note access patterns

2. **Planning**
   - Assign area codes (XX-YY)
   - Create categories (XX)
   - Map existing folders to items (XX.YY)

3. **Implementation**
   ```nix
   {
     johnny-mnemonix = {
       enable = true;
       # Define structure based on analysis
       areas = {
         "10-19" = {
           name = "Existing Directory A";
           categories = {
             "11" = {
               name = "Subfolder 1";
               items = {
                 "11.01" = "Important Files";
               };
             };
           };
         };
       };
     };
   }
   ```

4. **Migration**
   - Create new structure with Johnny-Mnemonix
   - Move files gradually
   - Update references as needed

## Advanced Usage

### Custom Base Directory
```nix
{
  johnny-mnemonix = {
    enable = true;
    baseDir = "/data/documents";
    # ... rest of configuration
  };
}
```

### Multiple Area Groups
```nix
{
  areas = {
    "10-19" = { name = "Personal"; };
    "20-29" = { name = "Work"; };
    "30-39" = { name = "Projects"; };
    "40-49" = { name = "Creative"; };
    "90-99" = { name = "Archive"; };
  };
}
```

## Common Patterns

1. **Time-Based Organization**
   ```nix
   "31" = {
     name = "Archives";
     items = {
       "31.01" = "2024";
       "31.02" = "2023";
       "31.03" = "2022";
     };
   };
   ```

2. **Project States**
   ```nix
   "21" = {
     name = "Projects";
     items = {
       "21.01" = "Active";
       "21.02" = "Planning";
       "21.03" = "Completed";
     };
   };
   ```

3. **Client Organization**
   ```nix
   "23" = {
     name = "Clients";
     items = {
       "23.01" = "Onboarding";
       "23.02" = "Active";
       "23.03" = "Archive";
     };
   };
   ``` 