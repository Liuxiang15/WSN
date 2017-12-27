#include "printf.h"
#include "../aggregator.h"

module AssistC {
    uses interface Boot;
    uses interface Timer<TMilli> as Timer;
    uses interface SplitControl as AMControl;

    uses interface AMSend as ResponseSend;
    uses interface Packet as ResponseSendPacket;

    uses interface Receive as RequestReceive;
    uses interface Packet as RequestReceivePacket;

    uses interface Receive as DataReceive;
    uses interface Packet as DataReceivePacket;
}

implementation {
    message_t response_pkt;
    uint8_t received[DATA_TOTAL];
    uint8_t numbers[DATA_TOTAL];

    event void Boot.booted()
    {
        uint16_t i;
        for(i = 0; i < DATA_TOTAL; i++)
        {
            received[i] = 0;
        }
        call AMControl.start();
    }

    event void Timer.fired()
    {

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
        //NOTHING
    }

    event void ResponseSend.sendDone(message_t* msg, error_t err)
    {
        if(&response_pkt == msg && err == SUCCESS)
        {
            printf("Response pkt has been successfully sent.\n");
            printfflush();
        }
    }

    event message_t* RequestReceive.receive(message_t* msg, void* payload, uint8_t len)
    {
        Request_Msg* rcv_payload;
        uint16_t seq;
        if(len == sizeof(Request_Msg))
        {
            printf("New request has been successfully received.\n");
            printfflush();

            rcv_payload = (Request_Msg*)payload;
            seq = rcv_payload->seq;

            printf("Sequence is %u.\n", seq);
            printfflush();

            //todo: send as response
        }
        return msg;
    }

    event message_t* DataReceive.receive(message_t* msg, void* payload, uint8_t len)
    {
        Data_Msg* rcv_payload;
        uint16_t seq;
        uint32_t num;
        if(len == sizeof(Data_Msg))
        {
            printf("New data has been successfully received.\n");
            printfflush();

            rcv_payload = (Data_Msg*)payload;
            seq = rcv_payload->seq;
            num = rcv_payload->num;

            printf("Sequence is %u and number is %lu.\n", seq, num);
            printfflush();

            received[seq] = 1;
            numbers[seq] = num;
        }
        return msg;
    }
}
