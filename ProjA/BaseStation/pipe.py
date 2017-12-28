import subprocess
import fcntl
import os
import time

server = subprocess.Popen(['python', '-u', 'oscilloscope.py', 'serial@/dev/ttyUSB0:115200'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
#flags = fcntl.fcntl(server.stdout, fcntl.F_GETFL)
#flags |= os.O_NONBLOCK
#fcntl.fcntl(server.stdout, fcntl.F_SETFL, flags)

cnt = 0
#f = open("output.txt", "w")
while True:
#    try:
        cnt += 1
        #print(cnt)
        p = server.stdout.readline()
        #time.sleep(1)
        print("No.", cnt, p)
    #except:
#        f.close()
server.kill()
