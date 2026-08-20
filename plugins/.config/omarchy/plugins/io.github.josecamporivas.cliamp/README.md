# cliamp now-playing card (Omarchy bar widget)

A click-to-toggle now-playing card for [cliamp](https://github.com/bjarneo/cliamp) in the Omarchy shell bar. The bar shows a single music-note icon; clicking it opens or closes a 300 x 72 card with a Winamp 2-style live spectrum, transport controls, and a click-to-seek progress bar. The card hides its content when cliamp is not running.

The card files are vendored from the [cliamp](https://github.com/bjarneo/cliamp) repo (`contrib/quickshell/`, MIT) and pinned to upstream tag `v1.63.2` (matching the installed cliamp 1.63.2-1):

- `NowPlaying.qml` — the card itself. Patched so the theme file is read from Omarchy quattro's `~/.local/state/omarchy/current/theme/colors.toml` instead of the legacy `~/.config/omarchy/current/theme/colors.toml` path the upstream widget expects.
- `BandStream.qml` — wraps `cliamp visstream` over the IPC socket and exposes the live 10-band frames.
- `TransportButton.qml`, `MediaIcon.qml` — vector transport icons.
- `Visualizer.qml` — Winamp 2-style segmented spectrum with falling peak caps.

## How it works

`BarWidget.qml` finds the cliamp player on the MPRIS bus (`org.mpris.MediaPlayer2.cliamp`) and passes it to `NowPlaying.qml` inside a `PopupCard`. The popup adds no chrome of its own — the card draws its own background and border. The `visstream` subprocess only runs while the card is open and cliamp is playing.

## Updating

To pick up a newer upstream widget:

```sh
git clone --depth 1 --branch v1.63.2 https://github.com/bjarneo/cliamp.git /tmp/cliamp
cp /tmp/cliamp/contrib/quickshell/{NowPlaying,BandStream,TransportButton,MediaIcon,Visualizer}.qml \
   plugins/.config/omarchy/plugins/io.github.josecamporivas.cliamp/
```

Re-apply the theme path patch in `NowPlaying.qml` if upstream changed it:

```
~/.config/omarchy/current/theme/colors.toml  ->  ~/.local/state/omarchy/current/theme/colors.toml
```
