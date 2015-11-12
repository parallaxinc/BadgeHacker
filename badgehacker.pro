TEMPLATE  = subdirs

SUBDIRS = \
    propellermanager/src/lib \
    badgehacker \

badgehacker.depends = propellermanager/src/lib
