import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Ui
import qs.Commons

// Bar slot for the cliamp now-playing card. The card itself (NowPlaying.qml)
// is the cliamp repo widget; this turns it into a click-to-toggle popup so
// the bar only ever shows an icon.

BarWidget {
  id: root
  moduleName: "io.github.josecamporivas.cliamp"

  readonly property var cliampPlayer: findCliampPlayer()
  readonly property bool hasPlayer: cliampPlayer !== null
  readonly property bool playing: hasPlayer && !!cliampPlayer.isPlaying

  property bool popupOpen: false

  // Popup open/close/opened contract that shell.summon/hide/toggle routes to
  // (Bar.findPanelWidget), so a hotkey can flip the card too.
  readonly property bool opened: popupOpen

  function open() { popupOpen = true }
  function close() { popupOpen = false }
  function closeForPopoutSwitch() { popupOpen = false }

  function findCliampPlayer() {
    var players = Mpris.players ? Mpris.players.values : []
    for (var i = 0; i < players.length; i++) {
      var p = players[i]
      if (p.dbusName === "cliamp" || p.identity === "Cliamp") return p
    }
    return null
  }

  readonly property string icon: "󰝚"

  readonly property string tooltipText: {
    if (!root.hasPlayer) return "cliamp — not running"
    var title = root.cliampPlayer.trackTitle || ""
    var artist = root.cliampPlayer.trackArtist || ""
    if (title !== "" && artist !== "") return title + " — " + artist
    if (title !== "") return title
    return "cliamp"
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.icon
    // Match other bar icons at rest; only mark active while music is playing.
    active: root.playing
    activeColor: Color.accent
    tooltipText: root.tooltipText
    onPressed: root.popupOpen = !root.popupOpen
  }

  PopupCard {
    id: popup
    anchorItem: button
    bar: root.bar
    owner: root
    // Use PopupCard's focus grab so clicks outside the card dismiss it.
    triggerMode: "click"
    open: root.popupOpen
    // The card draws its own background and border; the popup adds none so
    // the two surfaces don't double-frame.
    padding: 0
    borderSpec: Border.none()
    contentWidth: popup.fittedContentWidth(300)
    contentHeight: popup.fittedContentHeight(72)

    // Visible only while open so the visstream subprocess stops when the
    // card is dismissed instead of streaming spectrum forever in the background.
    NowPlaying {
      width: 300
      height: 72
      player: root.cliampPlayer
      visible: root.popupOpen
    }
  }
}
