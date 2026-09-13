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
    // NotoColorEmoji.ttf (usato sulle altre piattaforme) e' in formato
    // bitmap CBDT/CBLC (lo stesso di Android): DirectWrite, il motore di
    // testo di Windows usato anche da Qt, non sa renderizzare questo
    // formato affatto (a differenza di Skia su Android/Linux) - il glifo
    // viene risolto correttamente (spazio riservato) ma non viene mai
    // disegnato, restando invisibile. Serve quindi una build separata in
    // formato COLR/CPAL (vettoriale, supportato da DirectWrite): questa e'
    // "Noto-COLRv1.ttf" dal repo ufficiale googlefonts/noto-emoji.
    const int id = QFontDatabase::addApplicationFont(
        QStringLiteral(":/qt/qml/Orme/assets/fonts/NotoColorEmoji_Windows.ttf"));
#else
    const int id = QFontDatabase::addApplicationFont(
        QStringLiteral(":/qt/qml/Orme/assets/fonts/NotoColorEmoji.ttf"));
#endif

    if (id < 0)
        return;
    const QStringList families = QFontDatabase::applicationFontFamilies(id);
    if (families.isEmpty())
        return;

    QFont font = QGuiApplication::font();
#if defined(Q_OS_WINDOWS)
    // Anche con un font in formato corretto, aggiungerlo solo in coda alla
    // chain di fallback lascerebbe comunque il font UI di default (Segoe
    // UI) risolvere per primo i glifi emoji tramite il proprio
    // font-linking di sistema (Segoe UI Emoji) - stile diverso da Noto
    // usato sulle altre piattaforme. Per coerenza visiva forziamo quindi
    // il nostro font come UNICA famiglia esplicita: i glifi assenti (es.
    // lettere latine, che Noto Color Emoji non contiene) continuano
    // comunque a risolversi tramite il fallback di sistema automatico di
    // Qt.
    font.setFamilies(QStringList{families.first()});
#else
    QStringList chain = font.families();
    if (chain.isEmpty() && !font.family().isEmpty())
        chain << font.family();
    chain << families.first();
    font.setFamilies(chain);
#endif
    QGuiApplication::setFont(font);
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("Orme"));
    app.setOrganizationName(QStringLiteral("Orme"));
    app.setApplicationVersion(QStringLiteral("0.1"));

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
