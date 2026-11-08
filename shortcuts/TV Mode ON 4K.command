#!/bin/zsh
# Double-click before streaming to the TV in 4K: a 3840x2160 screen for Sunshine, then Sunshine restarts.
# In Moonlight on the TV, set the resolution to 4K too. TV Mode OFF switches it off.
# The window closes by itself when it worked, and stays open if something went wrong.
if ~/.config/sunshine/scripts/tvmode.sh on 4k; then
  ~/.config/sunshine/scripts/close-terminal.sh
else
  print "\nSomething went wrong (see above), so this window stays open."
fi
