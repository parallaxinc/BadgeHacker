#include "badgerow.h"

Q_LOGGING_CATEGORY(badgerow, "hackergang.row")

BadgeRow::BadgeRow(PropellerManager * manager,
        const QString & portname,
        QWidget *parent)
: QWidget(parent)
{
    ui.setupUi(this);

    this->manager = manager;
    badge = new Badge(manager, portname);

    ui.enable->setText(portname);

    connect(ui.enable, SIGNAL(clicked(bool)),   this, SLOT(badgeStateChanged()));

    connect(badge,      SIGNAL(statusChanged(const QString &)),
            ui.message, SLOT(setText(const QString &)));

    connect(badge, SIGNAL(success()), this, SLOT(success()));
    connect(badge, SIGNAL(failure()), this, SLOT(failure()));

    setBadgeState(BadgeIdle);
}

BadgeRow::~BadgeRow()
{
    delete badge;
}

void BadgeRow::setBadgeState(BadgeState state)
{
    QPalette p(ui.frame->palette());

    switch (state)
    {
        case BadgeIdle:
            setBadgeEnabled(true);
            p.setColor(QPalette::Window, QColor("#CDCDCD"));
            p.setColor(QPalette::WindowText, QColor("#808080"));
            ui.status->setPixmap(QPixmap(":/icons/badgehacker/dialog-plain_sm.png"));
            break;

        case BadgeInProgress:
            setBadgeEnabled(true);
            p.setColor(QPalette::Window, QColor("#FFFFB4"));
            p.setColor(QPalette::WindowText, QColor("#808000"));
            ui.status->setPixmap(QPixmap(":/icons/badgehacker/dialog-progress_sm.png"));
            break;

        case BadgeError:
            setBadgeEnabled(true);
            p.setColor(QPalette::Window, QColor("#FFB4B4"));
            p.setColor(QPalette::WindowText, QColor("#800000"));
            ui.status->setPixmap(QPixmap(":/icons/badgehacker/dialog-reject_sm.png"));
            break;

        case BadgeSuccess:
            setBadgeEnabled(true);
            p.setColor(QPalette::Window, QColor("#B4FFB4"));
            p.setColor(QPalette::WindowText, QColor("#007000"));
            ui.status->setPixmap(QPixmap(":/icons/badgehacker/dialog-accept_sm.png"));
            break;

        case BadgeDisabled:
            setBadgeEnabled(false);
            p.setColor(QPalette::Window, QColor("#BEBEBE"));
            p.setColor(QPalette::WindowText, QColor("#848484"));
            ui.status->setPixmap(QPixmap(":/icons/badgehacker/dialog-plain_sm.png"));
            break;
    }

    ui.frame->setPalette(p);
}

void BadgeRow::badgeStateChanged()
{
    if (ui.enable->isChecked())
        setBadgeState(BadgeIdle);
    else
        setBadgeState(BadgeDisabled);
}

void BadgeRow::setBadgeEnabled(bool enabled)
{
    if (enabled)
    {
        ui.message->setText(tr("Idle"));
    }
    else
    {
        ui.message->setText(tr("This port is disabled"));
    }

    ui.message->setEnabled(enabled);
    ui.status->setEnabled(enabled);
}

const QString & BadgeRow::portName()
{
    return badge->portName();
}

void BadgeRow::program()
{
    if (ui.enable->isChecked())
    {
        setBadgeState(BadgeInProgress);
        badge->program();
    }
}

void BadgeRow::success()
{
    setBadgeState(BadgeSuccess);
}

void BadgeRow::failure()
{
    setBadgeState(BadgeError);
}
