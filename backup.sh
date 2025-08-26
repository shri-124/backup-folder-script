#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <folder>

Required:
  <folder>               Path to the folder you want to back up.

Options:
  --encrypt              Encrypt archive with a passphrase (GPG symmetric).
  --encrypt-recipient=<email>
                         Encrypt with a public key for recipient (requires imported key).
  --cloud[=provider]     Simulate an upload. Providers: github|s3 (default: generic).
  --outdir=<path>        Where to store backups (default: ./backups)
  -h, --help             Show this help.

Notes:
- Archives are named: <name>_<YYYY-mm-dd_HH-MM-SS>.tar.gz (or .tar.gz.gpg if encrypted)
- The backups/ directory is created if it doesn't exist.
EOF
}

# Defaults
ENCRYPT_MODE=""
RECIPIENT=""
CLOUD=""
OUTDIR="backups"
SRC_DIR=""
EXTRA=()

# Parse args (simple long-option parser)
for arg in "$@"; do
  case "$arg" in
    --encrypt)
      ENCRYPT_MODE="symmetric";;
    --encrypt-recipient=*)
      ENCRYPT_MODE="recipient"
      RECIPIENT="${arg#*=}";;
    --cloud)
      CLOUD="generic";;
    --cloud=*)
      CLOUD="${arg#*=}";;
    --outdir=*)
      OUTDIR="${arg#*=}";;
    -h|--help)
      usage; exit 0;;
    -*)
      echo "Unknown option: $arg"; usage; exit 1;;
    *)
      if [[ -z "${SRC_DIR:-}" ]]; then SRC_DIR="$arg"; else EXTRA+=("$arg"); fi;;
  esac
done

if [[ -z "${SRC_DIR:-}" ]]; then
  echo "Error: <folder> is required."; usage; exit 1
fi
if [[ ! -d "$SRC_DIR" ]]; then
  echo "Error: '$SRC_DIR' is not a directory or does not exist."; exit 1
fi

# Resolve paths
if command -v realpath >/dev/null 2>&1; then
  SRC_DIR_ABS="$(realpath "$SRC_DIR")"
else
  pushd "$(dirname "$SRC_DIR")" >/dev/null
  SRC_DIR_ABS="$PWD/$(basename "$SRC_DIR")"
  popd >/dev/null
fi

mkdir -p "$OUTDIR"

timestamp="$(date +'%Y-%m-%d_%H-%M-%S')"
base="$(basename "$SRC_DIR_ABS")"
archive="${OUTDIR}/${base}_${timestamp}.tar.gz"

# Create the archive (use -C to avoid path issues with spaces)
tar -czf "$archive" -C "$(dirname "$SRC_DIR_ABS")" "$base"

# Quick integrity check
tar -tzf "$archive" >/dev/null

final_artifact="$archive"

# Optional encryption
if [[ -n "$ENCRYPT_MODE" ]]; then
  if ! command -v gpg >/dev/null 2>&1; then
    echo "Error: gpg not found. Install GnuPG to use --encrypt."; exit 1
  fi
  enc="${archive}.gpg"
  if [[ "$ENCRYPT_MODE" == "symmetric" ]]; then
    echo ">>> Encrypting (symmetric). You'll be prompted for a passphrase."
    gpg --quiet --symmetric --cipher-algo AES256 --output "$enc" "$archive"
  else
    if [[ -z "$RECIPIENT" ]]; then
      echo "Error: --encrypt-recipient requires an email (key must be imported)."; exit 1
    fi
    echo ">>> Encrypting for recipient: $RECIPIENT"
    gpg --quiet --yes --output "$enc" --encrypt --recipient "$RECIPIENT" "$archive"
  fi
  rm -f "$archive"
  final_artifact="$enc"
fi

# Optional "cloud" simulation
if [[ -n "$CLOUD" ]]; then
  case "$CLOUD" in
    github)
      dest="simulated_remote/github/releases";;
    s3)
      dest="simulated_remote/s3/bucket";;
    generic|*)
      dest="simulated_remote/uploads";;
  esac
  mkdir -p "$dest"
  cp -f "$final_artifact" "$dest/"
  echo ">>> Simulated upload:"
  case "$CLOUD" in
    github)
      echo "    # e.g., gh release upload v1.0 \"$final_artifact\""
      ;;
    s3)
      echo "    # e.g., aws s3 cp \"$final_artifact\" s3://my-bucket/"
      ;;
    *)
      echo "    # e.g., curl -T \"$final_artifact\" https://example.com/upload"
      ;;
  esac
  echo "    Copied to: $dest/$(basename "$final_artifact")"
fi

echo "✅ Backup created: $final_artifact"
