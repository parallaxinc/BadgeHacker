#include "badgehacker.h"

#include <QDebug>
#include <QEventLoop>
#include <QStringList>
#include <QFileDialog>
#include <QMessageBox>
#include <QPixmap>

#include "propellerloader.h"
#include "propellerimage.h"

Q_LOGGING_CATEGORY(badgehacker, "BadgeHacker")

BadgeHacker::BadgeHacker(PropellerManager * manager,
                   QWidget *parent)
: QWidget(parent)
{
    ui.setupUi(this);

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

    connect(manager, SIGNAL(portListChanged()), this, SLOT(updatePorts()));
    connect(session, SIGNAL(sendError(const QString &)), this, SLOT(handleError()));
    connect(session, SIGNAL(readyRead()), this, SLOT(read_line()));

    connect(ui.port, SIGNAL(currentIndexChanged(const QString &)), this, SLOT(portChanged()));
    connect(ui.configure, SIGNAL(clicked()), this, SLOT(configure()));
    connect(ui.program, SIGNAL(clicked()), this, SLOT(program()));
    connect(ui.update, SIGNAL(clicked()), this, SLOT(update()));
    connect(ui.refresh, SIGNAL(clicked()), this, SLOT(refresh()));
    connect(ui.saveContacts, SIGNAL(clicked()), this, SLOT(saveContacts()));

    ui.program->hide();
    ui.configure->hide();
    ui.update->hide();

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

    ui.contacts->clear();
    updatePorts();
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

void BadgeHacker::refresh()
{
    setEnabled(false);

    progress.setCancelButton(0);
    progress.setWindowTitle(tr("Loading..."));
    progress.setLabelText(tr("Waiting for badge..."));
    progress.show();

    if (blank())
        update();

    progress.setValue(100);
    progress.hide();

    setEnabled(true);
}

void BadgeHacker::open()
{
    ui.activeLight->setPixmap(QPixmap(":/icons/propterm/led-green.png"));
    portChanged();
    session->unpause();

    refresh();
}

void BadgeHacker::closed()
{
    ui.activeLight->setPixmap(QPixmap(":/icons/propterm/led-off.png"));
    session->pause();
}

void BadgeHacker::portChanged()
{
    session->setPortName(ui.port->currentText());
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

bool BadgeHacker::read_data(const QString & cmd)
{
    ack = false;
    timer.start(5000);

    QEventLoop loop;
    connect(this, SIGNAL(finished()), &loop, SLOT(quit()));
    connect(&timer, SIGNAL(timeout()), &loop, SLOT(quit()));

    write_line(cmd);
    wait_for_write();

    loop.exec();

    reply = reply.mid(reply.indexOf(16), reply.lastIndexOf(12)); //16,"CLS"   12,"CLRDN"
    reply = reply.remove(16).remove(12);
    replystrings = reply.split("\r",QString::KeepEmptyParts);

    foreach(QString s, replystrings)
    {
        qCDebug(badgehacker) << "  -" << qPrintable(s);
    }

    disconnect(this, SIGNAL(finished()), &loop, SLOT(quit()));
    disconnect(&timer, SIGNAL(timeout()), &loop, SLOT(quit()));

    timer.stop();
//    qDebug() << "ACK" << ack;
    return ack;
}

bool BadgeHacker::blank()
{
    session->reset();
    return read_data();
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

void BadgeHacker::contacts()
{
    read_data("contacts");

    QStringList contactlist = replystrings;
    
    if (contactlist.size() < 4) return;

    QStringList contactcount = contactlist[0].split(" ");
    if (contactcount.isEmpty()) return;

    ui.contacts_count->setText(tr("%1 Contacts").arg(contactcount[0]));

    contactlist.removeAt(0);
    contactlist.removeAt(0);

    ui.contacts->clear();
    foreach (QString s, contactlist)
    {
        ui.contacts->appendPlainText(s);
    }

    ui.contacts->setEnabled(true);
}

void BadgeHacker::wait_for_write()
{
    if (updateTimer.isActive())
    {
        QTimer wait;
        QEventLoop loop;
        connect(&wait, SIGNAL(timeout()), &loop, SLOT(quit()));
    //    wait.start(session->calculateTimeout(line.size())+10*line.size());
    //    qDebug() << session->calculateTimeout(line.size());
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

    updateTimer.start(session->calculateTimeout(line.size()));
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

void BadgeHacker::write_smsg1() { write_oneitem_line("smsg 1",ui.smsgLine1->text()); }
void BadgeHacker::write_smsg2() { write_oneitem_line("smsg 2",ui.smsgLine2->text()); }

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

void BadgeHacker::write_leftrgb()  { write_oneitem_line("rgb left", ui.leftRgb->currentText());  }
void BadgeHacker::write_rightrgb() { write_oneitem_line("rgb right",ui.rightRgb->currentText()); }

void BadgeHacker::setEnabled(bool enabled)
{
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

    ui.update->setEnabled(enabled);
    ui.configure->setEnabled(enabled);
    ui.program->setEnabled(enabled);
    ui.saveContacts->setEnabled(enabled);

    ui.refresh->setEnabled(enabled);
}

void BadgeHacker::configure()
{
    qCDebug(badgehacker) << "Configuring badge on" << session->portName();

    write_scroll();
    write_nsmsg1();
    write_nsmsg2();
    write_smsg1();
    write_smsg2();
    write_info1();
    write_info2();
    write_info3();
    write_info4();
    write_led();
    write_leftrgb();
    write_rightrgb();
}

void BadgeHacker::update()
{
    qCDebug(badgehacker) << "Getting info from" << session->portName();

    progress.show();
    progress.setValue(0);
    clear();

    progress.setLabelText(tr("Getting scroll enable..."));
    progress.setValue(50);
    scroll();

    progress.setLabelText(tr("Getting badge text..."));
    progress.setValue(20);
    nsmsg();

    progress.setLabelText(tr("Getting scrolling text..."));
    progress.setValue(40);
    smsg();

    progress.setLabelText(tr("Getting scroll enable..."));
    progress.setValue(60);
    info();

    progress.setLabelText(tr("Getting contacts..."));
    progress.setValue(70);
    contacts();

    progress.setValue(100);
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
}

void BadgeHacker::program()
{
    qCDebug(badgehacker) << "Programming badge on" << session->portName();
    PropellerLoader loader(manager, ui.port->currentText());

    QFile file(":/spin/jm_hackable_ebadge.binary");
    file.open(QIODevice::ReadOnly);

    PropellerImage image = PropellerImage(file.readAll());
    loader.upload(image, true);
}

void BadgeHacker::saveContacts()
{
    qCDebug(badgehacker) << "Saving contacts from" << session->portName();

    QString filename = QFileDialog::getSaveFileName(this,
            tr("Save File As..."), 
            QDir::homePath(), 
            tr("Text Files (*.txt)"));

    if (filename.isEmpty())
        return;

    filename += ".txt";

    QFile file(filename);
    if (!file.open(QFile::WriteOnly | QFile::Text))
    {
        QMessageBox::warning(this, tr("Recent Files"),
                    tr("Cannot write file %1:\n%2.")
                    .arg(filename)
                    .arg(file.errorString()));
        return;
    }

}
