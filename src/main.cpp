// Orme
// Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later

#include <QFont>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>

// Fredoka: font tondo e leggibile, incluso nel programma (assets/fonts/,
// licenza OFL). Se non si carica resta il font di sistema.
static void installAppFont()
{
    int id = -1;
    for (const char *weight : {"500", "700"}) {
        const int added = QFontDatabase::addApplicationFont(
            QStringLiteral(":/qt/qml/Orme/assets/fonts/Fredoka-%1.ttf")
                .arg(QLatin1String(weight)));
        if (added >= 0)
            id = added;
    }
    if (id < 0)
        return;
    const QStringList families = QFontDatabase::applicationFontFamilies(id);
    if (families.isEmpty())
        return;

    QFont font = QGuiApplication::font();
    font.setFamilies(families);
    QGuiApplication::setFont(font);
}

int main(int argc, char *argv[])
{
#if defined(Q_OS_HAIKU)
    // Su Haiku/Vitruvian il backend OpenGL di Qt Quick abortisce all'avvio:
    // il plugin di piattaforma, creando la superficie offscreen, rielabora in
    // modo annidato l'evento di esposizione e Qt Quick chiama qFatal. Il
    // renderer software non usa quella superficie. Si puo' ancora forzare un
    // altro backend con QT_QUICK_BACKEND o QSG_RHI_BACKEND.
    if (!qEnvironmentVariableIsSet("QT_QUICK_BACKEND")
        && !qEnvironmentVariableIsSet("QSG_RHI_BACKEND"))
        QQuickWindow::setSceneGraphBackend(QStringLiteral("software"));
#endif

    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("Orme"));
    app.setOrganizationName(QStringLiteral("Orme"));
    app.setApplicationVersion(QStringLiteral(ORME_VERSION));

    installAppFont();

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("Orme", "Main");

    return app.exec();
}
