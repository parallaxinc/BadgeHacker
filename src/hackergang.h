#pragma once

#include <QDialog>
#include <QTimer>
#include <QLoggingCategory>
#include <QProgressDialog>
#include <QMap>

#include <PropellerSession>

#include "badge.h"

#include "ui_hackergang.h"

Q_DECLARE_LOGGING_CATEGORY(hackergang)

class HackerGang : public QWidget 
{
    Q_OBJECT

private:
    Ui::HackerGang ui;
    PropellerManager * manager;
    QStringList ports;

    QList<QStringList> contactlist;

public:
    explicit HackerGang(PropellerManager * manager, QWidget *parent = 0);
    ~HackerGang();

private slots:
    void updatePorts();
//    void openContacts();
//    void saveContacts();

signals:
    void program();
};
