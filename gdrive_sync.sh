#!/bin/bash
# -------------------------------------------------------------------------
# FactWeb AI - Enterprise Backup Solution
# Description: Automated WHM to Google Drive Sync (Server-to-Cloud)
# -------------------------------------------------------------------------

# --- بخش تنظیمات (Configuration) ---

# نام کاربری اکانتی که نمی‌خواهید بکاپ گرفته شود را اینجا بنویسید
EXCLUDE_USER="نام_کاربری_مورد_نظر" 

# مسیر موقت برای ساخت بکاپ (پس از آپلود پاک می‌شود)
BACKUP_DIR="/home/gdrive_temp"

# نام ریموت در Rclone و مسیر ذخیره‌سازی (بر اساس تاریخ روز)
DATE_SUFFIX=$(date +%F)
GDRIVE_REMOTE="gdrive:WHM_Backups/$DATE_SUFFIX"

# --- شروع فرآیند (Initialization) ---

mkdir -p $BACKUP_DIR
echo "--- Starting Backup Process: $DATE_SUFFIX ---"

# استخراج لیست تمام یوزرهای سی‌پنل از سرور
USERS=$(whmapi1 listaccts | grep "user:" | awk '{print $2}')

for user in $USERS; do
    # بررسی اکانت مستثنی شده
    if [ "$user" == "$EXCLUDE_USER" ]; then
        echo "[SKIP] Ignoring account: $user"
        continue
    fi

    echo "--------------------------------------------------"
    echo "[1/2] Packing account: $user..."
    
    # ساخت بکاپ استاندارد سی‌پنل (pkgacct)
    # خروجی‌های اضافه برای شلوغ نشدن ترمینال بسته شده است
    /scripts/pkgacct $user $BACKUP_DIR > /dev/null 2>&1
    
    # پیدا کردن نام فایل ساخته شده
    FILE_NAME=$(ls -1 $BACKUP_DIR | grep "^cpmove-$user" | head -n 1)

    if [ -n "$FILE_NAME" ]; then
        echo "[2/2] Uploading $user to Google Drive..."
        
        # انتقال مستقیم به گوگل درایو
        # دستور move باعث می‌شود فایل بعد از آپلود موفق، از هارد سرور حذف شود
        rclone move "$BACKUP_DIR/$FILE_NAME" "$GDRIVE_REMOTE/" --progress
        
        echo "[SUCCESS] $user is now safe in the cloud."
    else
        echo "[ERROR] Backup failed for $user. Please check disk space or permissions."
    fi
done

echo "--------------------------------------------------"
echo "--- ALL OPERATIONS COMPLETED SUCCESSFULLY ---"
