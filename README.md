# Bash Installer V2

A collection of scripts to help you manage installing, updating, and removing custom bash scripts
from your Linux system. Newly rewritten for easier use, this is a personal project and
is probably not suited for secure development environments. The installer can add tools to one of
two paths:

```bash
# Global (system-wide)
/usr/bin
/usr/lib

# Locally (your user only)
$HOME/.local/bin
$HOME/.local/lib
```

Every tool that uses this installer must include a `tool.toml` file. I know, I know another
configuration file, but it's a simple way to handle metadata. I chose TOML because
it is easy to read and understand. An example file would be:

```toml
[project]
name="myproject"
author="your name"
repo="path/to/repo"

[dependencies]
other-project="path/to/other-project/repo"

```

All dependencies must also have a `tool.toml` file, as that is how this tool works. When
downloading dependencies, they will be installed with the
`installer install --repo <link>` command.

## COMMANDS

The following is a list of commands and some examples of usage. The installer itself is simply
a dispatcher similar to other tools like git. Here's how to get started:
```bash
installer help
installer install --help
installer remove --help
installer update --help
```

### Install

Used to install a project to a path either locally or globally. To use it on your own project, you must
lay out the project as follows:
```
project/
	project		# script or executable
	tool.toml	# metadata file
	lib/		# place for additional files and libraries
```

Usage:
```bash
installer install [opts] <path-to-tool>
```

Examples:
```bash
installer install --help                        # print help info
installer install $HOME/Projects/my-project     # local install
installer install --global ./Myproject          # global install
```

### Remove

Used to remove the given tool from the path.
Usage:
```bash
installer remove [opts] <tool name>
```

Examples:
```bash
installer remove --help
installer remove my-tool
```

### Update

Uses the tool's metadata file `tool.toml` to clone the repo and install an update
from the upstream tool. It will clone the tool into a temporary directory and then run the
installer on it.

Usage:
```bash
installer update [opts] <tool name>
```

Examples:
```bash
installer update installer
```

## Installing the Installer...lol

To install this project, we will use the project itself. Start by cloning the repo with the
following command:
```bash
git clone https://github.com/JMinyard1335/Bash-Installer.git installer
```
Then move into the new installer directory and grant the installer the correct permissions:
```bash
cd installer
chmod +x installer
```
Finally, install it with itself:
```bash
./installer install .
```
Use the `--global` flag if you want to install it globally on the system (this requires root).

All Commands:
```bash
git clone https://github.com/JMinyard1335/Bash-Installer.git installer
cd installer
chmod +x installer
installer install .
```

## TODO
- [ ] Implement the dependency installer.
