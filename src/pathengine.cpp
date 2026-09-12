// Orme
// Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later

#include "pathengine.h"

#include <QVariantMap>

PathEngine::PathEngine(QObject *parent)
    : QObject(parent)
{
    m_timer.setInterval(650);          // un passo ogni 0,65 s
    connect(&m_timer, &QTimer::timeout, this, &PathEngine::playStep);

    // I livelli. Campi: colonne, righe, partenza(col,riga), traguardo(col,riga),
    // emoji dell'oggetto da prendere, elenco delle rocce.
    // Coordinate (colonna, riga) con origine in alto a sinistra.
    //
    // --- 1..14: scuola dell'infanzia. Griglie piccole, 1-6 passi, nessuna roccia.
    m_levels = {
        {  3, 3,  0, 1,   1, 1,  "🍎", {} },   //  1  un passo a destra
        {  3, 3,  0, 1,   2, 1,  "⚽", {} },   //  2  due passi a destra
        {  3, 3,  1, 2,   1, 0,  "⭐", {} },   //  3  due passi in su
        {  3, 3,  0, 2,   2, 2,  "🍌", {} },   //  4  due passi a destra
        {  3, 3,  2, 0,   0, 0,  "🌸", {} },   //  5  due passi a sinistra
        {  4, 3,  0, 1,   3, 1,  "🐟", {} },   //  6  tre passi a destra
        {  3, 3,  0, 2,   2, 0,  "🎈", {} },   //  7  una L: su e destra
        {  3, 3,  0, 0,   2, 2,  "🍪", {} },   //  8  una L: destra e giu'
        {  4, 3,  0, 2,   3, 0,  "🐢", {} },   //  9  su e poi a destra
        {  4, 4,  0, 3,   3, 3,  "🚗", {} },   // 10  tre passi a destra
        {  4, 4,  0, 0,   0, 3,  "🦋", {} },   // 11  tre passi in giu'
        {  4, 4,  0, 3,   3, 0,  "🍓", {} },   // 12  su e a destra
        {  4, 4,  3, 3,   0, 0,  "🍇", {} },   // 13  su e a sinistra
        {  5, 4,  0, 2,   4, 2,  "🐝", {} },   // 14  quattro passi a destra

        // --- 15..24: piu' difficili. Griglie grandi, rocce, percorsi a serpentina.
        {  5, 4,  0, 2,   4, 2,  "🔑", { {2,1}, {2,2} } },                       // 15
        {  5, 5,  0, 0,   4, 4,  "🎁", { {2,0}, {2,1}, {2,2} } },                // 16
        {  5, 5,  0, 4,   4, 0,  "🍉", { {2,2}, {2,3}, {2,4} } },                // 17
        {  6, 5,  0, 4,   5, 0,  "🌙", { {2,3}, {2,4}, {4,1}, {4,2} } },         // 18
        {  6, 6,  0, 0,   5, 5,  "🐬", { {1,1},{2,1},{3,1},{4,1},{5,1},
                                        {0,3},{1,3},{2,3},{3,3},{4,3} } },       // 19
        {  6, 6,  0, 5,   5, 0,  "🦊", { {1,4},{2,4},{3,4},{4,4},{5,4},
                                        {0,2},{1,2},{2,2},{3,2},{4,2} } },       // 20
        {  7, 6,  0, 0,   6, 5,  "🚀", { {1,1},{2,1},{3,1},{4,1},{5,1},{6,1},
                                        {0,3},{1,3},{2,3},{3,3},{4,3},{5,3} } }, // 21
        {  7, 6,  0, 5,   6, 0,  "🍄", { {1,4},{2,4},{3,4},{4,4},{5,4},{6,4},
                                        {0,2},{1,2},{2,2},{3,2},{4,2},{5,2} } }, // 22
        {  7, 7,  0, 0,   6, 6,  "👑", { {1,1},{2,1},{3,1},{4,1},{5,1},{6,1},
                                        {0,3},{1,3},{2,3},{3,3},{4,3},{5,3},
                                        {1,5},{2,5},{3,5},{4,5},{5,5},{6,5} } }, // 23
        {  7, 7,  0, 6,   6, 0,  "🌈", { {1,5},{2,5},{3,5},{4,5},{5,5},{6,5},
                                        {0,3},{1,3},{2,3},{3,3},{4,3},{5,3},
                                        {1,1},{2,1},{3,1},{4,1},{5,1},{6,1} } }, // 24
    };

    loadLevel(0);
}

int PathEngine::columns() const   { return current().cols; }
int PathEngine::rows() const      { return current().rows; }
int PathEngine::goalColumn() const { return current().goalCol; }
int PathEngine::goalRow() const    { return current().goalRow; }
QString PathEngine::goalKind() const { return current().goal; }

