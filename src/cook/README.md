# Cook

`src/cook/` is for build-time asset preparation. Code here may depend on
source-asset import libraries, shader compilers, texture encoders, and other
heavy tooling that should not be linked into the shipped runtime executable.

The cook pipeline should transform project source assets into runtime assets:

- source textures such as PNG, PSD, TGA, or EXR into cooked texture packages
  such as KTX2 or an interim internal format
- source meshes such as OBJ into runtime mesh data
- shader source into backend-ready shader IR
- project source data into compact runtime manifests when that becomes useful

Runtime engine code should consume cooked outputs. It should not depend on this
directory.
