# API reference sheet

## Installer CLI.

The following is a list of commands and some examples of usage. The installer itself is simply
a dispatcher similar to other tools like git. Here's how to get started:

```bash
installer help
installer install --help
installer remove --help
installer update --help
```

### Install

Used to install a project to a path, either locally or globally. To install something globally, you need access to root,
aka `sudo`.

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


