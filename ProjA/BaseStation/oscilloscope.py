#!/usr/bin/env python
import sys
import tos

AM_0_TO_PC = 66
AM_PC_TO_0 = 77

class SensorMsg(tos.Packet):
    def __init__(self, packet = None):
        tos.Packet.__init__(self, [
            ('nodeid',  'int', 2),
            ('counter', 'int', 2),
            ('temperature', 'int', 2),
            ('humidity', 'int', 2),
            ('illumination', 'int', 2),
            ('timepoint', 'int', 2)],
        packet)

class ModifyMsg(tos.Packet):
    def __init__(self, packet = None):
        tos.Packet.__init__(self, [
            ('frequency', 'int', 2)],
        packet)

if '-h' in sys.argv:
    print "Usage:", sys.argv[0], "serial@/dev/ttyUSB0:115200"
    sys.exit()

am = tos.AM()

msg = ModifyMsg()
msg.frequency = 1000
print am.write(msg, amId = AM_PC_TO_0)

while True:
    p = am.read()
    if p and p.type == AM_0_TO_PC:
        msg = SensorMsg(p.data)
        print msg.nodeid, msg.counter, msg.temperature, msg.humidity, msg.illumination, msg.timepoint