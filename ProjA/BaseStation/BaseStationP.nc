#include "../config.h"

module BaseStationP @safe() {
    uses {
        interface Boot;
        interface Leds;
        interface Timer<TMilli> as Timer;
        interface SplitControl as SerialControl;
        interface SplitControl as RadioControl;

        interface AMSend as UartSend;
        interface Receive as UartReceive;
        interface Packet as UartPacket;
        interface AMPacket as UartAMPacket;

        interface AMSend as RadioSend;
        interface Receive as RadioReceive;
        interface Packet as RadioPacket;
        interface AMPacket as RadioAMPacket;

        interface PacketAcknowledgements as ModifyAck;
    }
}

implementation {
    message_t uartQueueBufs[QUEUE_SIZE]; // SensorMsg
    message_t* ONE_NOK uartQueue[QUEUE_SIZE];
    uint16_t uartIn = 0;
    uint16_t uartOut = 0;
    bool uartBusy = FALSE;
    bool uartFull = TRUE;

    message_t radioQueueBufs[QUEUE_SIZE]; // ModifyMsg
    message_t* ONE_NOK radioQueue[QUEUE_SIZE];
    uint16_t radioIn = 0;
    uint16_t radioOut = 0;
    bool radioBusy = FALSE;
    bool radioFull = TRUE;

    task void uartSendTask();
    task void radioSendTask();

    event void Boot.booted() {
        uint16_t i;

        for (i = 0; i < QUEUE_SIZE; i++) {
            uartQueue[i] = &uartQueueBufs[i];
        }

        for (i = 0; i < QUEUE_SIZE; i++) {
            radioQueue[i] = &radioQueueBufs[i];
        }

        call RadioControl.start();
    }

    event void RadioControl.startDone(error_t error) {
        if (error == SUCCESS) {
            radioFull = FALSE;
            call SerialControl.start();
        }
        else {
            call RadioControl.start();
        }
    }

    event void SerialControl.startDone(error_t error) {
        if (error == SUCCESS) {
            uartFull = FALSE;
            call Timer.startPeriodic(TIMER_PERIOD_MILLI);
        }
        else {
            call SerialControl.start();
        }
    }

    event void SerialControl.stopDone(error_t error) {

    }

    event void RadioControl.stopDone(error_t error) {

    }

    event void Timer.fired() {
        call Leds.led1Toggle();
    }

    event message_t* RadioReceive.receive(message_t* msg, void* payload, uint8_t len) {
        SensorMsg* dummy = (SensorMsg*)payload;
        if (len == sizeof(SensorMsg)) {
            call Leds.led2Toggle();
            atomic if (!uartFull) {
                uartQueueBufs[uartIn] = *msg;
                if (++uartIn >= QUEUE_SIZE) {
                    uartIn = 0;
                }
                if (uartIn == uartOut) {
                    uartFull = TRUE;
                }
                if (!uartBusy) {
                    post uartSendTask();
                    uartBusy = TRUE;
                }
            }
        }
        return msg;
    }

    task void uartSendTask() {
        am_addr_t src;
        message_t* msg;

        atomic if (uartIn == uartOut && !uartFull) {
            uartBusy = FALSE;
            return;
        }

        msg = uartQueue[uartOut];
        src = call RadioAMPacket.source(msg);
        call UartPacket.clear(msg);
        call UartAMPacket.setSource(msg, src);

        if (call UartSend.send(AM_BROADCAST_ADDR, msg, sizeof(SensorMsg)) == SUCCESS) {

        }
        else {
            post uartSendTask();
        }
    }

    event void UartSend.sendDone(message_t* msg, error_t error) {
        if (error == SUCCESS) {
            atomic if (msg == uartQueue[uartOut]) {
                if (++uartOut >= QUEUE_SIZE) {
                    uartOut = 0;
                }
                if (uartFull) {
                    uartFull = FALSE;
                }
            }
        }
        post uartSendTask();
    }

    event message_t* UartReceive.receive(message_t* msg, void* payload, uint8_t len) {
        if (len == sizeof(ModifyMsg)) {
            call Leds.led1Toggle();
            atomic if (!radioFull) {
                radioQueueBufs[radioIn] = *msg;
                if (++radioIn >= QUEUE_SIZE) {
                    radioIn = 0;
                }
                if (radioIn == radioOut) {
                    radioFull = TRUE;
                }
                if (!radioBusy) {
                    post radioSendTask();
                    radioBusy = TRUE;
                }
            }
        }
        return msg;
    }

    task void radioSendTask() {
        am_addr_t source;
        message_t* msg;

        atomic if (radioIn == radioOut && !radioFull) {
            radioBusy = FALSE;
            return;
        }

        msg = radioQueue[radioOut];
        source = call UartAMPacket.source(msg);
        call RadioPacket.clear(msg);
        call RadioAMPacket.setSource(msg, source);
        call ModifyAck.requestAck(msg);

        if (call RadioSend.send(NODE_1, msg, sizeof(ModifyMsg)) == SUCCESS) {

        }
        else {

        }
    }

    event void RadioSend.sendDone(message_t* msg, error_t error) {
        if (error == SUCCESS) {
            if (call ModifyAck.wasAcked(msg)) {
                call Leds.led0Toggle();
                atomic if (msg == radioQueue[radioOut]) {
                    if (++radioOut >= QUEUE_SIZE) {
                        radioOut = 0;
                    }
                    if (radioFull) {
                        radioFull = FALSE;
                    }
                }
            }
        }
        post radioSendTask();
    }
}
