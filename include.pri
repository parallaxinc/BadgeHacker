include(spin/include.pri)
include(icons/include.pri)

INCLUDEPATH += $$PWD/include/
LIBS        += -L$$PWD/lib/ -lbadgehacker

win32-msvc* {
	PRE_TARGETDEPS += $$PWD/lib/badgehacker.lib
} else {
	PRE_TARGETDEPS += $$PWD/lib/libbadgehacker.a
}

include(propellermanager/include.pri)
