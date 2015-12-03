include(propellermanager/include.pri)

QT += widgets serialport

CONFIG -= debug_and_release app_bundle

TOP_PWD = $$PWD

!greaterThan(QT_MAJOR_VERSION, 4): {
    error("PropellerIDE requires Qt5.2 or greater")
}
!greaterThan(QT_MINOR_VERSION, 1): {
    error("PropellerIDE requires Qt5.2 or greater")
}
