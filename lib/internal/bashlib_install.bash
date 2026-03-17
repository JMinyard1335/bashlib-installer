#!/usr/bin/env bash
# Source file for install logic

## SOURCE GUARD bashlib_install.bash -----------------------------------------------------
if [[ -v installer_install_sourced ]]; then
    return 0
fi
installer_install_sourced=1

BASHLIB_INSTALL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${BASHLIB_INSTALL_DIR}/../toml/toml_read.bash"
source "${BASHLIB_INSTALL_DIR}/installer_err.bash"
# source "${BASHLIB_INSTALL_DIR}/installer_helpers.bash"
source "${BASHLIB_INSTALL_DIR}/installer_format.bash"


## ---------------------------------------------------------------------------------------

## Install state -------------------------------------------------------------------------
## Used to avoid dependency cycles / duplicate installs in a single run.
## Keys in [dependencies] are expected to match the dependency tool name.
if ! declare -p _bashlib_install_seen_tools >/dev/null 2>&1; then
    declare -gA _bashlib_install_seen_tools=()
fi

if ! declare -p _bashlib_install_seen_urls >/dev/null 2>&1; then
    declare -gA _bashlib_install_seen_urls=()
fi
## ---------------------------------------------------------------------------------------


# bashlib_install_from_source <path to source dir> <install path> <debug_level>
#
# Used to install a project from a local directory on your system. this project will be
# installed to the install path. and debug info will be printed based off debug_level.
bashlib_install_from_source() {
    local source_dir="" install_dir="" debug="" tool_name="" status=0

    if [[ "$#" -lt 2 || "$#" -gt 3 ]]; then
        installer_error "Invalid number of arguments given"
        return 1
    fi

    source_dir="$1"
    install_dir="$2"
    debug="${3:-0}"

    if [[ ! -d "$source_dir" ]]; then
        installer_error "bashlib_install_from_source: Source directory not found - $source_dir"
        return 1
    fi

    if [[ ! -f "${source_dir}/tool.toml" ]]; then
        installer_error "bashlib_install_from_source: Missing tool.toml in: $source_dir"
        return 1
    fi

    _bashlib_check_install_path "$install_dir" || return 1

    if ! tool_name="$(toml_read_key "${source_dir}/tool.toml" "project" "tool")"; then
        installer_error "Failed to determine tool name from ${source_dir}/tool.toml"
        return 1
    fi

    if [[ -z "$tool_name" ]]; then
        installer_error "Failed to determine tool name from ${source_dir}/tool.toml"
        return 1
    fi

    # If this tool is already in the current dependency chain, do not recurse into it again.
    if [[ -n "${_bashlib_install_seen_tools[$tool_name]}" ]]; then
        [[ "$debug" -ge 1 ]] && installer_warn "Tool '${tool_name}' already being processed, skipping to avoid cycle"
        return 0
    fi

    _bashlib_install_seen_tools["$tool_name"]=1

    bashlib_install_dependencies "$source_dir" "$install_dir" "$debug" || return 1

    [[ "$debug" -ge 1 ]] && installer_logln "Installing ${tool_name}: $source_dir -> $install_dir"

    _bashlib_move_to_bin "$source_dir" "$install_dir" "$tool_name" "$debug" || status=1
    _bashlib_move_to_lib "$source_dir" "$install_dir" "$tool_name" "$debug" || status=1
    _bashlib_move_to_libexec "$source_dir" "$install_dir" "$tool_name" "$debug" || status=1

    return "$status"
}

