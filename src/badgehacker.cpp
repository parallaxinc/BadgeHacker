#include "badgehacker.h"

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

Q_LOGGING_CATEGORY(badgehacker, "app.badgehacker")

BadgeHacker::BadgeHacker(PropellerManager * manager,
                   QWidget *parent)
: QWidget(parent)
{
    ui.setupUi(this);

    _expected = firmware();

    read_timeout = 50;
    ledpattern = QString(6,'0');

    this->manager = manager;
    session = new PropellerSession(manager);

    colornames << "black" << "blue" << "green" << "cyan" 
               << "red" << "magenta" << "yellow" << "white";

    foreach (const QString & colorname, colornames) {
            const QColor color(colorname);

            QPixmap pix(24,24);

            pix.fill(QColor(colorname));

            ui.leftRgb->addItem(pix,colorname);
            ui.rightRgb->addItem(pix, colorname);
    }

    updatePorts();
    ui.contacts->clear();
    ui.contactList->clear();

    connect(ui.contactList, SIGNAL(currentRowChanged(int)), this, SLOT(showContact(int)));

    connect(manager, SIGNAL(portListChanged()), this, SLOT(updatePorts()));
    connect(session, SIGNAL(sendError(const QString &)), this, SLOT(handleError()));
    connect(session, SIGNAL(readyRead()), this, SLOT(read_line()));

    connect(ui.port, SIGNAL(currentIndexChanged(const QString &)), this, SLOT(portChanged()));
    connect(ui.configure, SIGNAL(clicked()), this, SLOT(configure()));
    connect(ui.saveContacts, SIGNAL(clicked()), this, SLOT(saveContacts()));

    connect(ui.refresh, SIGNAL(clicked()), this, SLOT(refresh()));
    connect(ui.activeButton, SIGNAL(toggled(bool)), this, SLOT(handleEnable(bool)));

    session->reset();
    readyTimer.setSingleShot(true);

    start_ready();
    connect(&readyTimer, SIGNAL(timeout()), this, SLOT(ready()));
}

BadgeHacker::~BadgeHacker()
{
    closed();

    delete session;
}

void BadgeHacker::updatePorts()
{
    ui.port->clear();
    QStringList ports = manager->listPorts();
    if (!ports.isEmpty())
    {
        ui.port->setEnabled(true);
        ui.refresh->setEnabled(true);
        foreach(QString p, ports)
        {
            ui.port->addItem(p);
        }
        open();
    }
    else
    {
        ui.port->setEnabled(false);
        ui.refresh->setEnabled(false);
        closed();
    }
}

void BadgeHacker::start_ready(int milliseconds)
{
    _ready = false;
    readyTimer.start(milliseconds);
}

void BadgeHacker::ready()
{
    _ready = true;
}

void BadgeHacker::refresh()
{
    qCDebug(badgehacker) << "refresh()";

    setEnabled(false);
    
    QProgressDialog * progress = new QProgressDialog(this, Qt::WindowStaysOnTopHint);
    progress->setCancelButton(0);
    progress->setWindowTitle(tr("Loading..."));
    progress->setLabelText(tr("Waiting for badge..."));
    progress->setValue(0);
    progress->show();

    clear();

    if (ping(progress))
        update(progress);

    progress->setValue(100);
    progress->hide();

    delete progress;

    setEnabled(true);
}

void BadgeHacker::handleEnable(bool checked)
{
    if (checked)
        open();
    else
        closed();
}


void BadgeHacker::open()
{
    portChanged();
    session->unpause();
    ui.activeLight->setPixmap(QPixmap(":/icons/badgehacker/led-green.png"));

    setEnabled(true);
}

void BadgeHacker::closed()
{
    session->pause();
    clear();
    ui.activeLight->setPixmap(QPixmap(":/icons/badgehacker/led-off.png"));

    setEnabled(false);
}

void BadgeHacker::portChanged()
{
    session->setPortName(ui.port->currentText());
    qCDebug(badgehacker) << "New port:" << session->portName();
}

void BadgeHacker::handleError()
{
    closed();
}

