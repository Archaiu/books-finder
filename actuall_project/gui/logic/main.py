from actuall_project.gui.windows.window import Ui_MainWindow
from PyQt5.QtWidgets import QApplication, QDialog, QMainWindow, QMessageBox, QTableWidgetItem, QPushButton, QHeaderView
import sys
from actuall_project.dates_and_refactoring import data_provider
from PyQt5.uic import loadUi
from .authors_dialog import AuthorsDialog
from .info_dialog import InfoWindow
from .path import PathWindow
from .delete_window import DeleteWindow
from actuall_project.dates_and_refactoring import dev_tools

class ImportantInfo:
    def __init__(self):
        self.include_author = True
        self.filtr_authors = []
        self.widgets = []
        

class Window(QMainWindow, Ui_MainWindow):
    def __init__(self,parent=None):
        super().__init__(parent)
        self.infos = ImportantInfo()
        self.setupUi(self)
        self.start_look()
        self.connect_functions()
        self.show_olders()
        
    def start_look(self):
        self.dev_tools_stack.setCurrentIndex(0)
        self.main_info_stack.setCurrentIndex(0)
        self.include_author_buttom.setChecked(True)
        self.books_table.horizontalHeader().setSectionResizeMode(0, QHeaderView.Stretch)
        self.books_table.horizontalHeader().setSectionResizeMode(1, QHeaderView.ResizeToContents)
        self.books_table.horizontalHeader().setSectionResizeMode(2, QHeaderView.ResizeToContents)
        self.results_table.horizontalHeader().setSectionResizeMode(3, QHeaderView.ResizeToContents)
        header = self.old_table.horizontalHeader()
        header.setSectionResizeMode(0, QHeaderView.Stretch)
        header.setSectionResizeMode(1, QHeaderView.Interactive)
        header.setSectionResizeMode(2, QHeaderView.Interactive)


    def connect_functions(self):
        self.dev_tools_button.stateChanged.connect(lambda state : self.dev_tools_stack.setCurrentIndex(1 if state == 2 else 0))
        self.include_author_buttom.stateChanged.connect(lambda state : setattr(self.infos, 'include_author', True))
        self.search_titles_button.clicked.connect(self.search_book)
        self.authors_button.clicked.connect(lambda ignored : AuthorsDialog(self).exec())
        self.reload_button.clicked.connect(
            lambda ignored : self.look_results_for_book(
                self.current_book_index))
        self.add_book_window = PathWindow(self, self.add_books)
        self.add_books_button.clicked.connect(lambda ignored : self.add_book_window.show())
        self.add_interactions_window= PathWindow(self, self.add_interactions)
        self.add_interactions_button.clicked.connect( lambda ignored : self.add_interactions_window.show())
        self.delete_books_window = DeleteWindow(self)
        self.delete_books_button.clicked.connect(lambda ignored : self.delete_books_window.show())

    def search_book(self):
        if not len(self.title_text.text()):
            return
        output = data_provider.get_books_with_start_as_string(self.title_text.text())
        self.main_info_stack.setCurrentIndex(1)
        self.books_table.setRowCount(0)
        for i,row in enumerate(output):
            self.books_table.insertRow(i)
            self.books_table.setItem(i, 0, QTableWidgetItem(row["title"]))
            self.books_table.setItem(i, 1, QTableWidgetItem(data_provider.get_info(row["id"])["author"]))
            button = QPushButton()
            button.setText("Click")
            button.clicked.connect(lambda ignored,x=row["id"] : self.look_results_for_book(x))
            self.books_table.setCellWidget(i, 2, button)

    def look_results_for_book(self, index : int):
        self.main_info_stack.setCurrentIndex(2)
        print("Catching data")
        data = data_provider.get_books_to_recommend(index,
        include_author=not self.include_author_buttom.isChecked(),
        filtr_authors=self.infos.filtr_authors)
        print("Data catched!")
        self.results_table.setRowCount(0)
        print(data[0])
        self.current_book_index = index
        self.result_book_label.setText(f"Result for {data_provider.get_info(index)['title']} book" )
        for i, row in enumerate(data[:20]):
            self.results_table.insertRow(i)
            self.results_table.setItem(i, 0, QTableWidgetItem(row["title"]))
            self.results_table.setItem(i, 1, QTableWidgetItem(row["author"]))
            self.results_table.setItem(i, 2, QTableWidgetItem(str(row["counts"])))
            button = QPushButton()
            button.setText("Click")
            button.clicked.connect(lambda ignored, x = row["title"] : self.show_book_info(x))
            self.results_table.setCellWidget(i, 3, button)
        self.show_olders()

    def show_book_info(self, book):
        self.current_book_index=data_provider.get_info(book)["id"]
        widget = InfoWindow(self)
        self.infos.widgets.append(widget)
        widget.show()

    def add_books(self, path):
        dev_tools.add_new_books(path)

    def delete_books(self, book):
        data_provider.remove_olds(data_provider.get_info(book)["id"])
        self.show_olders()

    def add_interactions(self, path):
        dev_tools.add_new_relations(path)

    def show_olders(self):
        data = data_provider.get_olds()
        self.old_table.setRowCount(0)
        for i, row in enumerate(data):
            self.old_table.insertRow(i)
            self.old_table.setItem(i, 0, QTableWidgetItem(row["title"]))
            button = QPushButton()
            button.setText("Search")
            button.clicked.connect(lambda ignored, x = row["title"] : self.look_results_for_book(data_provider.get_info(x)["id"]))
            self.old_table.setCellWidget(i, 1, button)
            button = QPushButton()
            button.setText("Delete")
            button.clicked.connect(lambda ignored, x = row["title"] : self.delete_books(x))
            self.old_table.setCellWidget(i, 2, button)
        self.show_authors()
            
    def show_authors(self):
        data = data_provider.get_stats()
        self.authors_table.setRowCount(0)
        for i, row in enumerate(data):
            self.authors_table.insertRow(i)
            self.authors_table.setItem(i, 0, QTableWidgetItem(row["author"]))
            self.authors_table.setItem(i, 1, QTableWidgetItem(str(row["positions"])))   


def main():
    app = QApplication([])
    with open("actuall_project/gui/templates/style.css", "r") as f:
        app.setStyleSheet(f.read())
    win = Window()
    win.show()
    sys.exit(app.exec())
    
if __name__ == "__main__":
    main()

