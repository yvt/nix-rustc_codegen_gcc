{ stdenv, naersk-lib, libgccjit, src }:

naersk-lib.buildPackage {
  name = "rustc_codegen_gcc";
  version = "${src.lastModifiedDate}-${src.rev}";
  inherit src;
  buildInputs = [ libgccjit ];

  # Copy `dylib` artifacts to `$out/lib`
  copyLibs = true;
  copyLibsFilter =  ''
    select(.reason == "compiler-artifact" and (.target.kind | contains(["dylib"]))
    and .filenames != null and .profile.test == false)'';
}
