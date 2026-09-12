cmake_minimum_required(VERSION 3.21)

project(Orme VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick Qml)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(Orme
    src/main.cpp
)

# I singleton QML vanno marcati PRIMA di qt_add_qml_module
set_source_files_properties(qml/Theme.qml   PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
set_source_files_properties(qml/Catalog.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(Orme
    URI Giochi
    VERSION 1.0
    SOURCES
        src/pathengine.h
        src/pathengine.cpp
    QML_FILES
        qml/Main.qml
        qml/Theme.qml
        qml/Catalog.qml
        qml/Launcher.qml
        qml/InfoPage.qml
        qml/GameTile.qml
        qml/common/SoundBank.qml
        qml/common/ScoreBar.qml
        qml/common/NamePrompt.qml
        qml/common/GameScaffold.qml
        qml/common/MiniGame.qml
        qml/games/path/PathGame.qml
        qml/games/path/Board.qml
        qml/games/path/Character.qml
        qml/games/path/Goal.qml
        qml/games/path/Rock.qml
        qml/games/path/Arrow.qml
        qml/games/path/CommandStrip.qml
        qml/games/path/DirectionPad.qml
        qml/games/path/Celebration.qml
        qml/games/path/TryAgainBanner.qml
        qml/games/loop/LoopGame.qml
        qml/games/rhythm/RhythmGame.qml
        qml/games/sort/SortGame.qml
        qml/games/sequence/SequenceGame.qml
        qml/games/draw/DrawGame.qml
        qml/games/catch/CatchGame.qml
        qml/games/count/CountGame.qml
        qml/games/color/ColorGame.qml
        qml/games/odd/OddGame.qml
        qml/games/pairs/PairsGame.qml
        qml/games/size/SizeGame.qml
        qml/games/bubbles/BubblesGame.qml
        qml/games/dots/DotsGame.qml
        qml/games/wake/WakeGame.qml
        qml/games/cups/CupsGame.qml
        qml/games/puzzle/PuzzleGame.qml
        qml/games/harvest/HarvestGame.qml
        qml/games/balloons/BalloonsGame.qml
        qml/games/reveal/RevealGame.qml
    RESOURCES
        assets/sounds/tap.wav
        assets/sounds/step.wav
        assets/sounds/win.wav
        assets/sounds/bump.wav
)

target_include_directories(Orme PRIVATE src)

target_link_libraries(Orme PRIVATE Qt6::Quick Qt6::Qml)

if(WIN32)
    target_sources(Orme PRIVATE packaging/windows/app.rc)
endif()

if(APPLE)
    # Generato a build-time (iconutil, disponibile solo su macOS) dal sorgente
    # in packaging/macos/AppIcon.iconset/ - vedi .github/workflows/macos.yml.
    # Se manca (build locale senza quello step) l'app resta senza icona
    # invece di rompere la configurazione.
    set(MACOS_ICON_FILE "${CMAKE_SOURCE_DIR}/packaging/macos/AppIcon.icns")
    if(EXISTS "${MACOS_ICON_FILE}")
        target_sources(Orme PRIVATE "${MACOS_ICON_FILE}")
        set_source_files_properties("${MACOS_ICON_FILE}" PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
        set_target_properties(Orme PROPERTIES MACOSX_BUNDLE_ICON_FILE AppIcon.icns)
    endif()
endif()

install(TARGETS Orme
    BUNDLE  DESTINATION .
    RUNTIME DESTINATION bin
)

# Voce menu (.desktop) e icona per i desktop Linux (letta da tutti i
# pacchetti: debian, arch, alpine e le tre RPM installano tramite
# "cmake --install", quindi la ereditano automaticamente).
install(FILES packaging/linux/debian/orme.desktop
    DESTINATION share/applications
)
install(FILES assets/icon/orme.svg
    DESTINATION share/icons/hicolor/scalable/apps
)
