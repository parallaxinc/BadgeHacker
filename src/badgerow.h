#pragma once

#include "hackergang.h"
#include "badge.h"
#include "ui_badgerow.h"

Q_DECLARE_LOGGING_CATEGORY(badgerow)

class HackerGang;

class BadgeRow : public QWidget 
{
    Q_OBJECT

public:
    enum BadgeState
    {
        BadgeIdle,
        BadgeInProgress,
        BadgeError,
        BadgeSuccess,
        BadgeDisabled
    };

private:
    Ui::BadgeRow ui;

    PropellerManager * manager;
    HackerGang * hackergang;
    Badge * badge;
    QStringList contact;

    BadgeState _state;

    void setBadgeState(BadgeState state);

private slots:
    void enableClicked();

public:
    explicit BadgeRow(PropellerManager * manager,
            HackerGang * hackergang,
            const QString & portname,
            QWidget *parent = 0);
    ~BadgeRow();

    const QString & portName();
    BadgeState state();

public slots:
    void setBadgeEnabled(bool enabled);
    void program();
    void programmed();
    void configure();
    void wipe();

    void success();
    void failure();

signals:
    void badgeStateChanged();
};
