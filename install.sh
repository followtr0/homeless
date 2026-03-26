#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
ADDON_NAME="Homeless"
DEST_ROOT="/Applications/World of Warcraft/_retail_/Interface/AddOns"
DEST_DIR="$DEST_ROOT/$ADDON_NAME"

echo "Installing $ADDON_NAME to: $DEST_DIR"

rm -rf "$DEST_DIR"
mkdir -p "$DEST_DIR/libs/LibStub"
mkdir -p "$DEST_DIR/libs/CallbackHandler-1.0"
mkdir -p "$DEST_DIR/libs/LibDataBroker-1.1"
mkdir -p "$DEST_DIR/libs/LibDBIcon-1.0"
mkdir -p "$DEST_DIR/core"
mkdir -p "$DEST_DIR/ui"

# Copy TOC
cp "$SOURCE_DIR/Homeless.toc" "$DEST_DIR/Homeless.toc"

# Copy libs
cp "$SOURCE_DIR/libs/LibStub/LibStub.lua" "$DEST_DIR/libs/LibStub/LibStub.lua"
cp "$SOURCE_DIR/libs/CallbackHandler-1.0/CallbackHandler-1.0.lua" "$DEST_DIR/libs/CallbackHandler-1.0/CallbackHandler-1.0.lua"
cp "$SOURCE_DIR/libs/LibDataBroker-1.1/LibDataBroker-1.1.lua" "$DEST_DIR/libs/LibDataBroker-1.1/LibDataBroker-1.1.lua"
cp "$SOURCE_DIR/libs/LibDBIcon-1.0/LibDBIcon-1.0.lua" "$DEST_DIR/libs/LibDBIcon-1.0/LibDBIcon-1.0.lua"

# Copy addon files
cp "$SOURCE_DIR/Homeless.lua" "$DEST_DIR/Homeless.lua"
cp "$SOURCE_DIR/core/db.lua" "$DEST_DIR/core/db.lua"
cp "$SOURCE_DIR/core/housing.lua" "$DEST_DIR/core/housing.lua"
cp "$SOURCE_DIR/core/smells.lua" "$DEST_DIR/core/smells.lua"
cp "$SOURCE_DIR/ui/warning.lua" "$DEST_DIR/ui/warning.lua"
cp "$SOURCE_DIR/ui/minimap.lua" "$DEST_DIR/ui/minimap.lua"

echo "Done. Reload UI in-game with /reload"
