#include "hackergang.h"

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

#include "selectcolumns.h"

Q_LOGGING_CATEGORY(hackergang, "badgehacker.bulk")

HackerGang::HackerGang(PropellerManager * manager,
                   QWidget *parent)
: QWidget(parent)
{
    ui.setupUi(this);

    this->signalMapper = new QSignalMapper(this);
    this->manager = manager;

    connect(manager, SIGNAL(portListChanged()), this, SLOT(updatePorts()));
    connect(signalMapper, SIGNAL(mapped(QWidget *)), this, SLOT(checkState(QWidget *)));

    connect (ui.program, SIGNAL(clicked()), this, SLOT(program()));
    connect (ui.open, SIGNAL(clicked()),    this, SLOT(openContacts()));
    connect (ui.save, SIGNAL(clicked()),    this, SLOT(saveContacts()));

    updatePorts();
    updateFileText();
    setConnectionState(false);
}

HackerGang::~HackerGang()
{
}

void HackerGang::updatePorts()
{
    QStringList newports = manager->listPorts();

    for (int i = 0; i < ui.badgeLayout->count(); i++)
    {
        QWidget * b = ui.badgeLayout->itemAt(i)->widget();
        if (b != NULL 
                && QString(b->metaObject()->className()) == "BadgeRow")
        {
            QString p = ((BadgeRow *) b)->portName();
            if (!newports.contains(p))
            {
                disconnect (this,   SIGNAL(programTriggered()),     b,              SLOT(program()));
                disconnect (b,      SIGNAL(badgeStateChanged()),    signalMapper,   SLOT(map()));
                signalMapper->removeMappings(b);
                _active.remove(b);

                ui.badgeLayout->removeWidget(b);
                delete b;
                b = NULL;
            }
        }
    }

    foreach(QString p, newports)
    {
        if (!ports.contains(p))
        {
            BadgeRow * b = new BadgeRow(manager, this, p);
            ui.badgeLayout->addWidget(b);

            connect (this,  SIGNAL(programTriggered()),     b,              SLOT(program()));
            connect (b,     SIGNAL(badgeStateChanged()),    signalMapper,   SLOT(map()));
            signalMapper->setMapping(b, b);
        }
    }

    ports = newports;
}

void HackerGang::checkState(QWidget * w)
{
    BadgeRow * b = (BadgeRow *) w;
    if (b->state() == BadgeRow::BadgeInProgress)
        _active[b] = true;
    else
        _active[b] = false;

//    qDebug() << "SUCCESS" << _active.size() << _active.values() << w;
    foreach (QWidget * i, _active.keys())
    {
        if (_active[i]) return;
    }

    setConnectionState(false);
}


void HackerGang::program()
{
    qCDebug(hackergang) << "program()";

    if (filename.isEmpty())
    {
        QMessageBox box(QMessageBox::Warning,
                tr("No file loaded!"),
                tr("Click \"Open Contacts\" to load a contact list."));
        box.setStandardButtons(QMessageBox::Ok);
        box.exec();
        return;
    }

    if (contactlist.isEmpty())
    {
        QMessageBox box(QMessageBox::Warning,
                tr("Contact list finished!"),
                tr("You're all out of badges to program. "
                   "Perhaps it's time to have a drink!"));
        box.setStandardButtons(QMessageBox::Ok);
        box.exec();
        return;
    }

    setConnectionState(true);
    emit programTriggered();
}

void HackerGang::saveContacts()
{
    qCDebug(hackergang) << "Saving contact write progress";

    if (filename.isEmpty())
    {
        QMessageBox box(QMessageBox::Warning,
                tr("No file loaded!"),
                tr("Click \"Open Contacts\" to load a contact list."));
        box.setStandardButtons(QMessageBox::Ok);
        box.exec();
        return;
    }

    if (contactlist.isEmpty())
    {
        QMessageBox box(QMessageBox::Warning,
                tr("Contact list finished!"),
                tr("You're all out of badges to program. "
                   "There's nothing to save!"));
        box.setStandardButtons(QMessageBox::Ok);
        box.exec();
        return;
    }

    QFileDialog dialog(this,
            tr("Save Progress"),
            QDir::homePath()+"/contacts.csv",
            tr("CSV Files (*.csv)"));

    dialog.setDefaultSuffix("csv");
    dialog.setAcceptMode(QFileDialog::AcceptSave);

    if (dialog.exec())
        filename = dialog.selectedFiles()[0];

    if (filename.isEmpty())
        return;

    QFileInfo fi(filename);
    if (fi.suffix() != "csv")
    {
        QMessageBox::warning(this,
                tr("Unsupported file extension!"),
                tr("The file extension \"%1\" is not supported by HackerGang.")
                .arg(fi.suffix()));
        return;
    }

    QFile file(filename);
    if (!file.open(QFile::WriteOnly | QFile::Text))
    {
        QMessageBox::warning(this, tr("Error opening file!"),
                    tr("Cannot write file %1:\n%2.")
                    .arg(filename)
                    .arg(file.errorString()));
        return;
    }

    QTextStream out(&file);
    out.setCodec("UTF-8");

    out << "\"non-scroll 1\",";
    out << "\"non-scroll 2\",";
    out << "\"scroll 1\",";
    out << "\"scroll 2\",";
    out << "\"scroll\",";
    out << "\"info 1\",";
    out << "\"info 2\",";
    out << "\"info 3\",";
    out << "\"info 4\",";
    out << "\"rgb left\",";
    out << "\"rgb right\",";
    out << "\"led\"\n";

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

    file.close();
}

