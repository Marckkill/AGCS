# AGCS — Agrohawk Ground Control Station

Custom build of [QGroundControl](https://github.com/mavlink/qgroundcontrol) (v5.0) tailored for the **AGH 3000** fixed-wing agricultural sprayer.

## Aircraft — AGH 3000

| Spec | Value |
|------|-------|
| Type | Fixed-wing crop sprayer (ArduPlane) |
| MTOW | 420 kg |
| Engine | ICE 100 hp |
| Spray tank | 400 L |
| Fuel tank | 80 L |
| Flight controller | Pixhawk 6X Pro |
| Datalink | XBLink (long range) |
| Backup control | HOTAS via vJoy |

## Features

### Branding
- Custom green + orange color palette
- Agrohawk logo and icons throughout the UI
- App name: **AGCS**

### Fixed-Wing Focused
- Orbit and ROI guidance hidden (irrelevant for fixed-wing)
- Multi-vehicle list hidden (single aircraft ops)
- Airspeed calibration enabled
- Default offline editing set to ArduPilot + FixedWing

### ICE Engine Telemetry
Real-time engine instrumentation via `EFI_STATUS` (MAVLink msg 225) and `NAMED_VALUE_FLOAT` (msg 251):
- **RPM** — tachometer with bar gauge (max 8000)
- **Fuel level** — tank percentage with low-fuel alert (<15%)
- **Throttle** — position percentage
- **Oil pressure** — bar gauge with low-pressure alert (<1.5 bar)
- **Engine temperature** — CHT with over-temp alert (>240°C)

### Sprayer Telemetry
Real-time spray system data via `NAMED_VALUE_FLOAT` (MAVLink msg 251):
- **Tank level** — 0-400 L with percentage and low-tank alert (<10%)
- **Pump pressure** — 0-10 bar with high-pressure warning
- **Flow rate** — L/min display
- **Pump status** — ON/OFF indicator

### Pop-out Telemetry Window
- Click the compact widget to open a full telemetry window
- Detachable — drag to a second monitor
- Native OS window with minimize/maximize/close buttons

## Architecture

```
custom/
├── cmake/
│   └── CustomOverrides.cmake      # App name, icon, GStreamer config
├── deploy/
│   └── windows/
│       ├── AGCS.ico               # Windows icon (multi-size)
│       └── AGCS.rc                # Windows resource file
├── res/
│   ├── images/
│   │   ├── icon.png               # App icon source
│   │   ├── logo.svg               # Agrohawk logo
│   │   └── name.svg               # Agrohawk name wordmark
│   └── lua/
│       └── sprayer_telemetry.lua   # Pixhawk Lua script
├── src/
│   ├── AgrohawkPlugin.h/cc        # QGCCorePlugin subclass
│   ├── AgrohawkSprayerTelemetry.h/cc  # NAMED_VALUE_FLOAT handler
│   └── FlyViewCustomLayer.qml     # Fly view overlay + pop-out window
├── CMakeLists.txt                 # Build config
└── custom.qrc                     # Qt resources
```

### MAVLink Messages

| Message | ID | Source | Data |
|---------|----|--------|------|
| `EFI_STATUS` | 225 | Native QGC | RPM, CHT, throttle, fuel flow |
| `NAMED_VALUE_FLOAT` | 251 | Lua script | `SPRAY_TNK`, `SPRAY_PSI`, `SPRAY_FLW`, `ENG_FUEL`, `ENG_OIL` |

## Build

### Requirements
- Qt 6.8.3 (MSVC 2022)
- Visual Studio 2022 Build Tools
- CMake 3.22+

### Steps

```bash
# 1. Clone QGC
git clone --recursive -b Stable_V5.0 https://github.com/mavlink/qgroundcontrol.git qgc

# 2. Copy custom/ into qgc/
cp -r custom/ qgc/custom/

# 3. Configure
cmake -S qgc -B qgc/build -G "Visual Studio 17 2022" -A x64 \
  -DCMAKE_PREFIX_PATH="C:/Qt/6.8.3/msvc2022_64"

# 4. Build
cmake --build qgc/build --config Release

# 5. Deploy Qt DLLs
windeployqt qgc/build/Release/AGCS.exe --qmldir qgc/src
```

## Pixhawk Lua Script

Copy `res/lua/sprayer_telemetry.lua` to the Pixhawk SD card at `APM/scripts/`.

The script reads analog sensors and sends telemetry at 5 Hz:

| Variable | ADC Pin | Range | Description |
|----------|---------|-------|-------------|
| `SPRAY_TNK` | 14 | 0-400 L | Spray tank level |
| `SPRAY_PSI` | 15 | 0-10 bar | Pump pressure |
| `SPRAY_FLW` | 16 | 0-20 L/min | Flow rate |
| `ENG_FUEL` | 17 | 0-80 L | Fuel tank level |
| `ENG_OIL` | 18 | 0-8 bar | Oil pressure |

Adjust ADC pin numbers and calibration values in the script to match your hardware.

## Testing

### With SITL + X-Plane 12
1. Run ArduPlane SITL with `--model xplane`
2. Connect X-Plane 12 via UDP
3. Open AGCS — it auto-connects on UDP 14550

### With Mock Link
1. Open AGCS
2. Go to Application Settings → Mock Link → Create ArduPilot FixedWing

## License

Based on QGroundControl, licensed under Apache 2.0.

---

**Agrohawk** — Agricultural drone technology
