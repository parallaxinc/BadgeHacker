#include "badgerow.h"

Q_LOGGING_CATEGORY(badgerow, "hackergang.row")

BadgeRow::BadgeRow(PropellerManager * manager,
        HackerGang * hackergang,
        const QString & portname,
        QWidget *parent)
: QWidget(parent)
{
    ui.setupUi(this);

    this->manager = manager;
    this->hackergang = hackergang;
    badge = new Badge(manager, portname);

    ui.enable->setText(portname);

    connect(ui.enable, SIGNAL(clicked(bool)),   this, SLOT(enableClicked()));

    connect(badge, SIGNAL(success()), this, SLOT(programmed()));
    connect(badge, SIGNAL(failure()), this, SLOT(failure()));

    setBadgeState(BadgeIdle);
}

BadgeRow::~BadgeRow()
{
    delete badge;
}

void BadgeRow::setBadgeState(BadgeState state)
{
    _state = state;
    emit badgeStateChanged();

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
            ui.message->setText(tr("Success!"));
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

void BadgeRow::enableClicked()
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
        connect(badge,      SIGNAL(statusChanged(const QString &)),
                ui.message, SLOT(setText(const QString &)));
        contact = hackergang->popContact();
        if (contact.isEmpty()) return;
        setBadgeState(BadgeInProgress);
        badge->program();
    }
}

void BadgeRow::programmed()
{
    disconnect(badge,      SIGNAL(statusChanged(const QString &)),
               ui.message, SLOT(setText(const QString &)));
    qCDebug(badgerow) << "programmed()";
    ui.message->setText(tr("Connecting to badge..."));

    connect(badge, SIGNAL(readyReceived()), this, SLOT(wipe()));
    badge->start_ready(6000);
}

void BadgeRow::wipe()
{
    disconnect(badge, SIGNAL(readyReceived()), this, SLOT(wipe()));
    qCDebug(badgerow) << "wipe()";
    ui.message->setText(tr("Wiping contacts..."));

    badge->wipe();

    connect(badge, SIGNAL(readyReceived()), this, SLOT(configure()));
    badge->start_ready(12000);
}

void BadgeRow::configure()
{
    disconnect(badge, SIGNAL(readyReceived()), this, SLOT(configure()));
    qCDebug(badgerow) << "configure()";
    ui.message->setText(tr("Configuring badge..."));

    badge->write_nsmsg( contact[0],
                        contact[1]);

    badge->write_smsg(  contact[3],
                        contact[4]);

    QStringList infostrings;
    infostrings << contact[5]
                << contact[6]
                << contact[7]
                << contact[8];
    badge->write_info(infostrings);

    badge->write_rgb(   contact[9],
                        contact[10]);

    // write led
    badge->write_line(QString("led all \%%1").arg(contact[11].left(6)));

    badge->write_scroll(contact[2] == "yes" ? true : false);

    connect(badge, SIGNAL(readyReceived()), this, SLOT(success()));
    badge->start_ready(5000);
}

void BadgeRow::success()
{
    qCDebug(badgerow) << "success()";
    disconnect(badge, SIGNAL(readyReceived()), this, SLOT(success()));
    setBadgeState(BadgeSuccess);
}

void BadgeRow::failure()
{
    setBadgeState(BadgeError);
    hackergang->pushContact(contact);
}

BadgeRow::BadgeState BadgeRow::state()
{
    return _state;
}
