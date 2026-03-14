message(STATUS "QGC: Adding Agrohawk GCS Custom Plugin")

# ---------------------------------------------------------------------------
# Habilitar custom build via preprocessor
# ---------------------------------------------------------------------------
set_property(DIRECTORY ${CMAKE_SOURCE_DIR}
    APPEND PROPERTY COMPILE_DEFINITIONS
    QGC_CUSTOM_BUILD
    CUSTOMHEADER="AgrohawkPlugin.h"
    CUSTOMCLASS=AgrohawkPlugin
)

# ---------------------------------------------------------------------------
# Recursos customizados (QRC)
# ---------------------------------------------------------------------------
list(APPEND CUSTOM_RESOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/custom.qrc
)
set(QGC_RESOURCES ${QGC_RESOURCES} ${CUSTOM_RESOURCES} CACHE STRING "Paths to .qrc Resources" FORCE)

# ---------------------------------------------------------------------------
# Fontes C++ — exportadas via CACHE INTERNAL para o root CMakeLists.txt
# ---------------------------------------------------------------------------
set(CUSTOM_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/AgrohawkPlugin.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/src/AgrohawkPlugin.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/AgrohawkSprayerTelemetry.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/src/AgrohawkSprayerTelemetry.h
    CACHE INTERNAL "" FORCE
)

set(CUSTOM_LIBRARIES
    CACHE INTERNAL "" FORCE
)

set(CUSTOM_INCLUDE_DIRECTORIES
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    CACHE INTERNAL "" FORCE
)
