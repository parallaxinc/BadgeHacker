TEMPLATE  = subdirs

SUBDIRS = \
    propellermanager/src \
    spin \
    src \

src.depends += propellermanager/src
src.depends += spin
