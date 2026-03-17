message(STATUS "AGCS: Loading custom overrides")

set(QGC_APP_NAME "AGCS" CACHE STRING "App Name" FORCE)

# Ícone Windows (tray, taskbar, title bar)
if(EXISTS ${CMAKE_SOURCE_DIR}/custom/deploy/windows/AGCS.ico)
    set(QGC_WINDOWS_ICON_PATH "${CMAKE_SOURCE_DIR}/custom/deploy/windows/AGCS.ico" CACHE FILEPATH "Windows Icon Path" FORCE)
    set(QGC_WINDOWS_RESOURCE_FILE_PATH "${CMAKE_SOURCE_DIR}/custom/deploy/windows/AGCS.rc" CACHE FILEPATH "Windows Resource File Path" FORCE)
endif()

# IMPORTANTE: NÃO desabilitar APM — o AGH 3000 usa ArduPlane
set(QGC_ENABLE_GST_VIDEOSTREAMING OFF CACHE BOOL "Disable GStreamer" FORCE)
set(QGC_ENABLE_QT_VIDEOSTREAMING ON CACHE BOOL "Enable QtMultimedia video streaming" FORCE)
