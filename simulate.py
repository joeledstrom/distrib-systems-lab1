from TOSSIM import *
import sys, random

t = Tossim([])
r = t.radio();

t.addChannel("SimpleTransceiverC", sys.stdout)
#t.addChannel("TestACK", sys.stdout)


# Create 10 nodes
nodes = [t.getNode(x) for x in range(10)]

# Connect a pair of nodes
def connect(x,y):
    if y:
        r.add(x.id(), y.id(), -60.0)
        r.add(y.id(), x.id(), -60.0)
    return y

# Abuse reduce function to create a circle of connected nodes
reduce(connect, nodes + nodes[:1])

# Add noise trace readings to all nodes
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
    n.createNoiseModel()

for i in range(0, 20000):
    t.runNextEvent();
