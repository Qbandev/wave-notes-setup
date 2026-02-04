#!/bin/bash
# wave-notes-setup v1.0.0
# Configure Wave Terminal with a Warp-like notes system
# https://github.com/qbandev/wave-notes-setup

set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="wave-notes-setup"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
DEFAULT_NOTES_DIR="$HOME/Documents/WaveNotes"
DEFAULT_BIN_DIR="$HOME/bin"
CONFIG_FILE="$HOME/.wave-notes.conf"

# Wave Terminal config path detection (supports both old and new paths)
detect_waveterm_config() {
    # New path (Wave Terminal 0.9+)
    if [[ -d "$HOME/.config/waveterm" ]]; then
        echo "$HOME/.config/waveterm"
    # Old path (Wave Terminal < 0.9)
    elif [[ -d "$HOME/.waveterm" ]]; then
        echo "$HOME/.waveterm/config"
    else
        echo ""
    fi
}

WAVETERM_BASE=""
WAVETERM_CONFIG=""

# Runtime variables
NOTES_DIR=""
BIN_DIR=""
# shellcheck disable=SC2034  # FORCE reserved for future use
FORCE=false
VERBOSE=false
UNINSTALL=false

# ============================================================================
# Utility Functions
# ============================================================================

print_header() {
    echo -e "${BLUE}🌊 $SCRIPT_NAME v$VERSION${NC}"
    echo "─────────────────────────────"
    echo ""
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️  Warning:${NC} $1"
}

print_error() {
    echo -e "${RED}[✗] Error:${NC} $1" >&2
}

print_info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
}

print_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

check_not_symlink() {
    local path="$1"
    if [[ -L "$path" ]]; then
        print_error "Refusing to overwrite symlink: $path"
        print_error "This could be a security attack. Please remove the symlink manually."
        return 1
    fi
    return 0
}

# ============================================================================
# Security Functions
# ============================================================================

