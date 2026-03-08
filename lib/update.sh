#!/usr/bin/env bash
# Used to update a tool from its repo
#
# When given a repo this command will clone the repo
# into a temp dir, cd into that dir, and run install on it.
#
# Examples:
#   installer update <repo>
#   installer update --global <repo>
#   installer update --install <path> <repo>

UPDATE_INSTALL_PATH=""
UPDATE_REPO=""
UPDATE_GLOBAL=false
UPDATE_USE_TEMP=true

_update_usage() {
    cat <<EOF
Usage:
  installer update [options] <repo>

Options:
  -g, --global			Install globally after cloning
  -c, --clone-dir	<dir>	Clone into this directory instead of a temp dir
  --help			Show this help message

Examples:
  installer update https://github.com/user/tool.git
  installer update --global https://github.com/user/tool.git
  installer update --install /tmp/tool-src https://github.com/user/tool.git
EOF
}

_update_error() {
    printf '[Error]: %s\n' "$*" >&2
}

_update_warn() {
    printf '[Warn]: %s\n' "$*" >&2
}

_update_info() {
    printf '[Update]: %s\n' "$*"
}

_update_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help)
                _update_usage
                exit 0
                ;;
            -g|--global)
                UPDATE_GLOBAL=true
                shift
                ;;
            -c|--clone-dir)
                [[ -n "${2:-}" ]] || {
                    _update_error "--install requires a directory path"
                    exit 1
                }
                UPDATE_INSTALL_PATH="$2"
                UPDATE_USE_TEMP=false
                shift 2
                ;;
            --)
                shift
                break
                ;;
            -*)
                _update_error "Unknown option: $1"
                _update_usage
                exit 1
                ;;
            *)
                if [[ -n "$UPDATE_REPO" ]]; then
                    _update_error "Too many arguments: $1"
                    _update_usage
                    exit 1
                fi
                UPDATE_REPO="$1"
                shift
                ;;
        esac
    done

    if [[ $# -gt 0 ]]; then
        if [[ -n "$UPDATE_REPO" ]]; then
            _update_error "Too many arguments: $1"
            _update_usage
            exit 1
        fi
        UPDATE_REPO="$1"
        shift
    fi

    [[ -n "$UPDATE_REPO" ]] || {
        _update_error "Missing repo URL"
        _update_usage
        exit 1
    }
}

_update_clone_dir() {
    if [[ "$UPDATE_USE_TEMP" == true ]]; then
        mktemp -d
    else
        printf '%s\n' "$UPDATE_INSTALL_PATH"
    fi
}

_update_run() {
    local clone_dir install_args=()

    clone_dir="$(_update_clone_dir)" || {
        _update_error "Failed to create clone directory"
        exit 1
    }

    if [[ "$UPDATE_USE_TEMP" == false ]]; then
        mkdir -p -- "$clone_dir" || {
            _update_error "Failed to create install directory: $clone_dir"
            exit 1
        }

        # Optional safety: warn if non-empty
        if [[ -n "$(find "$clone_dir" -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
            _update_warn "Directory '$clone_dir' is not empty; git may fail if it is not a fresh clone destination."
        fi
    fi

    _update_info "Cloning $UPDATE_REPO into $clone_dir"

    if ! git clone -- "$UPDATE_REPO" "$clone_dir"; then
        _update_error "git clone failed"
        [[ "$UPDATE_USE_TEMP" == true ]] && rm -rf -- "$clone_dir"
        exit 1
    fi

    _update_info "Clone finished."

    [[ "$UPDATE_GLOBAL" == true ]] && install_args+=(--global)

    (
        cd -- "$clone_dir" || exit 1
        _update_info "Running install from $(pwd)"
        install_cmd "${install_args[@]}" .
    )
    local status=$?

    if [[ "$UPDATE_USE_TEMP" == true ]]; then
        _update_info "Cleaning up temporary directory."
        rm -rf -- "$clone_dir" || _update_warn "Failed to remove temp directory: $clone_dir"
    fi

    if [[ $status -ne 0 ]]; then
        _update_error "Update failed during install step"
        exit "$status"
    fi

    _update_info "Update complete."
}

update_cmd() {
    _update_parse_args "$@"
    _update_run
}
