#!/bin/zsh
# Closes the Terminal window this runs in, a moment after the shortcut that ran it ends.
#   close-terminal.sh [seconds]   (default 2)
# The shortcuts/*.command files call it when the switch worked: Terminal keeps a window open after
# its command ends, so double-clicking them piles up windows. It closes the window only when the
# window holds just this one tab, and does nothing outside Terminal or if anything fails.
# Terminal asking Terminal to close a window needs no Automation permission.
[[ $TERM_PROGRAM == Apple_Terminal ]] || exit 0
t=$(tty 2>/dev/null) || exit 0
id=$(/usr/bin/osascript -e 'on run argv' -e 'tell application "Terminal"' \
  -e 'repeat with w in windows' \
  -e 'if (count of tabs of w) is 1 and tty of tab 1 of w is (item 1 of argv) then return id of w' \
  -e 'end repeat' -e 'end tell' -e 'return ""' -e 'end run' "$t" 2>/dev/null)
[[ $id == <-> ]] || exit 0
# Close it from a session of its own (setsid, through the system Perl), after the window's shell has
# exited: then Terminal has no running process to ask about, and the shell exiting does not stop this.
/usr/bin/perl -MPOSIX -e 'POSIX::setsid(); exec @ARGV' -- /usr/bin/osascript -e "delay ${1:-2}" \
  -e "tell application \"Terminal\" to close window id $id" </dev/null >/dev/null 2>&1 &!
exit 0
