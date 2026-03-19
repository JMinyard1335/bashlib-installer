#!/usr/bin/env bash

## SOURCE GUARD bashlib_install.bash -----------------------------------------------------
if [[ -v installer_lib_create_sourced ]]; then
    return 0
fi
installer_lib_create_sourced=1

bashlib_create_lib_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${bashlib_create_lib_dir}/installer_err.bash"
source "${bashlib_create_lib_dir}/installer_format.bash"
## ---------------------------------------------------------------------------------------

create_get_project() {
    local response=""
    read -r -p "Project name [new-project]: " response
    echo "${response:-new-project}"
}

create_get_tool() {
    local default_tool="${1:-tool}"
    local response=""
    read -r -p "Tool name [${default_tool}]: " response
    echo "${response:-$default_tool}"
}

create_get_author() {
    local default_author="${1:-unknown}"
    local response=""
    read -r -p "Author [${default_author}]: " response
    echo "${response:-$default_author}"
}

create_get_repo() {
    local default_repo="${1:-https://example.com/your-user/your-tool.git}"
    local response=""
    read -r -p "Repo [${default_repo}]: " response
    echo "${response:-$default_repo}"
}

create_validate_name() {
    local value="${1:-}"
    local label="${2:-value}"

    if [[ -z "$value" ]]; then
        installer_error "$label cannot be empty"
        return 1
    fi

    if [[ ! "$value" =~ ^[A-Za-z0-9._-]+$ ]]; then
        installer_error "$label may only contain letters, numbers, dots, underscores, and dashes"
        installer_logln "Invalid value: $value"
        return 1
    fi

    return 0
}

create_toml_escape() {
    local value="${1:-}"
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    value="${value//$'\t'/\\t}"
    value="${value//$'\r'/\\r}"
    value="${value//$'\n'/\\n}"
    printf '%s' "$value"
}

create_to_identifier() {
    local value="${1:-tool}"

    value="${value//[^A-Za-z0-9_]/_}"
    [[ "$value" =~ ^[0-9] ]] && value="_$value"
    [[ -z "$value" ]] && value="tool"

    printf '%s' "$value"
}

# create_mkdir <project name>
create_mkdirs() {
    local project_name="${1:-new-project}"

    if [[ -e "$project_name" ]]; then
        installer_error "Project path already exists: $project_name"
        return 1
    fi

    mkdir -p "$project_name"/{lib/internal,libexec,man} || {
        installer_error "Failed to create project directories"
        return 1
    }

    return 0
}

# create_write_tool_toml <project dir> <project name> <tool name> <author> <repo>
create_write_tool_toml() {
    if [[ "$#" -ne 5 ]]; then
        installer_error "create_write_tool_toml: invalid argument count"
        return 1
    fi

    local project_dir="$1"
    local project_name="$2"
    local tool_name="$3"
    local author="$4"
    local repo="$5"

    local escaped_project="$(create_toml_escape "$project_name")"
    local escaped_tool="$(create_toml_escape "$tool_name")"
    local escaped_author="$(create_toml_escape "$author")"
    local escaped_repo="$(create_toml_escape "$repo")"

    cat > "$project_dir/tool.toml" <<EOF
[project]
project="$escaped_project"
author="$escaped_author"
tool="$escaped_tool"
repo="$escaped_repo"

[directories]
lib="lib"
libexec="libexec"
man="man"

[dependencies]
EOF
}

# create_write_tool_script <project dir> <tool name>
create_write_tool_script() {
    if [[ "$#" -ne 2 ]]; then
        installer_error "create_write_tool_script: invalid argument count"
        return 1
    fi

    local project_dir="$1"
    local tool_name="$2"

    cat > "$project_dir/$tool_name" <<EOF
#!/usr/bin/env bash

SCRIPT_PATH="\$(realpath -- "\$0")"
SCRIPT_DIR="\$(dirname -- "\$SCRIPT_PATH")"

source "\$SCRIPT_DIR/lib/$tool_name.bash"

main() {
    printf "%s\\n" "$tool_name: not implemented"
}

main "\$@"
EOF

    chmod +x "$project_dir/$tool_name" || {
        installer_error "Failed to make tool script executable: $project_dir/$tool_name"
        return 1
    }

    return 0
}

