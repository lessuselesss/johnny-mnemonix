{
  config,
  lib,
  ...
}: let
  cfg = config.johnny-mnemonix;

  # Add secure permission handling
  securePermissions = {
    directory = "0750"; # More restrictive default
    file = "0640";
  };

  # Add path validation function
  validatePath = path: ''
    if [[ ! "''${path}" =~ ^[a-zA-Z0-9/_.-]+$ ]]; then
      echo "Error: Invalid characters in path: ''${path}" >&2
      return 1
    fi
  '';

  # Batch size for directory creation
  batchSize = 50;

  # Progress tracking function
  trackProgress = total: current: ''
    printf "\rProgress: [%-50s] %d%%" \
      "$(printf '#%.0s' $(seq 1 $(($current * 50 / $total))))" \
      $(($current * 100 / $total))
  '';

  # Calculate total operations
  calculateTotalOps = areas:
    lib.foldl (
      acc: area:
        acc
        + 1
        + # Area itself
        (lib.length area.categories)
        + # Categories
        (lib.foldl (cacc: cat: cacc + (lib.length cat.items)) 0 area.categories) # Items
    )
    0
    areas;
in {
  createDirectories = {
    createJohnnyStructure = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Define helper function with permissions
      createIfNotExists() {
        if [ ! -d "$1" ]; then
          mkdir -p "$1"
          chmod ${securePermissions.directory} "$1"
        fi
      }

      # Initialize progress tracking
      total_ops=$(${toString (calculateTotalOps cfg.areas)})
      current_op=0

      # Batch creation helper
      createBatch() {
        local -a dirs=("$@")
        local batch_size=${toString batchSize}
        local current=0

        for dir in "''${dirs[@]}"; do
          ${validatePath} "$dir"
          createIfNotExists "$dir"
          chmod ${securePermissions.directory} "$dir"
          current=$((current + 1))
          current_op=$((current_op + 1))

          # Update progress every batch
          if [ $((current % batch_size)) -eq 0 ]; then
            ${trackProgress "total_ops" "current_op"}
          fi

          # Small delay to prevent system overload
          sleep 0.01
        done
      }

      # Create directory lists for batching
      declare -a area_dirs=()
      declare -a category_dirs=()
      declare -a item_dirs=()

      # Collect directories
      ${builtins.concatStringsSep "\n" (lib.mapAttrsToList (areaId: area: ''
          area_dirs+=("${cfg.baseDir}/${areaId} ${area.name}")
          ${builtins.concatStringsSep "\n" (lib.mapAttrsToList (catId: category: ''
              category_dirs+=("${cfg.baseDir}/${areaId} ${area.name}/${catId} ${category.name}")
              ${builtins.concatStringsSep "\n" (lib.mapAttrsToList (itemId: itemName: ''
                  item_dirs+=("${cfg.baseDir}/${areaId} ${area.name}/${catId} ${category.name}/${itemId} ${itemName}")
                '')
                category.items)}
            '')
            area.categories)}
        '')
        cfg.areas)}

      # Create directories in batches
      echo "Creating area directories..."
      createBatch "''${area_dirs[@]}"

      echo "Creating category directories..."
      createBatch "''${category_dirs[@]}"

      echo "Creating item directories..."
      createBatch "''${item_dirs[@]}"

      # Final progress update
      ${trackProgress "total_ops" "total_ops"}
      echo -e "\nDirectory structure creation complete!"
    '';
  };
}
