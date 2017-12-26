#include "printf.h"

module MasterC {
    uses interface Boot;
    uses interface Timer<TMilli> as Timer;
    uses interface SplitControl as AMControl;

    uses interface AMSend as ResultSend;
    uses interface AMSend as RequestSend;

    uses interface Packet as ResultSendPacket;
    uses interface Packet as RequestSendPacket;

    uses interface Receive as DataReceive;
    uses interface Receive as ResponseReceive;

    uses interface Packet as DataReceivePacket;
    uses interface Packet as ResponseReceivePacket;
}

implementation {
    event void Boot.booted()
    {
        call AMControl.start();
        printf("g");
        printfflush();
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

    }

    event void ResultSend.sendDone(message_t* msg, error_t err)
    {

    }

    event void RequestSend.sendDone(message_t* msg, error_t err)
    {

    }

    event message_t* DataReceive.receive(message_t* msg, void* payload, uint8_t len)
    {

    }

    event message_t* ResponseReceive.receive(message_t* msg, void* payload, uint8_t len)
    {

    }
}
