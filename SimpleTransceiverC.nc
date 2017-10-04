

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

    interface Random;
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

  bool requestSendInProgress = FALSE;
  bool responseSendInProgress = FALSE;
  int16_t responseCounter = -1;
  am_addr_t responseAddress;

  event void Boot.booted() {
    dbg("out", "[%d] booted (TEST: does nodeId match address? %d)\n", TOS_NODE_ID, call AMPacket.address());
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

    if (!requestSendInProgress) {
      // responseCounter == -1 is the initial state, before any requests has been sent
      if (responseCounter != -1) {
        if (responseCounter < N_NEIGHBORS) {
          dbg("out", "REPORT: failure\n");
        } else {
          dbg("out", "REPORT: success\n");
        }
      }

      responseCounter = 0;

      payload = (Payload*)(call Packet.getPayload(&requestPacket, sizeof(Payload)));

      payload->messageType = REQUEST;

      if (call AMSend.send(AM_BROADCAST_ADDR, &requestPacket, sizeof(Payload)) == SUCCESS) {
	       //dbg("out", "sendStart\n");
         requestSendInProgress = TRUE;
      } else {
        responseCounter = -1; // to prevent printing a report, when the packet couldn't be sent
      }
    }
  }

  event void AMSend.sendDone(message_t* msg, error_t error) {
    if (msg == &requestPacket) {
      dbg("out", "Req sent (broadcast to neighbors)\n");
      requestSendInProgress = FALSE;
    }

    if (msg == &responsePacket) {
      dbg("out", "Resp sent (unicast to %d)\n", responseAddress);
      responseSendInProgress = FALSE;
    }
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t payloadLen) {
    if (payloadLen == sizeof(Payload)) {
      Payload* p = (Payload*)payload;

      if (p->messageType == REQUEST) {
        dbg("out", "Req received from: %d (can answer? %s)\n",
          call AMPacket.source(msg),
          !responseSendInProgress ? "yes" : "no");

        if (!responseSendInProgress) {
          sendResponse(msg);
        }
      }

      if (p->messageType == RESPONSE) {
        dbg("out", "Resp received from: %d\n", call AMPacket.source(msg));
        responseCounter++;
      }
    }
    return msg;
  }

  void sendResponse(message_t* msg) {

    int responseDelay = 2 * T * (call Random.rand16()) / (double)UINT16_MAX;

    dbg("out", "Starting response timer to fire with delay: %d\n", responseDelay);

    responseSendInProgress = TRUE;
    responseAddress = call AMPacket.source(msg);

    call ResponseTimer.startOneShot(responseDelay);
  }

  event void ResponseTimer.fired() {
    Payload* payload = (Payload*)(call Packet.getPayload(&responsePacket, sizeof(Payload)));
    payload->messageType = RESPONSE;

    if (call AMSend.send(responseAddress, &responsePacket, sizeof(Payload)) != SUCCESS) {
       dbg("out", "FAILED TO START SENDING RESPONSE TO %d\n", responseAddress);
       requestSendInProgress = FALSE;
    }
  }
}
