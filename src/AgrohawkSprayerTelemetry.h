#pragma once

#include <QObject>
#include <QString>
#include "MAVLinkLib.h"

class AgrohawkSprayerTelemetry : public QObject
{
    Q_OBJECT

    // --- Sprayer ---
    Q_PROPERTY(double tankLevel    READ tankLevel    NOTIFY dataUpdated)
    Q_PROPERTY(double tankPercent  READ tankPercent   NOTIFY dataUpdated)
    Q_PROPERTY(double pumpPressure READ pumpPressure NOTIFY dataUpdated)
    Q_PROPERTY(double flowRate     READ flowRate     NOTIFY dataUpdated)
    Q_PROPERTY(bool   pumpActive   READ pumpActive   NOTIFY dataUpdated)
    Q_PROPERTY(bool   tankLow      READ tankLow      NOTIFY dataUpdated)
    Q_PROPERTY(bool   dataValid    READ dataValid    NOTIFY dataUpdated)

    // --- Engine extras (via NAMED_VALUE_FLOAT) ---
    Q_PROPERTY(double fuelLevel    READ fuelLevel    NOTIFY dataUpdated)
    Q_PROPERTY(double fuelPercent  READ fuelPercent  NOTIFY dataUpdated)
    Q_PROPERTY(double oilPressure  READ oilPressure  NOTIFY dataUpdated)
    Q_PROPERTY(bool   oilLow      READ oilLow       NOTIFY dataUpdated)
    Q_PROPERTY(bool   fuelLow     READ fuelLow      NOTIFY dataUpdated)
    Q_PROPERTY(bool   engineDataValid READ engineDataValid NOTIFY dataUpdated)

public:
    explicit AgrohawkSprayerTelemetry(QObject* parent = nullptr);

    // Sprayer getters
    double tankLevel()    const { return _tankLevel; }
    double tankPercent()  const { return (_tankCapacity > 0) ? (_tankLevel / _tankCapacity) * 100.0 : 0.0; }
    double pumpPressure() const { return _pumpPressure; }
    double flowRate()     const { return _flowRate; }
    bool   pumpActive()   const { return _pumpPressure > 0.5; }
    bool   tankLow()      const { return _tankLevel < (_tankCapacity * 0.10); }
    bool   dataValid()    const { return _dataValid; }

    // Engine extras getters
    double fuelLevel()      const { return _fuelLevel; }
    double fuelPercent()    const { return (_fuelCapacity > 0) ? (_fuelLevel / _fuelCapacity) * 100.0 : 0.0; }
    double oilPressure()    const { return _oilPressure; }
    bool   oilLow()         const { return _engineDataValid && _oilPressure < 1.5; }
    bool   fuelLow()        const { return _engineDataValid && _fuelLevel < (_fuelCapacity * 0.15); }
    bool   engineDataValid() const { return _engineDataValid; }

    Q_INVOKABLE void setTankCapacity(double liters) { _tankCapacity = liters; }
    Q_INVOKABLE void setFuelCapacity(double liters) { _fuelCapacity = liters; }

    void handleMavlinkMessage(const mavlink_message_t& message);

signals:
    void dataUpdated();

private:
    // Sprayer
    double _tankLevel    = 0.0;
    double _pumpPressure = 0.0;
    double _flowRate     = 0.0;
    double _tankCapacity = 400.0;
    bool   _dataValid    = false;

    // Engine extras
    double _fuelLevel    = 0.0;
    double _oilPressure  = 0.0;
    double _fuelCapacity = 80.0;   // 80L tanque de combustível padrão
    bool   _engineDataValid = false;

    // NAMED_VALUE_FLOAT names (max 10 chars)
    static constexpr const char* TANK_LEVEL_NAME    = "SPRAY_TNK";
    static constexpr const char* PUMP_PRESSURE_NAME = "SPRAY_PSI";
    static constexpr const char* FLOW_RATE_NAME     = "SPRAY_FLW";
    static constexpr const char* FUEL_LEVEL_NAME    = "ENG_FUEL";
    static constexpr const char* OIL_PRESSURE_NAME  = "ENG_OIL";
};
