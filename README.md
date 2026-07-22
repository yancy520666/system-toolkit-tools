# system-toolkit-tools

Remote tool assets for the Windows System Optimizer.

This repository stores toolbox binaries used by the desktop app. The app downloads a tool only when the user clicks the corresponding toolbox card, then verifies file size and SHA256 before launching it.

## Layout

- Release tag: `tools-v1`
- Manifest: `tools-manifest.json`
- Assets: Windows maintenance tools from `runtime/system-tools/`

`smart-dns-switcher.bat` benchmarks public IPv4 DNS resolvers, applies a selected low-latency pair, and can restore DHCP/router-provided DNS. It requires administrator privileges because it changes the active network adapter configuration.

Do not run files from this repository manually unless you trust the source and understand the tool action.
