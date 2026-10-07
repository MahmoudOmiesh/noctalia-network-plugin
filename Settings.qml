import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property bool editShowSpeed: cfg.showSpeed ?? defaults.showSpeed
  property bool editShowPorts: cfg.showPorts ?? defaults.showPorts
  property int editRefreshInterval: cfg.refreshInterval ?? defaults.refreshInterval
  property bool editHideSystemPorts: cfg.hideSystemPorts ?? defaults.hideSystemPorts
  property bool editOnlyOwnProcesses: cfg.onlyOwnProcesses ?? defaults.onlyOwnProcesses
  property bool editIncludeUdp: cfg.includeUdp ?? defaults.includeUdp

  spacing: Style.marginM

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.show-speed")
    description: pluginApi?.tr("settings.show-speed-desc")
    checked: root.editShowSpeed
    onToggled: checked => root.editShowSpeed = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.show-ports")
    description: pluginApi?.tr("settings.show-ports-desc")
    checked: root.editShowPorts
    onToggled: checked => root.editShowPorts = checked
  }

  NDivider {
    Layout.fillWidth: true
  }

  NValueSlider {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.refresh-interval")
    description: pluginApi?.tr("settings.refresh-interval-desc")
    from: 1
    to: 30
    stepSize: 1
    value: root.editRefreshInterval
    text: pluginApi?.tr("settings.seconds", {
                          "value": root.editRefreshInterval
                        })
    onMoved: value => root.editRefreshInterval = value
  }

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.hide-system-ports")
    description: pluginApi?.tr("settings.hide-system-ports-desc")
    checked: root.editHideSystemPorts
    onToggled: checked => root.editHideSystemPorts = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.only-own-processes")
    description: pluginApi?.tr("settings.only-own-processes-desc")
    checked: root.editOnlyOwnProcesses
    onToggled: checked => root.editOnlyOwnProcesses = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.include-udp")
    description: pluginApi?.tr("settings.include-udp-desc")
    checked: root.editIncludeUdp
    onToggled: checked => root.editIncludeUdp = checked
  }

  function saveSettings() {
    pluginApi.pluginSettings.showSpeed = root.editShowSpeed;
    pluginApi.pluginSettings.showPorts = root.editShowPorts;
    pluginApi.pluginSettings.refreshInterval = root.editRefreshInterval;
    pluginApi.pluginSettings.hideSystemPorts = root.editHideSystemPorts;
    pluginApi.pluginSettings.onlyOwnProcesses = root.editOnlyOwnProcesses;
    pluginApi.pluginSettings.includeUdp = root.editIncludeUdp;
    pluginApi.saveSettings();
  }
}