# bashlib_install_from_repo <url to repo> <install path> <debug_level>
#
# Used to install a project from a remote repo on something like github.
# This way of installing will not leave behind a source dir as it will be
# cloned into a temp dir and removed after the installation.
bashlib_install_from_repo() {
    local source_url="" install_dir="" debug=""
    local temp_root="" clone_dir="" status=0

    if [[ "$#" -lt 2 || "$#" -gt 3 ]]; then
        echo "bashlib_install_from_repo: Invalid argument count." >&2
        return 1
    fi

    source_url="$1"
    install_dir="$2"
    debug="${3:-0}"

    _bashlib_check_install_path "$install_dir" || return 1

    if [[ -n "${_bashlib_install_seen_urls[$source_url]}" ]]; then
        [[ "$debug" -ge 1 ]] && echo "[install]: Repo already being processed, skipping to avoid cycle: $source_url"
        return 0
    fi

    if ! command -v git >/dev/null 2>&1; then
        echo "bashlib_install_from_repo: git is required but was not found." >&2
        return 1
    fi

    _bashlib_install_seen_urls["$source_url"]=1

    temp_root="$(mktemp -d)" || {
        echo "bashlib_install_from_repo: Failed to create temp dir." >&2
        return 1
    }
    clone_dir="${temp_root}/project"

    [[ "$debug" -ge 1 ]] && echo "[install]: Installing from: $source_url -> $install_dir"

    if ! git clone --depth 1 -- "$source_url" "$clone_dir"; then
        echo "bashlib_install_from_repo: Failed to clone repo: $source_url" >&2
        [[ -n "$temp_root" && -d "$temp_root" ]] && rm -rf -- "$temp_root"
        return 1
    fi

    if [[ ! -f "${clone_dir}/tool.toml" ]]; then
        echo "bashlib_install_from_repo: Cloned repo does not contain tool.toml" >&2
        [[ -n "$temp_root" && -d "$temp_root" ]] && rm -rf -- "$temp_root"
        return 1
    fi

    bashlib_install_from_source "$clone_dir" "$install_dir" "$debug"
    status="$?"

    [[ -n "$temp_root" && -d "$temp_root" ]] && rm -rf -- "$temp_root"
    return "$status"
}

# bashlib_install_dependencies <path to source dir> <install path> <debug_level>
#
# Reads [dependencies] from <source_dir>/tool.toml and installs any missing
# dependencies by calling bashlib_install_from_repo on each dependency URL.
#
# Dependency keys are expected to match the installed tool/executable name.
bashlib_install_dependencies() {
    local source_dir="" install_dir="" debug=""
    local tool_toml="" dep_name="" dep_url=""
    local found_any=0

    if [[ "$#" -lt 2 || "$#" -gt 3 ]]; then
        echo "bashlib_install_dependencies: Invalid argument count." >&2
        return 1
    fi

    source_dir="$1"
    install_dir="$2"
    debug="${3:-0}"
    tool_toml="${source_dir}/tool.toml"

    if [[ ! -d "$source_dir" ]]; then
        echo "bashlib_install_dependencies: Source directory not found: $source_dir" >&2
        return 1
    fi

    if [[ ! -f "$tool_toml" ]]; then
        echo "bashlib_install_dependencies: Missing tool.toml: $tool_toml" >&2
        return 1
    fi

    _bashlib_check_install_path "$install_dir" || return 1

    if ! command -v git >/dev/null 2>&1; then
        echo "bashlib_install_dependencies: git is required but was not found." >&2
        return 1
    fi

    [[ "$debug" -ge 1 ]] && echo "[install]: Resolving dependencies from $tool_toml"

    while IFS=$'\t' read -r dep_name dep_url; do
        [[ -z "$dep_name" || -z "$dep_url" ]] && continue
        found_any=1

        # Skip if already installed in the target prefix.
        if [[ -x "${install_dir}/bin/${dep_name}" ]]; then
            [[ "$debug" -ge 1 ]] && echo "[install]: Dependency '${dep_name}' already installed, skipping"
            continue
        fi

        # Skip if already in the current install chain.
        if [[ -n "${_bashlib_install_seen_tools[$dep_name]}" ]]; then
            [[ "$debug" -ge 1 ]] && echo "[install]: Dependency '${dep_name}' already being processed, skipping to avoid cycle"
            continue
        fi

        bashlib_install_from_repo "$dep_url" "$install_dir" "$debug" || return 1
    done < <(toml_read_table "$tool_toml" "dependencies" 2>/dev/null || true)

    if [[ "$found_any" -eq 0 ]]; then
        [[ "$debug" -ge 2 ]] && echo "[debug]: No dependencies found."
    fi

    return 0
}

# bashlib_install_project [opts] <project path>
# bashlib_install_project -r -d 1 "url to project"
# bashlib_install_project -d 3 ./path/to/project
bashlib_install_project() {
    return 1
}

## Helper functions ----------------------------------------------------------------------

