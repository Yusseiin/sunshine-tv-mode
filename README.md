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
| `tools/mirror.m` | `mirror list \| on <name> \| off \| main <name>\|builtin \| mode <name> <W>x<H>`: switches mirroring, picks the main display and sets a display's resolution. Uses public CoreGraphics API; changes last for the login session only. |
| `scripts/tvmode.sh` | `tvmode.sh on [1080p\|1440p\|4k] \| off \| status`: the TV mode toggle. |
| `shortcuts/` | `TV Mode ON.command`, `TV Mode ON 4K.command`, `TV Mode OFF.command`: double-click versions of the toggle. |
| `scripts/tvswitch.sh` | `tvswitch.sh 4k \| 1440p \| 1080p \| off`: the toggle as a Moonlight app entry, to switch from the sofa. |
| `scripts/nxgame.sh` | `nxgame.sh start\|stop <bundle id> [VAR=value ...]`: starts an nxnative game fullscreen without its launcher window and quits it cleanly when the stream ends. |
| `covers/badge.swift` | `swift badge.swift in.png out.png HUD`: draws a text badge in the top-right corner of a Moonlight cover. |
| `covers/cover.swift` | `swift cover.swift out.png 4K "TV Mode" 3df273`: draws a plain cover (a TV with big text and a caption). The `tv-mode-*.png` covers were made with it. |
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

### Switching from Moonlight

`examples/apps.json` has three entries that switch TV mode from the TV: **TV Mode 4K**, **TV Mode 1080p**
and **TV Mode OFF**. Each runs `tvswitch.sh` as a detached command:

```json
{ "name": "TV Mode 4K", "detached": ["/Users/YOUR_USER/.config/sunshine/scripts/tvswitch.sh 4k"],
  "image-path": "/Users/YOUR_USER/.config/sunshine/covers/tv-mode-4k.png" }
```

- A switch restarts Sunshine, so **the stream that started it ends** after a few seconds. Reconnect in
  Moonlight about 10 seconds later and start a game.
- If TV mode is already at that size, nothing changes; the entry just streams the desktop, so quit it.
- The switch runs in a session of its own (`setsid`, through the system Perl because macOS has no `setsid`
  command), so Sunshine stopping does not stop it halfway.
- `tvmode.sh` stops Sunshine *before* it changes the displays, so Sunshine never sees its display vanish
  mid-stream.

### 1440p and 4K

`tvmode.sh on 1440p` or `tvmode.sh on 4k` (or **TV Mode ON 4K**) runs the virtual display at 2560×1440 or
3840×2160. Running `on` again with another size switches it; plain `on` is 1080p. Set the same resolution in
Moonlight's settings on the TV, pick HEVC if it offers it, and raise the bitrate (about 40-80 Mbps for 4K at
60 fps). Many TVs, Samsung's among them, have a 100 Mbit/s Ethernet port, so keep the bitrate well under that
on a cable.

- The virtual display runs at 1x, so at 1440p and 4K the Mac's menus and windows look small on both screens.
  Games running fullscreen fill it at any size.
- A higher stream resolution only helps if the game draws that many pixels. Donkey Kong Bananza renders its
  scene at 1676×943 and its upscaler outputs at most 2304×1296 (less in busy scenes), so 1440p already holds
  all of its detail. 4K adds little but costs more bitrate.
- macOS mirrors two screens at a size both share (1920×1080), so `tvmode.sh` sets the size with
  `mirror mode` after it turns mirroring on, before Sunshine restarts.

### Settings

At the top of `tvmode.sh`:

- `DEFAULT_SIZE=1080p` and `REFRESH=60`: the virtual display's size when none is given, and its refresh rate.
- `MODE=mirror`: the built-in screen shows the same 16:9 picture, letterboxed, so the Mac stays usable.
  `MODE=extend` makes the 16:9 display the only main display and places the built-in screen beside it.
- `SOURCE=dummy` with `DUMMY_NAME=...` uses an HDMI dummy plug instead of the virtual screen. Use the name
  shown by `~/.config/sunshine/tools/mirror list`.

### Why a toggle and not a Sunshine prep command

On macOS, Sunshine does not pick up a display connected while it is running: you get "no video received" or
a "Hang detected" crash (LizardByte/Sunshine#2523). So the 16:9 display has to exist *before* Sunshine
starts. `tvmode.sh` stops Sunshine, connects the display, then starts Sunshine again. Afterwards it checks
Sunshine's new log: Sunshine tests its encoders by capturing the main display, so a found H.264 encoder means
capture works.

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
