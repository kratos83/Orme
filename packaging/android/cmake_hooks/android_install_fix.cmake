# Hook incluso via CMAKE_PROJECT_INCLUDE (vedi packaging/android/build.sh).
#
# Il CMakeLists.txt della root del repo (che non va toccato) contiene:
#
#   install(TARGETS giochi
#       BUNDLE  DESTINATION .
#       RUNTIME DESTINATION bin
#   )
#
# Su desktop "giochi" e' un vero eseguibile (RUNTIME/BUNDLE), ma su Android
# qt_add_executable() crea in realta' una libreria MODULE (il .so caricato
# dalla Activity Java), per cui CMake pretende anche una LIBRARY DESTINATION,
# altrimenti l'install() fallisce con:
#   "install TARGETS given no LIBRARY DESTINATION for module target"
#
# Non serve comunque eseguire "cmake --install" per generare l'APK
# (androiddeployqt lavora direttamente sugli artefatti di build), quindi qui
# ci limitiamo a intercettare install() e ad aggiungere una LIBRARY
# DESTINATION di comodo quando manca, cosi' la configurazione non fallisce.
if(ANDROID AND NOT COMMAND _android_install_fix_applied)
    function(install)
        set(_args ${ARGN})
        list(FIND _args "TARGETS" _targets_idx)
        list(FIND _args "LIBRARY" _library_idx)
        if(_targets_idx GREATER -1 AND _library_idx EQUAL -1)
            list(APPEND _args LIBRARY DESTINATION lib)
        endif()
        _install(${_args})
    endfunction()
    function(_android_install_fix_applied)
    endfunction()
endif()

# Applica QT_ANDROID_PACKAGE_SOURCE_DIR (per il nostro AndroidManifest.xml
# personalizzato, es. android:label="Orme") senza toccare il CMakeLists.txt
# della root: la property va impostata sul target dopo che questo e' stato
# creato da qt_add_executable(), quindi la rimandiamo con cmake_language(DEFER)
# a dopo che l'intero CMakeLists.txt della root e' stato processato.
#
# NB: il manifest vive in packaging/android/android-package/ e NON
# direttamente in packaging/android/, perche' quest'ultima e' anche la
# directory in cui viene creata la build-dir (packaging/android/build-android):
# se QT_ANDROID_PACKAGE_SOURCE_DIR puntasse a packaging/android,
# androiddeployqt copierebbe ricorsivamente anche la build-dir dentro se'
# stessa (loop infinito di copia).
if(ANDROID)
    get_filename_component(_giochi_android_package_source_dir "${CMAKE_CURRENT_LIST_DIR}/../android-package" ABSOLUTE)
    cmake_language(DEFER DIRECTORY "${CMAKE_SOURCE_DIR}" CALL
        _giochi_apply_android_package_source_dir "${_giochi_android_package_source_dir}")
endif()

function(_giochi_apply_android_package_source_dir dir)
    if(TARGET Orme)
        set_target_properties(Orme PROPERTIES QT_ANDROID_PACKAGE_SOURCE_DIR "${dir}")
        message(STATUS "Orme: QT_ANDROID_PACKAGE_SOURCE_DIR impostata su ${dir}")
    endif()
endfunction()
