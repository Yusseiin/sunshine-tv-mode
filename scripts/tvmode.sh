#!/bin/zsh
# TV mode: stream a 16:9 picture that fills the TV.
#   tvmode.sh on [size]  connect a 16:9 display, make it the main one, then restart Sunshine.
#                        size: 1080p (the default), 1440p or 4k. Running it again with another size
#                        switches the display to it. Set the same resolution in Moonlight on the TV.
#   tvmode.sh off        put the built-in screen back, remove the 16:9 display, then restart Sunshine
#   tvmode.sh status     show the displays and whether Sunshine is running
#
# Sunshine must start AFTER the 16:9 display is connected: on macOS it does not pick up a display
# connected while it is running and then sends no video (LizardByte/Sunshine#2523). That is why
# this is a toggle run before and after playing, not a per-stream prep command.
#
# SOURCE=vscreen: our own "Virtual 16x9 Screen" app (tools/vscreen) holds a virtual 16:9 display
#                 while it runs. It needs Screen Recording permission (granted 2026-11-07); a rebuild
#                 of the app changes its signature and needs the permission granted again.
# SOURCE=dummy:   an HDMI dummy plug; set DUMMY_NAME to its name as `tools/mirror list` shows it.
#                 Its resolution is set in System Settings > Displays, not by the size argument.
# MODE=mirror:    the built-in screen shows the same 16:9 picture (letterboxed), so the Mac stays usable.
# MODE=extend:    the 16:9 display alone is the main one; the built-in screen sits beside it.
# The virtual display runs at 1x, so at 1440p and 4k the Mac's menus and windows look small; games
# running fullscreen fill it at any size.
SOURCE=vscreen
DEFAULT_SIZE=1080p
REFRESH=60
DUMMY_NAME="DUMMY-PLUG-NAME"
MODE=mirror

TOOLS=~/.config/sunshine/tools
VAPP="$TOOLS/vscreen/Virtual 16x9 Screen.app"
SLOG=~/.config/sunshine/sunshine.log
[[ $SOURCE == vscreen ]] && DISPLAY_NAME="Virtual 16:9" || DISPLAY_NAME=$DUMMY_NAME

say() { print -- "$*"; print -- "$(date '+%F %T') $*" >> ~/.config/sunshine/tvmode.log }
online() { $TOOLS/mirror list | grep -qi -- "$DISPLAY_NAME" }
vscreen_pids() { pgrep -f "Virtual 16x9 Screen.app/Contents/MacOS/vscreen" }
sunshine_pids() { pgrep -f "Sunshine.app/Contents/MacOS/Sunshine" }

restart_sunshine() {
  local p=$(sunshine_pids)
  if [[ -n $p ]]; then
    say "stopping Sunshine..."
    kill -TERM ${=p} 2>/dev/null
    for i in {1..30}; do [[ -z $(sunshine_pids) ]] && break; sleep 0.5; done
  fi
  say "starting Sunshine..."
  open -g -a /Applications/Sunshine.app
  # Sunshine tests its encoders at startup by capturing the main display: finding one means capture works.
  for i in {1..60}; do
    sleep 0.5
    grep -q "Found H.264 encoder" $SLOG 2>/dev/null && { say "Sunshine is up and captures $(grep -o 'Configuring selected display ([0-9]*)' $SLOG | tail -1 | grep -o '[0-9]*' | sed 's/^/display /'): OK"; return 0; }
    grep -q "Fatal" $SLOG 2>/dev/null && { say "Sunshine reported a problem:"; grep "Fatal" $SLOG | tail -2; return 1; }
  done
  say "Sunshine did not report its encoders within 30 s; check $SLOG"
  return 1
}

stop_vscreen() {
  local p=$(vscreen_pids); [[ -n $p ]] && kill -TERM ${=p}
  for i in {1..20}; do [[ -z $(vscreen_pids) ]] && break; sleep 0.25; done
}

case $1 in
  on)
    case ${2:-$DEFAULT_SIZE} in
      1080p|1080) RESOLUTION=(1920 1080) ;;
      1440p|1440) RESOLUTION=(2560 1440) ;;
      4k|4K|2160p|2160) RESOLUTION=(3840 2160) ;;
      *) print "unknown size \"$2\": use 1080p, 1440p or 4k"; exit 2 ;;
    esac
    SIZE="${RESOLUTION[1]}x${RESOLUTION[2]}"
    if [[ $SOURCE == vscreen && -n $(vscreen_pids) ]] && ! $TOOLS/mirror list | grep -i -- "$DISPLAY_NAME" | grep -q -- $'\t'"$SIZE"; then
      say "switching the 16:9 display to $SIZE..."
      $TOOLS/mirror off
      $TOOLS/mirror main builtin
      stop_vscreen
      sleep 1
    fi
    if [[ $SOURCE == vscreen && -z $(vscreen_pids) ]]; then
      open -g -n -a "$VAPP" --args ${RESOLUTION[@]} $REFRESH
    fi
    for i in {1..40}; do online && break; sleep 0.25; done
    online || { say "the 16:9 display \"$DISPLAY_NAME\" is not connected; nothing changed"; exit 1; }
    if [[ $MODE == mirror ]]; then $TOOLS/mirror on "$DISPLAY_NAME"; else $TOOLS/mirror main "$DISPLAY_NAME"; fi
    # macOS mirrors at a size both screens share (1920x1080), so set the size asked for afterwards.
    [[ $SOURCE == vscreen ]] && { $TOOLS/mirror mode "$DISPLAY_NAME" $SIZE || say "could not set the 16:9 display to $SIZE"; }
    sleep 1
    say "TV mode ON ($SOURCE, $MODE):"; $TOOLS/mirror list
    restart_sunshine
    ;;
  off)
    $TOOLS/mirror off
    $TOOLS/mirror main builtin
    [[ $SOURCE == vscreen ]] && stop_vscreen
    sleep 1
    say "TV mode OFF:"; $TOOLS/mirror list
    restart_sunshine
    ;;
  status)
    $TOOLS/mirror list
    [[ -n $(sunshine_pids) ]] && print "Sunshine: running" || print "Sunshine: not running"
    [[ $SOURCE == vscreen ]] && { [[ -n $(vscreen_pids) ]] && print "Virtual 16x9 Screen: running" || print "Virtual 16x9 Screen: not running"; }
    ;;
  *) print "usage: $0 on [1080p|1440p|4k] | off | status"; exit 2 ;;
esac
