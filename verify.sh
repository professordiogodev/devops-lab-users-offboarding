#!/usr/bin/env bash
# Checks the state of the server. Run with: sudo ./verify.sh
set -uo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo:  sudo ./verify.sh" >&2; exit 1; }
pass=0; failn=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
in_group() { id -nG "$1" 2>/dev/null | tr ' ' '\n' | grep -qx "$2"; }
locked() { local f; f=$(passwd -S "$1" 2>/dev/null | awk '{print $2}'); [ "$f" = L ] || [ "$f" = LK ]; }
cant_login() { locked "$1" || [ "$(getent passwd "$1" | cut -d: -f7)" = /usr/sbin/nologin ] || [ "$(chage -l "$1" | awk -F': ' '/Account expires/{print $2}')" != never ]; }

echo "== Maya has left: her access is gone =="
check "Maya's account still exists (locked, not deleted)"   getent passwd maya
check "Maya cannot log in (locked, expired or nologin)"     cant_login maya
check "Maya is not in sudo"                                  bash -c "! id -nG maya | tr ' ' '\n' | grep -qx sudo"
check "Maya is not in devs or ops"                           bash -c "! id -nG maya | tr ' ' '\n' | grep -qxE 'devs|ops'"
check "Maya's SSH key no longer works (authorized_keys gone or empty)" bash -c "[ ! -s /home/maya/.ssh/authorized_keys ]"
check "Maya has no cron jobs"                                bash -c "! crontab -l -u maya 2>/dev/null | grep -q ."
check "No process runs as Maya"                              bash -c "! pgrep -u maya >/dev/null"
check "Nothing under /srv/clippy is owned by Maya"          bash -c "[ -z \"\$(find /srv/clippy -user maya 2>/dev/null)\" ]"
check "...her files went to priya (the successor)"           test "$(stat -c %U /srv/clippy/releases/v3.txt)" = priya
check "Her knowledge is saved: /var/backups/maya-home.tar.gz exists" bash -c "[ -s /var/backups/maya-home.tar.gz ] && tar tzf /var/backups/maya-home.tar.gz | grep -q restore-db.md"

echo "== The accounts nobody remembered =="
check "Only root has UID 0 (no 'toor')"                     bash -c "[ \"\$(awk -F: '\$3==0{print \$1}' /etc/passwd | tr '\n' ' ')\" = 'root ' ]"
check "No account has an empty password"                    bash -c "[ -z \"\$(awk -F: '\$2==\"\"{print \$1}' /etc/shadow)\" ]"
check "sam-contractor cannot log in"                        cant_login sam-contractor

echo "== Sudo done right =="
check "sudoers is valid (visudo -c)"                        visudo -c
check "no group (%name) has passwordless ALL anymore"               bash -c "! grep -rhE '^%[^#]*NOPASSWD:\s*ALL' /etc/sudoers /etc/sudoers.d 2>/dev/null | grep -q ."

echo "== Tomas, the new hire =="
check "tomas exists with a home directory and bash"         bash -c "getent passwd tomas | grep -q ':/home/tomas:/bin/bash' && [ -d /home/tomas ]"
check "tomas is in devs"                                    in_group tomas devs
check "tomas must change his password at first login"       bash -c "chage -l tomas | grep -qi 'must be changed'"
check "tomas can restart clippy with sudo"                 bash -c "sudo -l -U tomas | grep -q 'systemctl restart clippy'"
check "...and nothing else (no ALL)"                        bash -c "! sudo -l -U tomas | grep -qE '\\) (NOPASSWD: )?ALL'"

echo "== Nobody else was harmed =="
check "priya is still in devs and ops"                      bash -c "id -nG priya | tr ' ' '\n' | grep -qx devs && id -nG priya | tr ' ' '\n' | grep -qx ops"
check "priya can still log in"                              bash -c "! passwd -S priya | awk '{print \$2}' | grep -qE '^L'"

echo
if [ "$failn" -eq 0 ]; then echo "ALL CHECKS PASSED ($pass/$pass)"; else echo "$failn check(s) failed, $pass passed"; fi
exit "$failn"
