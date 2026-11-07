#!/bin/zsh
# Sunshine helper for nxnative Mac apps.
#   nxgame.sh start <bundle id> [VAR=value ...]
#                                 start the game fullscreen without its settings window, with any extra
#                                 nxnative settings (e.g. DM_METAL_HUD=1 for Apple's performance HUD),
#                                 and stay running until the game quits (Sunshine's "cmd")
#   nxgame.sh stop <bundle id>    quit the game if it is still running
#                                 (Sunshine's prep-cmd "undo", run when the stream ends)
# Quitting uses SIGTERM, which nxnative's game host handles as a clean exit (dm/host/hle_lifecycle.c);
# the launcher then exits by itself. No Apple Events, so no macOS automation prompt appears.
mode=$1 id=$2
[[ -n $id ]] || { print -u2 "usage: $0 start|stop <bundle id> [VAR=value ...]"; exit 2; }
envs=(--env DM_LAUNCHER=0 --env DM_FULLSCREEN=1)
for kv in "${@:3}"; do [[ $kv =~ '^[A-Z_][A-Z0-9_]*=' ]] && envs+=(--env "$kv"); done   # only VAR=value words

# The app's path from its bundle ID, through NSWorkspace (AppleScript's "path to application" would launch it).
app=$(osascript -l JavaScript -e "ObjC.import('AppKit'); \$.NSWorkspace.sharedWorkspace.URLForApplicationWithBundleIdentifier('$id').path.js" 2>/dev/null)
[[ -n $app ]] || { print -u2 "no app with bundle id $id"; exit 1; }
app=${app%/}

pids() { pgrep -f "$app/Contents/MacOS/$1" }
quit_game() {
  local p=$(pids dmhost)
  [[ -n $p ]] && kill -TERM ${=p} 2>/dev/null
  for i in {1..20}; do [[ -z $(pids '') ]] && return 0; sleep 0.5; done
  p=$(pids nxnative); [[ -n $p ]] && kill -TERM ${=p} 2>/dev/null   # launcher left over
  return 0
}

case $mode in
  start)
    # The stream ending kills this script: quit the game then too.
    trap 'quit_game; exit 0' TERM INT HUP
    open -W -b "$id" "${envs[@]}" &
    wait $!
    ;;
  stop)
    quit_game
    ;;
  *) print -u2 "unknown mode: $mode"; exit 2 ;;
esac
