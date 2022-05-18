{ stdenv, runCommand, naersk-lib, libgccjit, src }:

naersk-lib.buildPackage {
  name = "rustc_codegen_gcc";
  version = "${src.lastModifiedDate}-${src.rev}";
  inherit src;
  buildInputs = [ libgccjit ];

  override = (d: d // {
    prePatch = ''
      echo "patching 'Cargo.toml'"
      sed -i "Cargo.toml" -e \
        "s#^gccjit = .*# \
        gccjit = { git = \"https://github.com/antoyo/gccjit.rs\", rev = \"f24e1f49d99430941d8a747275b41c9a7930e049\" }#"

      echo "patching 'Cargo.lock'"
      sed -i "Cargo.lock" -e \
        "s#git+https://github.com/antoyo/gccjit.rs#\\0?rev=f24e1f49d99430941d8a747275b41c9a7930e049#"
      ${d.prePatch or ""}
    '';   
  });

  # Copy `dylib` artifacts to `$out/lib`
  copyLibs = true;
  copyLibsFilter =  ''
    select(.reason == "compiler-artifact" and (.target.kind | contains(["dylib"]))
    and .filenames != null and .profile.test == false)'';
}
