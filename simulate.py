from TOSSIM import *
import sys, random

t = Tossim([])
r = t.radio();

t.addChannel("SimpleTransceiverC", sys.stdout)
#t.addChannel("TestACK", sys.stdout)



nodes = [t.getNode(x) for x in range(10)]

def connect(x,y):
    if y:
        r.add(x.id(), y.id(), -60.0)
        r.add(y.id(), x.id(), -60.0)
    return y

reduce(connect, nodes + nodes[:1])

noise = open("radio-noise.txt", "r")
lines = noise.readlines()
for line in lines:
  str = line.strip()
  if (str != ""):
    val = int(str)
    for n in nodes:
        n.addNoiseTraceReading(val)

for n in nodes:
    n.bootAtTime(random.randint(1, 82123411))
    n.createNoiseModel

for i in range(0, 20000):
    t.runNextEvent();
