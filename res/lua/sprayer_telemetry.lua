-- =============================================================================
-- sprayer_telemetry.lua
-- Script Lua para Pixhawk 6X Pro (ArduPlane)
-- Envia telemetria do pulverizador + motor via NAMED_VALUE_FLOAT
-- Copiar para: APM/scripts/ no cartão SD da Pixhawk
-- =============================================================================

-- Intervalo de envio em milissegundos
local SEND_INTERVAL_MS = 200

-- ═══════════════════════════════════════════════════════════════
-- PINOS ADC (ajuste conforme sua fiação)
-- ═══════════════════════════════════════════════════════════════
-- Pulverizador
local TANK_LEVEL_ANALOG_PIN    = 14   -- sensor de nível do tanque spray
local PUMP_PRESSURE_ANALOG_PIN = 15   -- sensor de pressão da bomba
local FLOW_RATE_ANALOG_PIN     = 16   -- sensor de fluxo

-- Motor
local FUEL_LEVEL_ANALOG_PIN    = 17   -- sensor de nível combustível
local OIL_PRESSURE_ANALOG_PIN  = 18   -- sensor de pressão do óleo

-- ═══════════════════════════════════════════════════════════════
-- CALIBRAÇÃO PULVERIZADOR
-- ═══════════════════════════════════════════════════════════════
local TANK_VOLTAGE_MIN = 0.5   -- V @ tanque vazio
local TANK_VOLTAGE_MAX = 4.5   -- V @ tanque cheio (400L)
local TANK_CAPACITY    = 400.0 -- litros

local PRESSURE_VOLTAGE_MIN = 0.5  -- V @ 0 bar
local PRESSURE_VOLTAGE_MAX = 4.5  -- V @ 10 bar
local PRESSURE_MAX         = 10.0 -- bar

local FLOW_VOLTAGE_MIN = 0.0     -- V @ 0 L/min
local FLOW_VOLTAGE_MAX = 4.5     -- V @ 20 L/min
local FLOW_MAX         = 20.0    -- L/min

-- ═══════════════════════════════════════════════════════════════
-- CALIBRAÇÃO MOTOR
-- ═══════════════════════════════════════════════════════════════
local FUEL_VOLTAGE_MIN = 0.5    -- V @ tanque vazio
local FUEL_VOLTAGE_MAX = 4.5    -- V @ tanque cheio (80L)
local FUEL_CAPACITY    = 80.0   -- litros

local OIL_VOLTAGE_MIN  = 0.5   -- V @ 0 bar
local OIL_VOLTAGE_MAX  = 4.5   -- V @ 8 bar
local OIL_PRESSURE_MAX = 8.0   -- bar

-- Função auxiliar: mapear voltage para valor calibrado
local function map_voltage(voltage, v_min, v_max, out_min, out_max)
    local clamped = math.max(v_min, math.min(v_max, voltage))
    return out_min + (clamped - v_min) / (v_max - v_min) * (out_max - out_min)
end

function update()
    -- ── Pulverizador ──
    local tank_voltage  = analogin:voltage(TANK_LEVEL_ANALOG_PIN) or 0
    local press_voltage = analogin:voltage(PUMP_PRESSURE_ANALOG_PIN) or 0
    local flow_voltage  = analogin:voltage(FLOW_RATE_ANALOG_PIN) or 0

    local tank_level    = map_voltage(tank_voltage, TANK_VOLTAGE_MIN, TANK_VOLTAGE_MAX, 0, TANK_CAPACITY)
    local pump_pressure = map_voltage(press_voltage, PRESSURE_VOLTAGE_MIN, PRESSURE_VOLTAGE_MAX, 0, PRESSURE_MAX)
    local flow_rate     = map_voltage(flow_voltage, FLOW_VOLTAGE_MIN, FLOW_VOLTAGE_MAX, 0, FLOW_MAX)

    gcs:send_named_float("SPRAY_TNK", tank_level)
    gcs:send_named_float("SPRAY_PSI", pump_pressure)
    gcs:send_named_float("SPRAY_FLW", flow_rate)

    -- ── Motor ──
    local fuel_voltage = analogin:voltage(FUEL_LEVEL_ANALOG_PIN) or 0
    local oil_voltage  = analogin:voltage(OIL_PRESSURE_ANALOG_PIN) or 0

    local fuel_level   = map_voltage(fuel_voltage, FUEL_VOLTAGE_MIN, FUEL_VOLTAGE_MAX, 0, FUEL_CAPACITY)
    local oil_pressure = map_voltage(oil_voltage, OIL_VOLTAGE_MIN, OIL_VOLTAGE_MAX, 0, OIL_PRESSURE_MAX)

    gcs:send_named_float("ENG_FUEL", fuel_level)
    gcs:send_named_float("ENG_OIL",  oil_pressure)

    return update, SEND_INTERVAL_MS
end

return update, SEND_INTERVAL_MS
