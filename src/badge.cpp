#include "badge.h"

#include <QDebug>
#include <QEventLoop>
#include <QStringList>
#include <QFileDialog>
#include <QMessageBox>
#include <QPixmap>
#include <QTextStream>
#include <QMessageBox>
#include <QRegularExpression>

#include <PropellerLoader>
#include <PropellerImage>


Q_LOGGING_CATEGORY(badge, "badgehacker.badge")

Badge::Badge(PropellerManager * manager,
        const QString & portname,
        QObject *parent)
: PropellerSession(manager, portname, parent)
{
    this->manager = manager;

    _expected = firmware();

    read_timeout = 50;
    ledpattern = QString(6,'0');

    colornames << "black" << "blue" << "green" << "cyan" 
               << "red" << "magenta" << "yellow" << "white";

    connect(this, SIGNAL(readyRead()), this, SLOT(read_line()));
    connect(&readyTimer, SIGNAL(timeout()), this, SLOT(ready()));

    readyTimer.setSingleShot(true);

    reset();
    start_ready();
}

Badge::~Badge()
{
}

void Badge::start_ready(int milliseconds)
{
    _ready = false;
    readyTimer.start(milliseconds);
}

void Badge::ready()
{
    _ready = true;
}

void Badge::read_line()
{
    QByteArray data = readAll();
    reply += data;
//    qDebug() << "NEWDATA" << reply.toLatin1().toHex();
    foreach(char c, data)
    {
        if (c == 12) // CRLDN
        {
//            qDebug() << "CLRDN received";
            ack = true;
            timer.start(10);
            emit finished();
            return;
        }
    }

//    timer.start(read_timeout);
}

bool Badge::read_data(const QString & cmd, int timeout)
{
    ack = false;
    timer.start(timeout);

    QEventLoop loop;
    connect(this, SIGNAL(finished()), &loop, SLOT(quit()));
    connect(&timer, SIGNAL(timeout()), &loop, SLOT(quit()));

    write_line(cmd);
    wait_for_write();

    loop.exec();

    rawreply = reply;
    reply = reply.mid(reply.indexOf(16), reply.lastIndexOf(12)); //16,"CLS"   12,"CLRDN"
    reply = reply.remove(16).remove(12);
    replystrings = reply.split("\r",QString::KeepEmptyParts);

    foreach(QString s, replystrings)
    {
        qCDebug(badge) << "    -" << qPrintable(s);
    }

    disconnect(this, SIGNAL(finished()), &loop, SLOT(quit()));
    disconnect(&timer, SIGNAL(timeout()), &loop, SLOT(quit()));

    timer.stop();
//    qCDebug(badge) << "ACK" << ack;
    return ack;
}

bool Badge::blank()
{
    start_ready();

    PropellerLoader loader(manager, portName());

    bool ldr = loader.version();
    if (!ldr)
    {
        qDebug() << "Failed to detect hardware";
        return false;
    }
    else
    {
        qCDebug(badge) << "hardware found";
    }
    reset();
    _ready = read_data(QString(), 6000);
    readyTimer.stop();

    return _ready;
}

QStringList Badge::nsmsg()
{
    read_data("nsmsg");
    if (replystrings.size() < 2) return QStringList();
    return replystrings;
}

QStringList Badge::smsg()
{
    read_data("smsg");
    if (replystrings.size() < 2) return QStringList();
    return replystrings;
}

bool Badge::scroll()
{
    read_data("scroll");
    if (replystrings.size() < 1) return false;

    QString yesno = replystrings[0].toLower();
    return yesno == "yes";
}

QStringList Badge::info()
{
    read_data("info");
    if (replystrings.size() < 4) return QStringList();
    return replystrings;
}

QList<bool> Badge::led()
{
    read_data("led");

    if (replystrings.size() < 1) return QList<bool>();
    ledpattern = replystrings[0];
    ledpattern.remove(0, 1);

    QList<bool> leds;

    foreach(QChar c, ledpattern)
    {
        leds.append(c == '1');
    }

    return leds;
}

const QString Badge::rgbPatternToString(const QString & string)
{
    QString color;
    int i = string.toInt();
    switch (i)
    {
        case   0: color = "black";  break ;;
        case   1: color = "blue";   break ;;
        case  10: color = "green";  break ;;
        case  11: color = "cyan";   break ;;
        case 100: color = "red";    break ;;
        case 101: color = "magenta";break ;;
        case 110: color = "yellow"; break ;;
        case 111: color = "white";  break ;;
    }
    return color;
}

QStringList Badge::rgb()
{
    read_data("rgb");

    if (replystrings.size() < 1) return QStringList();
    QString colors = replystrings[0].remove(0,1);
    QStringList rgbs;
    rgbs.append(rgbPatternToString(colors.left(3)) );
    rgbs.append(rgbPatternToString(colors.right(3)));
    return rgbs;
}

