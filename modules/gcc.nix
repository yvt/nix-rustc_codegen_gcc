{ gcc11, flex, wrapCC, src, name }:

let
  overrideVersion = pkg: pkg.overrideAttrs (oldAttrs: oldAttrs // rec {
    version = "${src.lastModifiedDate}-${src.rev}";
  });

in

rec {
  cc =
    gcc11.cc.overrideAttrs (oldAttrs: oldAttrs // {
      inherit src;

      pname = "${name}-${oldAttrs.pname}";
      version = "${src.lastModifiedDate}-${src.rev}";
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

  gcc = wrapCC cc;

  libgccjit = cc.override {
    name = "libgccjit";
    langFortran = false;
    langCC = false;
    langC = false;
    profiledCompiler = false;
    langJit = true;
    enableLTO = false;
  };
}
