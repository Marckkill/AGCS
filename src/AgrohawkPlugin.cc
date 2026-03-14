#include "AgrohawkPlugin.h"
#include "AgrohawkSprayerTelemetry.h"
#include "QGCLoggingCategory.h"
#include "QGCPalette.h"
#include "QGCMAVLink.h"
#include "AppSettings.h"
#include "BrandImageSettings.h"
#include "Vehicle.h"

#if QT_VERSION >= QT_VERSION_CHECK(6, 8, 0)
#include <QtCore/QApplicationStatic>
#endif
#include <QtQml/QQmlApplicationEngine>
#include <QtQml/QQmlFile>
#include <QtQml/QQmlContext>

QGC_LOGGING_CATEGORY(AgrohawkLog, "gcs.agrohawk.plugin")

Q_APPLICATION_STATIC(AgrohawkPlugin, _agrohawkPluginInstance);

// ===========================================================================
// FlyView Options
// ===========================================================================
AgrohawkFlyViewOptions::AgrohawkFlyViewOptions(AgrohawkOptions* options, QObject* parent)
    : QGCFlyViewOptions(options, parent)
{
}

// ===========================================================================
// Options
// ===========================================================================
AgrohawkOptions::AgrohawkOptions(QGCCorePlugin* plugin, QObject* parent)
    : QGCOptions(parent)
    , _plugin(plugin)
    , _flyViewOptions(new AgrohawkFlyViewOptions(this, this))
{
}

bool AgrohawkOptions::showFirmwareUpgrade() const
{
    return _plugin->showAdvancedUI();
}

QGCFlyViewOptions* AgrohawkOptions::flyViewOptions() const
{
    return _flyViewOptions;
}

// ===========================================================================
// Plugin
// ===========================================================================
AgrohawkPlugin::AgrohawkPlugin(QObject* parent)
    : QGCCorePlugin(parent)
    , _options(new AgrohawkOptions(this, this))
    , _sprayer(new AgrohawkSprayerTelemetry(this))
{
    _showAdvancedUI = false;
}

AgrohawkPlugin::~AgrohawkPlugin()
{
}

QGCCorePlugin* AgrohawkPlugin::instance()
{
    return _agrohawkPluginInstance();
}

void AgrohawkPlugin::init()
{
}

void AgrohawkPlugin::cleanup()
{
    if (_qmlEngine) {
        _qmlEngine->removeUrlInterceptor(_selector);
    }
    delete _selector;
}

// ---------------------------------------------------------------------------
// Options
// ---------------------------------------------------------------------------
QGCOptions* AgrohawkPlugin::options()
{
    return _options;
}

// ---------------------------------------------------------------------------
// Branding
// ---------------------------------------------------------------------------
QString AgrohawkPlugin::brandImageIndoor() const
{
    return QStringLiteral("/custom/img/agrohawk_name.svg");
}

QString AgrohawkPlugin::brandImageOutdoor() const
{
    return QStringLiteral("/custom/img/agrohawk_name.svg");
}

// ---------------------------------------------------------------------------
// Settings — ocultar brand image settings (branding é fixo)
// ---------------------------------------------------------------------------
bool AgrohawkPlugin::overrideSettingsGroupVisibility(const QString& name)
{
    if (name == BrandImageSettings::name) {
        return false;
    }
    return true;
}

// ---------------------------------------------------------------------------
// Defaults para edição offline — ArduPlane + Fixed-Wing
// ---------------------------------------------------------------------------
bool AgrohawkPlugin::adjustSettingMetaData(const QString& settingsGroup, FactMetaData& metaData)
{
    bool parentResult = QGCCorePlugin::adjustSettingMetaData(settingsGroup, metaData);

    if (settingsGroup == AppSettings::settingsGroup) {
        if (metaData.name() == AppSettings::offlineEditingFirmwareClassName) {
            metaData.setRawDefaultValue(QGCMAVLink::FirmwareClassArduPilot);
            return false;
        } else if (metaData.name() == AppSettings::offlineEditingVehicleClassName) {
            metaData.setRawDefaultValue(QGCMAVLink::VehicleClassFixedWing);
            return false;
        }
    }

    return parentResult;
}

// ---------------------------------------------------------------------------
// First-run prompts — desativados
// ---------------------------------------------------------------------------
QList<int> AgrohawkPlugin::firstRunPromptStdIds()
{
    return QList<int>();
}

// ---------------------------------------------------------------------------
// Interceptação MAVLink — processa NAMED_VALUE_FLOAT para o sprayer
// ---------------------------------------------------------------------------
bool AgrohawkPlugin::mavlinkMessage(Vehicle* vehicle, LinkInterface* link, const mavlink_message_t& message)
{
    Q_UNUSED(vehicle);
    Q_UNUSED(link);

    _sprayer->handleMavlinkMessage(message);

    return true; // continua processamento normal
}

