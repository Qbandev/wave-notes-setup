# Contributing to wave-notes-setup

Thank you for your interest in contributing to wave-notes-setup!

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/wave-notes-setup.git
   cd wave-notes-setup
   ```
3. Install development dependencies:
   ```bash
   brew install bats-core shellcheck
   ```

## Development Workflow

### Making Changes

1. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes following the code style guidelines below

3. Run the test suite:
   ```bash
   ./test/run_tests.sh
   ```

4. Run shellcheck:
   ```bash
   shellcheck install.sh uninstall.sh
   ```

5. Test manually:
   ```bash
   ./install.sh -v
   # Verify widgets appear in Wave Terminal
   ./install.sh --uninstall
   ```

### Code Style Guidelines

#### Bash Scripts

- Always use `set -euo pipefail` at the top of scripts
- Use `local` for function variables
- Quote all variable expansions: `"$var"` not `$var`
- Use `[[ ]]` for conditionals, not `[ ]`
- Use meaningful function and variable names
- Add comments for non-obvious logic

#### Widget Configuration

- **Never hardcode user-specific paths** - use `$HOME`, `$NOTES_DIR`, `$BIN_DIR`
- **Never add `color` property** - widgets must follow Wave Terminal theme
- Always include `cmd:closeonexit: true` and `cmd:closeonexitdelay: 0` for term widgets
- Use `view: "preview"` for file/directory browsing, not `view: "term"` with commands

#### Testing

- Write tests for new functionality
- Follow existing test patterns in `test/*.bats`
- Use descriptive test names: `@test "function_name: describes what is tested"`
- Use the Arrange-Act-Assert pattern

### Test Structure

Tests are organized by file:

- `test/test_helper.bash` - Shared utilities, mocks, and assertions
- `test/install.bats` - Tests for install.sh functions
- `test/uninstall.bats` - Tests for uninstall.sh functions

### Adding New Tests

```bash
@test "function_name: describes the scenario being tested" {
    # Arrange - set up test conditions
    SOME_VAR="value"

    # Act - call the function
    run function_name "$arg1" "$arg2"

    # Assert - verify results
    [ "$status" -eq 0 ]
    [ "$output" = "expected output" ]
}
```

## Pull Request Guidelines

1. **Ensure all tests pass** - PRs with failing tests will not be merged
2. **Ensure shellcheck passes** - No warnings or errors
3. **Update documentation** if your changes affect user-facing behavior
4. **Add tests** for new functionality
5. **Keep commits focused** - One logical change per commit
6. **Write clear commit messages** - Explain what and why

### Commit Message Format

```
type: short description

Longer explanation if needed. Explain the problem being solved
and why this approach was chosen.

Fixes #123
```

Types: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`

## Architecture Overview

### Configuration Resolution

Configuration is resolved in order of precedence (lowest to highest):

1. **Defaults** - Hardcoded in `install.sh`
   - `NOTES_DIR="$HOME/Documents/WaveNotes"`
   - `BIN_DIR="$HOME/bin"`

2. **Config File** - `~/.wave-notes.conf`
   ```bash
   NOTES_DIR="$HOME/Dropbox/Notes"
   BIN_DIR="$HOME/.local/bin"
   ```

3. **Environment Variables** - Override everything
   ```bash
   WAVE_NOTES_DIR="$HOME/iCloud/Notes"
   WAVE_BIN_DIR="/usr/local/bin"
   ```

### Wave Terminal Detection

The installer supports both old and new Wave Terminal config paths:

- **v0.9+**: `~/.config/waveterm/`
- **< v0.9**: `~/.waveterm/config/`

Detection is handled by `detect_waveterm_config()`.

### JSON Processing

Widget configuration uses JSON. The installer supports two backends:

1. **jq** (preferred) - Fast, installed on many systems
2. **Python** (fallback) - Available on all macOS systems

Both are tested to ensure consistent behavior.

### Widget Types

| Widget | View Type | Purpose |
|--------|-----------|---------|
| New Note | `term` | Runs script to create note |
| All Notes | `preview` | Native directory browser |

The `term` view requires special handling:
- `cmd:closeonexit: true` - Close terminal on success
- `cmd:closeonexitdelay: 0` - No delay before closing

## Common Issues

### "wsh command not found"

The `wave-scratch.sh` script includes a `find_wsh()` function that searches:
1. `$PATH`
2. `$HOME/Library/Application Support/waveterm/bin/wsh`
3. `/usr/local/bin/wsh`
4. `/opt/homebrew/bin/wsh`

If adding new search paths, add them to this function.

### "No View Component" error

This occurs when using an invalid view type. For directory browsing, use:
```json
{
  "view": "preview",
  "file": "/path/to/directory"
}
```

Not:
```json
{
  "view": "term",
  "cmd": "wsh view /path/to/directory"
}
```

### Terminal block flashes briefly

This is a Wave Terminal limitation when using `view: "term"`. Minimize with:
- `cmd:closeonexit: true`
- `cmd:closeonexitdelay: 0`

## Questions?

Open an issue at [github.com/qbandev/wave-notes-setup/issues](https://github.com/qbandev/wave-notes-setup/issues)
