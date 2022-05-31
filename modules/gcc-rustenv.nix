# This `*gcc-rustenv` package provides two commands:
#
#  - `gcc-rustenv`, which is a program that sets up the necessary environment
#    variables and executes a provided command.
#
#  - `gcc-cargo`, which is a shorthand for `gcc-rustenv cargo`.
#
{ writeShellApplication, prefix, librustc_codegen_gcc, binutils, gcc
, rustToolchain, rustTargetTriple, symlinkJoin }:

let 
  gcc-rustenv = writeShellApplication {
    name = "${prefix}gcc-rustenv";
    runtimeInputs = [ rustToolchain binutils gcc ];
    text = ''
      if [ $# -gt 0 ]; then
        if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
          echo "usage: $0 (print variables)"
          echo "       $0 cargo VERB ARGS... (invoke Cargo)"
          echo "       $0 COMMAND ARGS... (invoke an arbitray comamnd)"
          exit 1
        elif [ $# -ge 2 ] && [ "$1" = "cargo" ]; then
          verb="$2"
          shift; shift
    
          target_spec=""
          target_spec_flags=""
          eval "$($0)"
          if [ "$target_spec" != "" ]; then
            target_spec_flags="--target=$target_spec"
          fi
          exec "$0" "env" "cargo" "$verb" $target_spec_flags "$@"
        else
          eval "$($0)"
          exec "$@"
        fi
      fi

      host_triple=$(rustc -vV | grep host | cut -d: -f2 | tr -d " ")
      target_triple=${if rustTargetTriple == null then "$host_triple" else rustTargetTriple}
      target_triple_upper="$(echo "$target_triple" | tr '[:lower:]-' '[:upper:]_')"
    
      if [ "$host_triple" != "$target_triple" ]; then
        if [ "$target_triple" = "rx-none-elf" ]; then
          echo target_spec='${librustc_codegen_gcc.src}/rx-none-elf.json'
          echo "export CC_''${target_triple//-/_}='${gcc}/bin/rx-none-elf-gcc'"
          rustflags='-Clinker=${gcc}/bin/rx-none-elf-gcc '
        else
          echo "unknown target: $target_triple"
          exit 2
        fi
      else
        rustflags=""
      fi
    
      rustflags="$rustflags -Cpanic=abort"
      rustflags="$rustflags -Csymbol-mangling-version=v0"
      rustflags="$rustflags -Cdebuginfo=2 -Clto=off -Zpanic-abort-tests"""
      rustflags="$rustflags -Zcodegen-backend=${librustc_codegen_gcc}/lib/librustc_codegen_gcc.so"
      echo "export CARGO_TARGET_''${target_triple_upper}_RUSTFLAGS='$rustflags'"
    '';
  };

  gcc-cargo = writeShellApplication {
    name = "${prefix}gcc-cargo";
    text = ''
      exec ${gcc-rustenv}/bin/${prefix}gcc-rustenv cargo "$@"
    '';
  };
in

symlinkJoin {
  name = "${prefix}gcc-rustenv";
  paths = [ gcc-rustenv gcc-cargo ];
}
