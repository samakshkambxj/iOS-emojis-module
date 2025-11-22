#####################################
#     Android Emoji Changer
#                By
# Khun Htetz Naing (t.me/HtetzNaing)
#####################################

# Load utils script
. "$MODPATH/utils.sh"

clear_cache() {
	PKG="$1"
	for subpath in "cache code_cache app_webview files/GCache"; do
		target_dir="/data/data/${PKG}/${subpath}"
		if [ -d "$target_dir" ]; then
			rm -rf "$target_dir"
		fi
	done

	# Force-stop
	force_stop_app "PKG"
}

replace_app_emoji() {
	local PKG="$1"
	local NAME="$2"
	local FONT_PATH="$3"
	local BASE_DIR="/data/data/$PKG"
	local TARGET_FILE="$BASE_DIR/$FONT_PATH"

	if package_installed "$PKG"; then
		ui_print "[!] $NAME 📱"
		ui_print " - $TARGET_FILE"
		if [ -f "$TARGET_FILE" ]; then
			if safe_replace_file "$MAIN_FONT_FILE" "$TARGET_FILE"; then
				ui_print " - Replaced emojis ✅"
				clear_cache "$PKG" && ui_print " - Cleared cache ✅"
			else
				ui_print " - Replaced emojis ❎"
			fi
		else
			ui_print " - No Emoji found ℹ️"
		fi
	else
		ui_print "[!] Not installed: $NAME"
	fi
}

gb_emoji() {
	local PKG="com.google.android.inputmethod.latin"
	if package_installed "$PKG"; then
		ui_print "[!] GBoard ⌨️"
		clear_cache "$PKG" && ui_print " - Cleared cache ✅"
	else
		ui_print "[!] Not installed: $NAME"
	fi
}

system_emoji() {
	ui_print "[!] System Emojis ⚙️"
	ui_print "[+] $MAIN_FONT_NAME ✅"
	for font in $VARIANTS; do
		local mirror="$FONT_DIR/$font"
		local system="/system/fonts/$font"
		if [ -f "$system" ] && [ ! -f "$mirror" ]; then
			if cp "$MAIN_FONT_FILE" "$mirror"; then
				ui_print "[+] $font ✅"
			else
				ui_print "[-] $font ❎"
			fi
		fi
	done
}

disable_conflict_modules() {
	local modules=$(get_conflict_font_modules $MODID)
	if [ -n "$modules" ]; then
		ui_print ""
		ui_print " ℹ️ Conflicts font modules ⚔️"
		ui_print "******************************"
		local conflict_count=0
		for id in $modules; do
			local full_path="$MODULES_DIR/$id"
			name=$(grep_prop name "$full_path/module.prop")
			conflict_count=$((conflict_count + 1))
			if disable_module "$id"; then
				ui_print "$conflict_count. $name [DISABLED]"
			else
				ui_print "$conflict_count. $name [PLZ DISABLE]"
			fi
		done
		if [ $conflict_count != 0 ]; then
			ui_print ""
			ui_print "*IMPORTANT: Make sure to disable other font modules to ensure this one works!!"
		fi
	fi
}

kernelSU() {
	if is_kernelsu; then
		ui_print ""
		ui_print " ℹ️ KernelSU ✨"
		ui_print "****************"
		if mv -f "$MODPATH/ksu.sh" "$MODPATH/post-fs-data.sh"; then
			ui_print "[+] post-fs-data.sh ✅"
		else
			ui_print "[-] post-fs-data.sh ❎"
		fi
	fi
}

credits() {
	ui_print ""
	ui_print " Credits & Thanks 🙏"
	ui_print "*********************"
	ui_print "- killgmsfont | @MrCarb0n"
	ui_print "- Reboot your device to apply changes :)"
}

# Main script execution
system_emoji
replace_app_emoji "com.facebook.orca" "Messenger" "app_ras_blobs/FacebookEmoji.ttf"
replace_app_emoji "com.facebook.katana" "Facebook" "app_ras_blobs/FacebookEmoji.ttf"
replace_app_emoji "com.facebook.lite" "Facebook Lite" "files/emoji_font.ttf"
replace_app_emoji "com.facebook.mlite" "Messenger Lite" "files/emoji_font.ttf"
gb_emoji
kernelSU
disable_conflict_modules
credits

# Main sure enable module
enable_module "$MODID"
