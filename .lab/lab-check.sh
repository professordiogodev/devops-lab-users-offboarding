#!/usr/bin/env bash
rc=0
for f in offboard.sh onboard.sh; do
  if [ -f "$f" ] && bash -n "$f" 2>/dev/null; then echo "- ✅ $f exists and is valid bash"
  else echo "- ❌ $f is missing or has a syntax error"; rc=1; fi
  if [ -f "$f" ] && grep -q 'set -e' "$f"; then echo "- ✅ $f uses strict mode"
  else echo "- ❌ $f should use strict mode: set -euo pipefail"; rc=1; fi
done
grep -qE '^ALL CHECKS PASSED \(' SUBMISSION.md && echo "- ✅ SUBMISSION.md shows ALL CHECKS PASSED" || { echo "- ❌ paste the verify.sh output ('ALL CHECKS PASSED') into SUBMISSION.md"; rc=1; }
exit $rc
