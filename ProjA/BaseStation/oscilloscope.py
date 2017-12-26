#!/usr/bin/env python

import sys
import tos

AM_SENSOR = 44

class SensorMsg(tos.Packet):
    def __init__(self, packet = None):
        tos.Packet.__init__(self, [
            ('nodeid',  'int', 2),
            ('counter', 'int', 2),
            ('timepoint', 'int', 2),
            ('temperature', 'int', 2),
            ('humidity', 'int', 2),
            ('illumination', 'int', 2)],
        packet)

if '-h' in sys.argv:
    print "Usage:", sys.argv[0], "serial@/dev/ttyUSB0:115200"
    sys.exit()

am = tos.AM()

while True:
    p = am.read()
    if p and p.type == AM_SENSOR:
        msg = SensorMsg(p.data)
        print msg.nodeid, msg.counter, msg.temperature, msg.humidity, msg.illumination, msg.timepoint
