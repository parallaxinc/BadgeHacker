TEMPLATE  = subdirs

SUBDIRS = \
    propellermanager/src/lib \
    spin \
    badgehacker \

badgehacker.depends = propellermanager/src/lib
badgehacker.depends = spin
