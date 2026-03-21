# Install Guide

Looking to install the installer? well you have come to the right spot. This guide will walk you through
Installing and using the `installer` CLI, auto install, and how to source it into other files. 

## Installing the Installer...LOL:

To install this project, we will use the project itself. Start by cloning the repo with the
following command:

```bash
git clone https://github.com/JMinyard1335/bashlib-installer
```

Then move into the new installer directory and grant the installer the correct permissions
The proper files should all ready have the required permissions, this is just to be safe.
The files that need to be granted executable permissions are:
- installer
- libexec/bashlib_install
- libexec/bashlib_remove
- libexec/bashlib_update

```bash
cd bashlib-installer
chmod +x installer libexec/bashlib_*
```

Finally, install it with itself:

```bash
./installer install .
```

Use the `--global` flag if you want to install it globally on the system (this requires root).

All commands:

```bash
git clone https://github.com/JMinyard1335/bashlib-installer
cd bashlib-installer
chmod +x installer libexec/bashlib_*
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

## Installing the installer from your script

You can install the installer locally without much trouble most of the time.
To that end, add the following code somewhere in your script when `tool install` is called.
This script will install the installer from its repo to the local install on the system. 

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

The other thing you could do to avoid this massive chunk of code is add the following as a guard
to keep your tool from running (install, remove, update) if bashlib-installer is not on the system.

```bash
if ! which installer; then
	echo "My installer is need for this feature to work. It can be found over at:"
	echo -e "\t\e[36mhttps://github.com/JMinyard1335/bashlib-installer\e[0m"
	echo "It will handle all the installations, updates, and removal of my tools."
	echo "If you want an option to just install it from the CLI go to github check for an issue"
	echo "if and only if there is not an issue and you dont see it in the change logs then open one."
	exit 1
fi
```

Which will just tell the user to go manually install the installer its a bit shorter and makes the user go find the tool and hopefully they will 
read the README to know how it works.


### Sourcing the Installer Lib (Best way to use in scripts)

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
While you could just call something like `installer install $var` in your script, it is faster to source.
Sourcing the project will give you access to the following API in your code.
see [here](API.md) for the full API.

