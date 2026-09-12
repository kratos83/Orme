// Orme
// Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later

#include <QFont>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QQmlApplicationEngine>

// Molti tablet Android reali (soprattutto ROM senza servizi Google) non
// hanno alcun font emoji a colori di sistema: le emoji usate come icone in
// tutta l'app (menu e giochi) restano invisibili o come quadratini vuoti.
// Includiamo Noto Color Emoji come font applicativo e lo mettiamo come
// fallback del font di default: qualunque Text senza font.family esplicito
// lo usera' automaticamente per i caratteri (le emoji) che il font
// principale non ha, senza dover toccare ogni file QML.
static void installEmojiFontFallback()
{
    const int id = QFontDatabase::addApplicationFont(
        QStringLiteral(":/qt/qml/Giochi/assets/fonts/NotoColorEmoji.ttf"));
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
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("Orme"));
    app.setOrganizationName(QStringLiteral("Giochi"));
    app.setApplicationVersion(QStringLiteral("0.2"));

    installEmojiFontFallback();

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("Giochi", "Main");

    return app.exec();
}
