#!/bin/bash

# Pastikan skrip dijalankan dengan hak akses root
if [ "$(id -u)" -ne 0 ]; then
    echo "Skrip ini harus dijalankan sebagai root. Gunakan sudo!"
    exit 1
fi

# Variabel username dan password
USER_NAME="lenwy"
USER_PASSWORD="123"
SHARED_FOLDER="/srv/shared"

# 1. Update dan instalasi Samba
echo "Melakukan update sistem..."
apt update && apt upgrade -y

echo "Menginstal Samba..."
apt install samba -y

# 2. Membuat direktori untuk file sharing
echo "Membuat direktori untuk sharing files di $SHARED_FOLDER..."
mkdir -p $SHARED_FOLDER

# 3. Membuat user di Ubuntu
echo "Membuat user $USER_NAME..."
adduser --disabled-password --gecos "" $USER_NAME
echo "$USER_NAME:$USER_PASSWORD" | chpasswd

# 4. Memberikan hak akses pada direktori
echo "Memberikan akses ke direktori untuk user $USER_NAME..."
chown -R $USER_NAME:$USER_NAME $SHARED_FOLDER
chmod -R 0777 $SHARED_FOLDER

# 5. Menambahkan user ke Samba
echo "Menambahkan user $USER_NAME ke Samba..."
smbpasswd -a $USER_NAME
echo -e "$USER_PASSWORD\n$USER_PASSWORD" | smbpasswd -a $USER_NAME

# 6. Mengonfigurasi Samba untuk sharing folder
echo "Mengonfigurasi Samba..."
cat <<EOL >> /etc/samba/smb.conf

[SharedFolder]
path = $SHARED_FOLDER
browseable = yes
writable = yes
valid users = $USER_NAME
create mask = 0777
directory mask = 0777
EOL

# 7. Mengaktifkan user di Samba
smbpasswd -e $USER_NAME

# 8. Restart layanan Samba
echo "Merestart layanan Samba..."
systemctl restart smbd

# 9. Menambahkan firewall rule untuk Samba (Jika menggunakan UFW)
if ufw status | grep -q "active"; then
    echo "Menambahkan aturan firewall untuk Samba..."
    ufw allow samba
fi

# 10. Menampilkan informasi selesai
echo "Samba telah dikonfigurasi dengan user $USER_NAME dan folder sharing di $SHARED_FOLDER"
echo "Cek koneksi ke folder melalui \\$(hostname -I) di Windows"
