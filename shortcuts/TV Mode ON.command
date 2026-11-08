#!/bin/zsh
# Double-click before streaming to the TV: a 16:9 screen for Sunshine, then Sunshine restarts.
# The window closes by itself when it worked, and stays open if something went wrong.
if ~/.config/sunshine/scripts/tvmode.sh on; then
  ~/.config/sunshine/scripts/close-terminal.sh
else
  print "\nSomething went wrong (see above), so this window stays open."
fi
