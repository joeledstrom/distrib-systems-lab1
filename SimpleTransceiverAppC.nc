

configuration SimpleTransceiverAppC {}
implementation {

  enum {
	  AM_SIMPLE_TRANSCEIVER_MSG = 10, // specify the AM type of the packet.
  };

  components MainC;
  components SimpleTransceiverC as App;
  components new AMSenderC(AM_SIMPLE_TRANSCEIVER_MSG);
  components new AMReceiverC(AM_SIMPLE_TRANSCEIVER_MSG);
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components ActiveMessageC;
  components RandomC;

  App.Boot -> MainC.Boot;

  App.IntervalTimer -> Timer0;
  App.ResponseTimer -> Timer1;

  App.AMControl -> ActiveMessageC;

  App.Receive -> AMReceiverC;

  App.AMSend -> AMSenderC;
  App.Packet -> AMSenderC;
  App.AMPacket -> AMSenderC;

  App.Random -> RandomC;

  //App.PacketAcknowledgements -> AMSenderC;
}
