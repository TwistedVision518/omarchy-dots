import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "twistedvis.model-switcher"
  ipcTarget: "twistedvis.model-switcher"
  manageIpc: false

  property string backendPath: decodeURIComponent(Qt.resolvedUrl("model_switcher.py").toString().replace(/^file:\/\//, ""))
  property var state: ({ agent: "copilot", model: "", models: [], todayTokens: 0, modelUsage: ({}), remainingPercent: null, limitLabel: "", usageStatus: "" })
  property string errorText: ""
  readonly property var configuredModelMap: parseModels(String(setting("models", "")))
  readonly property color foreground: bar ? bar.barForeground : Color.foreground
  readonly property color accent: Color.accent
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  function parseModels(value) {
    var result = ({})
    value.split(";").forEach(function(group) {
      var parts = group.split(":")
      if (parts.length < 2) return
      result[parts[0].trim()] = parts.slice(1).join(":").split(",").map(function(x) { return x.trim() }).filter(function(x) { return x !== "" })
    })
    return result
  }

  function compact(n) {
    n = Number(n || 0)
    if (n >= 1000000) return (n / 1000000).toFixed(n >= 10000000 ? 0 : 1) + "M"
    if (n >= 1000) return (n / 1000).toFixed(n >= 100000 ? 0 : 1) + "K"
    return String(Math.round(n))
  }

  function modelTokens(id) {
    var bucket = state.modelUsage[id] || {}
    return Number(bucket.inputTokens || 0) + Number(bucket.outputTokens || 0)
      + Number(bucket.cacheReadInputTokens || 0) + Number(bucket.cacheCreationInputTokens || 0)
  }

  function refresh() { if (!statusProcess.running) statusProcess.running = true }
  function chooseModel(model) {
    if (switchProcess.running || model === state.model) return
    switchProcess.command = ["python3", backendPath, "switch-model", model]
    switchProcess.running = true
  }
  function chooseAgent(agent) {
    if (switchProcess.running || agent === state.agent) return
    switchProcess.command = ["python3", backendPath, "switch-agent", agent]
    switchProcess.running = true
  }

  Component.onCompleted: refresh()
  onOpenedChanged: if (opened) refresh()
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Timer { interval: 60000; running: true; repeat: true; onTriggered: root.refresh() }

  Process {
    id: statusProcess
    command: ["python3", root.backendPath, "status"]
    stdout: StdioCollector { onStreamFinished: { try { root.state = JSON.parse(text); root.errorText = "" } catch (e) { root.errorText = "Could not read agent status" } } }
  }
  Process {
    id: switchProcess
    stdout: StdioCollector { onStreamFinished: { try { root.state = JSON.parse(text); root.errorText = "" } catch (e) {} } }
    stderr: StdioCollector { id: switchError }
    onExited: function(code) { if (code !== 0) root.errorText = switchError.text.trim() || "Model switch failed" }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰚩"
    tooltipText: (root.state.agent || "Agent") + " · " + (root.state.model || "auto") + " · " + root.compact(root.state.todayTokens) + " tokens today"
      + (root.state.remainingPercent === null ? " · allowance unavailable" : " · " + root.state.remainingPercent + "% left")
    onPressed: function(b) { if (b === Qt.LeftButton) root.toggle(); else if (b === Qt.MiddleButton) root.refresh() }
  }

  KeyboardPanel {
    id: popup
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: popup.fittedContentWidth(Style.space(360))
    contentHeight: popup.fittedContentHeight(content.implicitHeight, Style.space(520))

    ColumnLayout {
      id: content
      width: parent.width
      spacing: Style.space(10)

      Text { text: "Coding agent"; color: Color.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.title; font.bold: true }
      GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: Style.space(4)
        rowSpacing: Style.space(4)
        Repeater {
          model: ["copilot", "codex", "claude", "gemini", "opencode"]
          delegate: Rectangle {
            required property string modelData
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            implicitHeight: Style.space(30)
            radius: 8
            color: modelData === root.state.agent ? Style.selectedFillFor(Color.foreground, Color.accent) : "transparent"
            Text {
              id: agentLabel
              anchors.fill: parent
              anchors.leftMargin: Style.space(4)
              anchors.rightMargin: Style.space(4)
              verticalAlignment: Text.AlignVCenter
              horizontalAlignment: Text.AlignHCenter
              text: modelData
              elide: Text.ElideRight
              color: Color.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
            MouseArea { anchors.fill: parent; onClicked: root.chooseAgent(modelData) }
          }
        }
      }
      Text {
        Layout.fillWidth: true
        text: root.state.model || "No default model configured"
        color: Color.accent
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
      }
      Rectangle { Layout.fillWidth: true; height: 1; color: Style.selectedFillFor(Color.foreground, Color.accent) }

      Repeater {
        model: root.configuredModelMap[root.state.agent] || root.state.models
        delegate: Rectangle {
          required property string modelData
          Layout.fillWidth: true
          implicitHeight: Style.space(42)
          radius: 8
          color: modelMouse.containsMouse || modelData === root.state.model ? Style.selectedFillFor(Color.foreground, Color.accent) : "transparent"
          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Style.space(10)
            anchors.rightMargin: Style.space(10)
            Text { text: modelData === root.state.model ? "●" : "○"; color: modelData === root.state.model ? Color.accent : Color.foreground; font.family: root.fontFamily }
            Text {
              Layout.fillWidth: true
              Layout.minimumWidth: 0
              text: modelData
              elide: Text.ElideRight
              color: Color.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }
            Text { text: root.compact(root.modelTokens(modelData)); color: Qt.darker(Color.foreground, 1.45); font.family: root.fontFamily; font.pixelSize: Style.font.caption }
          }
          MouseArea { id: modelMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.chooseModel(modelData) }
        }
      }

      Rectangle { Layout.fillWidth: true; height: 1; color: Style.selectedFillFor(Color.foreground, Color.accent) }
      RowLayout {
        Layout.fillWidth: true
        Text { Layout.fillWidth: true; text: "Today"; color: Color.foreground; font.family: root.fontFamily }
        Text { text: root.compact(root.state.todayTokens) + " tokens"; color: Color.foreground; font.family: root.fontFamily; font.bold: true }
      }
      RowLayout {
        Layout.fillWidth: true
        Text { Layout.fillWidth: true; text: root.state.limitLabel || "Allowance"; color: Color.foreground; font.family: root.fontFamily }
        Text {
          text: root.state.remainingPercent === null ? "Unavailable" : root.state.remainingPercent + "% left"
          color: root.state.remainingPercent !== null && root.state.remainingPercent <= 10 ? Color.urgent : Color.foreground
          font.family: root.fontFamily
          font.bold: true
        }
      }
      Text {
        Layout.fillWidth: true
        visible: root.state.remainingPercent === null || root.errorText !== ""
        text: root.errorText || root.state.usageStatus || "This provider does not expose quota data."
        color: Color.urgent
        wrapMode: Text.WordWrap
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
      Text {
        Layout.fillWidth: true
        text: "The selected agent and model become the defaults for new sessions."
        color: Qt.darker(Color.foreground, 1.45)
        wrapMode: Text.WordWrap
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }
  }
}
