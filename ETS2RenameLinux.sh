#!/bin/bash

# ETS2 Profile Renamer for Linux (Steam native)
# Compatible with profiles in both active and backup folders

DOCS_DIR="$HOME/.local/share/Euro Truck Simulator 2"
SII_DECRYPT_URL="https://raw.githubusercontent.com/Cubixty/sii-decrypt/main/SII_Decrypt%20(any%20format).exe"
SII_DECRYPT_EXE="./SII_Decrypt.exe"

# Discover all "steam_profiles*" directories (active + backups)
PROFILE_DIRS=()
while IFS= read -r -d '' dir; do
    PROFILE_DIRS+=("$dir")
done < <(find "$DOCS_DIR" -maxdepth 1 -type d -name "steam_profiles*" -print0 | sort -z)

if [ ${#PROFILE_DIRS[@]} -eq 0 ]; then
    echo "❌ No steam_profiles folders found in $DOCS_DIR"
    exit 1
fi

# Ask user to select one of the profile directories
echo "Select which profile folder to use:"
select CHOSEN_DIR in "${PROFILE_DIRS[@]}"; do
    if [[ -n "$CHOSEN_DIR" ]]; then
        PROFILES_DIR="$CHOSEN_DIR"
        break
    else
        echo "Invalid choice, try again."
    fi
done

# Helper: convert hex to readable string
function decode_hex {
    echo "$1" | xxd -r -p
}

# Helper: convert string to uppercase hex
function encode_hex {
    echo -n "$1" | xxd -p | tr '[:lower:]' '[:upper:]'
}

while true; do
    clear
    echo "--------------------------------------"
    echo "Euro Truck Simulator 2 Rename Linux"
    echo "--------------------------------------"
    echo ""
    echo "Using profile folder: $PROFILES_DIR"
    echo ""
    echo "- Saved profiles:"
    echo ""

    # List profile folders
    mapfile -t profiles < <(find "$PROFILES_DIR" -mindepth 1 -maxdepth 1 -type d | sort)
    if [ ${#profiles[@]} -eq 0 ]; then
        echo "❌ No profiles found in selected folder."
        read -n 1 -s -r -p "Press any key to exit..."
        exit 1
    fi

    for p in "${profiles[@]}"; do
        hex_name=$(basename "$p")
        readable_name=$(decode_hex "$hex_name" 2>/dev/null)
        echo "- ${readable_name:-UNKNOWN} = $hex_name"
    done

    echo ""
    read -rp "Paste the profile Hex code to rename: " sel
    PROFILE_DIR="$PROFILES_DIR/$sel"

    if [[ ! -d "$PROFILE_DIR" ]]; then
        echo "❌ Profile not found. Try again."
        read -n 1 -s -r -p "Press any key to continue..."
        continue
    fi

    read -rp "Rename this profile to (new name): " ren
    hex=$(encode_hex "$ren")

    if [[ -d "$PROFILES_DIR/$hex" ]]; then
        echo "⚠️ A profile with this name already exists. Choose another."
        read -n 1 -s -r -p "Press any key to continue..."
        continue
    fi

    read -rp "Confirm rename? (y/n): " conf
    if [[ "$conf" != "y" && "$conf" != "Y" ]]; then
        continue
    fi

    # Force g_save_format = 2 in config.cfg (safe format)
    sed -i 's/uset g_save_format ".*"/uset g_save_format "2"/' "$DOCS_DIR/config.cfg" 2>/dev/null

    # Download SII_Decrypt.exe if not present
    if [[ ! -f "$SII_DECRYPT_EXE" ]]; then
        echo "⬇️  Downloading SII_Decrypt.exe..."
        wget "$SII_DECRYPT_URL" -O "$SII_DECRYPT_EXE"
        chmod +x "$SII_DECRYPT_EXE"
    fi

    # Find the profile.sii file in the selected profile folder
    PROFILE_SII_PATH="$PROFILE_DIR/profile.sii"
    if [[ ! -f "$PROFILE_SII_PATH" ]]; then
        echo "❌ profile.sii not found in $PROFILE_SII_PATH"
        read -n 1 -s -r -p "Press any key to continue..."
        continue
    fi

    # Run SII Decrypt
    echo "🔓 Decrypting profile..."
    wine "$SII_DECRYPT_EXE" "$PROFILE_SII_PATH"

    # Replace profile name in profile.sii
    echo "✏️ Updating profile name inside profile.sii..."
    sed -i "s/profile_name:.*/profile_name: \"$ren\"/" "$PROFILE_SII_PATH"

    # Rename folder
    mv "$PROFILE_DIR" "$PROFILES_DIR/$hex"

    echo ""
    echo "✅ Done! Profile renamed successfully."
    echo ""
    read -n 1 -s -r -p "Press any key to rename another profile..."
done
