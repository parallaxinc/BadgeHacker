#include <QApplication>
#include <QDesktopWidget>

#include "badgehacker.h"

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    PropellerManager manager;
    manager.enablePortMonitor(true);
    BadgeHacker w(&manager);

    QRect geo = QApplication::desktop()->screenGeometry();
    int x = (geo.width()-w.width()) / 2;
    int y = (geo.height()-w.height()) / 2;
    w.move(x, y);
    w.show();
    return a.exec();
}
