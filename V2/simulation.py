from TOSSIM import *
import sys

t = Tossim([])    # 1. define an object of TOSSIM
r = t.radio()    # 2. define an object of radio model

t.addChannel("MoteC", sys.stdout) # 3. channels here mean formats outputing debug information (standard output or a file).
t.addChannel("REPORT", sys.stdout)            # the first parameter is the channel destination, the second is the channel.

m1 = t.getNode(1)             # 4. define an object representing a specific mote.
m2 = t.getNode(2)
m3 = t.getNode(3)
m4 = t.getNode(4)
m5 = t.getNode(5)
m6 = t.getNode(6)
m7 = t.getNode(7)
m8 = t.getNode(8)
m9 = t.getNode(9)
m10 = t.getNode(0)


m1.bootAtTime(345321)        # 5. start the mote; ticks,time unit.   t.ticksPerSecond(), one second.  10 to the power 10 ticks per second.
m2.bootAtTime(812311)
m3.bootAtTime(824011)
m4.bootAtTime(523411)
m5.bootAtTime(421234)
m6.bootAtTime(321211)
m7.bootAtTime(221211)
m8.bootAtTime(212011)
m9.bootAtTime(300034)
m10.bootAtTime(520011)

# clock-wise links
r.add(1, 2, -60.0)           # 6. add a link, src is mote 1, the dest is mote 2.
r.add(2, 3, -60.0)
r.add(3, 4, -60.0)
r.add(5, 6, -60.0)
r.add(6, 7, -60.0)
r.add(7, 8, -60.0)
r.add(8, 9, -60.0)
r.add(9, 10, -60.0)
r.add(10, 1, -60.0)
# counterclock-wise links
r.add(1, 10, -60.0)
r.add(2, 1, -60.0)
r.add(3, 2, -60.0)
r.add(5, 4, -60.0)
r.add(6, 5, -60.0)
r.add(7, 6, -60.0)
r.add(8, 7, -60.0)
r.add(9, 8, -60.0)
r.add(10, 9, -60.0)

# 7. configure the CPM radio model. the radio noise is a piece
# of data from real mote platform experiment.
noise = open("radio-noise.txt", "r")
lines = noise.readlines()
for line in lines:
    s = line.strip()
    if s != "":
        val = int(s)
        m1.addNoiseTraceReading(val)
        m2.addNoiseTraceReading(val)
        m3.addNoiseTraceReading(val)
        m4.addNoiseTraceReading(val)
        m5.addNoiseTraceReading(val)
        m6.addNoiseTraceReading(val)
        m7.addNoiseTraceReading(val)
        m8.addNoiseTraceReading(val)
        m9.addNoiseTraceReading(val)
        m10.addNoiseTraceReading(val)

m1.createNoiseModel()
m2.createNoiseModel()
m3.createNoiseModel()
m4.createNoiseModel()
m5.createNoiseModel()
m6.createNoiseModel()
m7.createNoiseModel()
m8.createNoiseModel()
m9.createNoiseModel()
m10.createNoiseModel()

for i in range(0, 20000):          #  make the simulator run 2000 clock ticks.
    t.runNextEvent()             # 8. the way running a TOSSIM simulator is with "runNextEvent()"
