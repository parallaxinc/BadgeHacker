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

Q_LOGGING_CATEGORY(badgehacker, "badgehacker")

BadgeHacker::BadgeHacker(PropellerManager * manager,
                   QWidget *parent)
: QWidget(parent)
{
    ui.setupUi(this);

    this->manager = manager;
    badge = new Badge(manager, ui.port->currentText());

    version();

    foreach (const QString & colorname, badge->colors()) {
            const QColor color(colorname);

            QPixmap pix(24,24);

            pix.fill(QColor(colorname));

            ui.leftRgb->addItem(pix,colorname);
            ui.rightRgb->addItem(pix, colorname);
    }

    ui.contacts->clear();
    ui.contactList->clear();

    connect(manager, SIGNAL(portListChanged()), this, SLOT(updatePorts()));
    connect(badge, SIGNAL(sendError(const QString &)), this, SLOT(handleError()));

    connect(ui.port, SIGNAL(currentIndexChanged(const QString &)), this, SLOT(portChanged()));
    connect(ui.saveContacts, SIGNAL(clicked()), this, SLOT(saveContacts()));

    connect(ui.configure, SIGNAL(clicked()), this, SLOT(configure()));
    connect(ui.refresh, SIGNAL(clicked()), this, SLOT(refresh()));
    connect(ui.wipe, SIGNAL(clicked()), this, SLOT(wipe()));
    connect(ui.wipe, SIGNAL(clicked()), qApp, SLOT(aboutQt()));
    connect(ui.activeButton, SIGNAL(toggled(bool)), this, SLOT(handleEnable(bool)));
    connect(ui.contactList, SIGNAL(currentRowChanged(int)), this, SLOT(showContact(int)));

    updatePorts();
}

BadgeHacker::~BadgeHacker()
{
    closed();

    delete badge;
}

