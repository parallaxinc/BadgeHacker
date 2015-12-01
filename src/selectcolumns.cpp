#include "selectcolumns.h"

#include <QRegularExpression>

Q_LOGGING_CATEGORY(selectcolumns, "badgehacker.gang.columns")

SelectColumns::SelectColumns(QList<QStringList> contacts, QWidget *parent)
: QDialog(parent)
{
    ui.setupUi(this);

    QRegularExpression re("line[^_]+");
    QList<QLineEdit *> children = findChildren<QLineEdit *>(re);

    connect (ui.excludeFirstRow, SIGNAL(toggled(bool)),
             this, SLOT(updateLines()));

    foreach (QLineEdit * c, children)
    {
        connect(c, SIGNAL(textChanged(const QString &)),
                this, SLOT(updateLines()));
    }

    contactlist = contacts;
    updateLines();
}

SelectColumns::~SelectColumns()
{
}

void SelectColumns::updateLines()
{
    if (contactlist.isEmpty()) return;

    QList<QStringList> newcontactlist = contactlist;

    if (ui.excludeFirstRow->isChecked())
        newcontactlist.removeFirst();

//    qCDebug(selectcolumns) << "Contacts:" << contactlist.size();
//    qCDebug(selectcolumns) << "Columns:" << contactlist[0].size();
//
    QList<QLineEdit *> children = findChildren<QLineEdit *>();

    foreach (QLineEdit * c, children)
    {
        if (!c->objectName().contains("_2"))
        {
            QString s = c->objectName() + "_2";
            bool ok;
            int index = c->text().toInt(&ok) - 1;

            QLineEdit * row = findChild<QLineEdit *>(s);
            if (ok && index < newcontactlist[0].size() && index >= 0)
            {
                row->setEnabled(true);
                row->setText(newcontactlist[0][index]);
            }
            else
            {
                row->setEnabled(false);
                row->setText(QString());
            }
        }
        QString text = c->text();
    }
}

QList<QStringList> SelectColumns::acceptedList()
{
    QList<QStringList> newcontactlist = contactlist;

    if (ui.excludeFirstRow->isChecked()
            && !newcontactlist.isEmpty())
        newcontactlist.removeFirst();

    QHash<QString, int> indexhash;
    QList<QLineEdit *> children = findChildren<QLineEdit *>();

    foreach (QLineEdit * c, children)
    {
        if (!c->objectName().contains("_2"))
        {
//            qDebug() << c->objectName();
            bool ok;
            int index = c->text().toInt(&ok);

            if (ok && index <= newcontactlist[0].size() && index >= 1)
            {
                indexhash[c->objectName()] = index;
            }

            QString text = c->text();
        }
    }

    QList<QStringList> tempcontactlist;

    foreach (QStringList contact, newcontactlist)
    {
        QStringList newcontact;
        foreach (QLineEdit * c, children)
        {
            if (!c->objectName().contains("_2"))
            {
                int index = indexhash[c->objectName()];
                if (index <= contact.size() && index >= 1)
                {
                    newcontact.append(contact[index-1]);
//                    qDebug() << index << contact[index-1];
                }
                else
                {
                    newcontact.append(QString());
//                    qDebug() << 0 << QString();
                }
            }
        }

        tempcontactlist.append(newcontact);
//        qDebug() << "\n";
    }

    newcontactlist = tempcontactlist;

    return newcontactlist;
}
