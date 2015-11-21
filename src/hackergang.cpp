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

    updatePorts();
}

HackerGang::~HackerGang()
{
}

void HackerGang::updatePorts()
{
//    ui.port->clear();
    QStringList ports = manager->listPorts();
    if (!ports.isEmpty())
    {
        foreach(QString p, ports)
        {
            BadgeRow * b = new BadgeRow(manager, p);
            ui.badgeLayout->addWidget(b);
//            ui.port->addItem(p);
        }
    }
    else
    {
    }
}
