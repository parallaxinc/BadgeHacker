QT += widgets serialport

TARGET = badgehacker
TEMPLATE = app

INCLUDEPATH += ../propellermanager/src/lib/
LIBS += -L../propellermanager/src/lib/  -lpropellermanager

win32-msvc* {
	PRE_TARGETDEPS += ../propellermanager/src/lib/propellermanager.lib
} else {
	PRE_TARGETDEPS += ../propellermanager/src/lib/libpropellermanager.a
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
