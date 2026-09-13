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
    // Su Windows il font a colori non viene caricato correttamente se
    // l'applicazione non e' a DPI-aware, per cui lo dichiariamo subito all'avvio 
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

    QQuickWindow::setTextRenderType(QQuickWindow::NativeTextRendering);

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("Orme", "Main");

    return app.exec();
}
