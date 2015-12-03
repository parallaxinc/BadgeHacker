include(../common.pri)
include(../propellermanager/include.pri)
include(../spin/include.pri)
include(../icons/include.pri)

TEMPLATE = lib
TARGET = badgehacker
DESTDIR = ../lib/
CONFIG += staticlib

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
