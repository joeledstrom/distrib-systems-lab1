

module SimpleTransceiverC @safe() {
  uses {
    interface Boot;

    interface Timer<TMilli> as IntervalTimer;
    interface Timer<TMilli> as ResponseTimer;

    interface SplitControl as AMControl;

    interface Receive;
    interface AMSend;

    interface Packet;
	  interface AMPacket;

    //interface PacketAcknowledgements;
  }
}
implementation {

  const int T = 250;

  const int N_NEIGHBORS = 2;

  void sendResponse(message_t* msg);

  message_t requestPacket;
  message_t responsePacket;

  typedef enum {
    REQUEST,
    RESPONSE
  } MessageType;

  typedef nx_struct Payload {
    nx_uint8_t messageType;
  } Payload;

  bool requestSendInProgress;
  uint16_t responseCounter = -1;

  event void Boot.booted() {
    dbg("SimpleTransceiverC", "[%d] booted (TEST: does nodeId match address? %d)\n", TOS_NODE_ID, call AMPacket.address());
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call IntervalTimer.startPeriodic(T);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }

  event void IntervalTimer.fired() {

    Payload* payload;

    if (requestSendInProgress) {
      return;
    }
    else {
      // responseCounter == -1 is the initial state, before any requests has been sent
      if (responseCounter != -1) {
        if (responseCounter < N_NEIGHBORS) {
          dbg("SimpleTransceiverC", "[%d] failure\n", TOS_NODE_ID);
        } else {
          dbg("SimpleTransceiverC", "[%d] success\n", TOS_NODE_ID);
        }
      }

      responseCounter = 0;

      payload = (Payload*)(call Packet.getPayload(&requestPacket, sizeof(Payload)));

      payload->messageType = REQUEST;

      if (call AMSend.send(AM_BROADCAST_ADDR, &requestPacket, sizeof(Payload)) == SUCCESS) {
	       //dbg("SimpleTransceiverC", "SimpleTransceiverC: packet sent.\n", counter);
         requestSendInProgress = TRUE;
      }
    }
  }

  event void AMSend.sendDone(message_t* msg, error_t error) {

    if (msg == &requestPacket) {
      dbg("SimpleTransceiverC", "[%d] Req Sent!\n", TOS_NODE_ID);
      requestSendInProgress = FALSE;
    }

    if (msg == &responsePacket) {

    }
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t payloadLen) {   //4. when a message is received, come to here
    if (payloadLen == sizeof(Payload)) {
      Payload* p = (Payload*)payload;

      if (p->messageType == REQUEST) {
        sendResponse(msg);
      }

      if (p->messageType == RESPONSE) {
        responseCounter++;
      }
    }
    return msg;
  }

  void sendResponse(message_t* msg) {
    // start random timer:
    //   use ResponseTimer.startOneShot(ms)
    // set busy
  }

  event void ResponseTimer.fired() {
    // maybe use call AMPacket.sourceAddress(msg) to get the sender addr
    // unicast to sender
  }

}
