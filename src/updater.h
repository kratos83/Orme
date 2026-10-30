// Orme
// Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>

class QNetworkAccessManager;
class QNetworkReply;

// Controlla su GitHub Releases (kratos83/Orme) se c'e' una versione piu'
// nuova di quella in esecuzione. Se c'e' un pacchetto scaricabile e
// installabile in modo sicuro per la piattaforma corrente (Windows
// installer, macOS .dmg, Android .apk), canAutoInstall() e' true e
// startUpdate() scarica quel pacchetto e avvia l'installazione. Sulle altre
// piattaforme (pacchetti Linux, .zip portabile Windows) canAutoInstall() e'
// false: la UI deve aprire releaseUrl() nel browser, l'aggiornamento vero
// passa dal gestore pacchetti di sistema o dal sito.
//
// Registrato come singleton QML del modulo (QML_ELEMENT + QML_SINGLETON,
// come PathEngine usa QML_ELEMENT): e' qt_add_qml_module a generare la
// registrazione, l'istanza la crea il motore QML al primo uso da QML. Non
// va MAI registrato anche a mano (qmlRegisterSingletonInstance) in
// main.cpp: le due registrazioni per lo stesso modulo/versione confliggono
// e fanno fallire la registrazione automatica degli altri tipi del modulo
// (PathEngine compreso), con errore "PathEngine is not a type" a runtime.
class Updater : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool checking READ checking NOTIFY checkingChanged)
    Q_PROPERTY(bool updateAvailable READ updateAvailable NOTIFY updateAvailableChanged)
    Q_PROPERTY(QString currentVersion READ currentVersion CONSTANT)
    Q_PROPERTY(QString latestVersion READ latestVersion NOTIFY latestVersionChanged)
    Q_PROPERTY(QString releaseNotes READ releaseNotes NOTIFY releaseNotesChanged)
    Q_PROPERTY(QString releaseUrl READ releaseUrl NOTIFY releaseUrlChanged)
    Q_PROPERTY(bool canAutoInstall READ canAutoInstall NOTIFY canAutoInstallChanged)
    Q_PROPERTY(qreal downloadProgress READ downloadProgress NOTIFY downloadProgressChanged)
    Q_PROPERTY(bool downloading READ downloading NOTIFY downloadingChanged)
    Q_PROPERTY(QString errorString READ errorString NOTIFY errorStringChanged)

public:
    explicit Updater(QObject *parent = nullptr);

    bool checking() const { return m_checking; }
    bool updateAvailable() const { return m_updateAvailable; }
    QString currentVersion() const { return m_currentVersion; }
    QString latestVersion() const { return m_latestVersion; }
    QString releaseNotes() const { return m_releaseNotes; }
    QString releaseUrl() const { return m_releaseUrl; }
    bool canAutoInstall() const { return m_canAutoInstall; }
    qreal downloadProgress() const { return m_downloadProgress; }
    bool downloading() const { return m_downloading; }
    QString errorString() const { return m_errorString; }

public slots:
    // Interroga GitHub Releases; fallisce in silenzio (solo errorString
    // aggiornata) se offline - normalissimo su un tablet di scuola.
    void checkForUpdates();
    // Scarica l'asset scelto per questa piattaforma e avvia
    // l'installazione. Non fa nulla se canAutoInstall() e' false.
    void startUpdate();

signals:
    void checkingChanged();
    void updateAvailableChanged();
    void latestVersionChanged();
    void releaseNotesChanged();
    void releaseUrlChanged();
    void canAutoInstallChanged();
    void downloadProgressChanged();
    void downloadingChanged();
    void errorStringChanged();

private:
    void handleCheckReply(QNetworkReply *reply);
    void handleDownloadReply(QNetworkReply *reply);
    void applyDownloadedAsset(const QString &filePath);
    static int compareVersions(const QString &a, const QString &b);
    void setChecking(bool value);
    void setDownloading(bool value);
    void setError(const QString &message);

    QNetworkAccessManager *m_net;

    bool m_checking = false;
    bool m_updateAvailable = false;
    QString m_currentVersion;
    QString m_latestVersion;
    QString m_releaseNotes;
    QString m_releaseUrl;
    bool m_canAutoInstall = false;
    QString m_assetUrl;
    QString m_assetFileName;
    bool m_downloading = false;
    qreal m_downloadProgress = 0;
    QString m_errorString;
};
