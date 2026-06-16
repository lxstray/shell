# simple-shell

A minimal Quickshell panel for Niri, featuring a merged bar/launcher with morphing animations.

## Dependencies

- [Niri](https://github.com/YaLTeR/niri) (window manager)
- [Quickshell](https://github.com/quickshell-mirror/quickshell) (runtime)

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
