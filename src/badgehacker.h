#pragma once

#include <QDialog>
#include <QTimer>
#include <QLoggingCategory>
#include <QProgressDialog>
#include <QMap>

#include <PropellerSession>

#include "badge.h"
#include "hackergang.h"

#include "ui_badgehacker.h"

Q_DECLARE_LOGGING_CATEGORY(badgehacker)

class BadgeHacker : public QMainWindow
{
    Q_OBJECT

private:
    Ui::BadgeHacker ui;
    PropellerManager * manager;

    Badge * badge;
    HackerGang * hackergang;
    QMap<QString, QString> _expected;

    QList<QStringList> contactlist;
    void version();

public:
    explicit BadgeHacker(PropellerManager * manager, QWidget *parent = 0);
    ~BadgeHacker();

private slots:
    void open();
    void closed();
    void handleEnable(bool checked);
    void handleError();
    void portChanged();
    void updatePorts();
    void setEnabled(bool enabled);

    bool program(QProgressDialog * progress);
    bool ping(QProgressDialog * progress);
    void update(QProgressDialog * progress);

    void configure();
    void refresh();
    void wipe();
    bool unexpectedFirmware(QProgressDialog * progress);
    bool firmwareNotFound(QProgressDialog * progress);
    bool badgeNotFound(QProgressDialog * progress);
    bool notFound(const QString & title,
            const QString & text,
            QProgressDialog * progress);

    bool saveContacts();
    void saveContactsAsText(QFile * file);
    void saveContactsAsCsv(QFile * file);

    void showContact(int index);

    void clear();

    void write_nsmsg();
    void write_nsmsg1();
    void write_nsmsg2();

    void write_smsg();
    void write_smsg1();
    void write_smsg2();

    void write_scroll();

    void write_info();
    void write_info1();
    void write_info2();
    void write_info3();
    void write_info4();

    void write_led();

    void write_rgb();
    void write_leftrgb();
    void write_rightrgb();

    void nsmsg();
    void smsg();
    void scroll();
    void info();
    void contacts();
    void led();
    void rgb();

signals:
    void finished();
};