void BadgeHacker::read_line()
{
    QByteArray data = session->readAll();
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

bool BadgeHacker::read_data(const QString & cmd, int timeout)
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
        qCDebug(badgehacker) << "    -" << qPrintable(s);
    }

    disconnect(this, SIGNAL(finished()), &loop, SLOT(quit()));
    disconnect(&timer, SIGNAL(timeout()), &loop, SLOT(quit()));

    timer.stop();
//    qCDebug(badgehacker) << "ACK" << ack;
    return ack;
}

bool BadgeHacker::blank()
{
    start_ready();
    session->reset();
    _ready = read_data(QString(), 5000);
    readyTimer.stop();

    return _ready;
}

void BadgeHacker::nsmsg()
{
    read_data("nsmsg");
    if (replystrings.size() < 2) return;
    ui.nsmsgLine1->setText(replystrings[0]);
    ui.nsmsgLine2->setText(replystrings[1]);

    ui.nsmsgLine1->setEnabled(true);
    ui.nsmsgLine2->setEnabled(true);
}

void BadgeHacker::smsg()
{
    read_data("smsg");
    if (replystrings.size() < 2) return;
    ui.smsgLine1->setText(replystrings[0]);
    ui.smsgLine2->setText(replystrings[1]);

    ui.smsgLine1->setEnabled(true);
    ui.smsgLine2->setEnabled(true);
}

void BadgeHacker::scroll()
{
    read_data("scroll");
    if (replystrings.size() < 1) return;

    QString yesno = replystrings[0].toLower();

    if (yesno == "yes")
        ui.scroll->setChecked(true);
    else
        ui.scroll->setChecked(false);

    ui.scroll->setEnabled(true);
}

void BadgeHacker::info()
{
    read_data("info");
    if (replystrings.size() < 4) return;
    ui.infoLine1->setText(replystrings[0]);
    ui.infoLine2->setText(replystrings[1]);
    ui.infoLine3->setText(replystrings[2]);
    ui.infoLine4->setText(replystrings[3]);

    ui.infoLine1->setEnabled(true);
    ui.infoLine2->setEnabled(true);
    ui.infoLine3->setEnabled(true);
    ui.infoLine4->setEnabled(true);
}

void BadgeHacker::led()
{
    read_data("led");

    if (replystrings.size() < 1) return;
    ledpattern = replystrings[0];
    ledpattern.remove(0, 1);

    ui.led1->setChecked(ledpattern[0] == '1' ? true : false);
    ui.led2->setChecked(ledpattern[1] == '1' ? true : false);
    ui.led3->setChecked(ledpattern[2] == '1' ? true : false);
    ui.led4->setChecked(ledpattern[3] == '1' ? true : false);
    ui.led5->setChecked(ledpattern[4] == '1' ? true : false);
    ui.led6->setChecked(ledpattern[5] == '1' ? true : false);

    ui.led1->setEnabled(true);
    ui.led2->setEnabled(true);
    ui.led3->setEnabled(true);
    ui.led4->setEnabled(true);
    ui.led5->setEnabled(true);
    ui.led6->setEnabled(true);
}

const QString BadgeHacker::rgbPatternToString(const QString & string)
{
    QString color;
    int i = string.toInt();
    switch (i)
    {
        case 0:   color = "black";  break ;;
        case 1:   color = "blue";   break ;;
        case 10:  color = "green";  break ;;
        case 11:  color = "cyan";   break ;;
        case 100: color = "red";    break ;;
        case 101: color = "magenta";break ;;
        case 110: color = "yellow"; break ;;
        case 111: color = "white";  break ;;
    }
    return color;
}

void BadgeHacker::rgb()
{
    read_data("rgb");

    if (replystrings.size() < 1) return;
    QString colors = replystrings[0].remove(0,1);
    ui.leftRgb->setCurrentIndex( ui.leftRgb->findText( rgbPatternToString(colors.left(3))));
    ui.rightRgb->setCurrentIndex(ui.rightRgb->findText(rgbPatternToString(colors.right(3))));

    ui.leftRgb->setEnabled(true);
    ui.rightRgb->setEnabled(true);
}

