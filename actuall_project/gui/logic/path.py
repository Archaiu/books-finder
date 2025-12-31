from PyQt5.QtWidgets import QDialog
from actuall_project.gui.windows.path import Ui_Dialog

class PathWindow(QDialog):
    def __init__(self, parent, action):
        super().__init__(parent)
        self.ui = Ui_Dialog()
        self.ui.setupUi(self)
        self.action = action
        self.ui.accept.clicked.connect(self.confirm_action)
        
    def confirm_action(self):
        try:
            self.action(self.ui.path_input.toPlainText())
        except:
            print("Wrong file")
        self.ui.path_input.setText("")
        self.accept()