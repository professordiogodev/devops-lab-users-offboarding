#!/usr/bin/env bash
# Removes everything the lab created. Run with: sudo ./teardown.sh
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo" >&2; exit 1; }
pkill -u maya 2>/dev/null; pkill -f 'backup-sync' 2>/dev/null
crontab -u maya -r 2>/dev/null
rm -f /etc/sudoers.d/devs /etc/sudoers.d/tomas
for u in toor priya maya sam-contractor tomas ghost; do
  id "$u" >/dev/null 2>&1 && { [ "$u" = toor ] && sed -i '/^toor:/d' /etc/passwd /etc/shadow || userdel -rf "$u" 2>/dev/null; }
done
userdel backup-svc 2>/dev/null
groupdel devs 2>/dev/null; groupdel ops 2>/dev/null
rm -rf /srv/clipstr /var/backups/maya-home* /home/maya /home/tomas
echo "Lab environment removed."
