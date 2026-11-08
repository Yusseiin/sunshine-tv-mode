#!/bin/zsh
# Build, then install into ~/.config/sunshine, where tvmode.sh and nxgame.sh expect their tools.
#   ./install.sh                    install; an already installed Virtual 16x9 Screen app is kept
#   ./install.sh --rebuild-vscreen  also replace that app (macOS then asks for Screen Recording permission again)
# apps.json and sunshine.conf stay yours: see examples/ and the README.
set -e
cd "${0:A:h}"
./build.sh
D=~/.config/sunshine
APP="$D/tools/vscreen/Virtual 16x9 Screen.app"
mkdir -p $D/scripts $D/tools/vscreen $D/covers
cp scripts/tvmode.sh scripts/tvswitch.sh scripts/nxgame.sh $D/scripts/
chmod +x $D/scripts/tvmode.sh $D/scripts/tvswitch.sh $D/scripts/nxgame.sh
cp build/mirror tools/mirror.m $D/tools/
cp tools/vscreen/vscreen.m $D/tools/vscreen/
cp covers/badge.swift covers/cover.swift covers/tv-mode-*.png $D/covers/
if [[ ! -d $APP || $1 == --rebuild-vscreen ]]; then
  if pgrep -f "$APP/Contents/MacOS/vscreen" >/dev/null; then
    print -u2 "the Virtual 16x9 Screen app is running: run 'tvmode.sh off' first"; exit 1
  fi
  rm -rf "$APP"; cp -R "build/Virtual 16x9 Screen.app" "$APP"
  print "installed the Virtual 16x9 Screen app. The first 'tvmode.sh on' asks for Screen Recording permission:"
  print "allow it in System Settings > Privacy & Security > Screen Recording, then run 'tvmode.sh on' again."
else
  print "kept the installed Virtual 16x9 Screen app and its Screen Recording permission (--rebuild-vscreen replaces it)"
fi
print "installed into $D"
