// Orme
// Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
#include "updater.h"

#include <QCoreApplication>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QStandardPaths>
#include <QUrl>

#if defined(Q_OS_WIN)
#include <QProcess>
#elif defined(Q_OS_ANDROID)
#include <QJniObject>
// Non esiste un header "convenience" <QNativeInterface> per Android nel kit
// Qt6 (e' un namespace, non una classe): serve l'header esplicito.
#include <QtCore/qnativeinterface.h>
#endif

namespace {
const char kReleasesApiUrl[] = "https://api.github.com/repos/kratos83/Orme/releases/latest";
}

Updater::Updater(QObject *parent)
    : QObject(parent)
    , m_net(new QNetworkAccessManager(this))
    , m_currentVersion(QCoreApplication::applicationVersion())
{
}

void Updater::setChecking(bool value)
{
    if (m_checking == value)
        return;
    m_checking = value;
    emit checkingChanged();
}

void Updater::setDownloading(bool value)
{
    if (m_downloading == value)
        return;
    m_downloading = value;
    emit downloadingChanged();
}

void Updater::setError(const QString &message)
{
    m_errorString = message;
    emit errorStringChanged();
}

int Updater::compareVersions(const QString &a, const QString &b)
{
    const QStringList pa = a.split(QLatin1Char('.'));
    const QStringList pb = b.split(QLatin1Char('.'));
    const int n = qMax(pa.size(), pb.size());
    for (int i = 0; i < n; ++i) {
        const int va = i < pa.size() ? pa.at(i).toInt() : 0;
        const int vb = i < pb.size() ? pb.at(i).toInt() : 0;
        if (va != vb)
            return va - vb;
    }
    return 0;
}

void Updater::checkForUpdates()
{
    if (m_checking)
        return;
    setChecking(true);
    setError(QString());

    QNetworkRequest request{QUrl(QString::fromLatin1(kReleasesApiUrl))};
    request.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("Orme-Updater"));
    request.setRawHeader("Accept", "application/vnd.github+json");

    QNetworkReply *reply = m_net->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        handleCheckReply(reply);
        reply->deleteLater();
    });
}

void Updater::handleCheckReply(QNetworkReply *reply)
{
    setChecking(false);

    if (reply->error() != QNetworkReply::NoError) {
        // Offline o rete non disponibile: normale, nessun allarme per l'utente.
        setError(reply->errorString());
        return;
    }

    const QJsonObject obj = QJsonDocument::fromJson(reply->readAll()).object();
    QString tag = obj.value(QStringLiteral("tag_name")).toString();
    if (tag.startsWith(QLatin1Char('v')))
        tag.remove(0, 1);
    if (tag.isEmpty()) {
        setError(QStringLiteral("Risposta inattesa da GitHub"));
        return;
    }

    m_latestVersion = tag;
    emit latestVersionChanged();

    m_releaseNotes = obj.value(QStringLiteral("body")).toString();
    emit releaseNotesChanged();

    m_releaseUrl = obj.value(QStringLiteral("html_url")).toString();
    emit releaseUrlChanged();

    m_assetUrl.clear();
    m_assetFileName.clear();
    bool canInstall = false;

    const QJsonArray assets = obj.value(QStringLiteral("assets")).toArray();
    for (const QJsonValue &v : assets) {
        const QJsonObject asset = v.toObject();
        const QString name = asset.value(QStringLiteral("name")).toString();
        bool matches = false;
#if defined(Q_OS_WIN)
        matches = name.endsWith(QStringLiteral("windows-setup-x64.exe"));
#elif defined(Q_OS_MACOS)
        matches = name.endsWith(QStringLiteral("macos-universal.dmg"));
#elif defined(Q_OS_ANDROID)
        matches = name.endsWith(QStringLiteral(".apk"));
#endif
        if (matches) {
            m_assetUrl = asset.value(QStringLiteral("browser_download_url")).toString();
            m_assetFileName = name;
            canInstall = true;
            break;
        }
    }

    if (m_canAutoInstall != canInstall) {
        m_canAutoInstall = canInstall;
        emit canAutoInstallChanged();
    }

    const bool available = compareVersions(m_latestVersion, m_currentVersion) > 0;
    if (m_updateAvailable != available) {
        m_updateAvailable = available;
        emit updateAvailableChanged();
    }
}

