# Hook incluso via CMAKE_PROJECT_INCLUDE (vedi packaging/android/build.sh).
#
# Il fix per "install TARGETS given no LIBRARY DESTINATION for module
# target" vive direttamente in CMakeLists.txt (blocco if(ANDROID) prima di
# install(TARGETS Orme ...)), non qui: le sotto-build automatiche innescate
# da QT_ANDROID_BUILD_ALL_ABIS=ON (una per ogni ABI extra, es. armeabi-v7a)
# non ereditano CMAKE_PROJECT_INCLUDE, quindi un hook esterno non basta a
# coprirle - deve stare nel CMakeLists.txt stesso.

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
