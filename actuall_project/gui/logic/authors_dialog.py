from actuall_project.gui.windows.authors import Ui_filter_dialog
from PyQt5.QtWidgets import QDialog, QPushButton, QLineEdit
from typing import Optional, List

class AuthorsDialog(QDialog):
    def __init__(self, parent = None):
        super().__init__(parent)
        self.ui = Ui_filter_dialog()
        self.ui.setupUi(self)
        self.ui.save_button.clicked.connect(self.save)
        self.ui.undo_button.clicked.connect(self.reject)
        self.ui.add_button.clicked.connect(self.add_author)
        self.load_current_authors()

    def save(self):
        new_list = []
        for i in range(self.ui.authors_table.rowCount()):
            new_list.append(self.ui.authors_table.cellWidget(i, 0).text())
        self.parent().infos.filtr_authors = new_list
        self.accept()

    def load_current_authors(self):
        self.ui.authors_table.setRowCount(0)
        for i,author in enumerate(self.parent().infos.filtr_authors):
            self.ui.authors_table.insertRow(i)
            button = QPushButton()
            button.clicked.connect(lambda ignored, bt = button : self.ui.authors_table.removeRow(self.ui.authors_table.indexAt(bt.pos()).row()))
            text_input = QLineEdit()
            text_input.setText(author)
            self.ui.authors_table.setCellWidget(i,0,text_input)
            self.ui.authors_table.setCellWidget(i,1,button)

    def add_author(self):
        i = self.ui.authors_table.rowCount()
        self.ui.authors_table.insertRow(i)
        button = QPushButton()
        button.clicked.connect(lambda ignored, bt = button : self.ui.authors_table.removeRow(self.ui.authors_table.indexAt(bt.pos()).row()))
        text_input = QLineEdit()
        self.ui.authors_table.setCellWidget(i,0,text_input)
        self.ui.authors_table.setCellWidget(i,1,button)