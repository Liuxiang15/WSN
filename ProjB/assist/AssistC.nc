#include "printf.h"
#include "../aggregator.h"

module AssistC {
    uses interface Boot;
    uses interface Timer<TMilli> as Timer;
    uses interface Leds;
    uses interface SplitControl as AMControl;

    uses interface AMSend as ResponseSend;
    uses interface Packet as ResponseSendPacket;
    uses interface AMPacket as ResponseSendAMPacket;

    uses interface Receive as RequestReceive;
    uses interface Packet as RequestReceivePacket;

    uses interface Receive as DataReceive;
    uses interface Packet as DataReceivePacket;

    uses interface PacketAcknowledgements as assistAck;
}

implementation {
    message_t pkt;
    uint32_t numbers[DATA_TOTAL];

    message_t assistQueueBufs[QUEUE_SIZE];
    message_t* ONE_NOK assistQueue[QUEUE_SIZE];
    uint16_t assistIn = 0;
    uint16_t assistOut = 0;
    bool assistBusy = FALSE;
    bool assistFull = TRUE;

    task void assistSendTask();

    event void Boot.booted()
    {
        uint16_t i;
        for(i = 0; i < DATA_TOTAL; i++)
        {
            numbers[i] = UINT_MAX;
        }

        for (i = 0; i < QUEUE_SIZE; i++)
        {
            assistQueue[i] = &assistQueueBufs[i];
        }
        call AMControl.start();
    }

    event void AMControl.startDone(error_t err)
    {
        if(err == SUCCESS)
        {
            call Timer.startPeriodic(100);
        }
        else
        {
            call AMControl.start();
        }
    }

    event void AMControl.stopDone(error_t err)
    {

    }

    event void Timer.fired()
    {
        call Leds.led1Toggle();
    }

    event message_t* RequestReceive.receive(message_t* msg, void* payload, uint8_t len)
    {
        Response_Msg* responseMsg;
        uint16_t seq;
        if(len == sizeof(Request_Msg))
        {
            call Leds.led0Toggle();
            seq = ((Request_Msg*)payload)->seq;
            if (numbers[seq] != UINT_MAX)
            {
                responseMsg = (Response_Msg*)(call ResponseSendPacket.getPayload(&pkt, sizeof(Response_Msg)));
                atomic if (responseMsg != NULL && !assistFull)
                {
                    assistQueueBufs[assistIn] = pkt;
                    if (++assistIn >= QUEUE_SIZE)
                    {
                        assistIn = 0;
                    }
                    if (assistIn == assistOut)
                    {
                        assistFull = TRUE;
                    }
                    if (!assistBusy)
                    {
                        post assistSendTask();
                        assistBusy = TRUE;
                    }
                }
            }
        }
        return msg;
    }

    task void assistSendTask()
    {
        am_addr_t source;
        message_t* msg;

        atomic if (assistIn == assistOut && !assistFull)
        {
            assistBusy = FALSE;
            return;
        }
        msg = assistQueue[assistOut];
        source = call ResponseSendAMPacket.source(msg);
        call ResponseSendPacket.clear(msg);
        call ResponseSendAMPacket.setSource(msg, source);
        call assistAck.requestAck(msg);

        if (call ResponseSend.send(MASTER_ID, msg, sizeof(Response_Msg)) == SUCCESS)
        {

        }
        else
        {

        }
    }

    event void ResponseSend.sendDone(message_t* msg, error_t err)
    {
        if (err == SUCCESS) {
            if (call assistAck.wasAcked(msg)) {
                call Leds.led0Toggle();
                atomic if (msg == assistQueue[assistOut]) {
                    if (++assistOut >= QUEUE_SIZE) {
                        assistOut = 0;
                    }
                    if (assistFull) {
                        assistFull = FALSE;
                    }
                }
            }
        }
        post assistSendTask();
    }

    event message_t* DataReceive.receive(message_t* msg, void* payload, uint8_t len)
    {
        Data_Msg* rcv_payload;
        if(len == sizeof(Data_Msg))
        {
            call Leds.led2Toggle();
            rcv_payload = (Data_Msg*)payload;
            numbers[rcv_payload->seq - 1] = rcv_payload->num;
        }
        return msg;
    }
}
