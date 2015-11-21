QT += widgets serialport

DESTDIR = ../../bin/

CONFIG -= app_bundle debug_and_release

INCLUDEPATH += ../../include/
LIBS += -L../../lib/  -lbadgehacker

INCLUDEPATH += ../../propellermanager/include/
LIBS += -L../../propellermanager/lib/  -lpropellermanager

win32-msvc* {
	PRE_TARGETDEPS += ../../propellermanager/lib/propellermanager.lib
	PRE_TARGETDEPS += ../../lib/badgehacker.lib
} else {
	PRE_TARGETDEPS += ../../propellermanager/lib/libpropellermanager.a
	PRE_TARGETDEPS += ../../lib/libbadgehacker.a
}

PRE_TARGETDEPS += ../../spin/jm_hackable_ebadge.binary

RESOURCES += \
    ../../icons/icons.qrc \
    ../../spin/spin.qrc \
