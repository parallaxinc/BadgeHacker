#pragma once

#include <QDialog>
#include <QTimer>
#include <QLoggingCategory>
#include <QProgressDialog>
#include <QMap>

#include <PropellerSession>

#include "ui_badgehacker.h"

Q_DECLARE_LOGGING_CATEGORY(badgehacker)

class BadgeHacker : public QWidget 
{
    Q_OBJECT

private:
    Ui::BadgeHacker ui;
    PropellerManager * manager;
    PropellerSession * session;

    QMap<QString, QString> _expected;
    QString rawreply;
    QString reply;
    QStringList replystrings;
    QTimer timer;
    QTimer updateTimer;
    bool _ready;
    QTimer readyTimer;
    int read_timeout;
    bool ack;
    QString ledpattern;
    QStringList colornames;
    QList<QStringList> contactlist;
    QStringList allcontacts;

    const QString rgbPatternToString(const QString & string);
    QMap<QString, QString> parseFirmwareString(const QString & text);
    QMap<QString, QString> firmware();

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

    void configure();
    void refresh();
    void update(QProgressDialog * progress);
    bool program(QProgressDialog * progress);
    void clear();
    void saveContacts();
    void showContact(int index);

    void wait_for_write();
    void wait_for_ready();
    void ready();
    void start_ready(int milliseconds = 5000);

    void read_line();
    bool read_data(const QString & cmd = QString(), int timeout = 1000);

    void write_line(const QString & line);

    void write_oneitem_line(const QString & cmd, 
                            const QString & line1);

    void write_twoitem_line(const QString & cmd, 
                            const QString & line1,
                            const QString & line2);
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

    bool blank();
    bool ping(QProgressDialog * progress);
    bool notFound(const QString & title,
            const QString & text,
            QProgressDialog * progress);

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
