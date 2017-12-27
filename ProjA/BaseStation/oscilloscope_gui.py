import sys
import subprocess

from PyQt5.QtCore import *
from PyQt5.QtWidgets import *
from PyQt5.QtGui import *
import pyqtgraph as pg

NODE1_ID = 32
NODE2_ID = 33

node1_previous_counter = -1
node2_previous_counter = -1
node1_temp_list = []
node1_hum_list = []
node1_ill_list = []
node2_temp_list = []
node2_hum_list = []
node2_ill_list = []
frequency = 0

f = open('result.txt','w')
server = subprocess.Popen(['python', '-u', 'oscilloscope.py', 'serial@/dev/ttyUSB1:115200', '200'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

class Msg:
    def __init__(self):
        self.nodeid = 0
        self.counter = 0
        self.temperature = 0
        self.humidity = 0
        self.illumination = 0
        self.timepoint = 0


class CollectData(QThread):
    def __init__(self, parent=None):
        super(CollectData, self).__init__()

    def __del__(self):
        self.wait()

    def run(self):
        msg = Msg()
        while True:
            try:
                line = server.stdout.readline()
                params = [int(x) for x in line.split()]
            except:
                continue
            if len(params) != 6:
                continue

            msg.nodeid = params[0]
            msg.counter = params[1]
            msg.temperature = params[2]
            msg.humidity = params[3]
            msg.illumination = params[4]
            msg.timepoint = params[5]

            if msg.nodeid == NODE1_ID:
                if msg.counter != node1_previous_counter:
                    previous_counter = msg.counter
                    node1_temp_list.append(msg.temperature)
                    node1_hum_list.append(msg.humidity)
                    node1_ill_list.append(msg.illumination)
                    f.write('%d %d %d %d %d %d\n' % (msg.nodeid, msg.counter, msg.temperature, msg.humidity, msg.illumination, msg.timepoint))
            elif msg.nodeid == NODE2_ID:
                if msg.counter != node2_previous_counter:
                    previous_counter = msg.counter
                    node2_temp_list.append(msg.temperature)
                    node2_hum_list.append(msg.humidity)
                    node2_ill_list.append(msg.illumination)
                    f.write('%d %d %d %d %d %d\n' % (msg.nodeid, msg.counter, msg.temperature, msg.humidity, msg.illumination, msg.timepoint))


class PictureWindow(QWidget):
    def __init__(self):
        super().__init__()
        self.initUI()

    def initUI(self):
        # basic window parameters
        self.setGeometry(300, 300, 1000, 600)
        self.setWindowTitle('ScopePainter')

        # set label
        self.setlabel = QLabel('Set The Frequency: ',self)
        self.setlabel.resize(self.setlabel.sizeHint())
        self.setlabel.move(40,525)

        #set line edit
        self.setlineEdit = QLineEdit(self)
        self.setlineEdit.setGeometry(160,525,70,20)

        #set button
        self.setbtn = QPushButton('SET',self)
        self.setbtn.resize(self.setbtn.sizeHint())
        self.setbtn.move(250,520)
        self.setbtn.clicked.connect(self.setButtonClicked)


        # clear button
        self.exitbtn = QPushButton('Exit and Save!',self)
        self.exitbtn.resize(self.exitbtn.sizeHint())
        self.exitbtn.move(800,520)
        self.exitbtn.clicked.connect(self.exitButtonClicked)

        self.show()

        # timer
        self.checkTimer = QTimer()
        self.checkTimer.setInterval(50)
        self.checkTimer.timeout.connect(self.draw)
        self.checkTimer.start()

        # draw test line
        self.win = pg.GraphicsWindow(title="WCN实时数据显示")
        self.plotTemp = self.win.addPlot(title='温度变化')
        self.plotHum = self.win.addPlot(title='湿度变化' )
        self.plotIll = self.win.addPlot(title='光照强度变化')

        pg.QtGui.QApplication.exec_()

    def draw(self):
        # temp plot
        self.plotTemp.clear()
        if len(node1_temp_list) <= 20:
            self.plotTemp.plot(node1_temp_list)
        else:
            self.plotTemp.plot(node1_temp_list[-20:])

        if len(node2_temp_list) <= 20:
            self.plotTemp.plot(node2_temp_list,pen = pg.mkPen(color = 'c'))
        else:
            self.plotTemp.plot(node2_temp_list[-20:],pen = pg.mkPen(color = 'c'))

        # hum plot
        self.plotHum.clear()
        if len(node1_hum_list) <= 20:
            self.plotHum.plot(node1_hum_list)
        else:
            self.plotHum.plot(node1_hum_list[-20:])
        if len(node2_hum_list) <= 20:
            self.plotHum.plot(node2_hum_list,pen = pg.mkPen(color = 'c'))
        else:
            self.plotHum.plot(node2_hum_list[-20:], pen=pg.mkPen(color='c'))

        # hum plot
        self.plotIll.clear()
        if len(node1_ill_list) <= 20:
            self.plotIll.plot(node1_ill_list)
        else:
            self.plotIll.plot(node1_ill_list[-20:])
        if len(node2_ill_list) <= 20:
            self.plotIll.plot(node2_ill_list,pen = pg.mkPen(color = 'c'))
        else:
            self.plotIll.plot(node2_ill_list[-20:], pen=pg.mkPen(color='c'))


    def setButtonClicked(self):
        raw_fre = self.setlineEdit.text()
        if raw_fre.isdigit():
            frequency = int(raw_fre)
            global server
            server.kill()
            server = subprocess.Popen(['python', '-u', 'oscilloscope.py', 'serial@/dev/ttyUSB1:115200', str(frequency)], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            reply = QMessageBox.question(self, 'Success',
                                         "The frequency has been changed to %d." % (frequency), QMessageBox.Yes)

        else:
            reply = QMessageBox.question(self, 'Invalid',
                                         "Your input is invalid!", QMessageBox.Yes)

    def exitButtonClicked(self):
        f.close()
        reply = QMessageBox.question(self, 'Exit',
                                     "Result.txt has been saved!", QMessageBox.Yes)

if __name__ == '__main__':
    app = QApplication(sys.argv)
    thread = CollectData()
    thread.start()
    ex = PictureWindow()
    sys.exit(app.exec_())
