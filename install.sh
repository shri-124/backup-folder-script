#!/usr/bin/env bash
set -euo pipefail

# Choose install location (~/.local/bin if available; else ~/bin; else /usr/local/bin)
PREFIX="${PREFIX:-}"
if [[ -z "$PREFIX" ]]; then
  if [[ -d "$HOME/.local/bin" ]]; then PREFIX="$HOME/.local/bin"
  elif [[ -d "$HOME/bin" ]]; then PREFIX="$HOME/bin"
  else PREFIX="/usr/local/bin"
  fi
fi

mkdir -p "$PREFIX"
TMP="$(mktemp)"
# Replace USERNAME and REPO below after you push your repo (step 4)
RAW_URL="https://raw.githubusercontent.com/USERNAME/REPO/main/backup.sh"

echo "Downloading backup.sh..."
curl -fsSL "$RAW_URL" -o "$TMP"
chmod +x "$TMP"
mv "$TMP" "$PREFIX/backup-folder"

echo "Installed to: $PREFIX/backup-folder"
echo "Ensure $PREFIX is in your PATH. Try: backup-folder --help"
