# wave-notes-setup

One-command setup for a Warp-like notes system in [Wave Terminal](https://www.waveterm.dev/).

## What You Get

After running the installer, you'll have two new sidebar widgets in Wave Terminal:

| Widget | Description |
|--------|-------------|
| **New Note** | Creates a timestamped markdown note and opens it in Wave's editor |
| **All Notes** | Directory browser showing all your notes |

## Installation

### Option 1: Homebrew (Recommended)

```bash
brew tap qbandev/wave-notes-setup
brew install wave-notes-setup
wave-notes-setup
```

### Option 2: curl

```bash
curl -fsSL https://raw.githubusercontent.com/qbandev/wave-notes-setup/main/install.sh | bash
```

### Option 3: Manual

```bash
git clone https://github.com/qbandev/wave-notes-setup.git
cd wave-notes-setup
./install.sh
```

## Configuration (Optional)

The installer works with sensible defaults, but you can customize paths:

### Environment Variables

```bash
export WAVE_NOTES_DIR="$HOME/Dropbox/Notes"
export WAVE_BIN_DIR="$HOME/.local/bin"
wave-notes-setup
```

### Config File

Create `~/.wave-notes.conf`:

```bash
NOTES_DIR="$HOME/Documents/MyNotes"
BIN_DIR="$HOME/bin"
```

## CLI Options

```
wave-notes-setup [options]

Options:
  -f, --force      Overwrite existing files without prompt
  -v, --verbose    Enable verbose logging
  -u, --uninstall  Run uninstall procedure
  --version        Print version and exit
  -h, --help       Show help message
```

## Uninstallation

```bash
wave-notes-setup --uninstall
# or
wave-notes-uninstall
```

The uninstaller will:
- Remove widgets from Wave Terminal
- Remove the scratchpad script
- Optionally delete your notes folder (with confirmation)
- Optionally delete the config file

## Optional Enhancements

### Fuzzy Search with fzf

Install fzf for powerful note searching:

```bash
brew install fzf
```

Add this alias to your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
alias sn='find ~/Documents/WaveNotes -name "*.md" | fzf --preview "cat {}" | xargs -r wsh edit'
```

Now type `sn` to fuzzy-search your notes.

### Keyboard Shortcut (Cmd+Shift+N)

1. Open **Automator** and create a new **Quick Action**
2. Set "Workflow receives current" to **no input** in **any application**
3. Add "Run Shell Script" action with:
   ```bash
   ~/bin/wave-scratch.sh
   ```
4. Save as "WaveScratchpad"
5. Go to **System Settings > Keyboard > Keyboard Shortcuts > Services**
6. Find "WaveScratchpad" and assign **Cmd+Shift+N**

### iCloud Sync

Move your notes to iCloud for automatic sync across Macs:

```bash
# Move notes to iCloud
mv ~/Documents/WaveNotes ~/Library/Mobile\ Documents/com~apple~CloudDocs/WaveNotes

# Create symlink so scripts still work
ln -s ~/Library/Mobile\ Documents/com~apple~CloudDocs/WaveNotes ~/Documents/WaveNotes
```

## Requirements

- macOS
- [Wave Terminal](https://www.waveterm.dev/)
- `jq` (optional, falls back to Python if missing)

## How It Works

The installer:
1. Creates a notes directory (`~/Documents/WaveNotes`)
2. Installs a scratchpad script (`~/bin/wave-scratch.sh`)
3. Adds 2 custom widgets to Wave's `~/.config/waveterm/widgets.json`

All modifications are reversible with the uninstaller.

## Development

### Running Tests

The project includes a comprehensive test suite using [bats](https://github.com/bats-core/bats-core):

```bash
# Install bats
brew install bats-core

# Run all tests (50 tests)
./test/run_tests.sh

# Or run bats directly
bats test/*.bats
```

### Linting

```bash
# Install shellcheck
brew install shellcheck

# Run linter
shellcheck install.sh uninstall.sh
```

### Project Structure

```
wave-notes-setup/
├── install.sh              # Main installer
├── uninstall.sh            # Standalone uninstaller
├── README.md               # This file
├── LICENSE                 # MIT License
├── .wave-notes.conf.example # Config template
├── Formula/
│   └── wave-notes-setup.rb # Homebrew formula
├── test/
│   ├── test_helper.bash    # Test utilities
│   ├── install.bats        # Install tests
│   ├── uninstall.bats      # Uninstall tests
│   └── run_tests.sh        # Test runner
└── .github/
    └── workflows/
        └── test.yml        # CI workflow
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Issues and pull requests welcome at [github.com/qbandev/wave-notes-setup](https://github.com/qbandev/wave-notes-setup).

Please ensure all tests pass and shellcheck reports no issues before submitting a PR.
