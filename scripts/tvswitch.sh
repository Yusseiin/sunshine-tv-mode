#!/bin/zsh
# Switch TV mode from Moonlight: a Sunshine app entry runs this as a "detached" command.
#   tvswitch.sh 4k | 1440p | 1080p | off
# The switch restarts Sunshine (see tvmode.sh), which ends the stream that ran it: reconnect in Moonlight
# after about 10 seconds. If TV mode is already at that size, nothing changes and the stream shows the
# desktop: quit it from Moonlight.
LOG=~/.config/sunshine/tvmode.log
TOOLS=~/.config/sunshine/tools
case ${1:-4k} in
  1080p|1080) want=1920x1080 ;;
  1440p|1440) want=2560x1440 ;;
  4k|4K|2160p|2160) want=3840x2160 ;;
  off) want=off ;;
  *) print -u2 "usage: $0 4k|1440p|1080p|off"; exit 2 ;;
esac
if [[ $2 == --now ]]; then
  # The detached part (see below): wait a moment so Sunshine finishes starting this app entry, then switch.
  sleep 2
  print "$(date '+%F %T') tvswitch: switching to $1 from Moonlight" >> $LOG
  if [[ $want == off ]]; then exec ~/.config/sunshine/scripts/tvmode.sh off; else exec ~/.config/sunshine/scripts/tvmode.sh on $1; fi
fi
running=$(pgrep -f "Virtual 16x9 Screen.app/Contents/MacOS/vscreen")
already=0
if [[ $want == off ]]; then
  [[ -z $running ]] && already=1
elif [[ -n $running ]] && $TOOLS/mirror list | grep -i "Virtual 16:9" | grep -q -- $'\t'"$want"; then
  already=1
fi
if (( already )); then
  print "$(date '+%F %T') tvswitch: already ${want}, nothing to do" >> $LOG
  exit 0
fi
# Run the switch in a session of its own (setsid; macOS has no setsid command, so through the system Perl),
# so that Sunshine stopping, and ending its app processes, does not stop the switch with it.
/usr/bin/perl -MPOSIX -e 'POSIX::setsid() or die "setsid: $!"; exec @ARGV or die "exec: $!"' -- \
  /bin/zsh "$0" "${1:-4k}" --now </dev/null >/dev/null 2>&1 &!
exit 0
