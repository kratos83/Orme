// Orme
// Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QVariantList>
#include <QVector>
#include <QPoint>
#include <QString>
#include <QTimer>

// Motore del gioco "Il percorso".
//
// Modello: una griglia a celle. Il personaggio parte da una cella e deve
// raggiungere l'oggetto del livello (una mela, una palla, una stella...).
// Il bambino costruisce una sequenza di comandi (frecce con direzione
// assoluta: su/giu/sinistra/destra) e poi preme "vai": il motore esegue un
// passo alla volta, con un timer, ed emette segnali che il QML usa per
// animare e per i suoni.
//
// Livelli: i primi 14 sono pensati per la scuola dell'infanzia (griglie
// piccole, 1-6 passi, nessun ostacolo). Dal 15 in poi crescono di
// difficolta': griglie piu' grandi, rocce da aggirare, percorsi a serpentina.
class PathEngine : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int columns      READ columns      NOTIFY levelChanged)
    Q_PROPERTY(int rows         READ rows         NOTIFY levelChanged)
    Q_PROPERTY(int goalColumn   READ goalColumn   NOTIFY levelChanged)
    Q_PROPERTY(int goalRow      READ goalRow      NOTIFY levelChanged)
    Q_PROPERTY(QString goalKind READ goalKind     NOTIFY levelChanged)
    Q_PROPERTY(int playerColumn READ playerColumn NOTIFY playerChanged)
    Q_PROPERTY(int playerRow    READ playerRow    NOTIFY playerChanged)
    Q_PROPERTY(QVariantList obstacles READ obstacles NOTIFY levelChanged)
    Q_PROPERTY(QVariantList commands  READ commands  NOTIFY commandsChanged)
    Q_PROPERTY(int   activeStep READ activeStep NOTIFY activeStepChanged)
    Q_PROPERTY(State state      READ state      NOTIFY stateChanged)
    Q_PROPERTY(int   levelIndex READ levelIndex NOTIFY levelChanged)
    Q_PROPERTY(int   levelCount READ levelCount CONSTANT)

public:
    enum Direction { Up = 0, Down = 1, Left = 2, Right = 3 };
    Q_ENUM(Direction)

    enum State { Editing, Running, Won, Mistake };
    Q_ENUM(State)

    explicit PathEngine(QObject *parent = nullptr);

    int columns() const;
    int rows() const;
    int goalColumn() const;
    int goalRow() const;
    QString goalKind() const;
    int playerColumn() const { return m_playerCol; }
    int playerRow() const    { return m_playerRow; }
    QVariantList obstacles() const;
    QVariantList commands() const;
    int   activeStep() const { return m_activeStep; }
    State state() const      { return m_state; }
    int   levelIndex() const { return m_levelIndex; }
    int   levelCount() const { return int(m_levels.size()); }

    Q_INVOKABLE void addCommand(Direction dir);
    Q_INVOKABLE void removeCommand(int index);
    Q_INVOKABLE void clearCommands();
    Q_INVOKABLE void run();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void resetPlayer();
    Q_INVOKABLE void loadLevel(int index);
    Q_INVOKABLE void nextLevel();

signals:
    void levelChanged();
    void playerChanged();
    void commandsChanged();
    void activeStepChanged();
    void stateChanged();
    void stepPlayed(int index);  // un passo e' stato eseguito (per il suono)
    void bumped();               // ha sbattuto: solo per l'animazione di scossa
    void mistake();              // sequenza sbagliata: mostra "riprova" e azzera
    void won();                  // ha raggiunto la mela

private:
    struct Level {
        int cols;
        int rows;
        int startCol;
        int startRow;
        int goalCol;
        int goalRow;
        QString goal;              // emoji dell'oggetto da raggiungere
        QVector<QPoint> rocks;
    };

    const Level &current() const { return m_levels[m_levelIndex]; }
    void setState(State s);
    void playStep();
    bool blocked(int col, int row) const;

    QVector<Level> m_levels;
    int   m_levelIndex = 0;
    int   m_playerCol  = 0;
    int   m_playerRow  = 0;
    int   m_activeStep = -1;
    int   m_cursor     = 0;      // indice del prossimo comando da eseguire
    State m_state      = Editing;
    QVector<Direction> m_commands;
    QTimer m_timer;

    static constexpr int kMaxCommands = 32;
};