QMap<QString, QString> Badge::firmware()
{
    QFile file(":/spin/jm_hackable_ebadge.spin");
    file.open(QFile::ReadOnly);
    QString text = file.readAll();
    file.close();

    QString exp;
    exp += "DATE_CODE\\s+byte\\s+\"";
    exp += "(.+?)";
    exp += "\"\\s*,\\s*0";
    QRegularExpression re(exp);
    QRegularExpressionMatch match = re.match(text);

    qCDebug(badge) << "firmware:" << qPrintable(match.captured(1));

    return parseFirmwareString(match.captured(1));
}

QMap<QString, QString> Badge::parseFirmwareString(const QString & text)
{
    QString exp;
    exp += "(\\w+) ";                               // company
    exp += "(\\w+)";                                // name

    exp += "\\s+\\(\\s*";

    exp += "v(\\d+)\\.(\\d+)\\s+";                   // firmware, protocol
    exp += "(\\d\\d\\d\\d)-(\\d\\d)-(\\d\\d)";      // year, month, day

    exp += "\\s*\\)\\s*";

    QRegularExpression re(exp);
    QRegularExpressionMatch match = re.match(text);

//    foreach (QString s, match.capturedTexts())
//        qDebug() << s;

    QMap<QString, QString> map;

    map["company"]  = match.captured(1);
    map["product"]  = match.captured(2);
    map["firmware"] = match.captured(3);
    map["protocol"] = match.captured(4);
    map["year"]     = match.captured(5);
    map["month"]    = match.captured(6);
    map["day"]      = match.captured(7);

    return map;
}


bool Badge::badgeNotFound()
{
    QMessageBox::critical(0,
            tr("Badge Not Found!"),
            tr("There doesn't appear to be a badge attached. "
               "Please make sure that the power is on!"));
    return false;
}

bool Badge::firmwareNotFound()
{
    return notFound(
            tr("No Firmware Detected"),
            tr("Badge detected no firmware on the badge. "
               "Would you like to install new firmware?"));
}

bool Badge::notFound(const QString & title,
        const QString & text)
{
    QMessageBox box(QMessageBox::Warning, title, text);
    box.setStandardButtons(QMessageBox::Yes | QMessageBox::No);

    int ret = box.exec();
    if (ret == QMessageBox::Yes)
    {
        if (!program())
        {
            return badgeNotFound();
        }

        return blank();
    }
    else
        return false;
}

bool Badge::ping()
{
    if (!isOpen())
        blank();

    if (!_ready)
    {
        if (readyTimer.isActive())
            wait_for_ready();
        else
            blank();
    }

    if (!read_data("ping"))
    {
        if (!blank())
        {
            return badgeNotFound();
        }
        else
        {
            if (!read_data("ping"))
            {
                return firmwareNotFound();
            }

        }
    }

    if ( rawreply.isEmpty() 
            || replystrings.size() < 1 )
    {
        return firmwareNotFound();
    }

    QMap<QString, QString> version = parseFirmwareString(replystrings[0]);

    if ( version != _expected )
    {
        QString versionstring;

        if (version["firmware"].isEmpty() || version["protocol"].isEmpty())
            versionstring = "None";
        else
            versionstring = "v"+version["firmware"]+"."+version["protocol"];

        if (!notFound(
                tr("Install New Firmware?"),
                tr("Unexpected badge firmware detected:\n\n"
                   "Found: %1\n"
                   "Expected: v%2.%3\n\n"
                   "Would you like to install new firmware?")
                        .arg(versionstring)
                        .arg(_expected["firmware"]).arg(_expected["protocol"])))
        {
            if (version["protocol"] != _expected["protocol"])
                return false;
            else
                return true;
        }
    }

    return true;
}


QList<QStringList> Badge::contacts()
{
    read_data("contacts");

    // validate contacts

    if (replystrings.size() < 3) return QList<QStringList>();

    QStringList totalstrings = replystrings[0].split(' ');
    if (totalstrings.size() < 6) return QList<QStringList>();
    
    replystrings.removeAt(0);
    replystrings.removeAt(0);
    replystrings.removeLast();

    if (replystrings.size() < 5) return QList<QStringList>();
    if (replystrings.size() % 5 != 0) return QList<QStringList>();

    int total_contacts = replystrings.size() / 5;

    bool ok;
    int expected_contacts = totalstrings[0].toInt(&ok);     if (!ok) return QList<QStringList>();

    if (total_contacts != expected_contacts) return QList<QStringList>();

    // process contact list

    QString previous;
    contactlist.clear();

    for (int i = 0; i < total_contacts; i++)
    {
        QStringList contact;

        for (int j = 0;  j < 5; j++)
        {
            if (!replystrings[i*5 + j].isEmpty())
                contact.append(replystrings[i*5 + j]);
        }

        if (!contact.isEmpty())
        {
            if (QString::localeAwareCompare(contact[0], previous) < 0)
                contactlist.prepend(contact);
            else
                contactlist.append(contact);

            previous = contact[0];
        }
    }

    return contactlist;
}

