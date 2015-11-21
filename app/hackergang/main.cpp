#include <QApplication>
#include <QDesktopWidget>

#include <HackerGang>

int main(int argc, char *argv[])
{
    qSetMessagePattern("[%{time hh:mm:ss}] %{category}: %{message}");

    QApplication a(argc, argv);

    QApplication::setOrganizationName("Parallax");
    QApplication::setOrganizationDomain("www.parallax.com");
#ifdef VERSION
    QApplication::setApplicationVersion(VERSION);
#else
    QApplication::setApplicationVersion("DEV");
#endif
    QApplication::setApplicationName("HackerGang");

    PropellerManager manager;
    manager.enablePortMonitor(true);
    HackerGang w(&manager);

    QRect geo = QApplication::desktop()->screenGeometry();
    int x = (geo.width()-w.width()) / 2;
    int y = (geo.height()-w.height()) / 2;
    w.move(x, y);
    w.show();
    return a.exec();
}