# F3: Path Traversal - Validate paths are within $HOME
validate_safe_path() {
    local path="$1"
    local name="$2"
    local resolved

    # Reject paths with .. sequences (before directory may exist)
    if [[ "$path" == *".."* ]]; then
        print_error "$name cannot contain '..' sequences: $path"
        return 1
    fi

    # Reject paths with shell metacharacters (prevents command injection)
    # Allow: alphanumeric, /, -, _, ., ~, space (no $, ;, ", ', etc.)
    if [[ "$path" =~ [^a-zA-Z0-9/_~.[:space:]-] ]]; then
        print_error "$name contains invalid characters: $path"
        print_error "Only alphanumeric characters, /, -, _, ., ~, and spaces are allowed"
        return 1
    fi

    # Resolve to absolute path without requiring parent directory
    if ! resolved=$(python3 -c 'import os, sys; print(os.path.abspath(os.path.expanduser(sys.argv[1])))' "$path" 2>/dev/null); then
        print_error "$name cannot be resolved: $path"
        return 1
    fi

    # Must be under $HOME
    if [[ "$resolved" != "$HOME"/* && "$resolved" != "$HOME" ]]; then
        print_error "$name must be under \$HOME: $path"
        return 1
    fi

    # Blacklist critical paths (with and without trailing slashes)
    case "$resolved" in
        "$HOME"|"$HOME/"|"$HOME/Desktop"|"$HOME/Desktop/"|"$HOME/Documents"|"$HOME/Documents/"|"$HOME/Downloads"|"$HOME/Downloads/"|"$HOME/Library"|"$HOME/Library/")
            print_error "$name cannot be a protected directory: $path"
            return 1
            ;;
    esac

    # Block anything in ~/Library (Library itself is caught above, this catches subdirs)
    if [[ "$resolved" == "$HOME/Library/"* ]]; then
        print_error "$name cannot be in Library: $path"
        return 1
    fi

    return 0
}

# F4: Safe deletion function with protected path checks
safe_rmdir() {
    local path="$1"

    if [[ ! -d "$path" ]]; then
        return 0
    fi

    # Never delete root or home
    case "$(realpath "$path" 2>/dev/null || echo "$path")" in
        /|/etc|/usr|/var|/bin|/sbin|/home|/root|"$HOME")
            print_error "Refusing to delete protected path: $path"
            return 1
            ;;
    esac

    if ! validate_safe_path "$path" "PATH"; then
        return 1
    fi

    check_not_symlink "$path" || return 1

    rm -rf "$path"
    return $?
}

# ============================================================================
# Configuration Resolution
# ============================================================================

load_config() {
    # 1. Start with defaults
    NOTES_DIR="$DEFAULT_NOTES_DIR"
    BIN_DIR="$DEFAULT_BIN_DIR"

    # Detect Wave Terminal config path
    WAVETERM_BASE=$(detect_waveterm_config)
    if [[ -n "$WAVETERM_BASE" ]]; then
        WAVETERM_CONFIG="$WAVETERM_BASE"
    else
        WAVETERM_CONFIG=""
    fi

    # 2. Load from config file if exists
    if [[ -f "$CONFIG_FILE" ]]; then
        print_verbose "Loading config from $CONFIG_FILE"
        # Source config file safely (only specific variables)
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ "$key" =~ ^#.*$ ]] && continue
            [[ -z "$key" ]] && continue
            # F5: Trim whitespace using parameter expansion (safer than xargs)
            key="${key#"${key%%[![:space:]]*}"}"
            key="${key%"${key##*[![:space:]]}"}"
            value="${value#"${value%%[![:space:]]*}"}"
            value="${value%"${value##*[![:space:]]}"}"
            # Handle quotes
            value="${value#\"}" ; value="${value%\"}"
            value="${value#\'}" ; value="${value%\'}"
            # Expand $HOME in value
            value="${value//\$HOME/$HOME}"
            case "$key" in
                NOTES_DIR) NOTES_DIR="$value" ;;
                BIN_DIR) BIN_DIR="$value" ;;
            esac
        done < "$CONFIG_FILE"
    fi

    # 3. Override with environment variables (highest precedence)
    [[ -n "${WAVE_NOTES_DIR:-}" ]] && NOTES_DIR="$WAVE_NOTES_DIR"
    [[ -n "${WAVE_BIN_DIR:-}" ]] && BIN_DIR="$WAVE_BIN_DIR"

    # Resolve to absolute paths (expand ~)
    NOTES_DIR="${NOTES_DIR/#\~/$HOME}"
    BIN_DIR="${BIN_DIR/#\~/$HOME}"

    print_verbose "NOTES_DIR: $NOTES_DIR"
    print_verbose "BIN_DIR: $BIN_DIR"
    print_verbose "WAVETERM_CONFIG: $WAVETERM_CONFIG"
}

# ============================================================================
# Preflight Checks
# ============================================================================

check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        print_error "This tool only supports macOS."
        exit 1
    fi
    print_success "macOS detected"
}

check_wave_terminal() {
    if [[ -z "$WAVETERM_CONFIG" ]]; then
        print_error "Wave Terminal not found"
        echo ""
        echo "Checked paths:"
        echo "  - ~/.config/waveterm (Wave Terminal 0.9+)"
        echo "  - ~/.waveterm (Wave Terminal < 0.9)"
        echo ""
        echo "Please install Wave Terminal first:"
        echo "  https://www.waveterm.dev/"
        exit 1
    fi
    print_success "Wave Terminal found at $WAVETERM_CONFIG"
}

check_wave_installed() {
    if [[ -d "$HOME/.config/waveterm" ]]; then
        return 0
    elif [[ -d "$HOME/.waveterm" ]]; then
        return 0
    elif command -v wsh >/dev/null 2>&1; then
        return 0
    else
        print_error "Wave Terminal is not installed"
        echo "   Install from: https://www.waveterm.dev/download"
        return 1
    fi
}

check_wsh() {
    if ! command -v wsh >/dev/null 2>&1; then
        print_warning "'wsh' command not found in PATH"
        echo "   The notes widget may not work until Wave Terminal is running."
        echo "   You can install wsh from Wave Terminal menu: Wave > Install 'wsh' CLI"
    fi
}

check_jq() {
    if command -v jq >/dev/null 2>&1; then
        print_verbose "jq found, using for JSON processing"
        return 0
    else
        print_verbose "jq not found, will use Python fallback"
        return 1
    fi
}

validate_widgets() {
    local widgets_file="$1"
    if command -v jq >/dev/null 2>&1; then
        jq empty "$widgets_file" 2>/dev/null
        return $?
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "import sys, json; json.load(open(sys.argv[1]))" "$widgets_file" 2>/dev/null
        return $?
    fi
    print_warning "No JSON validator (jq or python3) available, skipping validation"
    return 0
}

# ============================================================================
# Installation Functions
# ============================================================================

create_directories() {
    mkdir -p "$NOTES_DIR"
    print_success "Created $NOTES_DIR"

    mkdir -p "$BIN_DIR"
    print_verbose "Created $BIN_DIR"

    mkdir -p "$WAVETERM_CONFIG"
    print_verbose "Created $WAVETERM_CONFIG"
}

install_scratchpad_script() {
    local script_path="$BIN_DIR/wave-scratch.sh"

    # Security check: refuse to overwrite symlinks
    check_not_symlink "$script_path" || return 1

    # Generate the script with injected paths
    cat > "$script_path" << 'SCRIPT_EOF'
#!/bin/bash
# Generated by wave-notes-setup v1.0.0
# Re-run wave-notes-setup to update paths

set -euo pipefail

NOTES_DIR="NOTES_DIR_PLACEHOLDER"
mkdir -p "$NOTES_DIR"

FILENAME="note-$(date +'%Y-%m-%d_%H%M%S').md"
FILEPATH="$NOTES_DIR/$FILENAME"

# Create file with header
echo "# Note - $(date +'%Y-%m-%d %H:%M')" > "$FILEPATH"
echo "" >> "$FILEPATH"

# Find wsh in common locations
find_wsh() {
    if command -v wsh >/dev/null 2>&1; then
        command -v wsh
        return
    fi
    local paths=(
        "$HOME/Library/Application Support/waveterm/bin/wsh"
        "/usr/local/bin/wsh"
        "/opt/homebrew/bin/wsh"
    )
    for p in "${paths[@]}"; do
        if [[ -x "$p" ]]; then
            echo "$p"
            return
        fi
    done
    echo ""
}

WSH_CMD=$(find_wsh)

if [[ -n "$WSH_CMD" ]]; then
    "$WSH_CMD" edit "$FILEPATH"
else
    echo "Error: 'wsh' command not found. Is Wave Terminal installed and running?" >&2
    echo "File created at: $FILEPATH" >&2
    exit 1
fi
SCRIPT_EOF

    # Replace placeholder with actual path
    # Escape characters that have special meaning in sed replacement strings (&, /, \)
    local escaped_notes_dir
    escaped_notes_dir=$(printf '%s' "$NOTES_DIR" | sed 's/[&/\]/\\&/g')
    sed -i '' "s|NOTES_DIR_PLACEHOLDER|$escaped_notes_dir|g" "$script_path"

    chmod +x "$script_path"
    print_success "Installed $script_path"
}

get_max_display_order() {
    local widgets_file="$1"
    local max_order=0

    if [[ -f "$widgets_file" ]]; then
        if command -v jq >/dev/null 2>&1; then
            max_order=$(jq '[.[] | ."display:order" // 0] | max // 0' "$widgets_file" 2>/dev/null || echo 0)
        else
            # Python fallback: output format is "value|error" (error empty on success)
            # Pass file path via sys.argv to prevent command injection
            local python_output
            python_output=$(python3 -c "
import json
import sys
try:
    with open(sys.argv[1], 'r') as f:
        data = json.load(f)
    orders = [v.get('display:order', 0) for v in data.values() if isinstance(v, dict)]
    print(str(max(orders) if orders else 0) + '|')
except Exception as e:
    print('0|' + str(e))
" "$widgets_file" 2>/dev/null || echo "0|python execution failed")
            max_order="${python_output%%|*}"
            local python_err="${python_output#*|}"
            if [[ -n "$python_err" ]]; then
                print_verbose "Python JSON parsing warning: $python_err"
            fi
        fi
    fi

    echo "$max_order"
}

get_existing_order() {
    local widgets_file="$1"
    local key="$2"
    local default="$3"

    if [[ ! -f "$widgets_file" ]]; then
        echo "$default"
        return
    fi

    local order
    if command -v jq >/dev/null 2>&1; then
        order=$(jq -r ".[\"$key\"][\"display:order\"] // \"$default\"" "$widgets_file" 2>/dev/null || echo "$default")
    else
        # Python fallback: output format is "value|error" (error empty on success)
        # Pass file path and parameters via sys.argv to prevent command injection
        local python_output
        python_output=$(python3 -c "
import json
import sys
widgets_file = sys.argv[1]
key = sys.argv[2]
default = sys.argv[3]
try:
    with open(widgets_file, 'r') as f:
        data = json.load(f)
    print(str(data.get(key, {}).get('display:order', default)) + '|')
except Exception as e:
    print(default + '|' + str(e))
" "$widgets_file" "$key" "$default" 2>/dev/null || echo "$default|python execution failed")
        order="${python_output%%|*}"
        local python_err="${python_output#*|}"
        if [[ -n "$python_err" ]]; then
            print_verbose "Python JSON parsing warning: $python_err"
        fi
    fi

    echo "$order"
}

install_widgets() {
    local widgets_file="$WAVETERM_CONFIG/widgets.json"
    local temp_file
    local backup_file=""
    temp_file=$(mktemp)

    # Backup existing file with secure permissions
    if [[ -f "$widgets_file" ]]; then
        backup_file="$widgets_file.bak.$(date +'%Y-%m-%dT%H%M%S')"
        cp "$widgets_file" "$backup_file"
        chmod 600 "$backup_file"
        print_success "Backed up widgets.json"
        print_verbose "Backup: $backup_file"
    fi

    # Get max display order for new widgets
    local max_order
    max_order=$(get_max_display_order "$widgets_file")
    local next_order=$((max_order + 1))

    # Calculate orders (preserve existing or assign new)
    local order_new

    order_new=$(get_existing_order "$widgets_file" "custom:notes-new" "$next_order")

    print_verbose "Widget order: new=$order_new"

    # Check if deprecated custom:notes-list exists for cleanup notification
    local has_legacy_notes_list=false
    if [[ -f "$widgets_file" ]]; then
        if command -v jq >/dev/null 2>&1; then
            if jq -e '."custom:notes-list"' "$widgets_file" >/dev/null 2>&1; then
                has_legacy_notes_list=true
            fi
        else
            # Pass file path via sys.argv to prevent command injection
            if python3 -c "import json, sys; data=json.load(open(sys.argv[1])); sys.exit(0 if 'custom:notes-list' in data else 1)" "$widgets_file" 2>/dev/null; then
                has_legacy_notes_list=true
            fi
        fi
    fi

    if [[ "$has_legacy_notes_list" == true ]]; then
        print_info "Removing deprecated 'All Notes' widget..."
    fi

    # Create new widgets JSON (no color property - follows theme)
    local new_widgets
    new_widgets=$(cat << WIDGETS_EOF
{
  "custom:notes-new": {
    "display:order": $order_new,
    "icon": "solid@note-sticky",
    "label": "note",
    "description": "Create a timestamped note",
    "blockdef": {
      "meta": {
        "view": "term",
        "controller": "cmd",
        "cmd": "$BIN_DIR/wave-scratch.sh",
        "cmd:cwd": "$NOTES_DIR",
        "cmd:runonstart": true,
        "cmd:clearonstart": true,
        "cmd:closeonexit": true,
        "cmd:closeonexitdelay": 0
      }
    }
  }
}
WIDGETS_EOF
)

    # Merge with existing widgets (removing deprecated custom:notes-list if present)
    if [[ -f "$widgets_file" ]]; then
        if command -v jq >/dev/null 2>&1; then
            jq -s '(.[0] | del(."custom:notes-list")) * .[1]' "$widgets_file" <(echo "$new_widgets") > "$temp_file"
        else
            # Pass file paths via sys.argv to prevent command injection
            # Pass new_widgets via stdin to avoid embedding in code
            echo "$new_widgets" | python3 -c "
import json
import sys

widgets_file = sys.argv[1]
temp_file = sys.argv[2]

# Read existing widgets
with open(widgets_file, 'r') as f:
    existing = json.load(f)

# Remove deprecated custom:notes-list widget if present
existing.pop('custom:notes-list', None)

# Parse new widgets from stdin (safer than embedding in code)
new_widgets = json.load(sys.stdin)

# Merge (new overwrites existing keys)
existing.update(new_widgets)

# Write result
with open(temp_file, 'w') as f:
    json.dump(existing, f, indent=2)
" "$widgets_file" "$temp_file"
        fi
    else
        echo "$new_widgets" > "$temp_file"
    fi

    # Security check: refuse to overwrite symlinks
    check_not_symlink "$widgets_file" || return 1

    # Atomic write
    mv "$temp_file" "$widgets_file"

    # Validate the generated JSON and rollback if invalid
    if ! validate_widgets "$widgets_file"; then
        print_error "Generated widgets.json is invalid"
        if [[ -n "$backup_file" && -f "$backup_file" ]]; then
            cp "$backup_file" "$widgets_file"
            print_success "Restored backup"
        else
            # Fresh install with no backup - remove invalid file
            rm -f "$widgets_file"
            print_warning "Removed invalid widgets.json"
        fi
        exit 1
    fi

    print_success "Added widget to widgets.json"
}

check_path() {
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        echo ""
        print_warning "$BIN_DIR is not in your PATH"
        echo "   Add this to your shell profile (~/.zshrc or ~/.bashrc):"
        echo "   export PATH=\"$BIN_DIR:\$PATH\""
    fi
}

print_success_message() {
    echo ""
    echo -e "${GREEN}✅ Setup complete!${NC}"
    echo ""
    echo "Restart Wave Terminal to see your new sidebar widgets."
    echo ""
    echo "Optional next steps:"
    echo "  - Install fzf for fuzzy search: brew install fzf"
    echo "  - See README for keyboard shortcut setup"
}

# ============================================================================
# Uninstall Functions
# ============================================================================

run_uninstall() {
    print_header
    echo "Uninstalling wave-notes-setup..."
    echo ""

    local widgets_file="$WAVETERM_CONFIG/widgets.json"
    local script_path="$BIN_DIR/wave-scratch.sh"

    # Remove widgets from widgets.json
    if [[ -f "$widgets_file" ]]; then
        local temp_file
        temp_file=$(mktemp)

        if command -v jq >/dev/null 2>&1; then
            jq 'with_entries(select(.key | startswith("custom:notes-") | not))' "$widgets_file" > "$temp_file"
        else
            # Pass file paths via sys.argv to prevent command injection
            python3 -c "
import json
import sys

widgets_file = sys.argv[1]
temp_file = sys.argv[2]

with open(widgets_file, 'r') as f:
    data = json.load(f)
filtered = {k: v for k, v in data.items() if not k.startswith('custom:notes-')}
with open(temp_file, 'w') as f:
    json.dump(filtered, f, indent=2)
" "$widgets_file" "$temp_file"
        fi

        # Security check: refuse to overwrite symlinks
        check_not_symlink "$widgets_file" || { rm -f "$temp_file"; return 1; }
        mv "$temp_file" "$widgets_file"
        print_success "Removed widgets from widgets.json"
    fi

    # Remove scratchpad script (with header verification)
    if [[ -f "$script_path" ]]; then
        if grep -q "Generated by wave-notes-setup" "$script_path" 2>/dev/null; then
            rm "$script_path"
            print_success "Removed $script_path"
        else
            print_warning "Skipping $script_path (file modified or unknown)"
        fi
    fi

    # Prompt for notes folder deletion
    echo ""
    read -p "Delete notes folder $NOTES_DIR? This will delete all your notes! (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ -d "$NOTES_DIR" ]]; then
            # F4: Use safe deletion with protected path checks
            if safe_rmdir "$NOTES_DIR"; then
                print_success "Deleted $NOTES_DIR"
            fi
        fi
    else
        echo "Keeping notes folder."
    fi

    # Prompt for config file deletion
    if [[ -f "$CONFIG_FILE" ]]; then
        read -p "Delete config file $CONFIG_FILE? (y/N) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm "$CONFIG_FILE"
            print_success "Deleted $CONFIG_FILE"
        fi
    fi

    echo ""
    echo -e "${GREEN}✅ Uninstall complete!${NC}"
    echo "Restart Wave Terminal for changes to take effect."
}

# ============================================================================
# CLI Argument Parsing
# ============================================================================

show_help() {
    cat << EOF
$SCRIPT_NAME v$VERSION
Configure Wave Terminal with a Warp-like notes system

Usage: $SCRIPT_NAME [options]

Options:
  -f, --force      Overwrite existing files without prompt
  -v, --verbose    Enable verbose logging
  -u, --uninstall  Run uninstall procedure
  --version        Print version and exit
  -h, --help       Show this help message

Configuration:
  Set WAVE_NOTES_DIR and WAVE_BIN_DIR environment variables,
  or create ~/.wave-notes.conf with:
    NOTES_DIR="\$HOME/Documents/WaveNotes"
    BIN_DIR="\$HOME/bin"

Examples:
  $SCRIPT_NAME              # Install with defaults
  $SCRIPT_NAME -v           # Install with verbose output
  $SCRIPT_NAME --uninstall  # Remove installation

More info: https://github.com/qbandev/wave-notes-setup
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force)
                # shellcheck disable=SC2034  # Reserved for future use
                FORCE=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -u|--uninstall)
                UNINSTALL=true
                shift
                ;;
            --version)
                echo "$SCRIPT_NAME v$VERSION"
                exit 0
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information."
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# Main
# ============================================================================

main() {
    parse_args "$@"
    load_config

    # F3: Validate paths are safe before proceeding
    validate_safe_path "$NOTES_DIR" "NOTES_DIR" || exit 1
    validate_safe_path "$BIN_DIR" "BIN_DIR" || exit 1

    if [[ "$UNINSTALL" == true ]]; then
        run_uninstall
        exit 0
    fi

    print_header

    # Preflight checks
    check_macos
    check_wave_terminal
    check_wsh

    # Installation
    create_directories
    install_scratchpad_script
    install_widgets

    # Post-install
    check_path
    print_success_message
}

main "$@"
