# Bash Installer

A collection of scripts to help you manage the install, update, and removing custom bash script 
from your linux system. This is a personal project and probably not suited for secure development
enviroments. The installer can add tools to one of two paths
```bash
# Global (System wide)
/usr/bin
/usr/lib

# Locally (your user only)
$HOME/.local/bin
$HOME/.local/lib
```

## COMMANDS

The following is the list of commands and some examples of usage. The installer itself is simply
a dispatcher similar to other tools like git heres how to get started
```bash
installer help
installer install --help
installer remove --help
installer update --help
```

### Install

Used to install a project to path either locally or globaly. To uses on your own project you must
lay out the project as follows:
```
project/
	project # script or executable
	lib/	# place for additional files and lib
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
installer remove --global my-tool
```

### Update

Used to update the tool from the given repo. This is a joke of an updater currently and more
of a installer for a given repo except it removes the clone after the install is done. I plan 
to try and update it to make it more of an updater, but that will probably come later with some
form of tool.txt that provides instructions.

Usage: 
```bash
installer update [opts] <reop-link>
```

Examples:
```bash
installer update "https://github.com/JMinyard1335/Bash-Installer"
```

## Installing the Installer...lol

To install this project we will use the project itself YAY! Start by cloning the repo with the
following commnad `git clone https://github.com/JMinyard1335/Bash-Installer.git installer` then
move into the new installer dir with `cd installer` grant the installer the correct premissions
with `chmod +x installer` then simply install it with itself `./installer install .` and the 
`--global` flag if you want to install it globally on the system (this requires root)


All Commands:
```bash 
git clone https://github.com/JMinyard1335/Bash-Installer.git installer
cd installer
chmod +x installer
installer install .
```
