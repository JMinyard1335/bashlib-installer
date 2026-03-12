#!/usr/bin/env bash
# Used in the installer tool to install the desired path to your system.
#
# Uses the tool.toml file to get the tool file name.
#
# Local installs go to:
#   ~/.local/bin
#   ~/.local/lib
#
# Global installs go to:
#   /usr/bin
#   /usr/lib

source ./read-toml.sh

INSTALL_LOCAL_BIN="$HOME/.local/bin"
INSTALL_LOCAL_LIB="$HOME/.local/lib"

INSTALL_GLOBAL_BIN="/usr/bin"
INSTALL_GLOBAL_LIB="/usr/lib"

INSTALL_GLOBAL=false
INSTALL_PATH=""

_install_usage() {
    cat <<EOF
Usage:
  installer install [options] <path>

Options:
  -g, --global     Install globally
  --help           Show this help message

Behavior:
  If <path> is a file:
    install it to bin as an executable.

  If <path> is a directory:
    expects a project layout like:
      <project-root>/<tool-name>
      <project-root>/lib/
    installs:
      <tool-name> -> bin
      lib/        -> lib/<tool-name>/

Examples:
  installer install ./myscript
  installer install ./installer
  installer install --global ./installer
EOF
}

_install_error() {
    printf '[Error]: %s\n' "$*" >&2
}


_install_warn() {
    printf '[Warn]: %s\n' "$*" >&2
}


_install_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help)
                _install_usage
                exit 0
                ;;
            -g|--global)
                INSTALL_GLOBAL=true
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                _install_error "Unknown option: $1"
                _install_usage
                exit 1
                ;;
            *)
                if [[ -n "$INSTALL_PATH" ]]; then
                    _install_error "Too many arguments: $1"
                    _install_usage
                    exit 1
                fi
                INSTALL_PATH="$1"
                shift
                ;;
        esac
    done

    if [[ $# -gt 0 ]]; then
        if [[ -n "$INSTALL_PATH" ]]; then
            _install_error "Too many arguments: $1"
            _install_usage
            exit 1
        fi
        INSTALL_PATH="$1"
        shift
    fi

    [[ -n "$INSTALL_PATH" ]] || {
        _install_error "Missing install path."
        _install_usage
        exit 1
    }
}


_install_set_targets() {
    if [[ "$INSTALL_GLOBAL" == true ]]; then
        INSTALL_BIN_ROOT="$INSTALL_GLOBAL_BIN"
        INSTALL_LIB_ROOT="$INSTALL_GLOBAL_LIB"
    else
        INSTALL_BIN_ROOT="$INSTALL_LOCAL_BIN"
        INSTALL_LIB_ROOT="$INSTALL_LOCAL_LIB"
    fi
}


_install_single_file() {
    local src="$1"
    local name dest

    name="$(basename -- "$src")"
    dest="$INSTALL_BIN_ROOT/$name"

    printf "[Install]: Installing file %s -> %s\n" "$src" "$dest"

    command install -Dm755 -- "$src" "$dest" || {
        _install_error "Failed to install file '$src'"
        exit 1
    }

    printf "[Install]: Installed executable to %s\n" "$dest"
}


_install_project_dir() {
    local project_root="$1"
    local tool_name entry_src entry_dest lib_src lib_dest

    tool_name="$(basename -- "$project_root")"
    entry_src="$project_root/$tool_name"
    lib_src="$project_root/lib"

    [[ -f "$entry_src" ]] || {
        _install_error "Project install expects entry script: $entry_src"
        exit 1
    }

    entry_dest="$INSTALL_BIN_ROOT/$tool_name"
    lib_dest="$INSTALL_LIB_ROOT/$tool_name"

    printf "[Install]: Installing project '%s'\n" "$tool_name"
    printf "[Install]: Entry -> %s\n" "$entry_dest"

    command install -Dm755 -- "$entry_src" "$entry_dest" || {
        _install_error "Failed to install entry script '$entry_src'"
        exit 1
    }

    if [[ -d "$lib_src" ]]; then
        printf "[Install]: Library -> %s\n" "$lib_dest"

        mkdir -p -- "$INSTALL_LIB_ROOT" || {
            _install_error "Failed to create lib root '$INSTALL_LIB_ROOT'"
            exit 1
        }

        rm -rf -- "$lib_dest" || {
            _install_error "Failed to clear previous library dir '$lib_dest'"
            exit 1
        }

        cp -r -- "$lib_src" "$lib_dest" || {
            _install_error "Failed to copy library dir '$lib_src' to '$lib_dest'"
            exit 1
        }

        printf "[Install]: Installed library to %s\n" "$lib_dest"
    else
        _install_warn "No lib directory found at $lib_src"
    fi

    printf "[Install]: Project '%s' installed successfully.\n" "$tool_name"
}


_install_run() {
    local src

    src="$(realpath -- "$INSTALL_PATH")" || {
        _install_error "Could not resolve path: $INSTALL_PATH"
        exit 1
    }

    [[ -e "$src" ]] || {
        _install_error "Path does not exist: $src"
        exit 1
    }

    _install_set_targets

    if [[ -f "$src" ]]; then
        _install_single_file "$src"
        return 0
    fi

    if [[ -d "$src" ]]; then
        _install_project_dir "$src"
        return 0
    fi

    _install_error "Unsupported path type: $src"
    exit 1
}


install_cmd() {
    _install_parse_args "$@"
    _install_run
}