bool BadgeHacker::notFound(const QString & title,
        const QString & text,
        QProgressDialog * progress)
{
    QMessageBox box(QMessageBox::Warning, title, text);
    box.setStandardButtons(QMessageBox::Yes | QMessageBox::No);

    progress->hide();
    
    int ret = box.exec();
    if (ret == QMessageBox::Yes)
    {
        progress->show();

        if (!program(progress))
        {
            QMessageBox::critical(this,
                    tr("Badge Not Found!"),
                    tr("There doesn't appear to be a badge attached. "
                       "Please make sure that the power is on!"));

            return false;
        }

        return blank();
    }
    else
        return false;
}

const QString BadgeHacker::firmware()
{
    QFile file(":/spin/jm_hackable_ebadge.spin");
    file.open(QFile::ReadOnly);
    QString text = file.readAll();
    file.close();

    QRegularExpression re("^\\s+DATE_CODE\\s+byte\\s+\"(.*?)\"\\s*,\\s*0\\s+.*$");
    re.setPatternOptions(QRegularExpression::MultilineOption);
    QRegularExpressionMatch match = re.match(text);

    if (match.hasMatch())
        return match.captured(1);
    else
        return QString();
}

bool BadgeHacker::ping(QProgressDialog * progress)
{
    if (!session->isOpen())
        blank();

    if (!_ready)
    {
        if (readyTimer.isActive())
            wait_for_ready();
        else
            blank();
    }

    // attempt ping three times
    progress->setLabelText(tr("Connecting to badge..."));
 
    if (!read_data("ping"))
    {
        read_data(QString(), 5000);
        read_data("ping");
    }

    QString version = replystrings[0];

    if ( rawreply.isEmpty() 
            || replystrings.size() < 1 )
    {
        return notFound(
                tr("No Firmware Detected"),
                tr("BadgeHacker detected no firmware on the badge. "
                   "Would you like to install new firmware?\n\n"
                   "NOTE: This will overwrite all contacts!"),
                progress);
    }

    if ( version != _expected )
    {
        return notFound(
                tr("Install New Firmware?"),
                tr("Unexpected badge firmware detected:\n\n"
                   "Found: %1\n"
                   "Expected: %2\n\n"
                   "Would you like to install new firmware?\n\n"
                   "NOTE: This will overwrite all contacts!")
                        .arg(version).arg(_expected),
                progress);
    }

    return true;
}

void BadgeHacker::contacts()
{
    ui.contacts->clear();

    // QListWidget::clear() is buggy
    disconnect(ui.contactList, SIGNAL(currentRowChanged(int)), this, SLOT(showContact(int)));
    ui.contactList->clearSelection();
    ui.contactList->clearFocus();
    ui.contactList->clear();
    connect(ui.contactList, SIGNAL(currentRowChanged(int)), this, SLOT(showContact(int)));

    read_data("contacts");

    // validate contacts

    if (replystrings.size() < 3)
    {
        ui.contacts_count->setText(tr("0 Contacts"));
        return;
    }
    
    replystrings.removeAt(0);
    replystrings.removeAt(0);
    replystrings.removeLast();

    if (replystrings.size() < 5) return;
    if (replystrings.size() % 5 != 0) return;

    // process contact list

    int total_contacts = replystrings.size() / 5;
    ui.contacts_count->setText(tr("%1 Contacts").arg(total_contacts));

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

    foreach (QStringList s, contactlist)
        ui.contactList->addItem(s[0]);

    ui.contactList->setCurrentRow(0);
}

void BadgeHacker::showContact(int index)
{
    ui.contacts->clear();

    if (index >= contactlist.size()) return;

    foreach (QString s, contactlist[index])
    {
        ui.contacts->appendPlainText(s);
    }

    ui.contacts->setEnabled(true);
}

void BadgeHacker::wait_for_ready()
{
    if (readyTimer.isActive())
    {
        QEventLoop loop;
        connect(&readyTimer, SIGNAL(timeout()), &loop, SLOT(quit()));
        loop.exec();
        disconnect(&readyTimer, SIGNAL(timeout()), &loop, SLOT(quit()));
    }
}

void BadgeHacker::wait_for_write()
{
    if (updateTimer.isActive())
    {
        QTimer wait;
        QEventLoop loop;
        connect(&wait, SIGNAL(timeout()), &loop, SLOT(quit()));
    //    wait.start(session->calculateTimeout(line.size())+10*line.size());
        wait.start(updateTimer.remainingTime());
        loop.exec();
        disconnect(&wait, SIGNAL(timeout()), &loop, SLOT(quit()));
    }
}

