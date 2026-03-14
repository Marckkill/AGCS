#include "AgrohawkSprayerTelemetry.h"
#include <cstring>

AgrohawkSprayerTelemetry::AgrohawkSprayerTelemetry(QObject* parent)
    : QObject(parent)
{
}

void AgrohawkSprayerTelemetry::handleMavlinkMessage(const mavlink_message_t& message)
{
    if (message.msgid != MAVLINK_MSG_ID_NAMED_VALUE_FLOAT) {
        return;
    }

    mavlink_named_value_float_t named;
    mavlink_msg_named_value_float_decode(&message, &named);

    // named.name é char[10], pode não ter null-terminator
    char safeName[11];
    std::memcpy(safeName, named.name, 10);
    safeName[10] = '\0';

    QString name = QString::fromLatin1(safeName).trimmed();

    // --- Sprayer values ---
    if (name == QLatin1String(TANK_LEVEL_NAME)) {
        _tankLevel = static_cast<double>(named.value);
        _dataValid = true;
        emit dataUpdated();
    }
    else if (name == QLatin1String(PUMP_PRESSURE_NAME)) {
        _pumpPressure = static_cast<double>(named.value);
        _dataValid = true;
        emit dataUpdated();
    }
    else if (name == QLatin1String(FLOW_RATE_NAME)) {
        _flowRate = static_cast<double>(named.value);
        _dataValid = true;
        emit dataUpdated();
    }
    // --- Engine extras ---
    else if (name == QLatin1String(FUEL_LEVEL_NAME)) {
        _fuelLevel = static_cast<double>(named.value);
        _engineDataValid = true;
        emit dataUpdated();
    }
    else if (name == QLatin1String(OIL_PRESSURE_NAME)) {
        _oilPressure = static_cast<double>(named.value);
        _engineDataValid = true;
        emit dataUpdated();
    }
}
