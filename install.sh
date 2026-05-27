#!/usr/bin/env bash
# Install or upgrade the Claude Quota widget for the current user.
set -euo pipefail
cd "$(dirname "$0")"

ID="io.github.ddedamian.claudequota"
TOOL=$(command -v kpackagetool6 || command -v kpackagetool5 || true)
[ -n "$TOOL" ] || { echo "kpackagetool5/6 not found — is KDE Plasma installed?"; exit 1; }

if "$TOOL" --type Plasma/Applet --list 2>/dev/null | grep -q "$ID"; then
  "$TOOL" --type Plasma/Applet --upgrade package
else
  "$TOOL" --type Plasma/Applet --install package
fi

echo
echo "Done. Add it: right-click your panel or desktop -> Add Widgets -> search 'Claude Quota'."
echo "Then right-click the widget -> Configure to pick the data source."
