#include "../config.h"

configuration BaseStationC {

}

implementation {
    components MainC;
    components LedsC;
    components BaseStationP as App;
    components ActiveMessageC;
    components SerialActiveMessageC;
    components new TimerMilliC() as Timer;
    components new SerialAMSenderC(AM_0_TO_PC);
    components new SerialAMReceiverC(AM_PC_TO_0);
    components new AMSenderC(AM_0_TO_1);
    components new AMReceiverC(AM_1_TO_0);

    App.Boot -> MainC;
    App.Leds -> LedsC;
    App.Timer -> Timer;

    App.RadioControl -> ActiveMessageC;
    App.SerialControl -> SerialActiveMessageC;

    App.UartPacket -> SerialAMSenderC;
    App.UartAMPacket -> SerialAMSenderC;
    App.UartSend -> SerialAMSenderC;
    App.UartReceive -> SerialAMReceiverC;

    App.RadioPacket -> AMSenderC;
    App.RadioAMPacket -> AMSenderC;
    App.RadioSend -> AMSenderC;
    App.RadioReceive -> AMReceiverC;

    App.ModifyAck -> AMSenderC;
}
