# 🚀 Automated WHM to Google Drive Backup Sync

A production-ready Bash script designed for system administrators and developers to automate cPanel account backups and transfer them directly to Google Drive using **Rclone**.

## ✨ Key Features
* **Zero-Footprint:** Moves backups directly to the cloud, ensuring your server's disk space is never bloated.
* **Native Integration:** Uses cPanel's internal `/scripts/pkgacct` for reliable and safe backups.
* **Smart Filtering:** Easily exclude specific accounts (like staging or development sites).
* **Organized Storage:** Automatically creates date-stamped directories in your Google Drive.

## 🛠 Prerequisites
* Root access to a WHM/cPanel server.
* [Rclone](https://rclone.org/) installed and configured with a remote named `gdrive`.

## 🚀 Installation

1. **Clone or Copy the script:**
   Download `gdrive_sync.sh` to your `/root` directory.

2. **Configure the Script:**
   Edit the `EXCLUDE_USER` variable inside the script to skip any specific account.

3. **Set Permissions:**
   ```bash
   chmod +x /root/gdrive_sync.sh
   
Run Manually:

Bash
./gdrive_sync.sh


## 📅 Automation (Cron Job)
To run this backup every Friday at 2:00 AM, add this to your crontab (`crontab -e`):
```bash
0 2 * * 5 /root/gdrive_sync.sh > /root/gdrive_sync.log 2>&1
📜 License
MIT License - Created for the DevOps community.


---

### ۲. محتوای فایل `gdrive_sync.sh` (کد اصلی اسکریپت)
این کد اصلی است که عملیات بکاپ و انتقال را انجام می‌دهد. محتوای زیر را کپی و در فایل `gdrive_sync.sh` قرار دهید:

```bash
#!/bin/bash
# -------------------------------------------------------------------------
# FactWeb AI Elite - Automated WHM to GDrive Sync
# Description: Packs cPanel accounts and moves them to Google Drive.
# -------------------------------------------------------------------------

# --- CONFIGURATION ---
EXCLUDE_USER="account_to_skip" # نام کاربری که نمیخواهید بکاپ گرفته شود را اینجا بنویسید
BACKUP_DIR="/home/gdrive_temp"
DATE_SUFFIX=$(date +%F)
GDRIVE_REMOTE="gdrive:WHM_Backups/$DATE_SUFFIX"

# --- INITIALIZATION ---
mkdir -p $BACKUP_DIR
echo "--- Starting Backup Process: $DATE_SUFFIX ---"

# Fetch all cPanel users
USERS=$(whmapi1 listaccts | grep "user:" | awk '{print $2}')

for user in $USERS; do
    # Check for excluded account
    if [ "$user" == "$EXCLUDE_USER" ]; then
        echo "[SKIP] Ignoring account: $user"
        continue
    fi

    echo "[1/2] Packing account: $user..."
    
    # Generate native cPanel backup
    /scripts/pkgacct $user $BACKUP_DIR > /dev/null 2>&1
    
    # Locate the generated file
    FILE_NAME=$(ls -1 $BACKUP_DIR | grep "^cpmove-$user" | head -n 1)

    if [ -n "$FILE_NAME" ]; then
        echo "[2/2] Uploading $user to Google Drive and clearing local cache..."
        # Move to GDrive (Automatically deletes the local file after success)
        rclone move "$BACKUP_DIR/$FILE_NAME" "$GDRIVE_REMOTE/" --progress
        echo "[SUCCESS] $user is securely stored in the cloud."
    else
        echo "[ERROR] Could not create backup for $user."
    fi
done

echo "--- Backup Operation Completed Successfully ---"
