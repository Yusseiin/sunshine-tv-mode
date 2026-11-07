# Sunshine TV mode for macOS

Stream a Mac to a 16:9 TV with [Sunshine](https://github.com/LizardByte/Sunshine) and
[Moonlight](https://moonlight-stream.org) so the picture **fills the TV**, with no black bars and no paid tools.
Also includes helpers that launch [nxnative](https://github.com/seedds/nxnative) games from Moonlight.

A MacBook screen is 16:10 (or taller), so Sunshine streams it letterboxed to a 16:9 TV. TV mode connects a
virtual 1920×1080 display, mirrors the built-in screen onto it so it becomes the main display, and restarts
Sunshine so it captures that display.

## What's inside

| Path | What it does |
|---|---|
| `tools/vscreen/` | **Virtual 16x9 Screen.app**: an invisible background app (no Dock icon, no window) that keeps a virtual 16:9 display connected while it runs. It uses CoreGraphics' private `CGVirtualDisplay` classes, the same ones DeskPad and BetterDisplay use. |
| `tools/mirror.m` | `mirror list \| on <name> \| off \| main <name>\|builtin`: switches mirroring and picks the main display. Uses public CoreGraphics API; changes last for the login session only. |
| `scripts/tvmode.sh` | `tvmode.sh on \| off \| status`: the TV mode toggle. |
| `shortcuts/` | `TV Mode ON.command` / `TV Mode OFF.command`: double-click versions of the toggle. |
| `scripts/nxgame.sh` | `nxgame.sh start\|stop <bundle id> [VAR=value ...]`: starts an nxnative game fullscreen without its launcher window and quits it cleanly when the stream ends. |
| `covers/badge.swift` | `swift badge.swift in.png out.png HUD`: draws a text badge in the top-right corner of a Moonlight cover. |
| `examples/` | A Sunshine `apps.json` with nxnative game entries, and the `sunshine.conf` used with it. |

## Requirements

- macOS on Apple silicon. Tested on macOS 27 with Sunshine 2026.914 and Moonlight on a Samsung Tizen TV.
- The Xcode command line tools: `xcode-select --install`.
- Sunshine in `/Applications`.

## Install

```bash
./install.sh
```

This builds the tools into `build/` and installs everything into `~/.config/sunshine`. Copy the two
`shortcuts/*.command` files anywhere you like, for example the Desktop.

The first `tvmode.sh on` asks for **Screen Recording** permission for *Virtual 16x9 Screen*: macOS only brings
a virtual display online for an app that holds it. Allow it in System Settings > Privacy & Security >
Screen Recording, then run `tvmode.sh on` again.

The app is signed ad hoc, so macOS ties that permission to this exact build. `./install.sh` keeps an
installed app; `./install.sh --rebuild-vscreen` replaces it, and you must then allow it again.

## Use

1. Before streaming: `~/.config/sunshine/scripts/tvmode.sh on`, or double-click **TV Mode ON**.
2. Connect from Moonlight and play.
3. Afterwards: `tvmode.sh off`, or double-click **TV Mode OFF**, to put the built-in screen back.

`tvmode.sh status` shows the displays and whether Sunshine and the virtual screen are running. Each run is
logged to `~/.config/sunshine/tvmode.log`.

Settings at the top of `tvmode.sh`:

- `RESOLUTION=(1920 1080 60)`: the virtual display mode.
- `MODE=mirror`: the built-in screen shows the same 16:9 picture, letterboxed, so the Mac stays usable.
  `MODE=extend` makes the 16:9 display the only main display and places the built-in screen beside it.
- `SOURCE=dummy` with `DUMMY_NAME=...` uses an HDMI dummy plug instead of the virtual screen. Use the name
  shown by `~/.config/sunshine/tools/mirror list`.

### Why a toggle and not a Sunshine prep command

On macOS, Sunshine does not pick up a display connected while it is running: you get "no video received" or
a "Hang detected" crash (LizardByte/Sunshine#2523). So the 16:9 display has to exist *before* Sunshine
starts. `tvmode.sh` connects it, then restarts Sunshine. After the restart it checks Sunshine's log: Sunshine
tests its encoders by capturing the main display, so a found H.264 encoder means capture works.

## nxnative games in Moonlight

`examples/apps.json` adds Donkey Kong Bananza and Pokémon Pokopia, each also in a "(HUD)" variant that shows
Apple's Metal performance HUD. To use it, replace `YOUR_USER` with your macOS user name, merge the entries
into `~/.config/sunshine/apps.json`, and provide your own cover images.

```json
{
  "name": "Donkey Kong Bananza (HUD)",
  "cmd": "/Users/YOUR_USER/.config/sunshine/scripts/nxgame.sh start org.nxnative.040074a01bf12000 DM_METAL_HUD=1",
  "prep-cmd": [{ "do": "", "undo": "/Users/YOUR_USER/.config/sunshine/scripts/nxgame.sh stop org.nxnative.040074a01bf12000" }],
  "image-path": "/Users/YOUR_USER/.config/sunshine/covers/donkey-kong-bananza-hud.png"
}
```

- nxnative names each app's bundle ID `org.nxnative.<title id in lower case>`.
- `nxgame.sh` always passes `DM_LAUNCHER=0` (no settings window) and `DM_FULLSCREEN=1`. Any extra
  `VAR=value` arguments are passed to the game as environment variables.
- It quits a game by sending SIGTERM to its `dmhost` process, which nxnative handles as a clean exit. It uses
  no Apple Events, so macOS shows no automation prompt.

Moonlight cuts long names short, so give the HUD entries a badged cover:

```bash
swift covers/badge.swift donkey-kong-bananza.png donkey-kong-bananza-hud.png HUD
```

## Troubleshooting

- **No picture on the TV after a crash mid-stream:** run `tvmode.sh off`, then `tvmode.sh on`.
- **"the 16:9 display is not connected":** check that Screen Recording is allowed for Virtual 16x9 Screen.
- Logs are in `~/.config/sunshine/sunshine.log` and `~/.config/sunshine/tvmode.log`.

## Credits

- Built with [Claude Code](https://claude.com/claude-code), Anthropic's AI coding assistant. Claude wrote the
  code, scripts and this README, and debugged the setup on a real Mac and TV.
- The per-launch display serial number (the window server rejects a serial it still remembers) comes from
  [manaflow-ai/cmux](https://github.com/manaflow-ai/cmux)'s `create-virtual-display.m`.
- The `CGVirtualDisplay` declarations follow those used by [DeskPad](https://github.com/Stengo/DeskPad).
