message(STATUS "AGCS: Loading custom overrides")

set(QGC_APP_NAME "AGCS" CACHE STRING "App Name" FORCE)

# Ícone Windows (tray, taskbar, title bar)
if(EXISTS ${CMAKE_SOURCE_DIR}/custom/deploy/windows/AGCS.ico)
    set(QGC_WINDOWS_ICON_PATH "${CMAKE_SOURCE_DIR}/custom/deploy/windows/AGCS.ico" CACHE FILEPATH "Windows Icon Path" FORCE)
    set(QGC_WINDOWS_RESOURCE_FILE_PATH "${CMAKE_SOURCE_DIR}/custom/deploy/windows/AGCS.rc" CACHE FILEPATH "Windows Resource File Path" FORCE)
endif()

# IMPORTANTE: NÃO desabilitar APM — o AGH 3000 usa ArduPlane
# GStreamer only — QtMultimedia disabled due to QVideoFrame::unmap crash (Qt 6.8.3 bug)
# UVC cameras work via GStreamer plugin mfvideosrc (same as official QGC)
set(QGC_ENABLE_GST_VIDEOSTREAMING ON CACHE BOOL "Enable GStreamer video streaming" FORCE)
set(QGC_ENABLE_QT_VIDEOSTREAMING OFF CACHE BOOL "Disabled — Qt 6.8.3 crash bug" FORCE)
