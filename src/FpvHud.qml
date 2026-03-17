// =============================================================================
// FpvHud.qml — Agrohawk GCS
// Full FPV Head-Up Display overlay for fixed-wing piloting
// Semi-transparent — video feed visible through the horizon
// Based on QGC v5.0.8 (Stable_V5.0)
// =============================================================================
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var  vehicle: null
    property bool hudVisible: true

    visible: hudVisible && vehicle

    // --- Telemetry bindings ---
    property real _roll:       vehicle ? vehicle.roll.value              : 0
    property real _pitch:      vehicle ? vehicle.pitch.value             : 0
    property real _heading:    vehicle ? vehicle.heading.value           : 0
    property real _airSpeed:   vehicle ? vehicle.airSpeed.value          : 0
    property real _gndSpeed:   vehicle ? vehicle.groundSpeed.value       : 0
    property real _altRel:     vehicle ? vehicle.altitudeRelative.value  : 0
    property real _climbRate:  vehicle ? vehicle.climbRate.value         : 0
    property real _distHome:   vehicle ? vehicle.distanceToHome.value    : 0
    property real _hdgHome:    vehicle ? vehicle.headingToHome.value     : 0
    property bool _armed:      vehicle ? vehicle.armed                   : false
    property string _flightMode: vehicle ? vehicle.flightMode            : "---"

    // Battery
    property var  _batt:       vehicle && vehicle.batteries.count > 0 ? vehicle.batteries.get(0) : null
    property real _battVolts:  _batt ? _batt.voltage.value               : 0
    property real _battPct:    _batt ? _batt.percentRemaining.value      : 0

    // GPS
    property real _gpsSats:    vehicle ? vehicle.gps.count.value         : 0
    property real _gpsLock:    vehicle ? vehicle.gps.lock.value          : 0

    // EFI (engine)
    property real _efiRpm:      vehicle ? vehicle.efi.rpm.rawValue           : 0
    property real _efiCht:      vehicle ? vehicle.efi.cylinderTemp.rawValue  : 0
    property real _efiThrottle: vehicle ? vehicle.efi.throttlePos.rawValue   : 0
    property bool _hasEfi:      vehicle && _efiRpm > 0

    // Sprayer + engine extras (via agrohawkSprayer global context object)
    property real _fuelPct:     agrohawkSprayer.fuelPercent
    property real _oilPressure: agrohawkSprayer.oilPressure
    property bool _oilLow:      agrohawkSprayer.oilLow
    property bool _fuelLow:     agrohawkSprayer.fuelLow
    property bool _pumpActive:  agrohawkSprayer.pumpActive
    property real _tankPct:     agrohawkSprayer.tankPercent
    property bool _tankLow:     agrohawkSprayer.tankLow
    property bool _sprayerOk:   agrohawkSprayer.dataValid
    property bool _engineOk:    agrohawkSprayer.engineDataValid

    // Display speed: prefer airspeed, fallback to ground speed
    property real _dispSpeed:  _airSpeed > 0 ? _airSpeed : _gndSpeed
    property string _speedLabel: _airSpeed > 0 ? "IAS" : "GS"

    // Compact mode for pip
    property bool _compact:    width < 400 || height < 300

    // --- Style constants ---
    readonly property color _accent:     "#f26d30"
    readonly property real  _deg2rad:    Math.PI / 180
    readonly property real  _fontSize:   Math.max(height * 0.028, 10)
    readonly property real  _bigFont:    _fontSize * 1.3
    readonly property real  _smallFont:  _fontSize * 0.85

    // =========================================================================
    // ARTIFICIAL HORIZON (Canvas) — SEMI-TRANSPARENT
    // =========================================================================
    Canvas {
        id: horizonCanvas
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative
        opacity: 0.35

        onPaint: {
            var ctx = getContext("2d")
            var w = width
            var h = height
            var cx = w / 2
            var cy = h / 2

            ctx.clearRect(0, 0, w, h)
            ctx.save()

            ctx.translate(cx, cy)
            ctx.rotate(-_roll * _deg2rad)

            var ppd = h / 45
            var pitchOffset = _pitch * ppd

            // Sky
            var skyGrad = ctx.createLinearGradient(0, -h, 0, pitchOffset)
            skyGrad.addColorStop(0, "#0a2040")
            skyGrad.addColorStop(1, "#2a6090")
            ctx.fillStyle = skyGrad
            ctx.fillRect(-w, -h * 2, w * 2, h * 2 + pitchOffset)

            // Ground
            var gndGrad = ctx.createLinearGradient(0, pitchOffset, 0, h * 2)
            gndGrad.addColorStop(0, "#4a3018")
            gndGrad.addColorStop(1, "#2a1808")
            ctx.fillStyle = gndGrad
            ctx.fillRect(-w, pitchOffset, w * 2, h * 3)

            ctx.restore()
        }
    }

    // =========================================================================
    // HORIZON LINES & INSTRUMENTS (Canvas) — fully opaque
    // =========================================================================
    Canvas {
        id: horizonLines
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        onPaint: {
            var ctx = getContext("2d")
            var w = width
            var h = height
            var cx = w / 2
            var cy = h / 2

            ctx.clearRect(0, 0, w, h)
            ctx.save()

            ctx.translate(cx, cy)
            ctx.rotate(-_roll * _deg2rad)

            var ppd = h / 45
            var pitchOffset = _pitch * ppd

            // Horizon line
            ctx.strokeStyle = "rgba(255,255,255,0.7)"
            ctx.lineWidth = 2
            ctx.beginPath()
            ctx.moveTo(-w, pitchOffset)
            ctx.lineTo(w, pitchOffset)
            ctx.stroke()

            // Pitch ladder
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            var ladderFont = Math.max(h * 0.022, 9) + "px monospace"
            ctx.font = ladderFont

            for (var deg = -60; deg <= 60; deg += 5) {
                if (deg === 0) continue
                var y = pitchOffset - deg * ppd
                var halfW = (deg % 10 === 0) ? w * 0.12 : w * 0.06

                ctx.strokeStyle = "rgba(255,255,255,0.6)"
                ctx.lineWidth = (deg % 10 === 0) ? 1.5 : 1
                ctx.beginPath()
                ctx.moveTo(-halfW, y)
                ctx.lineTo(halfW, y)
                ctx.stroke()

                if (deg % 10 === 0) {
                    ctx.fillStyle = "white"
                    ctx.strokeStyle = "black"
                    ctx.lineWidth = 2
                    var label = deg.toString()
                    ctx.strokeText(label, -halfW - 20, y)
                    ctx.fillText(label, -halfW - 20, y)
                    ctx.strokeText(label, halfW + 20, y)
                    ctx.fillText(label, halfW + 20, y)
                }
            }

            ctx.restore()

            // --- Roll indicator arc (fixed) ---
            ctx.save()
            ctx.translate(cx, cy)

            var rollRadius = Math.min(w, h) * 0.38
            var rollAngles = [0, 10, 20, 30, 45, 60]

            ctx.strokeStyle = "white"
            ctx.lineWidth = 1.5
            for (var i = 0; i < rollAngles.length; i++) {
                var a = rollAngles[i]
                var tickLen = (a % 30 === 0) ? 15 : 10
                for (var s = -1; s <= 1; s += 2) {
                    if (a === 0 && s === 1) continue
                    var angle = (-90 + s * a) * _deg2rad
                    ctx.beginPath()
                    ctx.moveTo(Math.cos(angle) * rollRadius, Math.sin(angle) * rollRadius)
                    ctx.lineTo(Math.cos(angle) * (rollRadius - tickLen), Math.sin(angle) * (rollRadius - tickLen))
                    ctx.stroke()
                }
            }

            // Roll pointer
            var rpAngle = (-90 - _roll) * _deg2rad
            var rpR = rollRadius - 2
            var rpSize = 8
            ctx.fillStyle = _accent
            ctx.beginPath()
            ctx.moveTo(Math.cos(rpAngle) * rpR, Math.sin(rpAngle) * rpR)
            ctx.lineTo(Math.cos(rpAngle - 0.06) * (rpR - rpSize), Math.sin(rpAngle - 0.06) * (rpR - rpSize))
            ctx.lineTo(Math.cos(rpAngle + 0.06) * (rpR - rpSize), Math.sin(rpAngle + 0.06) * (rpR - rpSize))
            ctx.closePath()
            ctx.fill()

            ctx.restore()

            // --- Fixed aircraft reference symbol ---
            ctx.save()
            ctx.translate(cx, cy)
            ctx.strokeStyle = _accent
            ctx.lineWidth = 3

            ctx.beginPath()
            ctx.moveTo(-60, 0); ctx.lineTo(-25, 0); ctx.lineTo(-25, 8)
            ctx.stroke()

            ctx.beginPath()
            ctx.moveTo(60, 0); ctx.lineTo(25, 0); ctx.lineTo(25, 8)
            ctx.stroke()

            ctx.fillStyle = _accent
            ctx.beginPath()
            ctx.arc(0, 0, 4, 0, Math.PI * 2)
            ctx.fill()

            ctx.restore()
        }
    }

    // Repaint on attitude changes
    Connections {
        target: root
        function on_RollChanged()  { horizonCanvas.requestPaint(); horizonLines.requestPaint() }
        function on_PitchChanged() { horizonCanvas.requestPaint(); horizonLines.requestPaint() }
    }

    // =========================================================================
    // HEADING TAPE (top)
    // =========================================================================
    Item {
        id: headingTape
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.02
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.6
        height: _bigFont * 2.5
        visible: !_compact
        clip: true

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.35)
            radius: 3
        }

        Canvas {
            id: headingCanvas
            anchors.fill: parent
            renderStrategy: Canvas.Cooperative

            onPaint: {
                var ctx = getContext("2d")
                var w = width
                var h = height
                ctx.clearRect(0, 0, w, h)

                var ppd = w / 90
                var cx = w / 2
                var cardinals = { 0: "N", 45: "NE", 90: "E", 135: "SE", 180: "S", 225: "SW", 270: "W", 315: "NW" }

                ctx.textAlign = "center"
                ctx.textBaseline = "top"

                for (var deg = -180; deg <= 540; deg += 5) {
                    var normDeg = ((deg % 360) + 360) % 360
                    var offset = deg - _heading
                    while (offset > 180) offset -= 360
                    while (offset < -180) offset += 360

                    var x = cx + offset * ppd
                    if (x < -20 || x > w + 20) continue

                    var isMajor = (normDeg % 10 === 0)
                    var isCardinal = cardinals.hasOwnProperty(normDeg)

                    ctx.strokeStyle = "white"
                    ctx.lineWidth = isMajor ? 1.5 : 0.8
                    ctx.beginPath()
                    ctx.moveTo(x, h - 2)
                    ctx.lineTo(x, h - (isMajor ? 14 : 8))
                    ctx.stroke()

                    if (isCardinal) {
                        ctx.font = "bold " + _fontSize + "px monospace"
                        ctx.fillStyle = _accent
                        ctx.strokeStyle = "black"
                        ctx.lineWidth = 2
                        ctx.strokeText(cardinals[normDeg], x, 4)
                        ctx.fillText(cardinals[normDeg], x, 4)
                    } else if (normDeg % 10 === 0) {
                        ctx.font = _smallFont + "px monospace"
                        ctx.fillStyle = "white"
                        ctx.strokeStyle = "black"
                        ctx.lineWidth = 2
                        ctx.strokeText(normDeg.toString(), x, 6)
                        ctx.fillText(normDeg.toString(), x, 6)
                    }
                }

                // Center pointer
                ctx.fillStyle = _accent
                ctx.beginPath()
                ctx.moveTo(cx, h)
                ctx.lineTo(cx - 6, h - 8)
                ctx.lineTo(cx + 6, h - 8)
                ctx.closePath()
                ctx.fill()
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: -2
            width: _bigFont * 4
            height: _bigFont * 1.4
            color: Qt.rgba(0, 0, 0, 0.6)
            radius: 3
            border.color: _accent
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: Math.round(_heading).toString().padStart(3, '0') + "\u00B0"
                color: "white"
                font.pixelSize: _bigFont
                font.family: "monospace"
                font.bold: true
                style: Text.Outline
                styleColor: "black"
            }
        }
    }

    Connections {
        target: root
        function on_HeadingChanged() { headingCanvas.requestPaint() }
    }

    // =========================================================================
    // AIRSPEED TAPE (left)
    // =========================================================================
    Item {
        id: speedTape
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.05
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.09
        height: parent.height * 0.5
        visible: !_compact
        clip: true

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.35)
            radius: 3
        }

        Canvas {
            id: speedCanvas
            anchors.fill: parent
            renderStrategy: Canvas.Cooperative

            onPaint: {
                var ctx = getContext("2d")
                var w = width
                var h = height
                ctx.clearRect(0, 0, w, h)

                var cy = h / 2
                var ppu = h / 40
                var speed = _dispSpeed

                ctx.textAlign = "right"
                ctx.textBaseline = "middle"
                ctx.font = _smallFont + "px monospace"

                for (var s = Math.floor(speed - 25); s <= Math.ceil(speed + 25); s += 1) {
                    if (s < 0) continue
                    var y = cy - (s - speed) * ppu
                    if (y < -10 || y > h + 10) continue

                    var isMajor = (s % 10 === 0)
                    var isMid = (s % 5 === 0)

                    if (isMajor || isMid) {
                        ctx.strokeStyle = "white"
                        ctx.lineWidth = isMajor ? 1.5 : 0.8
                        ctx.beginPath()
                        ctx.moveTo(w - 2, y)
                        ctx.lineTo(w - (isMajor ? 14 : 8), y)
                        ctx.stroke()
                    }

                    if (isMajor) {
                        ctx.fillStyle = "white"
                        ctx.strokeStyle = "black"
                        ctx.lineWidth = 2
                        ctx.strokeText(s.toString(), w - 18, y)
                        ctx.fillText(s.toString(), w - 18, y)
                    }
                }
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width + 10
            height: _bigFont * 1.6
            color: Qt.rgba(0, 0, 0, 0.7)
            radius: 3
            border.color: "white"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: Math.round(_dispSpeed)
                color: "white"
                font.pixelSize: _bigFont
                font.family: "monospace"
                font.bold: true
                style: Text.Outline
                styleColor: "black"
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: 2
            text: _speedLabel
            color: "white"
            font.pixelSize: _smallFont
            font.family: "monospace"
            style: Text.Outline
            styleColor: "black"
        }
    }

    Connections {
        target: root
        function on_DispSpeedChanged() { speedCanvas.requestPaint() }
    }

    // =========================================================================
    // ALTITUDE TAPE (right)
    // =========================================================================
    Item {
        id: altTape
        anchors.right: parent.right
        anchors.rightMargin: parent.width * 0.05
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.09
        height: parent.height * 0.5
        visible: !_compact
        clip: true

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.35)
            radius: 3
        }

        Canvas {
            id: altCanvas
            anchors.fill: parent
            renderStrategy: Canvas.Cooperative

            onPaint: {
                var ctx = getContext("2d")
                var w = width
                var h = height
                ctx.clearRect(0, 0, w, h)

                var cy = h / 2
                var ppu = h / 100
                var alt = _altRel

                ctx.textAlign = "left"
                ctx.textBaseline = "middle"
                ctx.font = _smallFont + "px monospace"

                for (var a = Math.floor(alt - 60); a <= Math.ceil(alt + 60); a += 1) {
                    var y = cy - (a - alt) * ppu
                    if (y < -10 || y > h + 10) continue

                    var isMajor = (a % 10 === 0)
                    var isMid = (a % 5 === 0)

                    if (isMajor || isMid) {
                        ctx.strokeStyle = "white"
                        ctx.lineWidth = isMajor ? 1.5 : 0.8
                        ctx.beginPath()
                        ctx.moveTo(2, y)
                        ctx.lineTo(isMajor ? 14 : 8, y)
                        ctx.stroke()
                    }

                    if (isMajor) {
                        ctx.fillStyle = "white"
                        ctx.strokeStyle = "black"
                        ctx.lineWidth = 2
                        ctx.strokeText(a.toString(), 18, y)
                        ctx.fillText(a.toString(), 18, y)
                    }
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width + 10
            height: _bigFont * 1.6
            color: Qt.rgba(0, 0, 0, 0.7)
            radius: 3
            border.color: "white"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: Math.round(_altRel)
                color: "white"
                font.pixelSize: _bigFont
                font.family: "monospace"
                font.bold: true
                style: Text.Outline
                styleColor: "black"
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: 2
            text: "ALT"
            color: "white"
            font.pixelSize: _smallFont
            font.family: "monospace"
            style: Text.Outline
            styleColor: "black"
        }
    }

    Connections {
        target: root
        function on_AltRelChanged() { altCanvas.requestPaint() }
    }

    // =========================================================================
    // VSI (right of altitude tape)
    // =========================================================================
    Item {
        id: vsiIndicator
        anchors.left: altTape.right
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        width: 12
        height: altTape.height * 0.6
        visible: !_compact

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.3)
            radius: 2
        }

        Rectangle {
            width: parent.width - 2
            anchors.horizontalCenter: parent.horizontalCenter
            color: _climbRate >= 0 ? "#44ff44" : "#ff4444"
            radius: 2
            property real maxRate: 10
            property real barFrac: Math.min(Math.abs(_climbRate) / maxRate, 1.0)
            height: parent.height / 2 * barFrac
            y: _climbRate >= 0 ? (parent.height / 2 - height) : (parent.height / 2)
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height / 2 - 0.5
            width: parent.width; height: 1; color: "white"
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: 2
            text: (_climbRate >= 0 ? "+" : "") + _climbRate.toFixed(1)
            color: "white"
            font.pixelSize: _smallFont * 0.85
            font.family: "monospace"
            style: Text.Outline; styleColor: "black"
        }
    }

    // =========================================================================
    // ENGINE + SPRAYER PANEL (top-left)
    // =========================================================================
    Rectangle {
        id: enginePanel
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: parent.width * 0.02
        anchors.topMargin: parent.height * 0.02
        width: _fontSize * 11
        height: engineCol.height + 10
        color: Qt.rgba(0, 0, 0, 0.45)
        radius: 4
        visible: !_compact

        ColumnLayout {
            id: engineCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 5
            spacing: 1

            // RPM
            RowLayout {
                spacing: 4
                Text { text: "RPM"; color: "#8aaa8a"; font.pixelSize: _smallFont; font.family: "monospace"; style: Text.Outline; styleColor: "black" }
                Text {
                    text: _hasEfi ? Math.round(_efiRpm) : "---"
                    color: _efiRpm > 7000 ? "#ff4444" : "white"
                    font.pixelSize: _smallFont; font.family: "monospace"; font.bold: true
                    style: Text.Outline; styleColor: "black"
                }
            }

            // Fuel
            RowLayout {
                spacing: 4
                Text { text: "FUEL"; color: "#8aaa8a"; font.pixelSize: _smallFont; font.family: "monospace"; style: Text.Outline; styleColor: "black" }
                Text {
                    text: _engineOk ? Math.round(_fuelPct) + "%" : "---"
                    color: _fuelLow ? "#ff4444" : "white"
                    font.pixelSize: _smallFont; font.family: "monospace"; font.bold: true
                    style: Text.Outline; styleColor: "black"
                }
            }

            // Throttle
            RowLayout {
                spacing: 4
                Text { text: "THR"; color: "#8aaa8a"; font.pixelSize: _smallFont; font.family: "monospace"; style: Text.Outline; styleColor: "black" }
                Text {
                    text: _hasEfi ? Math.round(_efiThrottle) + "%" : "---"
                    color: "white"
                    font.pixelSize: _smallFont; font.family: "monospace"; font.bold: true
                    style: Text.Outline; styleColor: "black"
                }
            }

            // Oil pressure
            RowLayout {
                spacing: 4
                Text { text: "OIL"; color: "#8aaa8a"; font.pixelSize: _smallFont; font.family: "monospace"; style: Text.Outline; styleColor: "black" }
                Text {
                    text: _engineOk ? _oilPressure.toFixed(1) + " bar" : "---"
                    color: _oilLow ? "#ff4444" : "white"
                    font.pixelSize: _smallFont; font.family: "monospace"; font.bold: true
                    style: Text.Outline; styleColor: "black"
                }
            }

            // CHT
            RowLayout {
                spacing: 4
                Text { text: "CHT"; color: "#8aaa8a"; font.pixelSize: _smallFont; font.family: "monospace"; style: Text.Outline; styleColor: "black" }
                Text {
                    text: _hasEfi ? Math.round(_efiCht) + "\u00B0C" : "---"
                    color: _efiCht > 240 ? "#ff4444" : (_efiCht > 200 ? "#ffaa00" : "white")
                    font.pixelSize: _smallFont; font.family: "monospace"; font.bold: true
                    style: Text.Outline; styleColor: "black"
                }
            }

            // Separator
            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.2) }

            // Sprayer: tank + pump
            RowLayout {
                spacing: 4
                Text { text: "TANK"; color: "#8aaa8a"; font.pixelSize: _smallFont; font.family: "monospace"; style: Text.Outline; styleColor: "black" }
                Text {
                    text: _sprayerOk ? Math.round(_tankPct) + "%" : "---"
                    color: _tankLow ? "#ff4444" : "#2196F3"
                    font.pixelSize: _smallFont; font.family: "monospace"; font.bold: true
                    style: Text.Outline; styleColor: "black"
                }
            }

            RowLayout {
                spacing: 4
                Rectangle {
                    width: _smallFont * 0.7; height: width; radius: width / 2
                    color: _sprayerOk ? (_pumpActive ? "#44ff44" : "#ffaa00") : "#888"
                }
                Text {
                    text: _sprayerOk ? (_pumpActive ? "PUMP ON" : "PUMP OFF") : "PUMP ---"
                    color: _pumpActive ? "#44ff44" : "#ffaa00"
                    font.pixelSize: _smallFont; font.family: "monospace"; font.bold: true
                    style: Text.Outline; styleColor: "black"
                }
            }
        }
    }

    // =========================================================================
    // COMPACT MODE OVERLAYS (when in pip)
    // =========================================================================
    Column {
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 2
        visible: _compact

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(_heading).toString().padStart(3, '0') + "\u00B0"
            color: "white"
            font.pixelSize: _fontSize; font.family: "monospace"; font.bold: true
            style: Text.Outline; styleColor: "black"
        }
    }

    Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10
        visible: _compact

        Text {
            text: Math.round(_dispSpeed) + " m/s"
            color: "white"
            font.pixelSize: _fontSize; font.family: "monospace"; font.bold: true
            style: Text.Outline; styleColor: "black"
        }
        Text {
            text: Math.round(_altRel) + " m"
            color: "white"
            font.pixelSize: _fontSize; font.family: "monospace"; font.bold: true
            style: Text.Outline; styleColor: "black"
        }
    }

    // =========================================================================
    // STATUS BAR (bottom)
    // =========================================================================
    Rectangle {
        id: statusBar
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.85
        height: _fontSize * 3.2
        color: Qt.rgba(0, 0, 0, 0.45)
        radius: 4
        anchors.bottomMargin: parent.height * 0.02
        visible: !_compact

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 1

            // Row 1: GS, Flight Mode, Armed, Battery
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "GS " + _gndSpeed.toFixed(1) + " m/s"
                    color: "white"
                    font.pixelSize: _smallFont; font.family: "monospace"
                    style: Text.Outline; styleColor: "black"
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: _flightMode
                    color: _accent
                    font.pixelSize: _fontSize; font.family: "monospace"; font.bold: true
                    style: Text.Outline; styleColor: "black"
                }

                Rectangle {
                    width: _fontSize * 0.8; height: width; radius: width / 2
                    color: _armed ? "#44ff44" : "#ff4444"
                }
                Text {
                    text: _armed ? "ARMED" : "DISARMED"
                    color: _armed ? "#44ff44" : "#ff4444"
                    font.pixelSize: _smallFont; font.family: "monospace"; font.bold: true
                    style: Text.Outline; styleColor: "black"
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: _battVolts.toFixed(1) + "V  " + Math.round(_battPct) + "%"
                    color: _battPct < 20 ? "#ff4444" : (_battPct < 40 ? "#ffaa00" : "white")
                    font.pixelSize: _smallFont; font.family: "monospace"; font.bold: true
                    style: Text.Outline; styleColor: "black"
                }
            }

            // Row 2: Home, GPS
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: {
                        var dist = _distHome
                        var distStr = dist >= 1000 ? (dist / 1000).toFixed(1) + " km" : Math.round(dist) + " m"
                        return "HOME " + distStr
                    }
                    color: "white"
                    font.pixelSize: _smallFont; font.family: "monospace"
                    style: Text.Outline; styleColor: "black"
                }

                Text {
                    text: "\u2191"
                    color: _accent
                    font.pixelSize: _fontSize * 1.2
                    font.bold: true
                    rotation: {
                        var rel = _hdgHome - _heading
                        return ((rel % 360) + 360) % 360
                    }
                    style: Text.Outline; styleColor: "black"
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: {
                        var lockNames = ["No GPS", "No Fix", "2D", "3D", "DGPS", "RTK Float", "RTK Fix"]
                        var lockStr = (_gpsLock >= 0 && _gpsLock < lockNames.length) ? lockNames[Math.round(_gpsLock)] : "?"
                        return "GPS: " + lockStr + " (" + Math.round(_gpsSats) + ")"
                    }
                    color: _gpsLock >= 3 ? "#44ff44" : (_gpsLock >= 2 ? "#ffaa00" : "#ff4444")
                    font.pixelSize: _smallFont; font.family: "monospace"; font.bold: true
                    style: Text.Outline; styleColor: "black"
                }
            }
        }
    }

    // =========================================================================
    // ALERTS OVERLAY (over-temp, oil low, fuel low)
    // =========================================================================
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: headingTape.visible ? headingTape.bottom : parent.top
        anchors.topMargin: 8
        spacing: 4
        visible: !_compact

        // Over-temp
        Rectangle {
            width: _fontSize * 14; height: _fontSize * 1.6; radius: 4
            color: "#88ff0000"
            visible: _efiCht > 240
            Text {
                anchors.centerIn: parent
                text: "OVER TEMP " + Math.round(_efiCht) + "\u00B0C"
                color: "white"; font.bold: true; font.pixelSize: _fontSize; font.family: "monospace"
                style: Text.Outline; styleColor: "black"
                SequentialAnimation on opacity {
                    running: _efiCht > 240; loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 400 }
                    NumberAnimation { to: 1.0; duration: 400 }
                }
            }
        }

        // Oil low
        Rectangle {
            width: _fontSize * 14; height: _fontSize * 1.6; radius: 4
            color: "#88ff0000"
            visible: _oilLow
            Text {
                anchors.centerIn: parent
                text: "OIL PRESSURE LOW"
                color: "white"; font.bold: true; font.pixelSize: _fontSize; font.family: "monospace"
                style: Text.Outline; styleColor: "black"
                SequentialAnimation on opacity {
                    running: _oilLow; loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 400 }
                    NumberAnimation { to: 1.0; duration: 400 }
                }
            }
        }

        // Fuel low
        Rectangle {
            width: _fontSize * 14; height: _fontSize * 1.6; radius: 4
            color: "#88ff8800"
            visible: _fuelLow
            Text {
                anchors.centerIn: parent
                text: "FUEL LOW"
                color: "white"; font.bold: true; font.pixelSize: _fontSize; font.family: "monospace"
                style: Text.Outline; styleColor: "black"
                SequentialAnimation on opacity {
                    running: _fuelLow; loops: Animation.Infinite
                    NumberAnimation { to: 0.4; duration: 500 }
                    NumberAnimation { to: 1.0; duration: 500 }
                }
            }
        }
    }
}