// ---------------------------------------------------------------------------
// Paleta de cores — verde escuro + laranja Agrohawk (#f26d30)
// ---------------------------------------------------------------------------
void AgrohawkPlugin::paletteOverride(const QString& colorName, QGCPalette::PaletteColorInfo_t& colorInfo)
{
    // --- Fundos: verde escuro ---
    if (colorName == QStringLiteral("window")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled]   = QColor("#0d1a0d");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled]  = QColor("#0d1a0d");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled]  = QColor("#e8f0e8");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#dde5dd");
    }
    else if (colorName == QStringLiteral("windowShade")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled]   = QColor("#142814");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled]  = QColor("#142814");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled]  = QColor("#d5e0d5");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#c8d4c8");
    }
    else if (colorName == QStringLiteral("windowShadeDark")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled]   = QColor("#091209");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled]  = QColor("#091209");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled]  = QColor("#c0cec0");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#b0beb0");
    }
    else if (colorName == QStringLiteral("text")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled]   = QColor("#e8f0e8");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled]  = QColor("#5a6b5a");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled]  = QColor("#0d1a0d");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#8a9a8a");
    }
    // --- Botões e destaques: laranja ---
    else if (colorName == QStringLiteral("primaryButton")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled]   = QColor("#f26d30");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled]  = QColor("#3a2a1a");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled]  = QColor("#f26d30");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#585858");
    }
    else if (colorName == QStringLiteral("primaryButtonText")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled]   = QColor("#ffffff");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled]  = QColor("#ffffff");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled]  = QColor("#ffffff");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#cad0d0");
    }
    else if (colorName == QStringLiteral("buttonHighlight")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled]   = QColor("#f5873d");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled]  = QColor("#3a2a1a");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled]  = QColor("#fdb386");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#d0d0d0");
    }
    // --- Toolbar: verde escuro ---
    else if (colorName == QStringLiteral("toolbarBackground")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled]   = QColor("#0d1a0d");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled]  = QColor("#0d1a0d");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled]  = QColor("#1a3a1a");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#1a3a1a");
    }
    // --- Branding: laranja substitui roxo ---
    else if (colorName == QStringLiteral("brandingPurple")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled]   = QColor("#1a3a1a");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled]  = QColor("#142814");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled]  = QColor("#1a3a1a");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#142814");
    }
    else if (colorName == QStringLiteral("brandingBlue")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled]   = QColor("#f26d30");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled]  = QColor("#c45a28");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled]  = QColor("#f26d30");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#c45a28");
    }
    else if (colorName == QStringLiteral("colorOrange")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled]   = QColor("#f26d30");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled]  = QColor("#c45a28");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled]  = QColor("#f26d30");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#c45a28");
    }
    // --- Campos de texto: verde suave ---
    else if (colorName == QStringLiteral("button")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled]   = QColor("#1a3a1a");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled]  = QColor("#142814");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled]  = QColor("#d5e0d5");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#c0c0c0");
    }
    else if (colorName == QStringLiteral("mapButton")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled]   = QColor("#1a3a1a");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled]  = QColor("#142814");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled]  = QColor("#1a3a1a");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#142814");
    }
    else if (colorName == QStringLiteral("mapButtonHighlight")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled]   = QColor("#f26d30");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled]  = QColor("#c45a28");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled]  = QColor("#f26d30");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#c45a28");
    }
    else if (colorName == QStringLiteral("mapIndicator")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled]   = QColor("#f26d30");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled]  = QColor("#c45a28");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled]  = QColor("#f26d30");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#c45a28");
    }
    else if (colorName == QStringLiteral("groupBorder")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled]   = QColor("#2a4a2a");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled]  = QColor("#1a3a1a");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled]  = QColor("#a0b8a0");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#b0c0b0");
    }
}

// ---------------------------------------------------------------------------
// QML Engine — configura interceptor de URLs para resource overrides
// ---------------------------------------------------------------------------
QQmlApplicationEngine* AgrohawkPlugin::createQmlApplicationEngine(QObject* parent)
{
    _qmlEngine = QGCCorePlugin::createQmlApplicationEngine(parent);

    // Registrar sprayer como context property global para uso no QML
    _qmlEngine->rootContext()->setContextProperty("agrohawkSprayer", _sprayer);

    // Instalar o interceptor que redireciona QML para versões em /Custom/
    _selector = new AgrohawkOverrideInterceptor();
    _qmlEngine->addUrlInterceptor(_selector);

    return _qmlEngine;
}

// ===========================================================================
// URL Override Interceptor
// ===========================================================================
AgrohawkOverrideInterceptor::AgrohawkOverrideInterceptor()
    : QQmlAbstractUrlInterceptor()
{
}

QUrl AgrohawkOverrideInterceptor::intercept(const QUrl& url, QQmlAbstractUrlInterceptor::DataType type)
{
    switch (type) {
    using DataType = QQmlAbstractUrlInterceptor::DataType;
    case DataType::QmlFile:
    case DataType::UrlString:
        if (url.scheme() == QStringLiteral("qrc")) {
            const QString origPath = url.path();
            const QString overrideRes = QStringLiteral(":/Custom%1").arg(origPath);
            if (QFile::exists(overrideRes)) {
                const QString relPath = overrideRes.mid(2);
                QUrl result;
                result.setScheme(QStringLiteral("qrc"));
                result.setPath('/' + relPath);
                return result;
            }
        }
        break;
    default:
        break;
    }
    return url;
}
