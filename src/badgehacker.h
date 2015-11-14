#pragma once

#include <QDialog>
#include <QTimer>
#include <QLoggingCategory>
#include <QProgressDialog>

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

    QString rawreply;
    QString reply;
    QStringList replystrings;
    QTimer timer;
    QTimer updateTimer;
    QProgressDialog progress;
    int read_timeout;
    bool ack;
    QString ledpattern;
    const QString rgbPatternToString(const QString & string);
    QStringList colornames;

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
    bool program();
    void refresh();
    void reset();
    void update();
    void clear();
    void saveContacts();

    void read_line();
    bool read_data(const QString & cmd = QString(), int timeout = 300);

    void wait_for_write();
    void write_line(const QString & line);

    void write_oneitem_line(const QString & cmd, 
                            const QString & line1);

    void write_twoitem_line(const QString & cmd, 
                            const QString & line1,
                            const QString & line2);
    void write_nsmsg1();
    void write_nsmsg2();
    void write_smsg1();
    void write_smsg2();
    void write_scroll();
    void write_info1();
    void write_info2();
    void write_info3();
    void write_info4();
    void write_led();
    void write_leftrgb();
    void write_rightrgb();

    bool blank();
    bool ping();

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
