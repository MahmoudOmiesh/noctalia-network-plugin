import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Services.UI
import qs.Widgets

Item {
  id: root
  property var pluginApi: null

  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: true

  property real contentPreferredWidth: 420 * Style.uiScaleRatio
  property real contentPreferredHeight: Math.min(mainColumn.implicitHeight + Style.margin2L, 640 * Style.uiScaleRatio)

  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property var listeners: mainInstance?.listeners ?? []

  anchors.fill: parent

  Component.onCompleted: SystemStatService.registerComponent("plugin-network-monitor-panel")
  Component.onDestruction: SystemStatService.unregisterComponent("plugin-network-monitor-panel")

  NText {
    id: portWidthReference
    visible: false
    text: "00000"
    family: Settings.data.ui.fontFixed
    pointSize: Style.fontSizeL
    font.weight: Style.fontWeightBold
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      id: mainColumn
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      NBox {
        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight + Style.margin2M

        RowLayout {
          id: headerRow
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          NIcon {
            icon: "network"
            pointSize: Style.fontSizeXXL
            color: Color.mPrimary
          }

          NText {
            text: pluginApi?.tr("panel.title")
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
            Layout.fillWidth: true
          }

          NIconButton {
            icon: "refresh"
            tooltipText: pluginApi?.tr("panel.refresh")
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: root.mainInstance?.refresh()
          }

          NIconButton {
            icon: "settings"
            tooltipText: pluginApi?.tr("panel.settings")
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: {
              const screen = pluginApi.panelOpenScreen;
              const manifest = pluginApi.manifest;
              pluginApi.closePanel(screen);
              Qt.callLater(() => BarService.openPluginSettings(screen, manifest));
            }
          }

          NIconButton {
            icon: "close"
            tooltipText: pluginApi?.tr("panel.close")
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: pluginApi.closePanel(pluginApi.panelOpenScreen)
          }
        }
      }

      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: 100 * Style.uiScaleRatio

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.marginS
          anchors.bottomMargin: Style.radiusM * 0.5
          spacing: Style.marginXS

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginXS

            NIcon {
              icon: "download-speed"
              pointSize: Style.fontSizeXS
              color: Color.mPrimary
            }

            NText {
              text: root.mainInstance?.formatRate(SystemStatService.rxSpeed) ?? ""
              pointSize: Style.fontSizeXS
              color: Color.mPrimary
              family: Settings.data.ui.fontFixed
              Layout.rightMargin: Style.marginS
            }

            NIcon {
              icon: "upload-speed"
              pointSize: Style.fontSizeXS
              color: Color.mSecondary
            }

            NText {
              text: root.mainInstance?.formatRate(SystemStatService.txSpeed) ?? ""
              pointSize: Style.fontSizeXS
              color: Color.mSecondary
              family: Settings.data.ui.fontFixed
            }

            Item {
              Layout.fillWidth: true
            }

            NText {
              text: pluginApi?.tr("panel.traffic")
              pointSize: Style.fontSizeXS
              color: Color.mOnSurfaceVariant
            }
          }

          NGraph {
            Layout.fillWidth: true
            Layout.fillHeight: true
            values: SystemStatService.rxSpeedHistory
            values2: SystemStatService.txSpeedHistory
            minValue: 0
            maxValue: SystemStatService.rxMaxSpeed
            minValue2: 0
            maxValue2: SystemStatService.txMaxSpeed
            color: Color.mPrimary
            color2: Color.mSecondary
            strokeWidth: Math.max(1, Style.uiScaleRatio)
            fill: true
            fillOpacity: 0.15
            updateInterval: SystemStatService.networkIntervalMs
            animateScale: true
          }
        }
      }

      NBox {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: portsColumn.implicitHeight + Style.margin2M

        ColumnLayout {
          id: portsColumn
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginXS

            NIcon {
              icon: "plug-connected"
              pointSize: Style.fontSizeXS
              color: Color.mPrimary
            }

            NText {
              text: pluginApi?.tr("panel.listening-ports")
              pointSize: Style.fontSizeXS
              color: Color.mOnSurfaceVariant
              Layout.fillWidth: true
            }

            NText {
              text: root.listeners.length
              pointSize: Style.fontSizeXS
              family: Settings.data.ui.fontFixed
              color: Color.mOnSurface
            }
          }

          ColumnLayout {
            visible: root.listeners.length === 0
            Layout.fillWidth: true
            Layout.topMargin: Style.marginL
            Layout.bottomMargin: Style.marginL
            spacing: Style.marginS

            NIcon {
              icon: "plug-connected-x"
              pointSize: 48
              color: Color.mOnSurfaceVariant
              Layout.alignment: Qt.AlignHCenter
            }

            NText {
              text: pluginApi?.tr("panel.no-ports")
              pointSize: Style.fontSizeM
              color: Color.mOnSurfaceVariant
              Layout.alignment: Qt.AlignHCenter
            }
          }

          NScrollView {
            id: portsScroll
            visible: root.listeners.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: portsList.implicitHeight
            contentWidth: availableWidth
            handleWidth: Math.round(3 * Style.uiScaleRatio)

            ColumnLayout {
              id: portsList
              width: portsScroll.availableWidth
              spacing: Style.marginXS

              Repeater {
                model: root.listeners

                delegate: NBox {
                  id: row
                  required property var modelData
                  readonly property color chipAccent: modelData.localOnly ? Color.mOnSurfaceVariant : Color.mTertiary

                  Layout.fillWidth: true
                  implicitHeight: rowLayout.implicitHeight + Style.margin2M
                  radius: Style.radiusM
                  forceOpaque: true
                  color: rowHover.hovered ? Qt.tint(Color.mSurface, Qt.alpha(Color.mHover, 0.08)) : Color.mSurface

                  HoverHandler {
                    id: rowHover
                  }

                  RowLayout {
                    id: rowLayout
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: Style.marginM

                    NText {
                      text: modelData.port
                      family: Settings.data.ui.fontFixed
                      pointSize: Style.fontSizeL
                      font.weight: Style.fontWeightBold
                      color: Color.mPrimary
                      Layout.preferredWidth: portWidthReference.implicitWidth
                    }

                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: Style.marginXXS

                      NText {
                        text: modelData.process || pluginApi?.tr("panel.unknown-process")
                        pointSize: Style.fontSizeM
                        color: modelData.process ? Color.mOnSurface : Color.mOnSurfaceVariant
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                      }

                      NText {
                        text: [modelData.proto.toUpperCase(), modelData.pid ? pluginApi?.tr("panel.pid", {
                                                                                                  "pid": modelData.pid
                                                                                                }) : "", modelData.addresses.join(", ")].filter(part => part).join(" · ")
                        pointSize: Style.fontSizeXXS
                        color: Qt.alpha(Color.mOnSurface, Style.opacityHeavy)
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                      }
                    }

                    Rectangle {
                      implicitWidth: chipText.implicitWidth + Style.margin2S
                      implicitHeight: chipText.implicitHeight + Style.margin2XXS
                      radius: Style.radiusXS
                      color: Qt.alpha(row.chipAccent, 0.12)

                      NText {
                        id: chipText
                        anchors.centerIn: parent
                        text: modelData.localOnly ? pluginApi?.tr("panel.local") : pluginApi?.tr("panel.exposed")
                        pointSize: Style.fontSizeXXS
                        color: row.chipAccent
                      }
                    }

                    RowLayout {
                      visible: rowHover.hovered
                      spacing: Style.marginXS

                      NIconButton {
                        visible: modelData.proto === "tcp"
                        icon: "external-link"
                        tooltipText: pluginApi?.tr("panel.open-in-browser")
                        baseSize: Style.baseWidgetSize * 0.7
                        onClicked: {
                          root.mainInstance?.openInBrowser(modelData);
                          pluginApi.closePanel(pluginApi.panelOpenScreen);
                        }
                      }

                      NIconButton {
                        icon: "x"
                        tooltipText: pluginApi?.tr("panel.stop-process")
                        baseSize: Style.baseWidgetSize * 0.7
                        colorBgHover: Color.mError
                        colorFgHover: Color.mOnError
                        onClicked: root.mainInstance?.killListener(modelData)
                      }
                    }

                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
