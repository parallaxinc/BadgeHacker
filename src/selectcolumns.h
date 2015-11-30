#pragma once

#include <QLoggingCategory>

#include "ui_selectcolumns.h"

Q_DECLARE_LOGGING_CATEGORY(selectcolumns)

class SelectColumns : public QDialog
{
    Q_OBJECT

private:
    Ui::SelectColumns ui;
    QList<QStringList> contactlist;

public:
    explicit SelectColumns(QList<QStringList> contacts, QWidget *parent = 0);
    QList<QStringList> acceptedList();
    ~SelectColumns();

private slots:
    void updateLines();

signals:
};
