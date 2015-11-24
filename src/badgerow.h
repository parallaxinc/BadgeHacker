#pragma once

#include "badge.h"
#include "ui_badgerow.h"

Q_DECLARE_LOGGING_CATEGORY(badgerow)

class BadgeRow : public QWidget 
{
    Q_OBJECT

private:
    Ui::BadgeRow ui;

    PropellerManager * manager;
    Badge * badge;

    enum BadgeState
    {
        BadgeIdle,
        BadgeInProgress,
        BadgeError,
        BadgeSuccess,
        BadgeDisabled
    };

    void setBadgeState(BadgeState state);

private slots:
    void badgeStateChanged();

public:
    explicit BadgeRow(PropellerManager * manager,
            const QString & portname,
            QWidget *parent = 0);
    ~BadgeRow();

    const QString & portName();

public slots:
    void setBadgeEnabled(bool enabled);
    void program();
    void success();
    void failure();

};
