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

## Using the installer in other projects

When creating a tool script I usually end up with an API along the lines of the following.
```bash
<tool> <function> [opts] <args>
```
so it makes sense to allow the tool to do something along the lines of 
```bash
<tool> install
<tool> update
<tool> remove
```
to this end add the following code to some where in your script when `tool install` is called
```bash
# if the tool is not installed globally or locally
local which_installer=$(which installer)
if [[ -z "$which_installer ]]; then
    printf "installer needed for project install now (y/N): "
    read -r answer

	# if the answer is not yes exit/.
    if [[ ! "$answer" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "installer not installed. exiting."
        exit 1
    fi

	# create a temp dir
	local temp_dir=""
	temp_dir="$(mktemp -d)" || {
		error "Failed to create temporary directory"
		exit 1
	}

	# attempt to clone
	git clone "$installer_repo" "$temp_dir" || {
		error "Failed to clone installer repository"
		rm -rf -- "$temp_dir"
		exit 1
	}	

	# attempt to install installer.
	"$temp_dir/installer" install "$temp_dir" || {
		error "Failed to install installer"
		rm -rf -- "$temp_dir"
		exit 1
	}

	# clean up the temp dir
	rm -rf -- "$temp_dir"

	# make sure install worked.
	which_installer="$(command -v installer)"
	[[ -z "$which_installer" ]] && {
		error "Installer still not found after installation"
		 exit 1
	}
fi
```
Yes this is quite the long script but toss it in a function or its own file and source it easy.


## TODO
- [ ] Implement the dependency installer.
