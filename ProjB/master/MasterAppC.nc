#include"../aggregator.h"
#include "printf.h"

configuration MasterAppC{

}

implementation {
    components MainC, LedsC, PrintfC;
    components new TimerMilliC() as Timer;
    components ActiveMessageC;
    components new AMSenderC(AM_RESULT_MSG) as ResultSender;
    components new AMSenderC(AM_REQUEST_MSG) as RequestSender;
    components new AMReceiverC(AM_DATA_MSG) as DataReceiver;
    components new AMReceiverC(AM_RESPONSE_MSG) as ResponseReceiver;
    components new AMReceiverC(AM_ACK_MSG) as ACKReceiver;

    components MasterC;

    MasterC.Boot -> MainC.Boot;
    MasterC.Timer -> Timer;
    MasterC.Leds -> LedsC;
    MasterC.AMControl -> ActiveMessageC.SplitControl;

    MasterC.ResultSend -> ResultSender.AMSend;
    MasterC.ResultSendPacket -> ResultSender.Packet;
    MasterC.RequestSend -> RequestSender.AMSend;
    MasterC.RequestSendPacket -> RequestSender.Packet;

    MasterC.DataReceive -> DataReceiver.Receive;
    MasterC.DataReceivePacket -> DataReceiver.Packet;
    MasterC.ResponseReceive -> ResponseReceiver.Receive;
    MasterC.ResponseReceivePacket -> ResponseReceiver.Packet;

    MasterC.ACKReceive -> ACKReceiver.Receive;
}
