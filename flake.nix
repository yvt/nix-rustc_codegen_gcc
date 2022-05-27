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
  };

  outputs = { self, nixpkgs, flake-utils, naersk, fenix, custom_gcc-src, rustc_codegen_gcc-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        fenixToolchain' = fenix.packages.${system}.toolchainOf { 
          date = "2022-03-26";
          sha256 = "/GO6g+X5qEo4HIl/jTHG1S57fWil1C3/WSi/4ZwFPHU=";
        };
        fenixToolchain = fenixToolchain'.withComponents [ "rustc" "cargo" "rustc-dev" ];
        naersk-lib = naersk.lib."${system}".override {
          cargo = fenixToolchain;
          rustc = fenixToolchain;
        };
        custom_gcc =
          (import ./modules/gcc.nix) {
            name = "rustc_codegen_gcc";
            src = custom_gcc-src;
            inherit (pkgs) gcc11 flex;
          };
      in
        rec {
          packages = {
            # Host compiler
            gcc = custom_gcc.cc;
            libgccjit = custom_gcc.libgccjit;
            librustc_codegen_gcc =
              (import ./modules/rustc_codegen_gcc.nix) {
                inherit (custom_gcc) libgccjit;
                inherit (pkgs) stdenv runCommand;
                inherit naersk-lib;
                src = rustc_codegen_gcc-src;
              };
          };

          defaultPackage = packages.librustc_codegen_gcc;
        });
}
