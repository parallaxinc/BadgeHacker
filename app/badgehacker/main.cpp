#include <QApplication>
#include <QDesktopWidget>

#include <BadgeHacker>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);

    QApplication::setOrganizationName("Parallax");
    QApplication::setOrganizationDomain("www.parallax.com");
#ifdef VERSION
    QApplication::setApplicationVersion(VERSION);
#else
    QApplication::setApplicationVersion("DEV");
#endif
    QApplication::setApplicationName("BadgeHacker");

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