void Updater::startUpdate()
{
    if (!m_canAutoInstall || m_assetUrl.isEmpty() || m_downloading)
        return;

    setDownloading(true);
    m_downloadProgress = 0;
    emit downloadProgressChanged();
    setError(QString());

    QNetworkRequest request{QUrl(m_assetUrl)};
    request.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("Orme-Updater"));
    // segue i redirect di GitHub verso l'oggetto reale su S3
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);

    QNetworkReply *reply = m_net->get(request);
    connect(reply, &QNetworkReply::downloadProgress, this, [this](qint64 done, qint64 total) {
        if (total > 0) {
            m_downloadProgress = qreal(done) / qreal(total);
            emit downloadProgressChanged();
        }
    });
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        handleDownloadReply(reply);
        reply->deleteLater();
    });
}

void Updater::handleDownloadReply(QNetworkReply *reply)
{
    setDownloading(false);

    if (reply->error() != QNetworkReply::NoError) {
        setError(reply->errorString());
        return;
    }

    const QString dir = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    QDir().mkpath(dir);
    const QString filePath = dir + QLatin1Char('/') + m_assetFileName;

    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly)) {
        setError(QStringLiteral("Impossibile scrivere il file scaricato"));
        return;
    }
    file.write(reply->readAll());
    file.close();

    applyDownloadedAsset(filePath);
}

void Updater::applyDownloadedAsset(const QString &filePath)
{
#if defined(Q_OS_WIN)
    // Avvia l'installer scaricato (Inno Setup) e chiude Orme: l'installer
    // si occupa di sostituire i file e proporre il riavvio dell'app.
    if (QProcess::startDetached(filePath, {}))
        QCoreApplication::quit();
    else
        setError(QStringLiteral("Impossibile avviare l'installer scaricato"));
#elif defined(Q_OS_MACOS)
    // Monta il .dmg in Finder: l'utente trascina Orme.app in Applications,
    // come per qualunque altra app mac senza notarizzazione.
    if (!QDesktopServices::openUrl(QUrl::fromLocalFile(filePath)))
        setError(QStringLiteral("Impossibile aprire il .dmg scaricato"));
#elif defined(Q_OS_ANDROID)
    // Apre il dialog di sistema "Vuoi installare questa app?" tramite
    // FileProvider (Android non permette mai un'installazione silenziosa
    // di un APK side-loaded). NOTA: percorso non verificabile in questa
    // sandbox Linux, va controllato su un device Android reale.
    QJniObject javaPath = QJniObject::fromString(filePath);
    QJniObject jFile("java/io/File", "(Ljava/lang/String;)V", javaPath.object<jstring>());

    QJniObject context = QNativeInterface::QAndroidApplication::context();
    QJniObject packageName = context.callObjectMethod("getPackageName", "()Ljava/lang/String;");
    QJniObject authority = QJniObject::fromString(packageName.toString() + QStringLiteral(".qtprovider"));

    QJniObject uri = QJniObject::callStaticObjectMethod(
        "androidx/core/content/FileProvider", "getUriForFile",
        "(Landroid/content/Context;Ljava/lang/String;Ljava/io/File;)Landroid/net/Uri;",
        context.object(), authority.object<jstring>(), jFile.object());

    QJniObject intent("android/content/Intent");
    intent.callObjectMethod(
        "setAction", "(Ljava/lang/String;)Landroid/content/Intent;",
        QJniObject::fromString(QStringLiteral("android.intent.action.VIEW")).object<jstring>());
    QJniObject mime = QJniObject::fromString(QStringLiteral("application/vnd.android.package-archive"));
    intent.callObjectMethod(
        "setDataAndType", "(Landroid/net/Uri;Ljava/lang/String;)Landroid/content/Intent;",
        uri.object(), mime.object<jstring>());
    intent.callObjectMethod("addFlags", "(I)Landroid/content/Intent;", 0x00000001); // FLAG_GRANT_READ_URI_PERMISSION
    intent.callObjectMethod("addFlags", "(I)Landroid/content/Intent;", 0x10000000); // FLAG_ACTIVITY_NEW_TASK

    context.callMethod<void>("startActivity", "(Landroid/content/Intent;)V", intent.object());
#else
    Q_UNUSED(filePath)
    setError(QStringLiteral("Installazione automatica non disponibile su questa piattaforma"));
#endif
}
