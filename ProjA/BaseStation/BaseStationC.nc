#include "../config.h"

configuration BaseStationC {

}

implementation {
    components MainC;
    components LedsC;
    components BaseStationP as App;
    components ActiveMessageC;
    components SerialActiveMessageC;
    components new SerialAMSenderC(AM_SENSOR);
    components new SerialAMReceiverC(AM_MODIFY);
    components new AMSenderC(AM_MODIFY);
    components new AMReceiverC(AM_SENSOR);

    App.Boot -> MainC;
    App.Leds -> LedsC;

    App.RadioControl -> ActiveMessageC;
    App.SerialControl -> SerialActiveMessageC;

    App.UartSend -> SerialAMSenderC;
    App.UartReceive -> SerialAMReceiverC;
    App.UartPacket -> SerialAMSenderC;
    App.UartAMPacket -> SerialAMSenderC;

    App.RadioSend -> AMSenderC;
    App.RadioReceive -> AMReceiverC;
    App.RadioPacket -> AMSenderC;
    App.RadioAMPacket -> AMSenderC;
}
