// =============================================================================
// FlyViewCustomLayer.qml — Agrohawk GCS
// Widget unificado Motor + Sprayer no Fly View
// Clique abre janela flutuante (Window) com barra de título do OS
// =============================================================================
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.ScreenTools

Item {
    id: _root

    property var parentToolInsets
    property var totalToolInsets:   _totalToolInsets
    property var mapControl

    property var  _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property real _toolsMargin:   ScreenTools.defaultFontPixelWidth * 0.75

    // Cores Agrohawk
    readonly property color _agOrange:      "#f26d30"
    readonly property color _agGreenDark:   "#0d1a0d"
    readonly property color _agGreenMid:    "#1a3a1a"
    readonly property color _agWidgetBg:    Qt.rgba(0.05, 0.1, 0.05, 0.85)

    property var _popoutWindow: null

    QGCToolInsets {
        id:                     _totalToolInsets
        leftEdgeTopInset:       parentToolInsets.leftEdgeTopInset
        leftEdgeCenterInset:    parentToolInsets.leftEdgeCenterInset
        leftEdgeBottomInset:    parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      parentToolInsets.rightEdgeTopInset
        rightEdgeCenterInset:   parentToolInsets.rightEdgeCenterInset
        rightEdgeBottomInset:   telemetryWidget.visible ? parent.width - telemetryWidget.x : parentToolInsets.rightEdgeBottomInset
        topEdgeLeftInset:       parentToolInsets.topEdgeLeftInset
        topEdgeCenterInset:     parentToolInsets.topEdgeCenterInset
        topEdgeRightInset:      parentToolInsets.topEdgeRightInset
        bottomEdgeLeftInset:    parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  parentToolInsets.bottomEdgeCenterInset
        bottomEdgeRightInset:   parentToolInsets.bottomEdgeRightInset
    }

    // =========================================================================
    // Helper: barra de gauge reutilizável
    // =========================================================================
    component GaugeBar: RowLayout {
        property string label: ""
        property real   value: 0
        property real   maxVal: 100
        property string unit: ""
        property string displayText: ""
        property bool   hasData: false
        property bool   alert: false
        property color  barColor: _agOrange
        property color  alertColor: "#ff4444"

        Layout.fillWidth: true
        spacing: 4

        Text {
            text: label
            Layout.preferredWidth: 70
            color: "#8aaa8a"; font.pixelSize: 13
        }
        Rectangle {
            Layout.fillWidth: true; height: 22; radius: 4; color: _agGreenMid
            Rectangle {
                width: parent.width * Math.min(value / maxVal, 1)
                height: parent.height; radius: 4
                color: alert ? alertColor : barColor
                Behavior on width { NumberAnimation { duration: 200 } }
            }
        }
        Text {
            text: hasData ? displayText : "---"
            font.bold: true; font.pixelSize: 14; color: alert ? "#ff4444" : "white"
            Layout.preferredWidth: 65; horizontalAlignment: Text.AlignRight
        }
    }

    // =========================================================================
    // Janela pop-out (janela real do OS — com barra de título e botões)
    // =========================================================================
    Component {
        id: popoutWindowComponent

        Window {
            id: pw
            title:   "Agrohawk — Telemetria"
            width:   560
            height:  560
            color:   _agGreenDark
            visible: true

            // Flags: janela normal com decoração do OS (close, minimize, etc.)
            flags: Qt.Window

            property var v: QGroundControl.multiVehicleManager.activeVehicle

            // EFI data
            property real efiRpm:      v ? v.efi.rpm.rawValue           : 0
            property real efiCht:      v ? v.efi.cylinderTemp.rawValue  : 0
            property real efiThrottle: v ? v.efi.throttlePos.rawValue   : 0
            property int  efiHealth:   v ? v.efi.health.rawValue        : 0
            property bool hasEfi:      v && efiRpm > 0

            // NAMED_VALUE_FLOAT engine extras
            property real engFuel:     agrohawkSprayer.fuelLevel
            property real engFuelPct:  agrohawkSprayer.fuelPercent
            property real engOil:      agrohawkSprayer.oilPressure
            property bool hasEngData:  agrohawkSprayer.engineDataValid

            onClosing: { _popoutWindow = null }

            Flickable {
                anchors.fill: parent
                anchors.margins: 14
                contentHeight: mainCol.height
                clip: true

                ColumnLayout {
                    id: mainCol
                    width: parent.width
                    spacing: 8

                    // ── HEADER ──
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "AGROHAWK TELEMETRY"; font.bold: true; font.pixelSize: 18; color: _agOrange }
                        Item { Layout.fillWidth: true }
                        Rectangle { width: 12; height: 12; radius: 6; color: pw.hasEfi ? "#44ff44" : "#888" }
                        Text { text: pw.hasEfi ? "ONLINE" : "OFFLINE"; font.bold: true; font.pixelSize: 12; color: pw.hasEfi ? "#44ff44" : "#888" }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#2a4a2a" }

                    // ══════════════════════════════════════════════════
                    // MOTOR
                    // ══════════════════════════════════════════════════
                    Text { text: "MOTOR"; font.bold: true; font.pixelSize: 15; color: _agOrange }

                    GaugeBar {
                        label: "RPM"; value: pw.efiRpm; maxVal: 8000; unit: ""
                        displayText: Math.round(pw.efiRpm).toString()
                        hasData: pw.hasEfi
                        alert: pw.efiRpm > 7000
                        barColor: pw.efiRpm > 5500 ? "#ffaa00" : _agOrange
                    }

                    GaugeBar {
                        label: "COMBUST."; value: pw.engFuel; maxVal: 80; unit: "L"
                        displayText: pw.engFuel.toFixed(1) + " L"
                        hasData: pw.hasEngData
                        alert: agrohawkSprayer.fuelLow
                        barColor: "#2196F3"
                    }

                    GaugeBar {
                        label: "ACELER."; value: pw.efiThrottle; maxVal: 100; unit: "%"
                        displayText: Math.round(pw.efiThrottle) + "%"
                        hasData: pw.hasEfi
                        barColor: _agOrange
                    }

                    GaugeBar {
                        label: "ÓLEO"; value: pw.engOil; maxVal: 8; unit: "bar"
                        displayText: pw.engOil.toFixed(1) + " bar"
                        hasData: pw.hasEngData
                        alert: agrohawkSprayer.oilLow
                        barColor: pw.engOil < 2.0 ? "#ff4444" : pw.engOil < 3.0 ? "#ffaa00" : "#44bb44"
                    }

                    GaugeBar {
                        label: "TEMP."; value: pw.efiCht; maxVal: 300; unit: "°C"
                        displayText: Math.round(pw.efiCht) + "°C"
                        hasData: pw.hasEfi
                        alert: pw.efiCht > 240
                        barColor: pw.efiCht > 200 ? "#ffaa00" : _agOrange
                    }

                    // Over-temp alert
                    Rectangle {
                        Layout.fillWidth: true; height: 30; radius: 4
                        color: "#44ff0000"
                        visible: pw.efiCht > 240
                        Text {
                            anchors.centerIn: parent
                            text: "⚠ TEMPERATURA ALTA"; font.bold: true; font.pixelSize: 15; color: "#ff4444"
                            SequentialAnimation on opacity {
                                running: pw.efiCht > 240; loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 400 }
                                NumberAnimation { to: 1.0; duration: 400 }
                            }
                        }
                    }

                    // Oil low alert
                    Rectangle {
                        Layout.fillWidth: true; height: 30; radius: 4
                        color: "#44ff0000"
                        visible: agrohawkSprayer.oilLow
                        Text {
                            anchors.centerIn: parent
                            text: "⚠ PRESSÃO ÓLEO BAIXA"; font.bold: true; font.pixelSize: 15; color: "#ff4444"
                            SequentialAnimation on opacity {
                                running: agrohawkSprayer.oilLow; loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 400 }
                                NumberAnimation { to: 1.0; duration: 400 }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#2a4a2a" }

                    // ══════════════════════════════════════════════════
                    // PULVERIZADOR
                    // ══════════════════════════════════════════════════
                    Text { text: "PULVERIZADOR"; font.bold: true; font.pixelSize: 15; color: _agOrange }

                    GaugeBar {
                        label: "TANQUE"; value: agrohawkSprayer.tankLevel; maxVal: 400; unit: "L"
                        displayText: agrohawkSprayer.tankLevel.toFixed(0) + " L (" + agrohawkSprayer.tankPercent.toFixed(0) + "%)"
                        hasData: agrohawkSprayer.dataValid
                        alert: agrohawkSprayer.tankLow
                        barColor: "#2196F3"
                    }

                    GaugeBar {
                        label: "PRESSÃO"; value: agrohawkSprayer.pumpPressure; maxVal: 10; unit: "bar"
                        displayText: agrohawkSprayer.pumpPressure.toFixed(1) + " bar"
                        hasData: agrohawkSprayer.dataValid
                        alert: agrohawkSprayer.pumpPressure > 8
                        barColor: agrohawkSprayer.pumpPressure > 6 ? "#ffaa00" : _agOrange
                    }

                    GaugeBar {
                        label: "VAZÃO"; value: agrohawkSprayer.flowRate; maxVal: 30; unit: "L/m"
                        displayText: agrohawkSprayer.flowRate.toFixed(1) + " L/min"
                        hasData: agrohawkSprayer.dataValid
                        barColor: _agOrange
                    }

                    // Pump status
                    RowLayout {
                        Layout.fillWidth: true
                        Rectangle { width: 14; height: 14; radius: 7; color: agrohawkSprayer.dataValid ? (agrohawkSprayer.pumpActive ? "#44ff44" : "#ffaa00") : "#888" }
                        Text { text: "BOMBA " + (agrohawkSprayer.pumpActive ? "LIGADA" : "DESLIGADA"); font.bold: true; font.pixelSize: 14; color: agrohawkSprayer.pumpActive ? "#44ff44" : "#ffaa00" }
                        Item { Layout.fillWidth: true }
                        Text { text: "TANQUE BAIXO"; font.bold: true; font.pixelSize: 14; color: "#ff8800"; visible: agrohawkSprayer.tankLow && agrohawkSprayer.dataValid }
                    }
                }
            }
        }
    }

    // =========================================================================
    // Widget compacto — canto inferior direito do mapa
    // =========================================================================
    Rectangle {
        id:     telemetryWidget
        width:  ScreenTools.defaultFontPixelWidth * 32
        height: ScreenTools.defaultFontPixelHeight * 12
        anchors.right:          parent.right
        anchors.bottom:         parent.bottom
        anchors.rightMargin:    _toolsMargin
        anchors.bottomMargin:   _toolsMargin + parentToolInsets.bottomEdgeRightInset
        color:   _agWidgetBg
        radius:  ScreenTools.defaultFontPixelWidth * 0.5
        border.color: _tempAlert || _oilAlert ? "#ff4444" : Qt.rgba(0.2, 0.4, 0.2, 0.5)
        border.width: _tempAlert || _oilAlert ? 2 : 1
        visible: _activeVehicle

        property real _rpm:      _activeVehicle ? _activeVehicle.efi.rpm.rawValue           : 0
        property real _cht:      _activeVehicle ? _activeVehicle.efi.cylinderTemp.rawValue   : 0
        property real _throttle: _activeVehicle ? _activeVehicle.efi.throttlePos.rawValue    : 0
        property int  _health:   _activeVehicle ? _activeVehicle.efi.health.rawValue         : 0
        property bool _hasEfi:   _activeVehicle && _rpm > 0
        property bool _tempAlert: _cht > 240
        property bool _oilAlert:  agrohawkSprayer.oilLow

        MouseArea {
            anchors.fill: parent
            cursorShape:  Qt.PointingHandCursor
            onClicked: {
                if (_popoutWindow) {
                    _popoutWindow.raise()
                    _popoutWindow.requestActivate()
                } else {
                    _popoutWindow = popoutWindowComponent.createObject(_root)
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelWidth * 0.7
            spacing: ScreenTools.defaultFontPixelHeight * 0.15

            // Header
            RowLayout {
                Layout.fillWidth: true
                QGCLabel { text: "AGH TELEMETRY"; font.bold: true; color: _agOrange }
                Item { Layout.fillWidth: true }
                QGCLabel { text: "\u2197 abrir"; color: _agOrange; font.pixelSize: ScreenTools.smallFontPointSize }
                Rectangle {
                    width: ScreenTools.defaultFontPixelWidth * 1.1; height: width; radius: width / 2
                    color: telemetryWidget._hasEfi ? (telemetryWidget._health > 0 ? "#44ff44" : "#ff4444") : "#888"
                }
            }

            // RPM bar
            RowLayout {
                Layout.fillWidth: true
                QGCLabel { text: "RPM"; Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 4; color: "#8aaa8a"; font.pixelSize: ScreenTools.smallFontPointSize }
                Rectangle {
                    Layout.fillWidth: true; height: ScreenTools.defaultFontPixelHeight * 0.9
                    radius: 3; color: _agGreenMid
                    Rectangle {
                        width: parent.width * Math.min(telemetryWidget._rpm / 8000, 1)
                        height: parent.height; radius: 3
                        color: telemetryWidget._rpm > 7000 ? "#ff4444" : telemetryWidget._rpm > 5500 ? "#ffaa00" : _agOrange
                    }
                }
                QGCLabel {
                    text: telemetryWidget._hasEfi ? Math.round(telemetryWidget._rpm) : "---"
                    font.bold: true; Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 5
                    horizontalAlignment: Text.AlignRight
                }
            }

            // FUEL + THROTTLE + OIL + TEMP (compact row)
            RowLayout {
                Layout.fillWidth: true
                QGCLabel { text: "FUEL"; color: "#8aaa8a"; font.pixelSize: ScreenTools.smallFontPointSize }
                QGCLabel {
                    text: agrohawkSprayer.engineDataValid ? agrohawkSprayer.fuelPercent.toFixed(0) + "%" : "---"
                    font.bold: true; color: agrohawkSprayer.fuelLow ? "#ff4444" : "white"
                }
                Item { Layout.fillWidth: true }
                QGCLabel { text: "THR"; color: "#8aaa8a"; font.pixelSize: ScreenTools.smallFontPointSize }
                QGCLabel {
                    text: telemetryWidget._hasEfi ? Math.round(telemetryWidget._throttle) + "%" : "---"
                    font.bold: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                QGCLabel { text: "OIL"; color: "#8aaa8a"; font.pixelSize: ScreenTools.smallFontPointSize }
                QGCLabel {
                    text: agrohawkSprayer.engineDataValid ? agrohawkSprayer.oilPressure.toFixed(1) + " bar" : "---"
                    font.bold: true; color: agrohawkSprayer.oilLow ? "#ff4444" : "white"
                }
                Item { Layout.fillWidth: true }
                QGCLabel { text: "TEMP"; color: "#8aaa8a"; font.pixelSize: ScreenTools.smallFontPointSize }
                QGCLabel {
                    text: telemetryWidget._hasEfi ? Math.round(telemetryWidget._cht) + "\u00B0C" : "---"
                    font.bold: true; color: telemetryWidget._tempAlert ? "#ff4444" : "white"
                }
            }

            // Separator
            Rectangle { Layout.fillWidth: true; height: 1; color: "#2a4a2a" }

            // Sprayer compact: tank bar
            RowLayout {
                Layout.fillWidth: true
                QGCLabel { text: "TANK"; Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 4; color: "#8aaa8a"; font.pixelSize: ScreenTools.smallFontPointSize }
                Rectangle {
                    Layout.fillWidth: true; height: ScreenTools.defaultFontPixelHeight * 1.0
                    radius: 3; color: _agGreenMid
                    Rectangle {
                        width: parent.width * Math.min(agrohawkSprayer.tankPercent / 100, 1)
                        height: parent.height; radius: 3
                        color: agrohawkSprayer.tankLow ? "#ff4444" : agrohawkSprayer.tankPercent < 25 ? "#ffaa00" : "#2196F3"
                        Behavior on width { NumberAnimation { duration: 300 } }
                    }
                    QGCLabel {
                        anchors.centerIn: parent
                        text: agrohawkSprayer.dataValid ? agrohawkSprayer.tankLevel.toFixed(0) + " L" : "---"
                        font.bold: true; font.pixelSize: ScreenTools.smallFontPointSize
                    }
                }
                QGCLabel {
                    text: agrohawkSprayer.dataValid ? agrohawkSprayer.tankPercent.toFixed(0) + "%" : "---"
                    font.bold: true; color: agrohawkSprayer.tankLow ? "#ff4444" : "white"
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 4
                    horizontalAlignment: Text.AlignRight
                }
            }

            // Pump + pressure + flow compact
            RowLayout {
                Layout.fillWidth: true
                Rectangle {
                    width: ScreenTools.defaultFontPixelWidth * 1.0; height: width; radius: width / 2
                    color: agrohawkSprayer.dataValid ? (agrohawkSprayer.pumpActive ? "#44ff44" : "#ffaa00") : "#888"
                }
                QGCLabel {
                    text: agrohawkSprayer.dataValid ? agrohawkSprayer.pumpPressure.toFixed(1) + " bar" : "---"
                    font.pixelSize: ScreenTools.smallFontPointSize; color: "#ccc"
                }
                Item { Layout.fillWidth: true }
                QGCLabel {
                    text: agrohawkSprayer.dataValid ? agrohawkSprayer.flowRate.toFixed(1) + " L/m" : "---"
                    font.pixelSize: ScreenTools.smallFontPointSize; color: "#ccc"
                }
            }
        }

        // Over-temp / oil-low flash
        Rectangle {
            anchors.fill: parent; radius: parent.radius
            color: "#44ff0000"
            visible: telemetryWidget._tempAlert || telemetryWidget._oilAlert
            QGCLabel {
                anchors.centerIn: parent
                text: telemetryWidget._tempAlert ? "OVER TEMP" : "OIL LOW"
                font.bold: true; font.pixelSize: ScreenTools.largeFontPointSize; color: "#ff4444"
                SequentialAnimation on opacity {
                    running: telemetryWidget._tempAlert || telemetryWidget._oilAlert
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 400 }
                    NumberAnimation { to: 1.0; duration: 400 }
                }
            }
        }
    }
}
