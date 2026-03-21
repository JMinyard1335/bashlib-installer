# Changelog
## 03/18/2026
author: Jachin Minyard

## Bug fixes
went through the project identified various simple bugs and fixed them.
1. Bad global directories `usr/` not `/usr/local`
2. Extra stdout put in update. (dont know if we should hide git clone output)
3. `rm` command failure's not effecting the rc of the function
4. Upodate could end up with the wrong install prefix.

Some of these fixes required other changes like now all logging functions are directed to `stdout`
This avoids them being captured in functions that grab stdout.

Tests were put in place for each of the bugs above and running `cd test && ./test_all.bash` passed.

## 03/17/2026
author: Jachin Minyard

### Structure layout changes
All command entrypoints now follow the same split architecture, and this full layout was finalized today.

1. `install`, `remove`, and `update` now use pure CLI wrappers in `libexec/`.
2. Argument parsing and command dispatch stay in `libexec/`.
3. Command logic now lives in `lib/internal/` (`bashlib_install.bash`, `bashlib_remove.bash`, `bashlib_update.bash`).
4. `update` completed the same migration today with `bashlib_update_tool` as the internal API.

This keeps all command logic in `lib/internal/` and keeps `libexec/` focused on CLI entrypoint behavior only.

### TOML module layout
The old single `toml.sh` approach is now a TOML script suite under `lib/toml/`.

1. `toml_read.bash`
2. `toml_check.bash`
3. `toml_helpers.bash`
4. `toml_err.bash`

This splits parsing, validation, and error handling into smaller internal modules.

### Library tests
Library-level tests were written/migrated today for all command internals.

1. `install` tests: `test/test_lib_install.bash`.
2. `remove` tests: `test/test_lib_remove.bash`.
3. `update` tests: `test/test_lib_update.bash`.
4. Aggregate runner updated: `test/test_all.bash` now includes install/remove/update suites.
5. `update` suite focuses on early-return/error paths without real clone operations:
   - missing tool name
   - tool not found in install paths
   - missing tool metadata file
   - missing `project.repo` in `tool.toml`
   - install failure propagation via stubbed `bashlib_install_from_repo`

This brings all three command libraries under the same testing model.

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