# create_write_lib_script <project dir> <tool name>
create_write_lib_script() {
    if [[ "$#" -ne 2 ]]; then
        installer_error "create_write_lib_script: invalid argument count"
        return 1
    fi

    local project_dir="$1"
    local tool_name="$2"
    local tool_identifier="$(create_to_identifier "$tool_name")"

    cat > "$project_dir/lib/$tool_name.bash" <<EOF
#!/usr/bin/env bash

if [[ -v ${tool_identifier}_lib_sourced ]]; then
    return 0
fi
${tool_identifier}_lib_sourced=1

${tool_identifier}_not_implemented() {
    printf "%s\\n" "$tool_name: library not implemented"
}
EOF

    return 0
}

# create_write_readme <project dir> <project name> <tool name> <author> <repo>
create_write_readme() {
    if [[ "$#" -ne 5 ]]; then
        installer_error "create_write_readme: invalid argument count"
        return 1
    fi

    local project_dir="$1"
    local project_name="$2"
    local tool_name="$3"
    local author="$4"
    local repo="$5"

    cat > "$project_dir/README.md" <<EOF
# $project_name

Created with bashlib-installer.

## Metadata
- Tool: $tool_name
- Author: $author
- Repo: $repo

## Quick start

\`\`\`bash
chmod +x ./$tool_name
./$tool_name --help
\`\`\`
EOF

    return 0
}

# create_write_gitignore <project dir>
create_write_gitignore() {
    if [[ "$#" -ne 1 ]]; then
        installer_error "create_write_gitignore: invalid argument count"
        return 1
    fi

    local project_dir="$1"

    cat > "$project_dir/.gitignore" <<'EOF'
*.swp
*.swo
EOF

    return 0
}

# create_touch_files <project name> <tool name> <author> <repo>
create_touch_files() {
    local project_name="${1:-new-project}"
    local tool_name="${2:-tool}"
    local author="${3:-unknown}"
    local repo="${4:-https://example.com/your-user/your-tool.git}"
    local project_label=""

    project_label="$(basename -- "$project_name")"

    create_write_tool_toml "$project_name" "$project_label" "$tool_name" "$author" "$repo" || return 1
    create_write_tool_script "$project_name" "$tool_name" || return 1
    create_write_lib_script "$project_name" "$tool_name" || return 1
    create_write_readme "$project_name" "$project_label" "$tool_name" "$author" "$repo" || return 1
    create_write_gitignore "$project_name" || return 1

    return 0
}

create_log_created_path() {
    local path="${1:-}"
    installer_log "  - "
    installer_path "$path"
    printf "\n" >&2
}

create_print_summary() {
    if [[ "$#" -ne 2 ]]; then
        installer_error "create_print_summary: invalid argument count"
        return 1
    fi

    local project_name="$1"
    local tool_name="$2"

    installer_ok "Created project scaffold: $project_name"
    installer_logln "Generated files and directories:"
    create_log_created_path "$project_name/"
    create_log_created_path "$project_name/tool.toml"
    create_log_created_path "$project_name/$tool_name"
    create_log_created_path "$project_name/lib/$tool_name.bash"
    create_log_created_path "$project_name/lib/internal/"
    create_log_created_path "$project_name/libexec/"
    create_log_created_path "$project_name/man/"
    create_log_created_path "$project_name/README.md"
    create_log_created_path "$project_name/.gitignore"
    installer_logln "Next step: cd $project_name"

    return 0
}

create_new_project() {
    local project=""
    local tool=""
    local author=""
    local repo=""
    local default_repo=""

    installer_logln "Create a new bash project"

    project="$(create_get_project)"
    create_validate_name "$project" "Project name" || return 1

    tool="$(create_get_tool "$project")"
    create_validate_name "$tool" "Tool name" || return 1

    author="$(create_get_author "unknown")"

    default_repo="https://example.com/your-user/${project}.git"
    repo="$(create_get_repo "$default_repo")"

    installer_logln "Creating project directories..."
    create_mkdirs "$project" || return 1

    installer_logln "Writing starter files..."
    create_touch_files "$project" "$tool" "$author" "$repo" || return 1

    create_print_summary "$project" "$tool" || return 1

    return 0
}
