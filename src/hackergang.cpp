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

Q_LOGGING_CATEGORY(hackergang, "hackergang")

HackerGang::HackerGang(PropellerManager * manager,
                   QWidget *parent)
: QWidget(parent)
{
    ui.setupUi(this);

    this->manager = manager;

    connect(manager, SIGNAL(portListChanged()), this, SLOT(updatePorts()));

    connect (ui.program, SIGNAL(clicked()), this, SIGNAL(program()));

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

//    int timeout_payload = session->calculateTimeout(payload.size());
//    if (write)
//        timeout_payload += 5000; // ms (EEPROM write speed is constant.
//                                 // the Propeller firmware only does 32kB EEPROMs
//                                 // and this transaction is handled entirely by the firmware.
//
//    totalTimeout.start(timeout_payload);
//    handshakeTimeout.start(session->calculateTimeout(request.size()));
//    elapsedTimer.start();