void BadgeHacker::version()
{
    _expected = badge->firmware();

    ui.version->setText(tr("BadgeHacker v%1 (firmware v%2.%3)")
            .arg(qApp->applicationVersion())
            .arg(_expected["firmware"])
            .arg(_expected["protocol"]));
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

void BadgeHacker::handleEnable(bool checked)
{
    if (checked)
        open();
    else
        closed();
}


void BadgeHacker::open()
{
    badge->unpause();

    portChanged();
    ui.activeLight->setPixmap(QPixmap(":/icons/badgehacker/led-green.png"));
    setEnabled(true);
}

void BadgeHacker::closed()
{
    badge->pause();

    clear();
    ui.activeLight->setPixmap(QPixmap(":/icons/badgehacker/led-off.png"));
    setEnabled(false);
}

void BadgeHacker::portChanged()
{
    qCDebug(badgehacker) << "port:" << qPrintable(badge->portName());
    badge->setPortName(ui.port->currentText());
}

void BadgeHacker::handleError()
{
    closed();
}

void BadgeHacker::nsmsg()
{
    QStringList data = badge->nsmsg();
    if (data.size() < 2) return;

    ui.nsmsgLine1->setText(data[0]);
    ui.nsmsgLine2->setText(data[1]);

    ui.nsmsgLine1->setEnabled(true);
    ui.nsmsgLine2->setEnabled(true);
}

void BadgeHacker::smsg()
{
    QStringList data = badge->smsg();
    if (data.size() < 2) return;

    ui.smsgLine1->setText(data[0]);
    ui.smsgLine2->setText(data[1]);

    ui.smsgLine1->setEnabled(true);
    ui.smsgLine2->setEnabled(true);
}

void BadgeHacker::scroll()
{
    ui.scroll->setEnabled(badge->scroll());
}

void BadgeHacker::info()
{
    QStringList data = badge->info();
    if (data.size() < 4) return;

    ui.infoLine1->setText(data[0]);
    ui.infoLine2->setText(data[1]);
    ui.infoLine3->setText(data[2]);
    ui.infoLine4->setText(data[3]);

    ui.infoLine1->setEnabled(true);
    ui.infoLine2->setEnabled(true);
    ui.infoLine3->setEnabled(true);
    ui.infoLine4->setEnabled(true);
}

void BadgeHacker::led()
{
    QList<bool> leds = badge->led();
    if (leds.size() < 6) return;

    ui.led1->setChecked(leds[0]);
    ui.led2->setChecked(leds[1]);
    ui.led3->setChecked(leds[2]);
    ui.led4->setChecked(leds[3]);
    ui.led5->setChecked(leds[4]);
    ui.led6->setChecked(leds[5]);

    ui.led1->setEnabled(true);
    ui.led2->setEnabled(true);
    ui.led3->setEnabled(true);
    ui.led4->setEnabled(true);
    ui.led5->setEnabled(true);
    ui.led6->setEnabled(true);
}

void BadgeHacker::rgb()
{
    QStringList data = badge->rgb();
    if (data.size() < 2) return;

    ui.leftRgb->setCurrentIndex( ui.leftRgb->findText( data[0]));
    ui.rightRgb->setCurrentIndex(ui.rightRgb->findText(data[1]));

    ui.leftRgb->setEnabled(true);
    ui.rightRgb->setEnabled(true);
}

void BadgeHacker::contacts()
{
    contactlist = badge->contacts();

    ui.contacts->clear();

    // QListWidget::clear() is buggy
    disconnect(ui.contactList, SIGNAL(currentRowChanged(int)), this, SLOT(showContact(int)));
    ui.contactList->clearSelection();
    ui.contactList->clearFocus();
    ui.contactList->clear();
    connect(ui.contactList, SIGNAL(currentRowChanged(int)), this, SLOT(showContact(int)));

    ui.contacts_count->setText(tr("%1 Contacts")
            .arg(contactlist.size()));

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

void BadgeHacker::write_nsmsg1() { badge->write_nsmsg1(ui.nsmsgLine1->text()); }
void BadgeHacker::write_nsmsg2() { badge->write_nsmsg2(ui.nsmsgLine2->text()); }
void BadgeHacker::write_nsmsg()
{
    badge->write_nsmsg(ui.nsmsgLine1->text(),ui.nsmsgLine2->text());
}

void BadgeHacker::write_smsg1() { badge->write_smsg1(ui.smsgLine1->text()); }
void BadgeHacker::write_smsg2() { badge->write_smsg2(ui.smsgLine2->text()); }
void BadgeHacker::write_smsg()
{
    badge->write_smsg(ui.smsgLine1->text(),ui.smsgLine2->text());
}

void BadgeHacker::write_scroll()
{
    badge->write_scroll(ui.scroll->isChecked());
}

void BadgeHacker::write_info1() { badge->write_info1(ui.infoLine1->text()); }
void BadgeHacker::write_info2() { badge->write_info2(ui.infoLine2->text()); }
void BadgeHacker::write_info3() { badge->write_info3(ui.infoLine3->text()); }
void BadgeHacker::write_info4() { badge->write_info4(ui.infoLine4->text()); }

void BadgeHacker::write_info()
{
    QStringList strings;
    strings << ui.infoLine1->text()
            << ui.infoLine2->text()
            << ui.infoLine3->text()
            << ui.infoLine4->text();
    badge->write_info(strings);
}

void BadgeHacker::write_led()
{
    QList<bool> leds;
    leds    << ui.led1->isChecked()
            << ui.led2->isChecked()
            << ui.led3->isChecked()
            << ui.led4->isChecked()
            << ui.led5->isChecked()
            << ui.led6->isChecked();
    badge->write_led(leds);
}

void BadgeHacker::write_leftrgb()  { badge->write_leftrgb(ui.leftRgb->currentText());   }
void BadgeHacker::write_rightrgb() { badge->write_rightrgb(ui.rightRgb->currentText()); }
void BadgeHacker::write_rgb()
{
    badge->write_rgb(ui.leftRgb->currentText(),ui.rightRgb->currentText());
}

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

    ui.refresh->setEnabled(enabled);
    ui.configure->setEnabled(enabled);
    ui.wipe->setEnabled(enabled);

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

bool BadgeHacker::saveContacts()
{
    qCDebug(badgehacker) << "Saving contacts from" << badge->portName();

    QFileDialog dialog(this,
            tr("Save Contacts"),
            QDir::homePath()+"/contacts.txt",
            tr("Text Files (*.txt);;CSV Files (*.csv)"));

    dialog.setDefaultSuffix("txt");
    dialog.setAcceptMode(QFileDialog::AcceptSave);

    QString filename;
    if (dialog.exec())
        filename = dialog.selectedFiles()[0];

    if (filename.isEmpty())
        return false;

    QFileInfo fi(filename);
    if (fi.suffix() != "txt" && fi.suffix() != "csv")
    {
        QMessageBox::warning(this,
                tr("Unsupported file extension!"),
                tr("The file extension \"%1\" is not supported by BadgeHacker.")
                .arg(fi.suffix()));
        return false;
    }

    QFile file(filename);
    if (!file.open(QFile::WriteOnly | QFile::Text))
    {
        QMessageBox::warning(this, tr("Error opening file!"),
                    tr("Cannot write file %1:\n%2.")
                    .arg(filename)
                    .arg(file.errorString()));
        return false;
    }

    if (fi.suffix() == "txt")
        saveContactsAsText(&file);
    else if (fi.suffix() == "csv")
        saveContactsAsCsv(&file);

    file.close();
    return true;
}


void BadgeHacker::saveContactsAsText(QFile * file)
{
    QTextStream out(file);
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
}

void BadgeHacker::saveContactsAsCsv(QFile * file)
{
    QTextStream out(file);
    out.setCodec("UTF-8");

    out << "\"info 1\",";
    out << "\"info 2\",";
    out << "\"info 3\",";
    out << "\"info 4\"\n";

    foreach(QStringList contact, contactlist)
    {
        QStringList sl = contact;

        if (contact.size() < 4)
        {
            for (int i = 0; i < 4 - contact.size() ; i++)
                sl.append(QString());
        }

        for (int i = 0; i < sl.size(); i++)
        {
            out << "\"" << sl[i] << "\"";

            if (i < sl.size()-1)
                out << ",";
        }

        out << "\n";
    }

    out.flush();
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

    badge->start_ready(2000);
    badge->wait_for_ready();
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

bool BadgeHacker::ping(QProgressDialog * progress)
{
    Badge::BadgeError result = badge->ping();

    switch (result)
    {
        case Badge::NoError:
            return true;

        case Badge::BadgeNotFoundError:
            return badgeNotFound(progress);

        case Badge::FirmwareNotFoundError:
            return firmwareNotFound(progress);

        case Badge::UnexpectedFirmwareError:
            return unexpectedFirmware(progress);
    }
}


void BadgeHacker::wipe()
{
    qCDebug(badgehacker) << "Wipe contacts on" << badge->portName();

    setEnabled(false);

    QMessageBox box(QMessageBox::Warning,
            tr("Wipe all contacts?"),
            tr("You are about to erase all contacts from your badge. "
               "Are you sure you want to continue?"));
    box.setStandardButtons(QMessageBox::Yes | QMessageBox::Save | QMessageBox::Cancel);

    box.setButtonText(QMessageBox::Save, tr("Save Contacts First"));
    box.setButtonText(QMessageBox::Yes, tr("Continue"));

    int ret = box.exec();
    if (ret == QMessageBox::Cancel)
    {
        setEnabled(true);
        return;
    }
    else if (ret == QMessageBox::Save)
    {
        if (!saveContacts())
        {
            setEnabled(true);
            return;
        }
    }

    QProgressDialog * progress = new QProgressDialog(this, Qt::WindowStaysOnTopHint);
    progress->setCancelButton(0);
    progress->setWindowTitle(tr("Loading..."));
    progress->setLabelText(tr("Waiting for badge..."));
    progress->setValue(0);
    progress->show();

    if (ping(progress))
    {
        progress->setLabelText(tr("Wiping contact database..."));
        progress->setValue(0);

        badge->wipe();

        for (int i = 0; i < 100; i++)
        {
            progress->setValue(i);
            badge->start_ready(120);
            badge->wait_for_ready();
        }
    }

    progress->setValue(100);
    progress->hide();

    delete progress;

    setEnabled(true);
}

bool BadgeHacker::program(QProgressDialog * progress)
{
    qCDebug(badgehacker) << "Programming badge on" << badge->portName();

    progress->show();
    progress->setLabelText(tr("Writing badge firmware..."));
    progress->setValue(0);

    return badge->program();
}

bool BadgeHacker::badgeNotFound(QProgressDialog * progress)
{
    progress->hide();
    QMessageBox::critical(this,
            tr("Badge Not Found!"),
            tr("There doesn't appear to be a badge attached. "
               "Please make sure that the power is on!"));
    return false;
}

bool BadgeHacker::firmwareNotFound(QProgressDialog * progress)
{
    return notFound(
            tr("No Firmware Detected"),
            tr("BadgeHacker detected no firmware on the badge. "
               "Would you like to install new firmware?"),
            progress);
}

bool BadgeHacker::unexpectedFirmware(QProgressDialog * progress)
{
    QMap<QString, QString> version = badge->version();
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
                    .arg(_expected["firmware"]).arg(_expected["protocol"]),
            progress))
    {
        if (version["protocol"] != _expected["protocol"])
            return false;
        else
            return true;
    }

    return true;
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
            return badgeNotFound(progress);
        }

        return badge->blank();
    }
    else
        return false;
}