# _bashlib_check_install_path <install path>
# install path must be one of:
#   $HOME/.local
#   /usr/local
_bashlib_check_install_path() {
    local install_path=""

    if [[ "$#" -ne 1 ]]; then
        echo "_bashlib_check_install_path: Invalid argument count." >&2
        return 1
    fi

    install_path="$1"

    case "$install_path" in
        "$HOME/.local"|"/usr/local")
            return 0
            ;;
        *)
            echo "_bashlib_check_install_path: invalid install path given: $install_path" >&2
            return 1
            ;;
    esac
}

# _bashlib_move_to_bin <path to tool> <install path> <tool name> <?debug>
_bashlib_move_to_bin() {
    local tool_path="" install_path="" tool_name="" debug=""
    local bin_path="" tool_script_path=""

    if [[ "$#" -lt 3 || "$#" -gt 4 ]]; then
        echo "_bashlib_move_to_bin: Invalid argument count." >&2
        return 1
    fi

    tool_path="$1"
    install_path="$2"
    tool_name="$3"
    debug="${4:-0}"

    _bashlib_check_install_path "$install_path" || return 1

    if [[ ! -d "$tool_path" ]]; then
        echo "_bashlib_move_to_bin: Unable to find tool source dir: $tool_path" >&2
        return 1
    fi

    bin_path="${install_path}/bin"
    tool_script_path="${tool_path}/${tool_name}"

    mkdir -p -- "$bin_path" || return 1

    if [[ -f "$tool_script_path" ]]; then
        install -m 755 -t "$bin_path" -- "$tool_script_path" || return 1
        return 0
    fi

    echo "_bashlib_move_to_bin: Missing tool executable: $tool_script_path" >&2
    return 1
}

# _bashlib_move_to_lib <path to tool> <install path> <tool name> <?debug>
_bashlib_move_to_lib() {
    local tool_path="" install_path="" tool_name="" debug=""
    local dest=""

    if [[ "$#" -lt 3 || "$#" -gt 4 ]]; then
        echo "_bashlib_move_to_lib: Invalid argument count." >&2
        return 1
    fi

    tool_path="$1"
    install_path="$2"
    tool_name="$3"
    debug="${4:-0}"

    _bashlib_check_install_path "$install_path" || return 1

    if [[ ! -d "$tool_path" ]]; then
        echo "_bashlib_move_to_lib: Unable to find tool source dir: $tool_path" >&2
        return 1
    fi

    if [[ ! -f "${tool_path}/tool.toml" ]]; then
        echo "_bashlib_move_to_lib: Missing tool metadata: ${tool_path}/tool.toml" >&2
        return 1
    fi

    dest="${install_path}/lib/${tool_name}"
    mkdir -p -- "$dest" || return 1

    if [[ -d "${tool_path}/lib" ]]; then
        cp -r -- "${tool_path}/lib/." "$dest" || return 1
    else
        [[ "$debug" -ge 2 ]] && echo "[debug]: No lib/ directory for ${tool_name}"
    fi

    install -m 644 -- "${tool_path}/tool.toml" "${dest}/tool.toml" || return 1
    return 0
}

# _bashlib_move_to_libexec <path to tool> <install path> <tool name> <?debug>
_bashlib_move_to_libexec() {
    local tool_path="" install_path="" tool_name="" debug=""
    local dest=""

    if [[ "$#" -lt 3 || "$#" -gt 4 ]]; then
        echo "_bashlib_move_to_libexec: Invalid argument count." >&2
        return 1
    fi

    tool_path="$1"
    install_path="$2"
    tool_name="$3"
    debug="${4:-0}"

    _bashlib_check_install_path "$install_path" || return 1

    if [[ ! -d "$tool_path" ]]; then
        echo "_bashlib_move_to_libexec: Unable to find tool source dir: $tool_path" >&2
        return 1
    fi

    if [[ ! -d "${tool_path}/libexec" ]]; then
        [[ "$debug" -ge 2 ]] && echo "[debug]: No libexec/ directory for ${tool_name}"
        return 0
    fi

    dest="${install_path}/libexec/${tool_name}"
    mkdir -p -- "$dest" || return 1

    cp -r -- "${tool_path}/libexec/." "$dest" || return 1
    return 0
}

_bashlib_move_to_man() {
    echo -e "\e[1;33m[Warn]:\e[0m Not implemented man pages will not be installed with the project."
    echo "     please see the projects github page for more info and updates."
    return 0
}
## END HELPER FUNCTIONS ------------------------------------------------------------------
