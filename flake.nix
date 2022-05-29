{
  description = "Rust toolchain with GCC code generator";

  inputs = {
    nixpkgs.url = "flake:nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nmattia/naersk/master";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    custom_gcc-src = {
      url = "github:antoyo/gcc/6c00b2a3b02d67cdf009d248103e821d784f4ace";
      flake = false;
    };

    rustc_codegen_gcc-src = {
      url = "github:rust-lang/rustc_codegen_gcc/e6dbecdff382691b9f072fedc7cf70cd8ab5a6a4";
      flake = false;
    };

    rx-embedded-rustc_codegen_gcc-src = {
      url = "github:yvt/rustc_codegen_gcc/d753e3fb84c670994a8e12349e3a832eb4d7d3e2";
      flake = false;
    };
  };

  outputs = {
    self, nixpkgs, flake-utils, naersk, fenix, custom_gcc-src, rustc_codegen_gcc-src,
    rx-embedded-rustc_codegen_gcc-src,
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        rustc_codegen_gcc-toolchain = { 
          date = "2022-03-26";
          sha256 = "/GO6g+X5qEo4HIl/jTHG1S57fWil1C3/WSi/4ZwFPHU=";
        };
        
        rcgPackages = { 
          pkgs, prefix ? "", rustc_codegen_gcc-src, rustc_codegen_gcc-toolchain,
        }:
          let
            fenixToolchain = 
              (fenix.packages.${system}.toolchainOf rustc_codegen_gcc-toolchain)
              .withComponents [ "rustc" "cargo" "rustc-dev" ];
            naersk-lib = naersk.lib."${system}".override {
              cargo = fenixToolchain;
              rustc = fenixToolchain;
            };
            customGcc =
              (import ./modules/gcc.nix) {
                name = "rustc_codegen_gcc";
                src = custom_gcc-src;
                inherit (pkgs) gcc11 flex;
              };
          in
          {
            "${prefix}binutils" = pkgs.binutils;
            "${prefix}gcc" = customGcc.cc;
            "${prefix}libgccjit" = customGcc.libgccjit;
            "${prefix}librustc_codegen_gcc" =
              (import ./modules/rustc_codegen_gcc.nix) {
                inherit (customGcc) libgccjit;
                inherit (pkgs) stdenv;
                inherit naersk-lib;
                src = rustc_codegen_gcc-src;
              };
          };

      in
        rec {
          packages =
            { default = packages.librustc_codegen_gcc; } //
            (rcgPackages { 
              inherit pkgs rustc_codegen_gcc-src rustc_codegen_gcc-toolchain; 
            }) //
            (rcgPackages { 
              prefix = "rx-embedded-"; 
              rustc_codegen_gcc-src = rx-embedded-rustc_codegen_gcc-src;
              rustc_codegen_gcc-toolchain = {
                date = "2022-03-30";
                sha256 = "lswbVXYK4g58MZpQ6M38yismKCEjRF525FlFEZ3RWLw=";
              };
              pkgs = pkgs.pkgsCross.rx-embedded.buildPackages;
            });
        });
}
