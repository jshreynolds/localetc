# Per-project devshell templates

Runtimes that used to sit on the global profile now live here instead, so each
project pins its own toolchain. `direnv` + `nix-direnv` are already enabled
globally (see `nix/home-manager/programs.nix`), so entering a project directory loads
its shell automatically.

## Use

```sh
cp -r ~/etc/templates/jvm/{flake.nix,.envrc} some-project/
cd some-project
direnv allow          # first time only; nix-direnv caches the shell afterward
```

Trim the `packages` list in the copied `flake.nix` to what the project actually
needs.

## What's here

| Template  | Provides                                            |
|-----------|-----------------------------------------------------|
| `jvm/`    | Java (Temurin 25), Gradle, Maven, Scala, Clojure    |
| `dotnet/` | .NET SDK 10                                          |
| `rust/`   | nix-pinned Rust: rustc, cargo, rustfmt, clippy, RA  |

Other single-runtime projects follow the same one-line pattern — copy `dotnet/`
and swap `pkgs.dotnet-sdk_10` for e.g. `pkgs.ruby_3_4`.
