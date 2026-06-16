# simple-shell

A minimal Quickshell panel for Niri, featuring a merged bar/launcher with morphing animations.

## Dependencies

- [Niri](https://github.com/YaLTeR/niri) (window manager)
- [Quickshell](https://github.com/quickshell-mirror/quickshell) (runtime)
- `upower` — battery status (most distros include this)
- `powerprofilesctl` — for power plan switching (part of `power-profiles-daemon`)
- `Material Symbols Rounded` font — for icons (included in most font packages)

## Installation

Clone into Quickshell config directory:

```
mkdir -p ~/.config/quickshell
git clone ... ~/.config/quickshell/simple-shell
```

## Usage

Start the shell:

```
qs -c simple-shell
```

Toggle the launcher via IPC:

```
qs -c simple-shell ipc call launcher onSignalTriggered toggle
```
