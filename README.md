# BashLib Installer

Part of my bashlib toolchain, this handles core package actions for Bash projects:

- install
- remove
- update

The goal is simple: stop copy-pasting scripts between repos and make Bash projects reusable.

This tool is standalone and does not require other bashlib tools to install.

## Table of Contents

- [Quick Start](#quick-start)
- [Commands](#commands)
- [Install Paths](#install-paths)
- [BAPs (bash packages)](#baps-bash-packages)
- [Project Layout](#project-layout)
- [Docs](#docs)
- [Testing](#testing)
- [Contributing](#contributing)

## Quick Start

```bash
git clone "https://github.com/JMinyard1335/bashlib-installer.git"
cd bashlib-installer
chmod +x ./installer
./installer help
./installer install .
```

For global install:

```bash
sudo ./installer install --global .
```

For full install instructions, see [Install.md](docs/INSTALL.md).


## Commands

```bash
installer help
installer install --help
installer remove --help
installer update --help
installer create --help
```

For complete CLI usage and sourceable API docs, see [API.md](docs/API.md).

## Install Paths

The installer uses one of two target prefixes:

```bash
# Global (system-wide)
/usr/local/bin
/usr/local/lib
/usr/local/libexec

# Locally (your user only)
$HOME/.local/bin
$HOME/.local/lib
$HOME/.local/libexec
```

Make sure the matching `bin` path is on your `PATH`.

Global install needs root/sudo.


## BAPs (bash packages)

I call them `baps` for now. A bap requires a `tool.toml` file.
Yes, another config file, but TOML keeps metadata readable and simple.
Create a new package template consider my other project: \
\
[bashlib-create](https:github.com/JMinyard1335/bashlib-create)

An example tool.toml file would be:

```toml
[project]
tool="myproject"
repo="https://github.com/you/myproject"

[dependencies]
other-project="https://github.com/you/other-project"

```

Dependencies should also have a `tool.toml` so they can be installed and updated correctly.

## Project Layout

Expected structure:

```text
project/
  <tool>            # script or executable
  tool.toml         # metadata file
  lib/              # sourceable library files
    <tool>.bash
    internal/
  libexec/          # subcommand executables
```

To help create the project structure and other script templates checkout [bashlib-create](https://github.com/JMinyard1335/bashlib-create)

If you are new to linux or what these folders are for then here's a quick explanation as I understand it.

- lib: holds files that should be sourced.
- libexec: holds subcommands or files that get executed.
- bin: Main executable and programs you run.

I didn't choose to include a bin and the root folder just holds the main executable aka the tool.


## Docs


- `INSTALL.md`: install this tool to your system.
- `API.md`: CLI reference + sourceable Bash API.
- `CONTRIBUTING.md`: contribution workflow, coding style, and PR expectations.


## Testing

Run the full suite:

```bash
./test/test_all.bash
```

The tests are fail-first and stop at the first failure.

## Contributing

If you want to contribute, check [CONTRIBUTING.md](CONTRIBUTING.md) for setup, guidelines, and checklist.


