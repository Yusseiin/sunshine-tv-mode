#!/bin/zsh
# Build the two native tools into build/:
#   build/mirror                    switches mirroring and the main display (public CoreGraphics API)
#   build/Virtual 16x9 Screen.app   background app that keeps a virtual 16:9 display connected while it runs
# Needs the Xcode command line tools (clang, codesign). Both are signed ad hoc.
set -e
cd "${0:A:h}"
APP="build/Virtual 16x9 Screen.app"
mkdir -p "$APP/Contents/MacOS"
clang -fobjc-arc -O2 -framework Foundation -framework AppKit -framework CoreGraphics tools/mirror.m -o build/mirror
codesign -s - --force build/mirror
cp tools/vscreen/Info.plist "$APP/Contents/Info.plist"
clang -fobjc-arc -O2 -framework AppKit -framework CoreGraphics tools/vscreen/vscreen.m -o "$APP/Contents/MacOS/vscreen"
codesign -s - --force --deep "$APP"
print "built build/mirror and $APP"
