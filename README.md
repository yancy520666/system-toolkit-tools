# system-toolkit-tools

Remote tool assets for the Windows System Optimizer.

This repository stores toolbox binaries used by the desktop app. The app downloads a tool only when the user clicks the corresponding toolbox card, then verifies file size and SHA256 before launching it.

## Layout

- Release tag: `tools-v1`
- Manifest: `tools-manifest.json`
- Assets: Windows maintenance tools from `runtime/system-tools/`

Do not run files from this repository manually unless you trust the source and understand the tool action.
