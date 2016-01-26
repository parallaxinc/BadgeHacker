TEMPLATE  = subdirs

SUBDIRS = \
    propellermanager \
    spin \
    src \
    app \

src.depends += spin propellermanager
app.depends += src

propellermanager.subdir = propellermanager/src
