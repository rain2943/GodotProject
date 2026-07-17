# sprite-gen vendored engine

This directory is a vendored snapshot of [aldegad/sprite-gen](https://github.com/aldegad/sprite-gen).

- Upstream revision: `d8e6c493433085da722b2d23b793165e91ebf174`
- Package version: `1.56.15`
- License: Apache-2.0 (see `LICENSE` and `NOTICE`)

The project-specific entry point is `../run_sprite_pipeline.ps1`. It keeps the
upstream stage contracts intact while choosing the Godot project output folder:
`assets/generated/sprites/<character-id>/`.

The vendored `sprite_gen/runio.py` adds a Windows `msvcrt` reader/writer lock
fallback because the upstream POSIX-only `fcntl` guard otherwise refuses to
publish on Windows. The fallback serializes reads and writes exclusively and
keeps the same atomic old-or-new publish behavior.
