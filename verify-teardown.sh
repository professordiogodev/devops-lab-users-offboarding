#!/usr/bin/env bash
# Proves the lab environment is gone. Run with: sudo ./verify-teardown.sh
set -uo pipefail
cd "$(dirname "$0")"
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo:  sudo ./verify-teardown.sh" >&2; exit 1; }
pass=0; failn=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
no_user() { ! id "$1" >/dev/null 2>&1; }
no_group() { ! getent group "$1" >/dev/null 2>&1; }
no_path() { [ ! -e "$1" ]; }
no_proc() { ! pgrep -f "$1" >/dev/null 2>&1; }
no_listener() { ! ss -ltn 2>/dev/null | grep -qE ":$1\\b"; }

for u in maya priya tomas sam-contractor ghost stranger; do check "user $u is gone" no_user $u; done
check "only root has UID 0 (toor is gone)" bash -c "[ \"\$(awk -F: '\$3==0{print \$1}' /etc/passwd | tr '\n' ' ')\" = 'root ' ]"
check "group devs is gone" no_group devs
check "group ops is gone" no_group ops
check "/srv/clippy is gone" no_path /srv/clippy
check "/etc/sudoers.d has no lab rules" bash -c "[ ! -e /etc/sudoers.d/devs ] && [ ! -e /etc/sudoers.d/tomas ]"
check "the offboarding archive is gone" no_path /var/backups/maya-home.tar.gz
check "no process runs the lab background job" no_proc backup-sync
check "no leftover home directories" bash -c "[ ! -e /home/maya ] && [ ! -e /home/tomas ] && [ ! -e /home/ghost ]"

echo
if [ "$failn" -eq 0 ]; then echo "TEARDOWN VERIFIED ($pass/$pass)"; else echo "NOT CLEAN: $failn leftover(s). Finish the tear down steps and run this again."; fi
exit "$failn"
