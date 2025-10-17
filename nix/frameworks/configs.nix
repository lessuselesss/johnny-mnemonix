# Frameworks Cell - Configs Block
# Pre-built frameworks for common organizational systems
{
  inputs,
  cell,
}: {
  # Classic Johnny Decimal (base 10, 2 digits, span 10)
  johnny-decimal-classic = import ./johnny-decimal-classic {
    inherit inputs cell;
    lib = inputs.self.lib.${inputs.nixpkgs.system};
  };

  # Hexadecimal Johnny Decimal (base 16)
  johnny-decimal-hex = import ./johnny-decimal-hex {
    inherit inputs cell;
    lib = inputs.self.lib.${inputs.nixpkgs.system};
  };

  # Semantic Versioning framework
  semver = import ./semver {
    inherit inputs cell;
    lib = inputs.self.lib.${inputs.nixpkgs.system};
  };
}
