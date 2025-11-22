#!/bin/bash

# Paths and configurations
FONT_DIR="$MODPATH/system/fonts"
MAIN_FONT_NAME='NotoColorEmoji.ttf'
MAIN_FONT_FILE="$FONT_DIR/$MAIN_FONT_NAME"
VARIANTS='SamsungColorEmoji.ttf AndroidEmoji-htc.ttf ColorUniEmoji.ttf DcmColorEmoji.ttf CombinedColorEmoji.ttf HTC_ColorEmoji.ttf LGNotoColorEmoji.ttf NotoColorEmojiLegacy.ttf'
MODULES_DIR="/data/adb/modules"
MODULES_UPDATE_DIR="/data/adb/modules_update"

read_emoji_names() {
	local FONT_XML="$1"
	# Extract font file names for emoji fonts from fonts.xml
	sed -ne '/<family lang="und-Zsye".*>/,/<\/family>/ {s/.*<font weight="400" style="normal">\([^<]*\)<\/font>.*/\1/p;}' "$FONT_XML"
}

get_emoji_names() {
	# Define paths and attempt to replace fonts from XML
	FONT_XML_PATH="/system/etc/fonts.xml"
	MIRROR_PATH="/sbin/.core/mirror$FONT_XML_PATH"
	LIST=$(read_emoji_names "$FONT_XML_PATH")
	if [ -f "$MIRROR_PATH" ]; then
		LIST2=$(read_emoji_names "$FONT_XML_PATH")
		LIST="${LIST} ${LIST2}"
	fi
	echo "$LIST"
}

is_conflict() {
	local system_font="$1/system/fonts"
	if [ -d "$system_font" ] && cd "$system_font"; then
		for file in *; do
			if echo "$VARIANTS" | grep -q "$(basename "$file")"; then
				return 0
			fi
		done
	fi
	return 1
}

is_kernelsu() {
	[ "$KSU" = true ]
}

is_apatch() {
	[ "$APATCH" = true ]
}

is_magisk() {
	! is_kernelsu && ! is_apatch && command -v magisk &>/dev/null
}

str_trim() {
	input="$1"
	# Trim leading and trailing whitespace
	input="${input#"${input%%[![:space:]]*}"}"
	input="${input%"${input##*[![:space:]]}"}"
	echo "$input"
}

get_conflict_font_modules() {
	local ignore_id="$1"
	local conflict_modules=""
	# Check if directory exists and is not empty
	if [ -d "$MODULES_DIR" ] && [ "$(ls -A "$MODULES_DIR" 2>/dev/null)" ]; then
	  # Use full paths instead of changing directory
		for module_path in "$MODULES_DIR"/*; do
			[ ! -e "$module_path" ] && continue

			# Get just the module ID (basename)
			local id=$(basename "$module_path")

			# Skip hidden files and non-directories
			[[ "$id" == .* ]] && continue
			[ ! -d "$module_path" ] && continue

			local upd_path="$MODULES_UPDATE_DIR/$id"
			if is_conflict "$module_path" || is_conflict "$upd_path"; then
				local disable_path="$module_path/disable"
				if [ ! -f "$disable_path" ] && [ "$ignore_id" != "$id" ]; then
					conflict_modules="${conflict_modules} $id"
				fi
			fi
		done
	fi

	# Trim leading and trailing whitespace
	str_trim "${conflict_modules}"
}

enable_module() {
	rm -f "$MODULES_DIR/$1"/{disable,remove}
}

disable_module() {
  local id="$1"
  if is_magisk; then
    touch "$MODULES_DIR/$id/disable"
  else
    ksud module disable "$id" || apd module disable "$id"
  fi
}

uninstall_module() {
  local id="$1"
  if is_magisk; then
    touch "$MODULES_DIR/$id/remove"
  else
    ksud module uninstall "$id" || apd module uninstall "$id"
  fi
}

fix_conflicts() {
	current="$1"
	local conflict_count=0
	for id in $(get_conflict_font_modules); do
		conflict_count=$((conflict_count + 1))
		if [ "$id" != "$current" ]; then
			if disable_module "$id"; then
				echo "$conflict_count. $id [DISABLED]"
			else
				echo "$conflict_count. $id [CANNOT DISABLE]"
			fi
		fi
	done
}

read_module_prop() {
	cat "$MODULES_DIR/$1/module.prop"
}

package_installed() {
	pm path "$1" >/dev/null
	return $?
}

flash_module() {
	local zip="$1"
	magisk --install-module "$zip" || ksud module install "$zip" || apd module install "$zip"
}

mount_font(){
  if mount -o bind "$1" "$2"; then
      # Ensure correct permissions for the replacement file
      chmod 644 "$system"
  else
    return 1
  fi
}

force_stop_app(){
  run_silently am force-stop "$1"
}

run_silently() {
    "$@" > /dev/null 2>&1
}

safe_replace_file() {
  local source="$1"
  local target="$2"

  # Get original file info - FIXED: added stat command and proper capture
  local original_perms=$(stat -c '%a' "$target" 2>/dev/null)

  # Check if we got the permissions
  if [ -z "$original_perms" ]; then
    original_perms=644
  fi

  if cp "$source" "$target"; then
      chmod "$original_perms" "$target"
      return 0
  else
      return 1
  fi
}

# Append variants from fonts.xml
VARIANTS="${VARIANTS} $(get_emoji_names)"
