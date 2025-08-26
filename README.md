# Backup & Compress Folder Script

A Bash CLI tool that creates timestamped `.tar.gz` backups of any folder into a `backups/` directory, with optional encryption (`--encrypt`, `--encrypt-recipient`) and simulated cloud uploads (`--cloud=github` or `--cloud=s3`).

---

## 🚀 Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/shri-124/backup-folder-script/main/install.sh | bash
