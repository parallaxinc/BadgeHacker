#pragma once

#include <QDialog>
#include <QTimer>
#include <QLoggingCategory>
#include <QProgressDialog>
#include <QMap>

#include <PropellerSession>

Q_DECLARE_LOGGING_CATEGORY(badge)

class Badge : public PropellerSession
{
    Q_OBJECT


private:
    PropellerManager * manager;

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

public:
    explicit Badge(PropellerManager * manager,
            const QString & portname = QString(),
            QObject *parent = 0);
    ~Badge();

    QStringList colors();
    QMap<QString, QString> firmware();


public slots:
    void wipe();
    void start_ready(int milliseconds = 5000);
    void wait_for_ready();

    void write_nsmsg(const QString & line1, const QString & line2);
    void write_nsmsg1(const QString & text);
    void write_nsmsg2(const QString & text);

    void write_smsg(const QString & line1, const QString & line2);
    void write_smsg1(const QString & text);
    void write_smsg2(const QString & text);

    void write_scroll(bool enabled);

    void write_info(const QStringList & strings);
    void write_info1(const QString & text);
    void write_info2(const QString & text);
    void write_info3(const QString & text);
    void write_info4(const QString & text);

    void write_led(QList<bool> leds);

    void write_rgb(const QString & left, const QString & right);
    void write_leftrgb (const QString & color);
    void write_rightrgb(const QString & color);

    bool ping();
    bool firmwareNotFound();
    bool badgeNotFound();
    bool program();
    bool notFound(const QString & title,
            const QString & text);

    void wait_for_write();
    void ready();

    void read_line();
    bool read_data(const QString & cmd = QString(), int timeout = 1000);

    void write_line(const QString & line);

    void write_oneitem_line(const QString & cmd, 
                            const QString & line1);

    void write_twoitem_line(const QString & cmd, 
                            const QString & line1,
                            const QString & line2);

    bool blank();

    QStringList         nsmsg();
    QStringList         smsg();
    bool                scroll();
    QStringList         info();
    QList<QStringList>  contacts();
    QList<bool>         led();
    QStringList         rgb();

signals:
    void finished();
};