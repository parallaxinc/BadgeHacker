QT += widgets serialport

TARGET = badgehacker
TEMPLATE = app
DESTDIR = ../bin/

INCLUDEPATH += ../propellermanager/include/
LIBS += -L../propellermanager/lib/  -lpropellermanager

win32-msvc* {
	PRE_TARGETDEPS += ../propellermanager/lib/propellermanager.lib
} else {
	PRE_TARGETDEPS += ../propellermanager/lib/libpropellermanager.a
}

PRE_TARGETDEPS += ../spin/jm_hackable_ebadge.binary

CONFIG -= app_bundle debug_and_release

SOURCES += \
    badgehacker.cpp \
    main.cpp \

HEADERS += \
    badgehacker.h \

FORMS += \
    badgehacker.ui \

RESOURCES += \
    ../icons/badgehacker/badgehacker.qrc \
    ../spin/spin.qrc \
