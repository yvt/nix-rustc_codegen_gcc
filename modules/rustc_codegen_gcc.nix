{ stdenv, runCommand, naersk-lib, libgccjit, src }:

let
  patchedSrc = runCommand "rustc_codegen_gcc-patch" {}
    ''
    mkdir -p "$out"
    cp -r "${src}"/* "$out/"

    echo "patching 'Cargo.toml'"
    sed -i "$out/Cargo.toml" -e \
      "s#^gccjit = .*# \
      gccjit = { git = \"https://github.com/antoyo/gccjit.rs\", rev = \"f24e1f49d99430941d8a747275b41c9a7930e049\" }#"

    echo "patching 'Cargo.lock'"
    sed -i "$out/Cargo.lock" -e \
      "s#git+https://github.com/antoyo/gccjit.rs#\\0?rev=f24e1f49d99430941d8a747275b41c9a7930e049#"
    '';
in

naersk-lib.buildPackage {
  name = "rustc_codegen_gcc";
  version = "${src.lastModifiedDate}-${src.rev}";
  src = patchedSrc;
  buildInputs = [ libgccjit ];

  # Copy `dylib` artifacts to `$out/lib`
  copyLibs = true;
  copyLibsFilter =  ''
    select(.reason == "compiler-artifact" and (.target.kind | contains(["dylib"]))
    and .filenames != null and .profile.test == false)'';
}
