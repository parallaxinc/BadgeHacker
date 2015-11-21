TEMPLATE  = subdirs

SUBDIRS = \
    propellermanager/src \
    spin \
    src \
    app \

src.depends += propellermanager/src
src.depends += spin
app.depends += src
