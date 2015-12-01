#pragma once

#include <QDialog>
#include <QTimer>
#include <QLoggingCategory>
#include <QProgressDialog>
#include <QMap>
#include <QSignalMapper>

#include <PropellerSession>

#include "badgerow.h"
#include "badge.h"

#include "ui_hackergang.h"

Q_DECLARE_LOGGING_CATEGORY(hackergang)

class BadgeRow;

class HackerGang : public QWidget 
{
    Q_OBJECT

private:
    Ui::HackerGang ui;
    PropellerManager * manager;
    QSignalMapper * signalMapper;
    QStringList ports;
    QHash<QWidget *, bool> _active;

    QString filename;
    QList<QStringList> contactlist;
    QList<QStringList> inprogresscontactlist;
    QStringList contact;

public:
    explicit HackerGang(PropellerManager * manager, QWidget *parent = 0);
    ~HackerGang();

    QStringList popContact();
    void pushContact(QStringList contact);

private slots:
    void updatePorts();
    void openContacts();
    void saveContacts();
    void checkString(QString &temp, QChar character = 0);
    void updateProgrammedText();
    void updateFileText(QString filename = QString());

    void program();
    void setConnectionState(bool connected);
    void checkState(QWidget * w);

signals:
    void programTriggered();
};
