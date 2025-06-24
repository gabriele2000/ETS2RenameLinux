# ETS2 Profile Renamer (Linux)

A simple Bash script to rename **Euro Truck Simulator 2** profiles on **Linux (Steam native)**.

---

## 📦 Features

- Works with profiles in both:
  - `profiles`
  - `steam_profiles/`
  - `steam_profiles(...).bak/` (all backups)
- Detects and lists available profiles
- Converts between hex folder names and readable names
- Updates the `profile_name` inside `profile.sii`
- Handles folder rename to match the new hex name

---

## 🧰 Requirements

- Linux system with Steam and ETS2 installed
- `wine` installed and working
- `wget`, `xxd`, and `sed` (usually pre-installed)

To install Wine (if not already installed):

```bash
sudo pacman -S wine      # Arch
sudo apt install wine    # Debian/Ubuntu
````

---

## 🚀 Usage

```bash
chmod +x ETS2RenameLinux.sh
./ETS2RenameLinux.sh
```

You'll be prompted to:

1. Select the profile folder to use (e.g., `steam_profiles`, `profiles`)
2. Choose which profile to rename
3. Enter the new name
4. Confirm the rename

The script will:

* Decrypt `profile.sii` using `SII_Decrypt.exe` (downloaded automatically if missing)
* Edit the internal name
* Rename the profile folder

---

## 📄 License

MIT License – you are free to use, modify, and redistribute this script.

---

## 🙏 Credits

* Original idea and BAT version by [Zoult](https://github.com/Zoult/ets2-profile-renamer)
* SII files Decrypt by [TheLazyTomcat](https://github.com/TheLazyTomcat/SII_Decrypt)

