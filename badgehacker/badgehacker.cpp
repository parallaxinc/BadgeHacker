#include "badgehacker.h"

#include <QDebug>
#include <QEventLoop>
#include <QStringList>
#include <QFileDialog>
#include <QMessageBox>

#include "propellerloader.h"
#include "propellerimage.h"

Q_LOGGING_CATEGORY(badgehacker, "BadgeHacker")

BadgeHacker::BadgeHacker(PropellerManager * manager,
                   QWidget *parent)
: QDialog(parent)
{
    ui.setupUi(this);

    read_timeout = 50;

    this->manager = manager;
    session = new PropellerSession(manager);

    connect(manager, SIGNAL(portListChanged()), this, SLOT(updatePorts()));
    connect(session, SIGNAL(sendError(const QString &)), this, SLOT(handleError()));
    connect(session, SIGNAL(readyRead()), this, SLOT(read_line()));

    connect(ui.port, SIGNAL(currentIndexChanged(const QString &)), this, SLOT(portChanged()));
    connect(ui.configure, SIGNAL(clicked()), this, SLOT(configure()));
    connect(ui.program, SIGNAL(clicked()), this, SLOT(program()));
    connect(ui.update, SIGNAL(clicked()), this, SLOT(update()));
    connect(ui.saveContacts, SIGNAL(clicked()), this, SLOT(saveContacts()));

    ui.contacts->clear();
    updatePorts();
    open();
}

BadgeHacker::~BadgeHacker()
{
    close();
    delete session;
}

void BadgeHacker::updatePorts()
{
    ui.port->clear();
    foreach(QString s, manager->listPorts())
    {
        ui.port->addItem(s);
    }
}

void BadgeHacker::open()
{
    session->reset();
    ui.activeLight->setPixmap(QPixmap(":/icons/propterm/led-green.png"));
    portChanged();
    session->unpause();

    progress.setCancelButton(0);
    progress.setWindowTitle(tr("Loading..."));
    progress.setLabelText(tr("Waiting for badge..."));
    progress.show();

    QTimer wait;
    QEventLoop loop;

    connect(&updateTimer, SIGNAL(timeout()), &loop, SLOT(quit()));
    updateTimer.start(3500);
    loop.exec();
    update();

    disconnect(&updateTimer, SIGNAL(timeout()), &loop, SLOT(quit()));

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
    reply += session->readAll();
    timer.start(read_timeout);
}

void BadgeHacker::read_data(const QString & cmd)
{
    timer.start(500);
    reply.clear();

    write_line(cmd);

    QEventLoop loop;
    connect(&timer, SIGNAL(timeout()), &loop, SLOT(quit()));

    loop.exec();

    reply = reply.remove(16);
    replystrings = reply.split("\r",QString::KeepEmptyParts);
    foreach(QString s, replystrings)
    {
        qCDebug(badgehacker) << "  -" << qPrintable(s);
    }

    disconnect(&timer, SIGNAL(timeout()), &loop, SLOT(quit()));
    timer.stop();
}

void BadgeHacker::nsmsg()
{
    read_data("nsmsg");
    if (replystrings.size() < 2) return;
    ui.nsmsgLine1->setText(replystrings[0]);
    ui.nsmsgLine2->setText(replystrings[1]);
}

void BadgeHacker::smsg()
{
    read_data("smsg");
    if (replystrings.size() < 2) return;
    ui.smsgLine1->setText(replystrings[0]);
    ui.smsgLine2->setText(replystrings[1]);
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
}

void BadgeHacker::info()
{
    read_data("info");
    if (replystrings.size() < 4) return;
    ui.infoLine1->setText(replystrings[0]);
    ui.infoLine2->setText(replystrings[1]);
    ui.infoLine3->setText(replystrings[2]);
    ui.infoLine4->setText(replystrings[3]);
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
}

void BadgeHacker::write_line(const QString & line)
{
    QString s = line;
    s += "\n";
    qCDebug(badgehacker) << "-" << qPrintable(line);
    session->write(s.toLocal8Bit());

    QTimer wait;
    QEventLoop loop;
    connect(&wait, SIGNAL(timeout()), &loop, SLOT(quit()));
    wait.start(session->calculateTimeout(line.size())+10*line.size());
    loop.exec();
    disconnect(&wait, SIGNAL(timeout()), &loop, SLOT(quit()));
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

void BadgeHacker::write_nsmsg()
{
    write_oneitem_line("nsmsg 1",ui.nsmsgLine1->text());
    write_oneitem_line("nsmsg 2",ui.nsmsgLine2->text());
}

void BadgeHacker::write_smsg()
{
    write_oneitem_line("smsg 1",ui.smsgLine1->text());
    write_oneitem_line("smsg 2",ui.smsgLine2->text());
}

void BadgeHacker::write_scroll()
{
    if (ui.scroll->isChecked())
        write_oneitem_line("scroll","yes");
    else
        write_oneitem_line("scroll","no");
}

void BadgeHacker::write_info()
{
    write_oneitem_line("info 1",ui.infoLine1->text());
    write_oneitem_line("info 2",ui.infoLine2->text());
    write_oneitem_line("info 3",ui.infoLine3->text());
    write_oneitem_line("info 4",ui.infoLine4->text());
}

void BadgeHacker::setEnabled(bool enabled)
{
    ui.update->setEnabled(enabled);
    ui.configure->setEnabled(enabled);
    ui.program->setEnabled(enabled);
    ui.saveContacts->setEnabled(enabled);

}

void BadgeHacker::configure()
{
    qCDebug(badgehacker) << "Configuring badge on" << session->portName();

    write_nsmsg();
    write_smsg();
    write_scroll();
    write_info();
}

void BadgeHacker::update()
{
    qCDebug(badgehacker) << "Getting info from" << session->portName();

    progress.show();
    progress.setValue(0);
    clear();

    progress.setLabelText(tr("Getting badge text..."));
    progress.setValue(20);
    nsmsg();

    progress.setLabelText(tr("Getting scrolling text..."));
    progress.setValue(40);
    smsg();

    progress.setLabelText(tr("Getting scroll enable..."));
    progress.setValue(50);
    scroll();

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
