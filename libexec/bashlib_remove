#!/usr/bin/env bash
# Remove an installed tool from standard install locations.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/installer-color.sh"

TOOL_NAME=''

_remove_usage() {
    cat <<EOF
Usage:
  remove <project-name>

Options:
  --help    Show this help message

Examples:
  remove cli-builder
EOF
}

_remove_error() {
    printf '%b[Error]:%b %s\n' "$RED" "$RESET" "$*" >&2
}

_remove_warn() {
    printf '%b[Warn]:%b %s\n' "$YELLOW" "$RESET" "$*" >&2
}

_remove_info() {
    printf '%b[Remove]:%b %s\n' "$GREEN" "$RESET" "$*"
}

_remove_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help)
                _remove_usage
                exit 0
                ;;
            --)
                shift
                break
                ;;
            -*)
                _remove_error "Unknown option: $1"
                _remove_usage
                exit 1
                ;;
            *)
                if [[ -n "$TOOL_NAME" ]]; then
                    _remove_error "Too many arguments: $1"
                    _remove_usage
                    exit 1
                fi
                TOOL_NAME="$1"
                shift
                ;;
        esac
    done

    if [[ $# -gt 0 ]]; then
        if [[ -n "$TOOL_NAME" ]]; then
            _remove_error "Too many arguments: $1"
            _remove_usage
            exit 1
        fi
        TOOL_NAME="$1"
        shift
    fi

    [[ -z "$TOOL_NAME" ]] && {
        _remove_error "missing project name"
        _remove_usage
        exit 1
    }
}

_confirm_remove() {
    local target="$1"
    local kind="$2"
    local reply

    [[ -e "$target" || -L "$target" ]] || return 1

    printf "%b[REMOVE]:%b Remove %s %b%s%b? [y/N] " \
	   "$YELLOW" "$RESET" "$kind" "$MAGENTA" "$target" "$RESET"
    
    read -r reply

    case "$reply" in
        y|Y|yes|YES)
            if [[ "$kind" == "directory" ]]; then
                rm -r -- "$target" && printf "removed %s\n" "$target"
            else
                rm -f -- "$target" && printf "removed %s\n" "$target"
            fi
            ;;
        *)
            printf "skipped %s\n" "$target"
            ;;
    esac
}

_remove_local() {
    local local_bin="$HOME/.local/bin/$TOOL_NAME"
    local local_lib="$HOME/.local/lib/$TOOL_NAME"

    [[ -f "$local_bin" || -L "$local_bin" ]] && _confirm_remove "$local_bin" "file"
    [[ -d "$local_lib" ]] && _confirm_remove "$local_lib" "directory"
}

_remove_global() {
    local global_bin="/usr/bin/$TOOL_NAME"
    local global_lib="/usr/lib/$TOOL_NAME"

    [[ -f "$global_bin" || -L "$global_bin" ]] && _confirm_remove "$global_bin" "file"
    [[ -d "$global_lib" ]] && _confirm_remove "$global_lib" "directory"
}

remove_cmd() {
    _remove_parse_args "$@"

    _remove_info "Checking standard install locations for $TOOL_NAME..."
    _remove_local
    _remove_global
    _remove_info "Remove finished."
}
