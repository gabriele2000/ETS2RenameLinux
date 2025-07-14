#!/bin/bash

# ETS2 Profile Renamer for Linux (Steam native and offline)
# Supports profiles in steam_profiles, steam_profiles(*).bak and profiles/

DOCS_DIR="$HOME/.local/share/Euro Truck Simulator 2"
SII_DECODE="./sii-decode"
SII_DECODE_LINK="https://github.com/gabriele2000/ETS2RenameLinux/blob/aed3137332b9b24546be23b0fe908edbe2088611/sii-decode"

# Search for all relevant profile directories
PROFILE_DIRS=()
for dir in "$DOCS_DIR"/profiles "$DOCS_DIR"/steam_profiles*; do
    [[ -d "$dir" ]] && PROFILE_DIRS+=("$dir")
done

if [ ${#PROFILE_DIRS[@]} -eq 0 ]; then
    echo "❌ No profile folders found in $DOCS_DIR"
    exit 1
fi

# Let the user choose which one to use
echo "Select which profile folder to use:"
select CHOSEN_DIR in "${PROFILE_DIRS[@]}"; do
    if [[ -n "$CHOSEN_DIR" ]]; then
        PROFILES_DIR="$CHOSEN_DIR"
        break
    else
        echo "Invalid choice, try again."
    fi
done

# Hex/string conversion helpers
function decode_hex {
    echo "$1" | xxd -r -p
}

function encode_hex {
    echo -n "$1" | xxd -p | tr '[:lower:]' '[:upper:]'
}

# Main loop
while true; do
    clear
    echo "--------------------------------------"
    echo "Euro Truck Simulator 2 Profile Renamer"
    echo "--------------------------------------"
    echo ""
    echo "Using profile folder: $PROFILES_DIR"
    echo ""
    echo "- Saved profiles:"
    echo ""

    # List subfolders = hex profile folders
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

    # Force save format to text
    sed -i 's/uset g_save_format ".*"/uset g_save_format "2"/' "$DOCS_DIR/config.cfg" 2>/dev/null

    # Find profile.sii in the profile folder
    PROFILE_SII_PATH="$PROFILE_DIR/profile.sii"
    if [[ ! -f "$PROFILE_SII_PATH" ]]; then
        echo "❌ profile.sii not found in $PROFILE_SII_PATH"
        read -n 1 -s -r -p "Press any key to continue..."
        continue
    fi

    # Rename profile.sii to profile.sii.bak (overwrite if existing)
    mv -f "$PROFILE_DIR/profile.sii" "$PROFILE_DIR/profile.sii.bak"

    # Download decode tool if needed
    if [[ ! -f "$SII_DECODE" ]]; then
        echo "⬇️  Downloading sii-decode..."
        wget $SII_DECODE_LINK
        chmod +x "$SII_DECODE"
    fi
    
    # Decrypt profile.sii.bak and save the result in profile.sii
    echo "🔓 Decrypting profile and saving new file..."
    $SII_DECODE "$PROFILE_DIR/profile.sii.bak" &> "$PROFILE_DIR/profile.sii"
    
    # Replace name inside profile.sii.bak
    echo "✏️ Updating profile name..."
    sed -i "s/profile_name:.*/profile_name: \"$ren\"/" "$PROFILE_SII_PATH"

    # Rename the folder
    mv "$PROFILE_DIR" "$PROFILES_DIR/$hex"

    echo ""
    echo "✅ Done! Profile renamed successfully."
    echo ""
    read -n 1 -s -r -p "Press any key to rename another profile..."
done
