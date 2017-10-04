configuration MoteAppC
{

}

implementation
{
enum { AM_SIMPLE_TRANSCEIVER_MSG = 10 };

components MainC, MoteC, ActiveMessageC, RandomC;
components new AMSenderC(AM_SIMPLE_TRANSCEIVER_MSG); // private instance
components new AMReceiverC(AM_SIMPLE_TRANSCEIVER_MSG); // private instance
components new TimerMilliC() as Timer0; // private instance
components new TimerMilliC() as Timer1; // private instance


/* Wiring; user -> provider */
MoteC.Boot -> MainC; // Main.Boot
MoteC.RTimer -> Timer0; // TimerMilliC.Timer
MoteC.BTimer -> Timer1; // TimerMilliC.Timer

MoteC.AMPacket -> AMSenderC; // AMSenderC.AMPacket
MoteC.AMSend -> AMSenderC;   // AMSenderC.AMSend
MoteC.Receive -> AMReceiverC; // AMReceiverC.Receive
MoteC.RadioControl -> ActiveMessageC; // ActiveMessageC.SplitControl

MoteC.Random -> RandomC; // RnadomC.Random

}
