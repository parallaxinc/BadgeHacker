TEMPLATE  = subdirs

SUBDIRS = \
    spin \
    src \
    app \

src.depends += spin
app.depends += src
