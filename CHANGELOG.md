# Changelog

## 03/12/2026
author: Jachin Minyard
### tool.toml file
began swapping the installer tools to uses a tool.toml file to store metadata about the project.
These toml files will hold the following info in the current itteration. 
```toml
[project]
name=<name of tool script>
author=<name of author>
repo=<download location>

[dependencies]
tool1=<download location>
tool2=<download location>
# etc...
```
for this the following script has been added into `lib/toml.sh` it adds the following api 
```bash
toml_r <file> <table> <field> # reads from toml file
toml_w <file> <table> <value> # writes to toml file
```

### Commands
#### Install 
1. can now be given a repos url
   - cloned into a temp dir that will be cleaned up.
   - tools installed this way must have a tool.toml file in there root.
```bash
installer install --repo <url>
```

#### Remove
1. Got rid of the following options as they provided nothing
   - [--search]
   - [--lib, --bin]
   - [--global]

#### Update
1. now more of a real updater.
2. takes in tool name
3. searches install paths for the tool.
4. if it finds the tool searches its lib/tool/ for tool.toml
5. pulls the repo from the meta data.
6. clones and installs the update.
