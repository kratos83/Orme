-- Imposta la vista a icone del volume "Orme" montato (vedi
-- .github/workflows/macos.yml), cosi' aprendo il .dmg si vede subito
-- l'icona dell'app accanto al collegamento ad Applications.
tell application "Finder"
    tell disk "Orme"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 120, 700, 470}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 100
        set position of item "Orme.app" of container window to {120, 150}
        set position of item "Applications" of container window to {380, 150}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
