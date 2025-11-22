#!/bin/bash

# Determine the directory of the script
MODDIR="${0%/*}"

# Find the first .ttf file in the specified directory
FONT_FILE=$(find "$MODDIR/system/fonts" -type f -name "*.ttf" 2>/dev/null | head -n 1)

# Load utils script
. "$MODDIR/utils.sh"

mount_emojis() {
	for font in $VARIANTS; do
		local system="/system/fonts/$font"
		if [ -f "$system" ]; then
		  mount_font "$FONT_FILE" "$system"
		fi
	done
}

mount_emojis
