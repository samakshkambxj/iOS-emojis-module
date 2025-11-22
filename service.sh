# Determine the directory of the script
MODDIR="${0%/*}"

# Load utils script
. "$MODDIR/utils.sh"

log() {
	echo "[*] $(echo "$1" | sed 's/^[A-Z]*: //')"
}

# Log script header
log "==================================="
log "Brand: $(getprop ro.product.brand)"
log "Device: $(getprop ro.product.model)"
log "Android Version: $(getprop ro.build.version.release)"
log "==================================="

replace_emoji_fonts() {
	log "INFO: Starting emoji replacement process..."
	# Find all .ttf files containing "Emoji" in their names
	EMOJI_FONTS=$(find /data/data -iname "*emoji*.ttf")
	if [ -z "$EMOJI_FONTS" ]; then
		log "INFO: No emoji fonts found to replace. Skipping."
		return
	fi

	# Replace each emoji font with the custom font
	for font in $EMOJI_FONTS; do
		# Check if the target font file is writable
		if [ ! -w "$font" ]; then
			log "ERROR: Font file is not writable: $font"
			continue
		fi

		if safe_replace_file $MAIN_FONT_FILE "$font"; then
			log "INFO: Successfully replaced emoji font: $font"
		else
			log "ERROR: Failed to mount emoji font: $font"
		fi
	done

	log "INFO: Emoji replacement process completed."
}

# Thanks to @MrCarb0n https://github.com/MrCarb0n/killgmsfont/blob/master/customize.sh
# Disable GMS' font service
disable_gms_font_service() {
	GMSF="com.google.android.gms/com.google.android.gms.fonts"
	UPS=$(ls -d /data/user/*) # Dynamically get user profiles
	PM="$(command -v pm)"
	for UP in $UPS; do
		run_silently pm disable --user "${UP##*/}" "$GMSF.update.UpdateSchedulerService"
		run_silently pm disable --user "${UP##*/}" "$GMSF.provider.FontsProvider"
	done
}

delete_gms_font() {
	DATA_FONTS_DIR="/data/fonts"
	if [ -d "$DATA_FONTS_DIR" ]; then
		if ! rm -rf "$DATA_FONTS_DIR"; then
			log "ERROR: Failed to clean up directory: $DATA_FONTS_DIR"
		else
			log "INFO: Successfully cleaned up directory: $DATA_FONTS_DIR"
		fi
	fi

	local gms_font_dir = "/data/data/com.google.android.gms/files/fonts/opentype"
	EMOJI_FONTS=$(find "$gms_font_dir" -iname "*emoji*.ttf")
	if [ -n "$EMOJI_FONTS" ]; then
		for font in $EMOJI_FONTS; do
			if safe_replace_file "$MAIN_FONT_FILE" "$font"; then
				log "Mounted: $font"
			fi
		done
	fi
}

force_stop_fb_apps() {
	local pkgs = "com.facebook.orca com.facebook.katana com.facebook.lite com.facebook.mlite"
	for pkg in $pkgs; do
		if package_installed "$pkg"; then
			if force_stop_app "$pkg"; then
				log "INFO: Successfully force-stopped app: $pkg"
			else
				log "ERROR: Failed to force-stop app: $pkg"
			fi
		fi
	done
}

# Wait until the device has completed booting
until [ "$(resetprop sys.boot_completed)" = "1" ] && [ -d "/data" ]; do
	sleep 1
done

replace_emoji_fonts
disable_gms_font_service
delete_gms_font
force_stop_fb_apps