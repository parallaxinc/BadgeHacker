#include <QApplication>

#include "badgehacker.h"

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    PropellerManager manager;
    manager.enablePortMonitor(true);
    BadgeHacker w(&manager);
    w.show();
    return a.exec();
}