void Badge::wait_for_ready()
{
    if (readyTimer.isActive())
    {
        QEventLoop loop;
        connect(&readyTimer, SIGNAL(timeout()), &loop, SLOT(quit()));
        loop.exec();
        disconnect(&readyTimer, SIGNAL(timeout()), &loop, SLOT(quit()));
    }
}

void Badge::wait_for_write()
{
    if (updateTimer.isActive())
    {
        QTimer wait;
        QEventLoop loop;
        connect(&wait, SIGNAL(timeout()), &loop, SLOT(quit()));
    //    wait.start(calculateTimeout(line.size())+10*line.size());
        wait.start(updateTimer.remainingTime());
        loop.exec();
        disconnect(&wait, SIGNAL(timeout()), &loop, SLOT(quit()));
    }
}

void Badge::write_line(const QString & line)
{
    wait_for_write();

    reply.clear();
    QString s = line;
    s += "\n";
    qCDebug(badge) << "-" << qPrintable(line);
    write(s.toLocal8Bit());

    updateTimer.start(25);  //session->calculateTimeout(line.size()));
    start_ready(2000);              // wait before refreshing
}

void Badge::write_oneitem_line(const QString & cmd, 
                                     const QString & line1)
{
    write_line(QString("%1 \"%2\"").arg(cmd)
                                     .arg(line1));
}


void Badge::write_twoitem_line(const QString & cmd, 
                                     const QString & line1,
                                     const QString & line2)
{
    write_line(QString("%1 \"%2\" \"%3\"").arg(cmd)
                                            .arg(line1)
                                            .arg(line2));
}

void Badge::write_nsmsg1(const QString & text) { write_oneitem_line("nsmsg 1",text); }
void Badge::write_nsmsg2(const QString & text) { write_oneitem_line("nsmsg 2",text); }

void Badge::write_nsmsg(const QString & line1, const QString & line2)
{
    write_twoitem_line("nsmsg", line1, line2);
}

void Badge::write_smsg1(const QString & text) { write_oneitem_line("smsg 1",text); }
void Badge::write_smsg2(const QString & text) { write_oneitem_line("smsg 2",text); }

void Badge::write_smsg (const QString & line1, const QString & line2)
{
    write_twoitem_line("smsg",line1, line2);
}

void Badge::write_scroll(bool enabled)
{
    if (enabled)
        write_oneitem_line("scroll","yes");
    else
        write_oneitem_line("scroll","no");
}

void Badge::write_info1(const QString & text) { write_oneitem_line("info 1",text); }
void Badge::write_info2(const QString & text) { write_oneitem_line("info 2",text); }
void Badge::write_info3(const QString & text) { write_oneitem_line("info 3",text); }
void Badge::write_info4(const QString & text) { write_oneitem_line("info 4",text); }

void Badge::write_info(const QStringList & strings)
{
    if (strings.size() < 4) return;
    write_line(QString("info \"%1\" \"%2\" \"%3\" \"%4\"")
                                            .arg(strings[0])
                                            .arg(strings[1])
                                            .arg(strings[2])
                                            .arg(strings[2]));
}

void Badge::write_led(QList<bool> leds)
{
    if (leds.size() < 6) return;

    for (int i = 0; i < 6; i++)
    {
        ledpattern[i] = leds[i] ? '1' : '0';
    }

    write_line(QString("led all \%%1").arg(ledpattern));
}

void Badge::write_leftrgb(const QString & color)  { write_oneitem_line("rgb left", color); }
void Badge::write_rightrgb(const QString & color) { write_oneitem_line("rgb right",color); }
void Badge::write_rgb(const QString & left, const QString & right)
{
    write_twoitem_line("rgb",left,right);
}

void Badge::wipe()
{
    if (ping())
    {
        write_line("contacts wipe");

        for (int i = 0; i < 100; i++)
        {
            start_ready(120);
            wait_for_ready();
        }
    }
}


QStringList Badge::colors()
{
    return colornames;
}


bool Badge::program()
{
    qCDebug(badge) << "program()" << portName();

    PropellerLoader loader(manager, portName());

    QFile file(":/spin/jm_hackable_ebadge.binary");
    file.open(QIODevice::ReadOnly);
    PropellerImage image = PropellerImage(file.readAll());
    if (!loader.upload(image, true))
        return false;

    return true;
}

