{ gcc11, flex, src, name }:

let
  overrideVersion = pkg: pkg.overrideAttrs (oldAttrs: oldAttrs // rec {
    version = "${src.lastModifiedDate}-${src.rev}";
  });
in

rec {
  gcc =
    gcc11.overrideAttrs (oldAttrs: oldAttrs // {
      inherit src;
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ flex ];

      # `no-sys-dirs.patch` expects `gcc.cc` and `cppdefault.cc` to have a
      # different file extension
      prePatch = ''
        mv gcc/gcc.cc gcc/gcc.c
        mv gcc/cppdefault.cc gcc/cppdefault.c
      '';
      postPatch = oldAttrs.postPatch + ''
        mv gcc/gcc.c gcc/gcc.cc
        mv gcc/cppdefault.c gcc/cppdefault.cc
      '';

      configureFlags = oldAttrs.configureFlags ++
        [ "--disable-werror" ];
    });

  cc = overrideVersion (gcc.cc.override {
    name = "gcc-${name}";
  });

  libgccjit = overrideVersion (gcc.cc.override {
    name = "libgccjit-${name}";
    langFortran = false;
    langCC = false;
    langC = false;
    profiledCompiler = false;
    langJit = true;
    enableLTO = false;
  });
}
