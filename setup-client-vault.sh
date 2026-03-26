#!/usr/bin/env bash
# setup-client-vault.sh
# Copy the vault-template into an existing Obsidian vault and optionally
# substitute a client name throughout all copied files.
#
# Usage:
#   ./setup-client-vault.sh /path/to/vault
#   ./setup-client-vault.sh /path/to/vault "Smith Family"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/vault-template"

# ---- Arguments ---------------------------------------------------------------

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <vault-path> [client-name]"
  echo "  vault-path    Path to your Obsidian vault (or any directory)"
  echo "  client-name   Optional. Replaces [CLIENT] in all copied files."
  exit 1
fi

VAULT_PATH="$1"
CLIENT_NAME="${2:-}"

# ---- Validate ----------------------------------------------------------------

if [[ ! -d "$VAULT_PATH" ]]; then
  echo "Error: vault path does not exist: $VAULT_PATH"
  exit 1
fi

if [[ ! -d "$TEMPLATE_DIR" ]]; then
  echo "Error: vault-template directory not found at $TEMPLATE_DIR"
  exit 1
fi

# ---- Copy --------------------------------------------------------------------

DEST="$VAULT_PATH/Genealogy"

if [[ -d "$DEST" ]]; then
  echo "Warning: $DEST already exists. Files will be merged (existing files will not be overwritten)."
  CP_FLAGS="-rn"
else
  CP_FLAGS="-r"
fi

cp $CP_FLAGS "$TEMPLATE_DIR/." "$DEST"
echo "Copied vault-template to: $DEST"

# ---- Substitute client name --------------------------------------------------

if [[ -n "$CLIENT_NAME" ]]; then
  # Find all markdown files in the destination and replace [CLIENT] placeholder
  while IFS= read -r -d '' file; do
    if grep -q "\[CLIENT\]" "$file" 2>/dev/null; then
      # Use a temp file to avoid in-place issues on all platforms
      tmp=$(mktemp)
      sed "s/\[CLIENT\]/$CLIENT_NAME/g" "$file" > "$tmp"
      mv "$tmp" "$file"
    fi
  done < <(find "$DEST" -type f -name "*.md" -print0)
  echo "Substituted [CLIENT] with: $CLIENT_NAME"
fi

# ---- Summary -----------------------------------------------------------------

FILE_COUNT=$(find "$DEST" -type f | wc -l | tr -d ' ')
echo ""
echo "Setup complete."
echo "  Destination : $DEST"
echo "  Files       : $FILE_COUNT"
if [[ -n "$CLIENT_NAME" ]]; then
  echo "  Client      : $CLIENT_NAME"
fi
echo ""
echo "Next steps:"
echo "  1. Open $DEST in Obsidian."
echo "  2. Fill in Family_Tree.md with what you already know about this client's family."
echo "  3. Add scanned documents to a folder and update Data_Inventory.md."
echo "  4. Run prompts/13-document-annotation.md to begin annotating documents."