void BadgeHacker::write_line(const QString & line)
{
    wait_for_write();

    reply.clear();
    QString s = line;
    s += "\n";
    qCDebug(badgehacker) << "-" << qPrintable(line);
    session->write(s.toLocal8Bit());

    updateTimer.start(25);  //session->calculateTimeout(line.size()));
    start_ready(2000);              // wait before refreshing
}

void BadgeHacker::write_oneitem_line(const QString & cmd, 
                                     const QString & line1)
{
    write_line(QString("%1 \"%2\"").arg(cmd)
                                     .arg(line1));
}


void BadgeHacker::write_twoitem_line(const QString & cmd, 
                                     const QString & line1,
                                     const QString & line2)
{
    write_line(QString("%1 \"%2\" \"%3\"").arg(cmd)
                                            .arg(line1)
                                            .arg(line2));
}

void BadgeHacker::write_nsmsg1() { write_oneitem_line("nsmsg 1",ui.nsmsgLine1->text()); }
void BadgeHacker::write_nsmsg2() { write_oneitem_line("nsmsg 2",ui.nsmsgLine2->text()); }

void BadgeHacker::write_nsmsg()
{
    write_twoitem_line("nsmsg",ui.nsmsgLine1->text(),ui.nsmsgLine2->text());
}

void BadgeHacker::write_smsg1() { write_oneitem_line("smsg 1",ui.smsgLine1->text()); }
void BadgeHacker::write_smsg2() { write_oneitem_line("smsg 2",ui.smsgLine2->text()); }

void BadgeHacker::write_smsg()
{
    write_twoitem_line("smsg",ui.smsgLine1->text(),ui.smsgLine2->text());
}

void BadgeHacker::write_scroll()
{
    if (ui.scroll->isChecked())
        write_oneitem_line("scroll","yes");
    else
        write_oneitem_line("scroll","no");
}

void BadgeHacker::write_info1() { write_oneitem_line("info 1",ui.infoLine1->text()); }
void BadgeHacker::write_info2() { write_oneitem_line("info 2",ui.infoLine2->text()); }
void BadgeHacker::write_info3() { write_oneitem_line("info 3",ui.infoLine3->text()); }
void BadgeHacker::write_info4() { write_oneitem_line("info 4",ui.infoLine4->text()); }

void BadgeHacker::write_info()
{
    write_line(QString("info \"%1\" \"%2\" \"%3\" \"%4\"")
                                            .arg(ui.infoLine1->text())
                                            .arg(ui.infoLine2->text())
                                            .arg(ui.infoLine3->text())
                                            .arg(ui.infoLine4->text()));
}

void BadgeHacker::write_led()
{
    ledpattern[0] = ui.led1->isChecked() ? '1' : '0';
    ledpattern[1] = ui.led2->isChecked() ? '1' : '0';
    ledpattern[2] = ui.led3->isChecked() ? '1' : '0';
    ledpattern[3] = ui.led4->isChecked() ? '1' : '0';
    ledpattern[4] = ui.led5->isChecked() ? '1' : '0';
    ledpattern[5] = ui.led6->isChecked() ? '1' : '0';

    write_line(QString("led all \%%1").arg(ledpattern));
}

void BadgeHacker::write_rgb()
{
    write_twoitem_line("rgb",ui.leftRgb->currentText(),ui.rightRgb->currentText());
}

void BadgeHacker::write_leftrgb()  { write_oneitem_line("rgb left", ui.leftRgb->currentText());  }
void BadgeHacker::write_rightrgb() { write_oneitem_line("rgb right",ui.rightRgb->currentText()); }