void HackerGang::openContacts()
{
    qCDebug(hackergang) << "Importing contacts to program";

    QFileDialog dialog(this,
            tr("Open Contact Sheet"),
            QDir::homePath()+"/contacts.csv",
            tr("CSV Files (*.csv)"));

    dialog.setDefaultSuffix("csv");
    dialog.setAcceptMode(QFileDialog::AcceptOpen);

    if (dialog.exec())
        filename = dialog.selectedFiles()[0];

    if (filename.isEmpty())
        return;

    QFileInfo fi(filename);
    if (fi.suffix() != "csv")
    {
        QMessageBox::warning(this,
                tr("Unsupported file extension!"),
                tr("The file extension \"%1\" is not supported by HackerGang.")
                .arg(fi.suffix()));
        return;
    }

    QFile file(filename);
    if (!file.open(QFile::ReadOnly))
    {
        QMessageBox::warning(this, tr("Error opening file!"),
                    tr("Cannot write file %1:\n%2.")
                    .arg(filename)
                    .arg(file.errorString()));
        return;
    }

    QString data = file.readAll();
    inprogresscontactlist.clear();
    contactlist.clear();
    contact.clear();

    // fix newlines
    QRegularExpression newlines("\r\n|\r|\n",QRegularExpression::DotMatchesEverythingOption);
    data.replace(newlines,"\n");

    QString temp;
    QChar character;
    QTextStream textStream(&data);

    // process CSV
    while (!textStream.atEnd())
    {
        textStream >> character;
        if (character == ',') 
        {
            checkString(temp, character);
        }
        else if (character == '\n')
        {
            checkString(temp, character);
        }
        else if (textStream.atEnd())
        {
            temp.append(character);
            checkString(temp);
        }
        else
        {
            temp.append(character);
        }
    }

    SelectColumns * w = new SelectColumns(contactlist, this);
    int ret = w->exec();
    if (ret == QDialog::Rejected)
    {
        inprogresscontactlist.clear();
        contactlist.clear();
        updateFileText();
        return;
    }

    contactlist = w->acceptedList();
    updateFileText(filename);
}

QStringList HackerGang::popContact()
{
    if (!contactlist.isEmpty())
    {
        QStringList c = contactlist.takeFirst();
        inprogresscontactlist.append(c);
        updateProgrammedText();
        return c;
    }
    else
    {
        return QStringList();
    }
}

void HackerGang::pushContact(QStringList contact)
{
    inprogresscontactlist.removeLast();
    contactlist.prepend(contact);
    updateProgrammedText();
}

void HackerGang::updateProgrammedText()
{
    if (contactlist.size() > 0 || inprogresscontactlist.size() > 0)
    {
        ui.labelProgrammed->setText(tr("%1 of %2 badges programmed")
                .arg(inprogresscontactlist.size())
                .arg(contactlist.size()+inprogresscontactlist.size())
                );
        ui.labelProgrammed->show();
    }
    else
    {
        ui.labelProgrammed->hide();
    }
}

void HackerGang::updateFileText(QString filename)
{
    if (filename.isEmpty())
        ui.labelFile->setText(tr("No file loaded"));
    else
        ui.labelFile->setText(tr("File: %1").arg(QFileInfo(filename).fileName()));

    updateProgrammedText();
}

void HackerGang::checkString(QString &temp, QChar character)
{
    if(temp.count("\"") % 2 == 0)
    {
        if (temp.startsWith( QChar('\"')) && temp.endsWith( QChar('\"') ) )
        {
            temp.remove( QRegExp("^\"") );
            temp.remove( QRegExp("\"$") );
        }

        temp.replace("\"\"", "\"");
        contact.append(temp);
        if (character != QChar(','))
        {
            contactlist.append(contact);
            contact.clear();
        }
        temp.clear();
    }
    else 
    {
        temp.append(character);
    }
}

void HackerGang::setConnectionState(bool connected)
{
    QPalette p(ui.connectionStateText->palette());

    if (connected)
    {
        ui.program->setEnabled(false);
        ui.open->setEnabled(false);
        p.setColor(QPalette::Dark,  QColor("#DDDD11"));
        p.setColor(QPalette::Light, QColor("#FFFFBB"));
        p.setColor(QPalette::Window, QColor("#FFFF94"));
        p.setColor(QPalette::WindowText, QColor("#BDBD00"));
        ui.connectionStateText->setFrameStyle(QFrame::Panel | QFrame::Sunken);
        ui.connectionStateText->setText(tr("DO NOT REMOVE BADGES"));
    }
    else
    {
        ui.program->setEnabled(true);
        ui.open->setEnabled(true);
        p.setColor(QPalette::Dark,  QColor("#54FF54"));
        p.setColor(QPalette::Light, QColor("#D4FFD4"));
        p.setColor(QPalette::Window, QColor("#94FF94"));
        p.setColor(QPalette::WindowText, QColor("#00BD00"));
        ui.connectionStateText->setFrameStyle(QFrame::Panel | QFrame::Raised);
        ui.connectionStateText->setText(tr("Safe to remove badges"));
    }

    ui.connectionStateText->setPalette(p);
}

