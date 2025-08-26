#!/usr/bin/env bash
set -euo pipefail

# --- Config ---------------------------------------------------------------
# Default install dir (override with: PREFIX=/some/path bash install.sh)
PREFIX="${PREFIX:-"$HOME/.local/bin"}"
RAW_URL="${RAW_URL:-https://raw.githubusercontent.com/shri-124/backup-folder-script/main/backup.sh}"
BIN_NAME="${BIN_NAME:-backup-folder}"

# --- Create install dir ---------------------------------------------------
mkdir -p "$PREFIX"

# --- Download script ------------------------------------------------------
TMP="$(mktemp)"
echo "Downloading backup.sh..."
curl -fsSL "$RAW_URL" -o "$TMP"

chmod +x "$TMP"
mv "$TMP" "$PREFIX/$BIN_NAME"

echo "✅ Installed to: $PREFIX/$BIN_NAME"

# --- Ensure PATH contains PREFIX -----------------------------------------
add_path_line='export PATH="$HOME/.local/bin:$PATH"'

ensure_in_file() {
  local file="$1" line="$2"
  # Create the file if it doesn't exist
  [[ -e "$file" ]] || touch "$file"
  # Add the line only if it's not present
  if ! grep -Fqs "$line" "$file"; then
    printf '\n# Added by backup-folder installer\n%s\n' "$line" >> "$file"
    echo "Updated $file to include $PREFIX in PATH."
  fi
}

needs_path_add() {
  case ":$PATH:" in
    *":$PREFIX:"*) return 1 ;;  # already in PATH
    *) return 0 ;;
  esac
}

if needs_path_add; then
  # Try to detect shell and update appropriate profile files
  SHELL_NAME="$(basename "${SHELL:-bash}")"
  case "$SHELL_NAME" in
    bash)
      # WSL/Ubuntu typically uses ~/.bashrc; macOS bash may use ~/.bash_profile
      ensure_in_file "$HOME/.bashrc" 'export PATH="$HOME/.local/bin:$PATH"'
      if [[ "$OSTYPE" == "darwin"* ]]; then
        ensure_in_file "$HOME/.bash_profile" 'export PATH="$HOME/.local/bin:$PATH"'
      fi
      ;;
    zsh)
      ensure_in_file "$HOME/.zshrc" 'export PATH="$HOME/.local/bin:$PATH"'
      ;;
    fish)
      # For fish shell, use universal variable
      if command -v fish >/dev/null 2>&1; then
        if ! fish -c "contains $HOME/.local/bin \$fish_user_paths" >/dev/null 2>&1; then
          fish -c "set -U fish_user_paths $HOME/.local/bin \$fish_user_paths"
          echo "Updated fish_user_paths to include $HOME/.local/bin."
        fi
      fi
      ;;
    *)
      # Fallback to bashrc
      ensure_in_file "$HOME/.bashrc" 'export PATH="$HOME/.local/bin:$PATH"'
      ;;
  escase
  echo "ℹ️  Open a new terminal or run: source ~/.bashrc (or ~/.zshrc) to refresh PATH."
else
  echo "PATH already includes $PREFIX."
fi

echo
echo "Run: $BIN_NAME --help"

