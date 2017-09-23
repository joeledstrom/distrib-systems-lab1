/*

Other implementation, using a queue for buffered messages:
  A send-loop pops messages from the buffers.
  It is activated when queue goes from size 0 to 1. (after a receive request)
  It is deactivated when queue is empty. (after a timer.fired)

*/


#ifndef MOTE_H
#define MOTE_H
 

// "external type" to ignore endianness
typedef nx_struct packet {
     nx_uint16_t seq;
     nx_uint16_t type;
} packet_t;
 
#endif

module MoteC
{
    uses interface Boot; // listens on booted
    uses interface Timer<TMilli> as BTimer; // broadcast timer
    uses interface Timer<TMilli> as RTimer; // response timer
    uses interface Packet;   // access message_t fields
    uses interface AMPacket; // access message_t fields
    uses interface AMSend;   // post send requests to multiplexing radio
    uses interface SplitControl as RadioControl; // listen for start/stop from ActiveMessageC.SplitControl
    uses interface Receive;
    uses interface Random;
}

implementation
{/*////////////////////////////////*/
enum {
    EXPECTED_RESPONSES = 2,
    REQUEST = 100, RESPONSE = 200,
    TIMER_PERIOD_MILLI = 250, 
};
message_t request ;// = {0, REQUEST}; // buffered request
message_t response; // = {0, RESPONSE}; // buffered response
bool req_lock = FALSE;
bool res_lock = FALSE;
uint8_t response_counter = 0; // count responses received after broadcast
uint8_t sequence = 0; // identifies current broadcast; wraps around to zero again


/*
The AM-based radio is not automatically started when the system boots nor on-demand.
So, it must be done manually at booted:
*/
event void Boot.booted() {
    call RadioControl.start(); // start radio on boot
}

event void RadioControl.startDone(error_t error)
{
    if (error == SUCCESS)
        call BTimer.startPeriodic(TIMER_PERIOD_MILLI);
    else
        call RadioControl.start(); // retry start radio
}

event void RadioControl.stopDone(error_t error) {} // ignore radio stop event



event void BTimer.fired() // time to broadcast
{
    packet_t *payload;
    if (req_lock) return; // For the duration of the send attempt, the packet is owned by the radio
                          // and user code must not access it; drops message.
    
    // check if the previous broadcast got the expected number of responses
    if (response_counter < EXPECTED_RESPONSES)
        dbg("REPORT", "FAILURE; %d/%d responses received\n", response_counter, EXPECTED_RESPONSES);
    else
        dbg("REPORT", "SUCCESS; %d/%d responses received\n", response_counter, EXPECTED_RESPONSES);
    // prepare for next broadcast period:
    response_counter = 0;
    sequence += 1; // wraps around

    // send broadcast
    payload = call AMSend.getPayload(&request, sizeof (packet_t));
    if (payload) { // can send if the payload fits
        payload->seq = sequence;
        payload->type = REQUEST;
        if (call AMSend.send(AM_BROADCAST_ADDR, &request, sizeof (packet_t)) == SUCCESS)
            req_lock = TRUE; // For the duration of the send attempt, the packet is owned by the radio, and user code must not access it.
    }
    
}
event void RTimer.fired() // time to respond
{
    if (res_lock) return; // during sending, the packet is owned by the radio, and user code must not access it.
                          // Drops message.
    // send the stored response; the payload is already set and source is automatically set... I think.
    if (call AMSend.send(call AMPacket.destination(&response), &response, sizeof (packet_t)) == SUCCESS) {
        res_lock = TRUE;
    }
}

event void AMSend.sendDone(message_t* msg, error_t error)
{
    if (msg == &request) // if a request was sent
        req_lock = FALSE; // indicate that the message buffer can be reused
    else if(msg == &response) { // if a response was sent
        res_lock = FALSE;
    }
}


event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len)
{
    packet_t *msg_payload, *res_payload; // {.seq, .type}
    if (len == sizeof(packet_t)) {
        msg_payload = payload;
        if (msg_payload->type == REQUEST) {
            if (res_lock) return msg; // can't touch the buffered response; drop message
            if (call RTimer.isRunning()) return msg; // a response is already pending; drop the new message

            call RTimer.startOneShot(2 * TIMER_PERIOD_MILLI * (call Random.rand16() / 65535.0));
            
            // update the buffered response
            msg_payload = payload; // cast to packet_t
            res_payload = call AMSend.getPayload(&response, sizeof (packet_t));
            if (res_payload) { // can send if the payload fits
                res_payload->seq = msg_payload->seq;
                res_payload->type = RESPONSE;
                call AMPacket.setDestination(&response, call AMPacket.source(msg)); // used later when sending the response
            } // else debug to detect unexpected error
        }
        else if (msg_payload->type == RESPONSE) {
            msg_payload = payload; // cast
            // responses aren't broadcasts so we know it is for us
            if (msg_payload->seq == sequence) // check if the response is for this sequence
                response_counter += 1;
        }
    }
    return msg;
}
}/*////////////////////////////////*/