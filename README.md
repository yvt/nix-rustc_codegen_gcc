# [`rustc_codegen_gcc`](https://github.com/rust-lang/rustc_codegen_gcc) as Nix Flake

```shell
nix shell github:yvt/nix-rustc_codegen_gcc#rx-embedded-gcc-rustenv
cd tests/rx-rusty-blinky
rx-embedded-gcc-cargo build --release -Zbuild-std
```
