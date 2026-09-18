// Orme
// Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later

#include <QFont>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>


static void installEmojiFontFallback()
{
#if defined(Q_OS_WINDOWS)
    // Niente di custom su Windows: Segoe UI Emoji e' gia' installato di
    // serie su ogni Windows 10/11, e' un font a colori in formato COLR
    // (supportato nativamente da DirectWrite) e Qt lo usa gia' in automatico
    // come fallback per i codepoint emoji quando il font di default non li
    // copre. NotoColorEmoji.ttf (usato sulle altre piattaforme) e' invece
    // in formato bitmap CBDT/CBLC, che DirectWrite non sa renderizzare
    // affatto.
    return;
#else
    const int id = QFontDatabase::addApplicationFont(
        QStringLiteral(":/qt/qml/Orme/assets/fonts/NotoColorEmoji.ttf"));
    if (id < 0)
        return;
    const QStringList families = QFontDatabase::applicationFontFamilies(id);
    if (families.isEmpty())
        return;

    QFont font = QGuiApplication::font();
    QStringList chain = font.families();
    if (chain.isEmpty() && !font.family().isEmpty())
        chain << font.family();
    chain << families.first();
    font.setFamilies(chain);
    QGuiApplication::setFont(font);
#endif
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("Orme"));
    app.setOrganizationName(QStringLiteral("Orme"));
    app.setApplicationVersion(QStringLiteral(ORME_VERSION));

    installEmojiFontFallback();

    // Il renderer di testo di default di QtQuick (GPU, cache glyph a
    // distance-field) non disegna in modo affidabile i glyph a colori
    // (l'emoji font appena impostato come fallback) su tutti i backend
    // grafici: su Windows (Direct3D/ANGLE) le emoji restano invisibili,
    // anche se il glyph esiste ed e' quello giusto. NativeRendering usa
    // invece QPainter/FreeType direttamente, che gestisce i glyph a colori
    // in modo corretto e uniforme su ogni piattaforma.
    QQuickWindow::setTextRenderType(QQuickWindow::NativeTextRendering);

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("Orme", "Main");

    return app.exec();
}
