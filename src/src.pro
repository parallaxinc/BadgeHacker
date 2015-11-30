QT += widgets serialport

TEMPLATE = lib
TARGET = badgehacker
DESTDIR = ../lib/

CONFIG += staticlib

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
    hackergang.cpp \
    badge.cpp \
    badgerow.cpp \
    selectcolumns.cpp \

HEADERS += \
    badgehacker.h \
    hackergang.h \
    badge.h \
    badgerow.h \
    selectcolumns.h \

FORMS += \
    badgehacker.ui \
    badgerow.ui \
    hackergang.ui \
    selectcolumns.ui \

RESOURCES += \
    ../icons/icons.qrc \
    ../spin/spin.qrc \
