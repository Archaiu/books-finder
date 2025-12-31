from PyQt5.QtWidgets import QDialog, QPushButton, QLineEdit
from actuall_project.gui.windows.authors import Ui_filter_dialog
from actuall_project.dates_and_refactoring.data_provider import get_info
from actuall_project.dates_and_refactoring.dev_tools import delete_books

class DeleteWindow(QDialog):
    def __init__(self, parent):
        super().__init__(parent)
        self.ui = Ui_filter_dialog()
        self.ui.setupUi(self)
        self.ui.authors_table.setRowCount(0)
        self.ui.save_button.clicked.connect(self.save)
        self.ui.undo_button.clicked.connect(self.reject)
        self.ui.add_button.clicked.connect(self.add_row)
        self.horrific_abomination_of_good_programing()

    def horrific_abomination_of_good_programing(self):
        self.ui.authors_table.setHorizontalHeaderLabels(["Title", "Delete"])

    def add_row(self):
        i = self.ui.authors_table.rowCount()
        self.ui.authors_table.insertRow(i)
        button = QPushButton()
        button.clicked.connect(lambda ignored, bt = button : self.ui.authors_table.removeRow(self.ui.authors_table.indexAt(bt.pos()).row()))
        text_input = QLineEdit()
        self.ui.authors_table.setCellWidget(i,0,text_input)
        self.ui.authors_table.setCellWidget(i,1,button)

    def save(self):
        new_list = []
        for i in range(self.ui.authors_table.rowCount()):
            new_list.append(self.ui.authors_table.cellWidget(i, 0).text())
        if not len(new_list):
            self.accept()
            return
        indexes = list(map(lambda row : row["id"], filter(lambda row : row != None, map(lambda el : get_info(el), new_list))))
        delete_books(indexes)
        self.ui.authors_table.setRowCount(0)
        self.accept()
