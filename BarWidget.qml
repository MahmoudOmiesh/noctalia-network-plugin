import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.System
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property string screenName: screen?.name ?? ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)
  readonly property real iconSize: Style.toOdd(capsuleHeight * 0.48)
  readonly property real arrowSize: Style.toOdd(capsuleHeight * 0.4)

  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property int portCount: mainInstance?.listenerCount ?? 0
  readonly property bool speedVisible: mainInstance?.showSpeed ?? true
  readonly property bool portsVisible: (mainInstance?.showPorts ?? true) && portCount > 0

  readonly property bool hovered: mouseArea.containsMouse
  readonly property color fgColor: hovered ? Color.mOnHover : Color.mOnSurface

  readonly property real contentWidth: isVertical ? capsuleHeight : Math.round(content.implicitWidth + Style.margin2M)
  readonly property real contentHeight: isVertical ? Math.round(content.implicitHeight + Style.margin2M) : capsuleHeight

  readonly property string tooltipText: {
    if (!mainInstance)
      return "";
    const lines = [pluginApi.tr("tooltip.speed", {
                                  "rx": mainInstance.formatRate(SystemStatService.rxSpeed),
                                  "tx": mainInstance.formatRate(SystemStatService.txSpeed)
                                })];
    const shown = mainInstance.listeners.slice(0, 8);
    for (const listener of shown) {
      lines.push((":" + listener.port + "  " + listener.process).trim());
    }
    if (portCount > shown.length) {
      lines.push(pluginApi.tr("tooltip.more", {
                                "count": portCount - shown.length
                              }));
    }
    return lines.join("\n");
  }

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  onTooltipTextChanged: {
    if (hovered) {
      TooltipService.updateText(tooltipText);
    }
  }

  Component.onCompleted: SystemStatService.registerComponent("plugin-network-monitor-bar:" + screenName)
  Component.onDestruction: SystemStatService.unregisterComponent("plugin-network-monitor-bar:" + screenName)

  NPopupContextMenu {
    id: contextMenu
    model: [
      {
        "label": pluginApi?.tr("context.refresh"),
        "action": "refresh",
        "icon": "refresh"
      },
      {
        "label": pluginApi?.tr("context.settings"),
        "action": "settings",
        "icon": "settings"
      }
    ]
    onTriggered: action => {
                   contextMenu.close();
                   PanelService.closeContextMenu(screen);
                   if (action === "refresh") {
                     root.mainInstance?.refresh();
                   } else if (action === "settings") {
                     BarService.openPluginSettings(screen, pluginApi.manifest);
                   }
                 }
  }

  Rectangle {
    id: visualCapsule
    width: root.contentWidth
    height: root.contentHeight
    anchors.centerIn: parent
    radius: Style.radiusM
    color: root.hovered ? Color.mHover : Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    Behavior on color {
      enabled: !Color.isTransitioning
      ColorAnimation {
        duration: Style.animationFast
        easing.type: Easing.InOutQuad
      }
    }

    GridLayout {
      id: content
      anchors.centerIn: parent
      flow: root.isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
      rows: root.isVertical ? -1 : 1
      columns: root.isVertical ? 1 : -1
      rowSpacing: Style.marginS
      columnSpacing: Style.marginS

      Repeater {
        model: root.speedVisible ? ["arrow-down", "arrow-up"] : []

        delegate: GridLayout {
          required property string modelData
          required property int index
          readonly property real speed: index === 0 ? SystemStatService.rxSpeed : SystemStatService.txSpeed

          flow: root.isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
          rows: root.isVertical ? -1 : 1
          columns: root.isVertical ? 1 : -1
          rowSpacing: Style.marginXXS
          columnSpacing: Style.marginXS
          Layout.alignment: Qt.AlignCenter

          Item {
            Layout.preferredWidth: root.arrowSize
            Layout.preferredHeight: root.arrowSize
            Layout.alignment: Qt.AlignCenter

            NIcon {
              icon: modelData
              pointSize: root.arrowSize
              applyUiScale: false
              x: Style.pixelAlignCenter(parent.width, width)
              y: Style.pixelAlignCenter(parent.height, contentHeight)
              color: root.hovered ? Color.mOnHover : (speed > 1024 ? Color.mPrimary : Color.mOnSurfaceVariant)
            }
          }

          NText {
            text: root.isVertical ? SystemStatService.formatCompactSpeed(speed) : SystemStatService.formatSpeed(speed).padStart(5, " ")
            family: Settings.data.ui.fontFixed
            pointSize: root.barFontSize
            applyUiScale: false
            color: root.fgColor
            Layout.alignment: Qt.AlignCenter
          }
        }
      }

      Rectangle {
        visible: root.speedVisible && root.portsVisible
        implicitWidth: root.isVertical ? Math.round(root.capsuleHeight * 0.45) : 1
        implicitHeight: root.isVertical ? 1 : Math.round(root.capsuleHeight * 0.45)
        color: Qt.alpha(root.fgColor, 0.2)
        Layout.alignment: Qt.AlignCenter
      }

      // Falls back to a bare plug icon when nothing else is shown so the widget stays clickable.
      GridLayout {
        visible: root.portsVisible || !root.speedVisible
        flow: root.isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rows: root.isVertical ? -1 : 1
        columns: root.isVertical ? 1 : -1
        rowSpacing: Style.marginXXS
        columnSpacing: Style.marginXS
        Layout.alignment: Qt.AlignCenter

        Item {
          Layout.preferredWidth: root.iconSize
          Layout.preferredHeight: root.iconSize
          Layout.alignment: Qt.AlignCenter

          NIcon {
            icon: "plug-connected"
            pointSize: root.iconSize
            applyUiScale: false
            x: Style.pixelAlignCenter(parent.width, width)
            y: Style.pixelAlignCenter(parent.height, contentHeight)
            color: root.fgColor
          }
        }

        NText {
          visible: root.portsVisible
          text: root.portCount
          family: Settings.data.ui.fontFixed
          pointSize: root.barFontSize
          applyUiScale: false
          color: root.fgColor
          Layout.alignment: Qt.AlignCenter
        }
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: TooltipService.show(root, root.tooltipText, BarService.getTooltipDirection(root.screenName))
    onExited: TooltipService.hide()
    onClicked: mouse => {
                 TooltipService.hide();
                 if (mouse.button === Qt.LeftButton) {
                   pluginApi?.togglePanel(root.screen, root);
                 } else if (mouse.button === Qt.RightButton) {
                   PanelService.showContextMenu(contextMenu, root, screen);
                 } else if (mouse.button === Qt.MiddleButton) {
                   root.mainInstance?.refresh();
                 }
               }
  }
}
