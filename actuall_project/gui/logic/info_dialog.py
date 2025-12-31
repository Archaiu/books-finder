from PyQt5.QtWidgets import QWidget
from actuall_project.dates_and_refactoring import data_provider
from actuall_project.gui.windows.info import Ui_Form

class InfoWindow(QWidget):
    def __init__(self, parent = None):
        super().__init__(None)
        self.parent = parent
        self.ui = Ui_Form()
        self.ui.setupUi(self)

        self.connect_functions()
        self.insert_values()

    def connect_functions(self):
        self.ui.search.clicked.connect(lambda ignored : self.parent.look_results_for_book(self.parent.current_book_index))

    def insert_values(self):
        info = data_provider.get_info(self.parent.current_book_index)
        self.ui.title.setText(info["title"])
        self.ui.author.setText(info["author"])
        self.ui.description.setText(info["descript"])
