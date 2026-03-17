#!/usr/bin/env bash
# Used to update a tool from its repo
#
# Determines where the tool is installed,
# reads the tool.toml file from lib/,
# then clones the repo to a temp dir
# and runs install on that temp dir.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/toml.sh"
source "${SCRIPT_DIR}/installer-color.sh"
source "${SCRIPT_DIR}/install.sh"

TOOL_NAME=""
TOOL_LOCATION=""

_update_usage() {
    cat <<EOF
Usage:
  installer update [options] <tool>

Options:
  --help        Shows this help menu

Examples:
  installer update installer
EOF
}

_update_error() {
    printf "${RED}[update-Err]:${RESET} %s\n" "$*" >&2
}

_update_warn() {
    printf "${YELLOW}[update-Warn]:${RESET} %s\n" "$*" >&2
}

_update_info() {
    printf "${CYAN}[update]:${RESET} %s\n" "$*"
}

_update_success() {
    printf "${GREEN}[update-Ok]:${RESET} %s\n" "$*"
}

_update_parse_args() {
    TOOL_NAME=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help)
                _update_usage
                return 2
                ;;
            --)
                shift
                break
                ;;
            -*)
                _update_error "Unknown option: $1"
                _update_usage
                return 1
                ;;
            *)
                if [[ -n "$TOOL_NAME" ]]; then
                    _update_error "Too many arguments: $1"
                    _update_usage
                    return 1
                fi
                TOOL_NAME="$1"
                shift
                ;;
        esac
    done

    while [[ $# -gt 0 ]]; do
        if [[ -n "$TOOL_NAME" ]]; then
            _update_error "Too many arguments: $1"
            _update_usage
            return 1
        fi
        TOOL_NAME="$1"
        shift
    done

    if [[ -z "$TOOL_NAME" ]]; then
        _update_error "Missing tool name"
        _update_usage
        return 1
    fi

    return 0
}

# _update_find_tool <tool name>
_update_find_tool() {
    local tool="$1"

    if [[ -f "$HOME/.local/bin/$tool" ]]; then
        TOOL_LOCATION="$HOME/.local"
        return 0
    elif [[ -f "/usr/bin/$tool" ]]; then
        TOOL_LOCATION="/usr"
        return 0
    else
        _update_error "Tool not found: $tool"
        return 1
    fi
}

_update_set_install_target() {
    case "$TOOL_LOCATION" in
        "$HOME/.local")
            INSTALL_GLOBAL=false
            ;;
        "/usr")
            INSTALL_GLOBAL=true
            ;;
        *)
            _update_error "Unknown tool location: $TOOL_LOCATION"
            return 1
            ;;
    esac

    _install_get_dir "$INSTALL_GLOBAL" || return 1
    _install_check_dir "$INSTALL_LOCATION" || return 1
    return 0
}

update_cmd() {
    local parse_status=0
    local repo=""

    _update_parse_args "$@"
    parse_status=$?

    case "$parse_status" in
        0) ;;
        1) return 1 ;;
        2) return 0 ;;
        *) return 1 ;;
    esac

    _update_find_tool "$TOOL_NAME" || return 1
    _update_info "Found ${MAGENTA}$TOOL_NAME${RESET} in ${MAGENTA}$TOOL_LOCATION${RESET}"

    _update_set_install_target || return 1
    _update_info "Updating into ${MAGENTA}$INSTALL_LOCATION${RESET}"

    repo="$(toml_r "$TOOL_LOCATION/lib/$TOOL_NAME/tool.toml" project repo)" || {
        _update_error "Failed to read repo from $TOOL_LOCATION/lib/$TOOL_NAME/tool.toml"
        return 1
    }

    [[ -n "$repo" ]] || {
        _update_error "No repo found in tool metadata"
        return 1
    }

    install_from_repo "$repo" || return 1

    _update_success "$TOOL_NAME updated successfully."
    return 0
}
