# Bash Installer V2

A collection of scripts to help you manage installing, updating, and removing custom bash scripts
from your Linux system. It was newly rewritten for easier use. This is a personal project and is
probably not suited for secure development environments. The installer can add tools to one of
two paths:

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

If installing or running any command globally you need access to root on your system usually through `sudo`.
Every tool that uses this installer must include a `tool.toml` file. I know, I know, another
configuration file, but it's a simple way to handle metadata. I chose TOML because
it is easy to read and understand. An example file would be:

```toml
[project]
tool="myproject"
repo="path/to/repo"

[dependencies]
other-project="path/to/other-project/repo"

```

You can add additional metadata if you want, but it is not currently used by the installer.

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

Used to install a project to a path, either locally or globally. To install something globally you need access to root 
aka `sudo`. To use it on your own project, you must lay out the project as follows:

```
project/
	project		# script or executable
	tool.toml	# metadata file
	lib/		# place for additional files and libraries
	libexec/	# place for additional subcommands

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

All commands:

```bash
git clone https://github.com/JMinyard1335/Bash-Installer.git installer
cd installer
chmod +x installer
installer install .
```

## Using the installer in other projects

When creating a tool script, I usually end up with an API along the lines of the following:

```bash
<tool> <function> [opts] <args>
```

So it makes sense to allow the tool to do something like:

```bash
<tool> install
<tool> update
<tool> remove
```

### Installing the installer from your script

You can install the installer locally without much trouble most of the time.
To that end, add the following code somewhere in your script when `tool install` is called.

```bash
# if the tool is not installed globally or locally
local which_installer=$(which installer)
if [[ -z "$which_installer" ]]; then
    printf "installer needed for project install now (y/N): "
    read -r answer

	# if the answer is not yes, exit.
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

	# attempt to install installer
	"$temp_dir/installer" install "$temp_dir" || {
		error "Failed to install installer"
		rm -rf -- "$temp_dir"
		exit 1
	}

	# clean up the temp dir
	rm -rf -- "$temp_dir"

	# make sure install worked
	which_installer="$(command -v installer)"
	[[ -z "$which_installer" ]] && {
		error "Installer still not found after installation"
		exit 1
	}
fi
```

Yes, this is quite the long script, but toss it in a function or its own file and source it. Easy.
The code above simply tells the user the installer is required and asks if they want to install it.
If they answer no, the program exits. If not, the installer is installed and you are good to go.

### Sourcing the Installer Lib

If the installer is installed, you can easily source it with the following:

```bash
if [[ -f "${HOME}/.local/lib/installer/bashlib_installer.bash" ]]; then
    source "${HOME}/.local/lib/installer/bashlib_installer.bash"
elif [[ -f "/usr/local/lib/installer/bashlib_installer.bash" ]]; then
    source "/usr/local/lib/installer/bashlib_installer.bash"
else
    echo "couldn't source the installer."
	exit 1
fi
```

This will give you access to the underlying API used by the CLI tool:

```bash
bashlib_install_dependencies <path-to-source-dir> <install-path> <debug-level>
bashlib_install_from_repo <url-to-repo> <install-path> <debug-level>
bashlib_install_from_source <path-to-source-dir> <install-path> <debug-level>
bashlib_update_tool <tool-name>
bashlib_remove_tool <tool-name>
```

## Contributing

If you want to contribute, feel free to report bugs or other issues you find. For security-related concerns,
please contact me through email so I can fix the issue and release a patch. If you feel generous and want to
add new features or fix bugs yourself, feel free to make a pull request. Please keep to the current coding
style where you can. This includes file conventions.

- scripts that you run have no extension
- scripts you source are `*.bash`

We could use `.sh`, but since a lot of bash is used, let's just call them `.bash`.
Code you write for the libraries should be tested and have tests in `test/`.
These tests should make sure that:

- input is validated
- all error handling works
- proper execution of the happy path

For certain things like testing cloning, that seems a bit much. As long as other tests are in place, it is good.
This is simply a way to test future changes against defined behaviors.

## Testing

To run the tests for the project, simply:

```bash
cd <project-dir>/test
./test_all.bash
```

This is a fail-first testing suite. If any test goes wrong along the way, it errors so you can fix the issue before running again.
This is just my preferred way to test scripts like this. Code a little, test a little, fix the error, and move on.
When writing tests, if you are a contributor, there is a file `test_asserts.bash` which gives you access to a lot
of simple wrappers for tests that print a message on error and quit. Stick to using these, even if you wrap them.
If you find they are not enough, consider adding what you need to `test_asserts.bash`. Just make sure you follow
the naming convention and that the file exits on failure and returns 0 on success.

