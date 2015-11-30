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

#include "badgerow.h"
#include "selectcolumns.h"

Q_LOGGING_CATEGORY(hackergang, "badgehacker.gang")

HackerGang::HackerGang(PropellerManager * manager,
                   QWidget *parent)
: QWidget(parent)
{
    ui.setupUi(this);

    this->manager = manager;

    connect(manager, SIGNAL(portListChanged()), this, SLOT(updatePorts()));

    connect (ui.program, SIGNAL(clicked()), this, SIGNAL(program()));
    connect (ui.open, SIGNAL(clicked()),    this, SLOT(openContacts()));
    connect (ui.save, SIGNAL(clicked()),    this, SLOT(saveContacts()));

    updatePorts();
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
                disconnect (this, SIGNAL(program()), b, SLOT(program()));

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
            BadgeRow * b = new BadgeRow(manager, p);
            ui.badgeLayout->addWidget(b);

            connect (this, SIGNAL(program()), b, SLOT(program()));
        }
    }

    ports = newports;
}


void HackerGang::saveContacts()
{
    qCDebug(hackergang) << "Saving contact write progress";

    QFileDialog dialog(this,
            tr("Save Progress"),
            QDir::homePath()+"/contacts.csv",
            tr("CSV Files (*.csv)"));

    dialog.setDefaultSuffix("csv");
    dialog.setAcceptMode(QFileDialog::AcceptSave);

    QString filename;
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

    QString filename;
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
    w->exec();

    contactlist = w->acceptedList();

////    qCDebug(hackergang) << "SIZE" << contactlist.size();
//    foreach (QStringList c, contactlist)
//    {
////        qCDebug(hackergang) << "SIZE" << c.size();
//        foreach (QString s, c)
//        {
////            qCDebug(hackergang) << "  " << s.size();
//        }
//
//    }
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
//        qCDebug(hackergang) << temp;
        contact.append(temp);
        if (character != QChar(','))
        {
//            qCDebug(hackergang) << "\n";
            contactlist.append(contact);
            contact.clear();
//            model->appendRow(standardItemList);
        }
        temp.clear();
    }
    else 
    {
        temp.append(character);
    }
}

//    QTextStream out(&file);
//    out.setCodec("UTF-8");
//
//    out << "\"info 1\",";
//    out << "\"info 2\",";
//    out << "\"info 3\",";
//    out << "\"info 4\"\n";
//
//    foreach(QStringList contact, contactlist)
//    {
//        QStringList sl = contact;
//
//        if (contact.size() < 4)
//        {
//            for (int i = 0; i < 4 - contact.size() ; i++)
//                sl.append(QString());
//        }
//
//        for (int i = 0; i < sl.size(); i++)
//        {
//            out << "\"" << sl[i] << "\"";
//
//            if (i < sl.size()-1)
//                out << ",";
//        }
//
//        out << "\n";
//    }
//
//    out.flush();
//
//    file.close();
