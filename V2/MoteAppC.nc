configuration
{

}

implementation
{
//enum { AM_REQ = 42, AM_REP = 43 }; send and receive same type of messages
components MainC, MoteC, ActiveMessageC, RandomC;
components new AMSenderC(AM_SIMPLE_TRANSCEIVER_MSG); // private instance
components new AMReceiverC(AM_SIMPLE_TRANSCEIVER_MSG); // private instance
components new TimerMilliC() as Timer0; // private instance
components new TimerMilliC() as Timer1; // private instance


/* Wiring; user -> provider */
// you can omit one of the interface name.
MoteC.Boot -> MainC; // Main.Boot
MoteC.RTimer -> Timer0; // TimerMilliC.Timer
MoteC.BTimer -> Timer1; // TimerMilliC.Timer

MoteC.AMPacket -> AMSenderC; // AMSenderC.AMPacket
MoteC.AMSend -> AMSenderC;   // AMSenderC.AMSend
MoteC.Receive -> AMReceiver; // AMReceiverC.Receive
MoteC.RadioControl -> ActiveMessageC; // ActiveMessageC.SplitControl

MoteC.Random -> RandomC; // RnadomC.Random
//MainC.SoftwareInit -> RandomC; // RandomC.Init; (Auto-initialize)
}