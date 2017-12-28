#ifndef CONFIG_H
#define CONFIG_H

enum {
    AM_2_TO_1 = 0x94,
    AM_1_TO_0 = 0x95,
    AM_0_TO_PC = 0x96,
    AM_PC_TO_0 = 0x97,
    AM_0_TO_1 = 0x98,
    AM_1_TO_2 = 0x99,

    NODE_0 = 34,
    NODE_1 = 35,
    NODE_2 = 36,

    TIMER_PERIOD_MILLI = 200,
    QUEUE_SIZE = 32
};

typedef nx_struct SensorMsg {
    nx_uint16_t nodeid;
    nx_uint16_t counter;
    nx_uint16_t temperature;
    nx_uint16_t humidity;
    nx_uint16_t illumination;
    nx_uint16_t timepoint;
} SensorMsg;

typedef nx_struct ModifyMsg {
    nx_uint16_t frequency;
} ModifyMsg;

#endif
