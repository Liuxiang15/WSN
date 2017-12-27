#include <Timer.h>
#include "../config.h"

configuration SensorAppC {

}

implementation {
    components MainC;
    components LedsC;
    components SensorC as App;
    components ActiveMessageC;
    components new TimerMilliC() as Timer;
    components new AMSenderC(AM_1_TO_0) as SensorSend;
    components new AMReceiverC(AM_2_TO_1) as SensorReceive;
    components new AMSenderC(AM_1_TO_2) as ModifySend;
    components new AMReceiverC(AM_0_TO_1) as ModifyReceive;
    components new SensirionSht11C() as Sensor_sht11;
    components new HamamatsuS1087ParC() as Sensor_s1087par;

    App.Boot -> MainC;
    App.Leds -> LedsC;
    App.Timer -> Timer;
    App.RadioControl -> ActiveMessageC;

    App.SensorPacket -> SensorSend;
    App.SensorAMPacket -> SensorSend;
    App.SensorSend -> SensorSend;
    App.SensorReceive -> SensorReceive;

    App.ModifyPacket -> ModifySend;
    App.ModifyAMPacket -> ModifySend;
    App.ModifySend -> ModifySend;
    App.ModifyReceive -> ModifyReceive;

    App.Read_Temperature -> Sensor_sht11.Temperature;
    App.Read_Humidity -> Sensor_sht11.Humidity;
    App.Read_Illumination -> Sensor_s1087par;

    App.SensorAck -> SensorSend;
    App.ModifyAck -> ModifySend;
}