void BadgeHacker::setEnabled(bool enabled)
{
    if (!enabled)
    {
        disconnect(ui.nsmsgLine1,  SIGNAL(editingFinished()), this, SLOT(write_nsmsg1()));
        disconnect(ui.nsmsgLine2,  SIGNAL(editingFinished()), this, SLOT(write_nsmsg2()));

        disconnect(ui.smsgLine1,   SIGNAL(editingFinished()), this, SLOT(write_smsg1()));
        disconnect(ui.smsgLine2,   SIGNAL(editingFinished()), this, SLOT(write_smsg2()));

        disconnect(ui.infoLine1,   SIGNAL(editingFinished()), this, SLOT(write_info1()));
        disconnect(ui.infoLine2,   SIGNAL(editingFinished()), this, SLOT(write_info2()));
        disconnect(ui.infoLine3,   SIGNAL(editingFinished()), this, SLOT(write_info3()));
        disconnect(ui.infoLine4,   SIGNAL(editingFinished()), this, SLOT(write_info4()));

        disconnect(ui.scroll,      SIGNAL(stateChanged(int)), this, SLOT(write_scroll()));

        disconnect(ui.led1,        SIGNAL(stateChanged(int)), this, SLOT(write_led()));
        disconnect(ui.led2,        SIGNAL(stateChanged(int)), this, SLOT(write_led()));
        disconnect(ui.led3,        SIGNAL(stateChanged(int)), this, SLOT(write_led()));
        disconnect(ui.led4,        SIGNAL(stateChanged(int)), this, SLOT(write_led()));
        disconnect(ui.led5,        SIGNAL(stateChanged(int)), this, SLOT(write_led()));
        disconnect(ui.led6,        SIGNAL(stateChanged(int)), this, SLOT(write_led()));

        disconnect(ui.leftRgb,     SIGNAL(currentIndexChanged(int)), this, SLOT(write_leftrgb()));
        disconnect(ui.rightRgb,    SIGNAL(currentIndexChanged(int)), this, SLOT(write_rightrgb()));
    }

    ui.scroll    ->setEnabled(enabled);
    ui.nsmsgLine1->setEnabled(enabled);
    ui.nsmsgLine2->setEnabled(enabled);
    ui.smsgLine1 ->setEnabled(enabled);
    ui.smsgLine2 ->setEnabled(enabled);

    ui.infoLine1 ->setEnabled(enabled);
    ui.infoLine2 ->setEnabled(enabled);
    ui.infoLine3 ->setEnabled(enabled);
    ui.infoLine4 ->setEnabled(enabled);

    ui.leftRgb->setEnabled(enabled);
    ui.rightRgb->setEnabled(enabled);

    ui.led1->setEnabled(enabled);
    ui.led2->setEnabled(enabled);
    ui.led3->setEnabled(enabled);
    ui.led4->setEnabled(enabled);
    ui.led5->setEnabled(enabled);
    ui.led6->setEnabled(enabled);

    ui.configure->setEnabled(enabled);

    ui.refresh->setEnabled(enabled);
    ui.port->setEnabled(enabled);

    if (enabled)
    {
        connect(ui.nsmsgLine1,  SIGNAL(editingFinished()), this, SLOT(write_nsmsg1()));
        connect(ui.nsmsgLine2,  SIGNAL(editingFinished()), this, SLOT(write_nsmsg2()));
    
        connect(ui.smsgLine1,   SIGNAL(editingFinished()), this, SLOT(write_smsg1()));
        connect(ui.smsgLine2,   SIGNAL(editingFinished()), this, SLOT(write_smsg2()));
    
        connect(ui.infoLine1,   SIGNAL(editingFinished()), this, SLOT(write_info1()));
        connect(ui.infoLine2,   SIGNAL(editingFinished()), this, SLOT(write_info2()));
        connect(ui.infoLine3,   SIGNAL(editingFinished()), this, SLOT(write_info3()));
        connect(ui.infoLine4,   SIGNAL(editingFinished()), this, SLOT(write_info4()));
    
        connect(ui.scroll,      SIGNAL(stateChanged(int)), this, SLOT(write_scroll()));
    
        connect(ui.led1,        SIGNAL(stateChanged(int)), this, SLOT(write_led()));
        connect(ui.led2,        SIGNAL(stateChanged(int)), this, SLOT(write_led()));
        connect(ui.led3,        SIGNAL(stateChanged(int)), this, SLOT(write_led()));
        connect(ui.led4,        SIGNAL(stateChanged(int)), this, SLOT(write_led()));
        connect(ui.led5,        SIGNAL(stateChanged(int)), this, SLOT(write_led()));
        connect(ui.led6,        SIGNAL(stateChanged(int)), this, SLOT(write_led()));
    
        connect(ui.leftRgb,     SIGNAL(currentIndexChanged(int)), this, SLOT(write_leftrgb()));
        connect(ui.rightRgb,    SIGNAL(currentIndexChanged(int)), this, SLOT(write_rightrgb()));
    }
}

