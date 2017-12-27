#include <Timer.h>
#include "../config.h"


module SensorC {
    uses {
        interface Boot;
        interface Leds;
        interface Timer<TMilli> as Timer;
        interface SplitControl as RadioControl;

        interface Packet as SensorPacket;
        interface AMPacket as SensorAMPacket;
        interface AMSend as SensorSend;

        interface Receive as ModifyReceive;

        interface Read<uint16_t> as Read_Temperature;
        interface Read<uint16_t> as Read_Humidity;
        interface Read<uint16_t> as Read_Illumination;

        interface PacketAcknowledgements as SensorAck;
    }
}

implementation {
    uint16_t counter = 0;
    message_t sensorPkt;
    SensorMsg curSensorMsg;

    message_t sensorQueueBufs[QUEUE_SIZE]; // SensorMsg
    message_t* ONE_NOK sensorQueue[QUEUE_SIZE];
    uint16_t sensorIn = 0;
    uint16_t sensorOut = 0;
    bool sensorBusy = FALSE;
    bool sensorFull = TRUE;

    task void sensorSendTask();

    void preparation() {
        SensorMsg* sensorMsg = (SensorMsg*)(call SensorPacket.getPayload(&sensorPkt, sizeof(SensorMsg)));
        if (sensorMsg == NULL) {
            return;
        }

        sensorMsg->nodeid = TOS_NODE_ID;
        sensorMsg->counter = counter;
        sensorMsg->timepoint = call Timer.getNow();
        sensorMsg->temperature = curSensorMsg.temperature;
        sensorMsg->humidity = curSensorMsg.humidity;
        sensorMsg->illumination = curSensorMsg.illumination;

        atomic if (!sensorFull) {
            sensorQueueBufs[sensorIn] = sensorPkt;

            if (++sensorIn >= QUEUE_SIZE) {
                sensorIn = 0;
            }
            if (sensorIn == sensorOut) {
                sensorFull = TRUE;
            }
            if (!sensorBusy) {
                post sensorSendTask();
                sensorBusy = TRUE;
            }
        }
    }
    event void Boot.booted() {
        uint16_t i;

        for (i = 0; i < QUEUE_SIZE; i++) {
            sensorQueue[i] = &sensorQueueBufs[i];
        }

        call RadioControl.start();
    }

    event void RadioControl.startDone(error_t error) {
        if (error == SUCCESS) {
            sensorFull = FALSE;
            call Timer.startPeriodic(TIMER_PERIOD_MILLI);
        }
        else {
            call RadioControl.start();
        }
    }

    event void RadioControl.stopDone(error_t error) {

    }

    event void Timer.fired() {
        ++counter;
        call Read_Temperature.read();
        call Read_Humidity.read();
        call Read_Illumination.read();
        call Leds.led1Toggle();
        preparation();
    }

    event void Read_Temperature.readDone(error_t result, uint16_t data) {
        if (result == SUCCESS) {
            curSensorMsg.temperature = (nx_uint16_t)(-39.6 + 0.01 * data);
        }
    }

    event void Read_Humidity.readDone(error_t result, uint16_t data) {
        if (result == SUCCESS) {
            curSensorMsg.humidity = (nx_uint16_t)(-4.0 + 0.0405 * data - 0.00000028 * data * data);
            curSensorMsg.humidity += (nx_uint16_t)((curSensorMsg.temperature - 25.0) * (0.01 + 0.00008 * data));
        }
    }

    event void Read_Illumination.readDone(error_t result, uint16_t data) {
        if (result == SUCCESS) {
            curSensorMsg.illumination = data;
        }
    }

    task void sensorSendTask() {
        am_addr_t source;
        message_t* msg;

        atomic if (sensorIn == sensorOut && !sensorFull) {
            sensorBusy = FALSE;
            return;
        }

        msg = sensorQueue[sensorOut];
        source = call SensorAMPacket.source(msg);
        call SensorPacket.clear(msg);
        call SensorAMPacket.setSource(msg, source);
        call SensorAck.requestAck(msg);

        if (call SensorSend.send(NODE_1, msg, sizeof(SensorMsg)) == SUCCESS) {

        }
        else {

        }
    }

    event void SensorSend.sendDone(message_t* msg, error_t error) {
        if (error == SUCCESS) {
            if (call SensorAck.wasAcked(msg)) {
                call Leds.led0Toggle();
                atomic if (msg == sensorQueue[sensorOut]) {
                    if (++sensorOut >= QUEUE_SIZE) {
                        sensorOut = 0;
                    }
                    if (sensorFull) {
                        sensorFull = FALSE;
                    }
                }
            }
        }
        post sensorSendTask();
    }

    event message_t* ModifyReceive.receive(message_t* msg, void* payload, uint8_t len) {
        if (len == sizeof(ModifyMsg)) {
            call Timer.startPeriodic(((ModifyMsg*)payload)->frequency);
        }
        return msg;
    }
}
