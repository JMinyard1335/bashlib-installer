# Bash Installer V2

A collection of scripts to help you manage the install, update, and removing custom bash script 
from your Linux system. Now newly rewritten for more ease of use. This is a personal project and 
probably not suited for secure development environments. The installer can add tools to one of 
two paths:

```bash
# Global (System wide)
/usr/bin
/usr/lib

# Locally (your user only)
$HOME/.local/bin
$HOME/.local/lib
```

Every tool that uses this installer will need to implement a `tool.toml` file. I know I know 
another configuration file but hey its a simple enough way to do things. I chose TOML because
it is simple enough to read and understand. an example file would be

```toml
[project]
name="myproject"
author="your name"
repo="path/to/repo"

[dependencies]
other-project="path/to/other-project/repo"

```

All dependencies must also have a tool.toml file as that is how this tool works. When
downloading the dependencies they will be installed with the 
`installer install --repo <link>` cmd

## COMMANDS

The following is the list of commands and some examples of usage. The installer itself is simply
a dispatcher similar to other tools like git here's how to get started
```bash
installer help
installer install --help
installer remove --help
installer update --help
```

### Install

Used to install a project to path either locally or globally. To uses on your own project you must
lay out the project as follows:
```
project/
	project		# script or executable
	tool.toml	# metadata file.
	lib/		# place for additional files and lib
```

Usage:
```bash
installer install [opts] <path-to-tool>
```

Examples: 
```bash
installer install --help						# print help info
installer install $HOME/Projects/my-project	    # local install
installer install --global ./Myproject			# global install
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

Uses the tools metadata file `tool.toml` to clone the repo and install an update
from the upstream tool. It will clone the tool into a temp dir and then run the
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

To install this project we will use the project itself YAY! Start by cloning the repo with the
following command `git clone https://github.com/JMinyard1335/Bash-Installer.git installer` then
move into the new installer dir with `cd installer` grant the installer the correct permissions
with `chmod +x installer` then simply install it with itself `./installer install .` and the 
`--global` flag if you want to install it globally on the system (this requires root)

All Commands:
```bash 
git clone https://github.com/JMinyard1335/Bash-Installer.git installer
cd installer
chmod +x installer
installer install .
```

## TODO:
- [ ] implement the dependency installer.