void BadgeHacker::configure()
{
    qCDebug(badgehacker) << "configure()";

    write_scroll();
    write_nsmsg();
    write_smsg();
    write_info();
    write_rgb();
    write_led();
}

void BadgeHacker::update(QProgressDialog * progress)
{
    qCDebug(badgehacker) << "update()";

    progress->setValue(0);
    clear();

    progress->setLabelText(tr("Getting scroll enable..."));
    progress->setValue(10);
    scroll();

    progress->setLabelText(tr("Getting non-scrolling text..."));
    progress->setValue(20);
    nsmsg();

    progress->setLabelText(tr("Getting scrolling text..."));
    progress->setValue(40);
    smsg();

    progress->setLabelText(tr("Getting shareable info..."));
    progress->setValue(50);
    info();


    progress->setLabelText(tr("Getting LED config..."));
    progress->setValue(50);
    rgb();
    led();

    progress->setLabelText(tr("Getting contacts..."));
    progress->setValue(70);
    contacts();

    progress->setValue(100);
}

void BadgeHacker::clear()
{
    setEnabled(false);

    ui.nsmsgLine1->clear();
    ui.nsmsgLine2->clear();
    ui.smsgLine1->clear();
    ui.smsgLine2->clear();

    ui.infoLine1->clear();
    ui.infoLine2->clear();
    ui.infoLine3->clear();
    ui.infoLine4->clear();

    ui.scroll->setChecked(false);

    ui.contacts->clear();

    // QListWidget::clear() is buggy
    disconnect(ui.contactList, SIGNAL(currentRowChanged(int)), this, SLOT(showContact(int)));
    ui.contactList->clearSelection();
    ui.contactList->clearFocus();
    ui.contactList->clear();
    connect(ui.contactList, SIGNAL(currentRowChanged(int)), this, SLOT(showContact(int)));
}

bool BadgeHacker::program(QProgressDialog * progress)
{
    qCDebug(badgehacker) << "Programming badge on" << session->portName();

    progress->show();
    progress->setLabelText(tr("Writing badge firmware..."));
    progress->setValue(0);

    PropellerLoader loader(manager, ui.port->currentText());

    QFile file(":/spin/jm_hackable_ebadge.binary");
    file.open(QIODevice::ReadOnly);
    PropellerImage image = PropellerImage(file.readAll());
    if (!loader.upload(image, true))
        return false;

    progress->setLabelText(tr("Wiping contact database..."));
    progress->setValue(0);

    start_ready(15000);
    wait_for_ready();

    return true;
}

void BadgeHacker::saveContacts()
{
    qCDebug(badgehacker) << "Saving contacts from" << session->portName();

    QFileDialog dialog(this, tr("Save Contacts"), QDir::homePath()+"/contacts.txt", tr("Text Files (*.txt)"));
    dialog.setDefaultSuffix("txt");
    dialog.setAcceptMode(QFileDialog::AcceptSave);

    QString filename;
    if (dialog.exec())
        filename = dialog.selectedFiles()[0];

    if (filename.isEmpty())
        return;

    QFile file(filename);
    if (!file.open(QFile::WriteOnly | QFile::Text))
    {
        QMessageBox::warning(this, tr("Recent Files"),
                    tr("Cannot write file %1:\n%2.")
                    .arg(filename)
                    .arg(file.errorString()));
        return;
    }

    QTextStream out(&file);
    out.setCodec("UTF-8");

    out << "Contacts for " << ui.nsmsgLine1->text().trimmed() << " "
                           << ui.nsmsgLine2->text().trimmed() << "\n";
    out << "-----------------------------------------------\n";
    out << "Generated by BadgeHacker, (C) 2015 Parallax Inc\n";
    out << "-----------------------------------------------\n\n";

    out << contactlist.size() << " contacts\n\n";

    QChar previous;
    QChar next;

    foreach(QStringList contact, contactlist)
    {
        next = contact[0][0];
        if (next != previous)
        {
            out << next << "\n\n";
            previous = next;
        }

        foreach(QString s, contact)
        {
            out << "    " << s << "\n";
        }

        out << "\n";
    }

    out.flush();
    file.close();
}
