#include "../aggregator.h"
#include "printf.h"

configuration AssistAppC{

}

implementation {
    components MainC, LedsC, PrintfC;
    components new TimerMilliC() as Timer;
    components ActiveMessageC;
    components new AMSenderC(AM_RESPONSE_MSG) as ResponseSender;
    components new AMReceiverC(AM_REQUEST_MSG) as RequestReceiver;
    components new AMReceiverC(AM_DATA_MSG) as DataReceiver;

    components AssistC;

    AssistC.Boot -> MainC.Boot;
    AssistC.Timer -> Timer;
    AssistC.Leds -> LedsC;
    AssistC.AMControl -> ActiveMessageC.SplitControl;

    AssistC.ResponseSend -> ResponseSender.AMSend;
    AssistC.ResponseSendPacket -> ResponseSender.Packet;
    AssistC.ResponseSendAMPacket -> ResponseSender;
    AssistC.assistAck -> ResponseSender;

    AssistC.RequestReceive -> RequestReceiver.Receive;
    AssistC.RequestReceivePacket -> RequestReceiver.Packet;
    AssistC.DataReceive -> DataReceiver.Receive;
    AssistC.DataReceivePacket -> DataReceiver.Packet;
}
