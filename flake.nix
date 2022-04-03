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
      url = "github:antoyo/gcc";
      flake = false;
    };

    rustc_codegen_gcc-src = {
      url = "github:rust-lang/rustc_codegen_gcc";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, naersk, fenix, custom_gcc-src, rustc_codegen_gcc-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        fenixToolchain = fenix.packages.${system}.latest.withComponents [ "rustc" "cargo" "rustc-dev" ];
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
