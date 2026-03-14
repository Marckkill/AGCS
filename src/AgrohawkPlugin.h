#pragma once

#include <QtQml/QQmlAbstractUrlInterceptor>

#include "QGCCorePlugin.h"
#include "QGCOptions.h"

class AgrohawkOptions;
class AgrohawkSprayerTelemetry;
class QQmlApplicationEngine;

Q_DECLARE_LOGGING_CATEGORY(AgrohawkLog)

// ---------------------------------------------------------------------------
// FlyView options — controla visibilidade de elementos no Fly View
// ---------------------------------------------------------------------------
class AgrohawkFlyViewOptions : public QGCFlyViewOptions
{
public:
    AgrohawkFlyViewOptions(AgrohawkOptions* options, QObject* parent = nullptr);

    bool showMultiVehicleList() const final { return false; }
    bool showInstrumentPanel()  const final { return true;  }
    bool guidedBarShowOrbit()   const final { return false; }
    bool guidedBarShowROI()     const final { return false; }
};

// ---------------------------------------------------------------------------
// Options — toggles de UI globais
// ---------------------------------------------------------------------------
class AgrohawkOptions : public QGCOptions
{
public:
    AgrohawkOptions(QGCCorePlugin* plugin, QObject* parent = nullptr);

    bool wifiReliableForCalibration()    const final { return true;  }
    bool showFirmwareUpgrade()           const final;
    bool showOfflineMapExport()          const final { return true;  }
    bool showSensorCalibrationAirspeed() const final { return true;  }
    QGCFlyViewOptions* flyViewOptions()  const final;

private:
    QGCCorePlugin*          _plugin = nullptr;
    AgrohawkFlyViewOptions* _flyViewOptions = nullptr;
};

// ---------------------------------------------------------------------------
// Plugin principal — singleton via Q_APPLICATION_STATIC
// ---------------------------------------------------------------------------
class AgrohawkPlugin : public QGCCorePlugin
{
    Q_OBJECT

public:
    explicit AgrohawkPlugin(QObject* parent = nullptr);
    ~AgrohawkPlugin();

    static QGCCorePlugin* instance();

    // Overrides from QGCCorePlugin
    void                    init() final;
    void                    cleanup() final;
    QGCOptions*             options() final;
    QString                 brandImageIndoor() const final;
    QString                 brandImageOutdoor() const final;
    bool                    overrideSettingsGroupVisibility(const QString& name) final;
    bool                    adjustSettingMetaData(const QString& settingsGroup, FactMetaData& metaData) final;
    void                    paletteOverride(const QString& colorName, QGCPalette::PaletteColorInfo_t& colorInfo) final;
    QQmlApplicationEngine*  createQmlApplicationEngine(QObject* parent) final;
    QList<int>              firstRunPromptStdIds() final;

    // Interceptação de mensagens MAVLink — usado para NAMED_VALUE_FLOAT (sprayer)
    bool mavlinkMessage(Vehicle* vehicle, LinkInterface* link, const mavlink_message_t& message) final;

private:
    AgrohawkOptions*            _options   = nullptr;
    AgrohawkSprayerTelemetry*   _sprayer   = nullptr;
    QQmlApplicationEngine*      _qmlEngine = nullptr;
    class AgrohawkOverrideInterceptor* _selector = nullptr;
};

// ---------------------------------------------------------------------------
// URL interceptor — redireciona QML/resources para versões customizadas
// ---------------------------------------------------------------------------
class AgrohawkOverrideInterceptor : public QQmlAbstractUrlInterceptor
{
public:
    AgrohawkOverrideInterceptor();
    QUrl intercept(const QUrl& url, QQmlAbstractUrlInterceptor::DataType type) final;
};
