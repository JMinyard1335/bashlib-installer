#!/usr/bin/env bash
# Internal shared library for update command

## SOURCE GUARD bashlib_update.bash -----------------------------------------------------
if [[ -v installer_update_sourced ]]; then
	return 0
fi
installer_update_sourced=1
## --------------------------------------------------------------------------------------

BASHLIB_UPDATE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${BASHLIB_UPDATE_DIR}/../toml/toml_read.bash"
source "${BASHLIB_UPDATE_DIR}/installer_format.bash"
source "${BASHLIB_UPDATE_DIR}/bashlib_install.bash"

# _bashlib_update_find_prefix <tool-name>
# Prints the install prefix for a tool and returns 0 when found.
_bashlib_update_find_prefix() {
	local tool_name="$1"

	if [[ -f "$HOME/.local/bin/$tool_name" || -L "$HOME/.local/bin/$tool_name" ]]; then
		printf "%s\n" "$HOME/.local"
		return 0
	fi

	if [[ -f "/usr/local/bin/$tool_name" || -L "/usr/local/bin/$tool_name" ]]; then
		printf "%s\n" "/usr/local"
		return 0
	fi

	if [[ -f "/usr/bin/$tool_name" || -L "/usr/bin/$tool_name" ]]; then
		printf "%s\n" "/usr"
		return 0
	fi

	return 1
}

# bashlib_update_tool <tool-name>
# Finds a tool install location, reads its repo from tool metadata,
# then installs the latest version from that repo to the same prefix.
bashlib_update_tool() {
	local tool_name="$1"
	local install_prefix=""
	local tool_toml=""
	local repo=""

	if [[ -z "$tool_name" ]]; then
		installer_error "missing tool name"
		return 1
	fi

	install_prefix="$(_bashlib_update_find_prefix "$tool_name")" || {
		installer_error "Tool not found: $tool_name"
		return 1
	}

	tool_toml="${install_prefix}/lib/${tool_name}/tool.toml"
	if [[ ! -f "$tool_toml" ]]; then
		installer_error "Missing tool metadata: $tool_toml"
		return 1
	fi

	repo="$(toml_read_key "$tool_toml" "project" "repo" 2>/dev/null || true)"
	if [[ -z "$repo" ]]; then
		installer_error "No repo found in: $tool_toml"
		return 1
	fi

	installer_log "Found "
	installer_path "$tool_name"
	printf " in "
	installer_path "$install_prefix"
	printf "\n"

	installer_log "Updating from "
	installer_path "$repo"
	printf "\n"
	echo "$install_prefix"
	bashlib_install_from_repo "$repo" "$install_prefix" 0 || return 1

	installer_ok "$tool_name updated successfully."
	return 0
}
