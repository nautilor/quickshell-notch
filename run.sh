#!/usr/bin/env bash
# Silence harmless warnings: Qt text-input-v3 focus races on layer-shell surfaces, and screencopy failures for
# windows that cannot be captured right now (off-screen columns, other workspaces). The dock falls back to the last thumbnail.
rules="qt.qpa.wayland.textinput.warning=false;quickshell.wayland.screencopy.hyprland.warning=false"
export QT_LOGGING_RULES="${QT_LOGGING_RULES:+$QT_LOGGING_RULES;}$rules"
exec quickshell -p "$(dirname "$(readlink -f "$0")")" "$@"