QVariantList PathEngine::obstacles() const
{
    QVariantList out;
    for (const QPoint &p : current().rocks) {
        QVariantMap m;
        m.insert(QStringLiteral("column"), p.x());
        m.insert(QStringLiteral("row"),    p.y());
        out.append(m);
    }
    return out;
}

QVariantList PathEngine::commands() const
{
    QVariantList out;
    for (Direction d : m_commands)
        out.append(int(d));
    return out;
}

void PathEngine::addCommand(Direction dir)
{
    if (m_state == Running)
        return;
    if (m_commands.size() >= kMaxCommands)
        return;

    // Se il turno precedente e' finito (vinto o sbattuto), si ricomincia a comporre.
    if (m_state != Editing) {
        resetPlayer();
        m_commands.clear();
    }

    m_commands.append(dir);
    emit commandsChanged();
}

void PathEngine::removeCommand(int index)
{
    if (m_state == Running)
        return;
    if (index < 0 || index >= m_commands.size())
        return;

    m_commands.remove(index);
    emit commandsChanged();
    resetPlayer();
}

void PathEngine::clearCommands()
{
    if (m_state == Running)
        return;

    m_commands.clear();
    emit commandsChanged();
    resetPlayer();
}

void PathEngine::run()
{
    if (m_state == Running || m_commands.isEmpty())
        return;

    resetPlayer();
    m_cursor = 0;
    setState(Running);
    m_timer.start();
}

void PathEngine::stop()
{
    m_timer.stop();
    m_activeStep = -1;
    emit activeStepChanged();
    setState(Editing);
}

void PathEngine::resetPlayer()
{
    m_timer.stop();
    m_playerCol  = current().startCol;
    m_playerRow  = current().startRow;
    m_activeStep = -1;
    m_cursor     = 0;
    emit playerChanged();
    emit activeStepChanged();
    if (m_state != Editing)
        setState(Editing);
}

void PathEngine::loadLevel(int index)
{
    if (index < 0 || index >= m_levels.size())
        return;

    m_levelIndex = index;
    m_commands.clear();
    m_playerCol  = current().startCol;
    m_playerRow  = current().startRow;
    m_activeStep = -1;
    m_cursor     = 0;
    m_state      = Editing;

    emit levelChanged();
    emit commandsChanged();
    emit playerChanged();
    emit activeStepChanged();
    emit stateChanged();
}

void PathEngine::nextLevel()
{
    loadLevel((m_levelIndex + 1) % int(m_levels.size()));
}

void PathEngine::setState(State s)
{
    if (m_state == s)
        return;
    m_state = s;
    emit stateChanged();
}

bool PathEngine::blocked(int col, int row) const
{
    for (const QPoint &p : current().rocks)
        if (p.x() == col && p.y() == row)
            return true;
    return false;
}

void PathEngine::playStep()
{
    if (m_cursor >= m_commands.size()) {
        // Finiti i comandi senza arrivare alla mela: sequenza sbagliata.
        m_timer.stop();
        m_activeStep = -1;
        emit activeStepChanged();
        setState(Mistake);
        emit mistake();
        return;
    }

    m_activeStep = m_cursor;
    emit activeStepChanged();
    emit stepPlayed(m_cursor);

    int nc = m_playerCol;
    int nr = m_playerRow;
    switch (m_commands[m_cursor]) {
    case Up:    --nr; break;
    case Down:  ++nr; break;
    case Left:  --nc; break;
    case Right: ++nc; break;
    }

    const Level &l = current();
    const bool outside = nc < 0 || nr < 0 || nc >= l.cols || nr >= l.rows;
    if (outside || blocked(nc, nr)) {
        // Ha sbattuto contro un muro o una roccia: anche questa e' una mossa sbagliata.
        m_timer.stop();
        setState(Mistake);
        emit bumped();     // scossa del personaggio
        emit mistake();    // messaggio "riprova" + azzeramento
        return;
    }

    m_playerCol = nc;
    m_playerRow = nr;
    emit playerChanged();
    ++m_cursor;

    if (m_playerCol == l.goalCol && m_playerRow == l.goalRow) {
        m_timer.stop();
        m_activeStep = -1;
        emit activeStepChanged();

        if (m_cursor >= m_commands.size()) {
            // Arrivato all'oggetto ed erano finite le frecce: vittoria.
            setState(Won);
            emit won();
        } else {
            // Arrivato all'oggetto ma ci sono ancora frecce: lo "supererebbe".
            // Troppe frecce = mossa sbagliata, si riprova.
            setState(Mistake);
            emit mistake();
        }
    }
}
