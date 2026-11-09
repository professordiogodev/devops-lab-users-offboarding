#!/usr/bin/env bash
# Builds Clipstr's messy server. Run with: sudo ./setup.sh  (safe to run again)
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo:  sudo ./setup.sh" >&2; exit 1; }
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get install -y -qq cron sudo >/dev/null

# clean slate so the script can be re-run
./teardown.sh >/dev/null 2>&1 || true

groupadd devs; groupadd ops
mk() { useradd -m -s /bin/bash -c "$2" "$1"; echo "$1:Welcome-2024!" | chpasswd; }
mk priya  "Priya Nair (backend)";   usermod -aG devs,ops priya
mk maya   "Maya Santos (lead dev)"; usermod -aG devs,ops,sudo maya
mk sam-contractor "Sam (contractor)"; passwd -d sam-contractor >/dev/null; usermod -aG devs sam-contractor
# somebody once added a second root account "for emergencies"
useradd -o -u 0 -g 0 -M -s /bin/bash -d /root toor; echo 'toor:Welcome-2024!' | chpasswd
id backup >/dev/null 2>&1 || useradd --system --shell /usr/sbin/nologin backup-svc

# Maya's footprint
install -d -o maya -g maya -m 700 /home/maya/.ssh
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMayaLaptop00000000000000000000000000000 maya@laptop' > /home/maya/.ssh/authorized_keys
chown maya:maya /home/maya/.ssh/authorized_keys; chmod 600 /home/maya/.ssh/authorized_keys
cat > /home/maya/restore-db.md <<'N'
# How to restore the Clipstr database (only Maya knows this)
1. Stop the app. 2. Restore the latest dump from /srv/clipstr/backups. 3. Start the app.
N
chown maya:maya /home/maya/restore-db.md
printf '#!/bin/bash\ndate >> /srv/clipstr/backups/last-sync.txt\n' > /home/maya/backup-sync.sh
chown maya:maya /home/maya/backup-sync.sh; chmod 755 /home/maya/backup-sync.sh
install -d -o root -g devs -m 2775 /srv/clipstr /srv/clipstr/releases /srv/clipstr/backups
for v in v1 v2 v3; do echo "release $v" > /srv/clipstr/releases/$v.txt; done
chown maya:devs /srv/clipstr/releases/v3.txt /srv/clipstr/backups
chown priya:devs /srv/clipstr/releases/v1.txt /srv/clipstr/releases/v2.txt
echo "db password rotation notes" > /srv/clipstr/backups/rotation.txt; chown maya:maya /srv/clipstr/backups/rotation.txt
printf '*/5 * * * * /home/maya/backup-sync.sh\n' | crontab -u maya -
sudo -u maya bash -c 'setsid nohup bash -c "exec -a backup-sync sleep 999999" >/dev/null 2>&1 &'

# a sudoers rule that someone thought was a good idea
echo '%devs ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/devs
chmod 440 /etc/sudoers.d/devs

echo
echo "The server is ready. Friday, 16:45. Open README.md and start Part 1."
