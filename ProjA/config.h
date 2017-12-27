#ifndef CONFIG_H
#define CONFIG_H

enum {
    AM_2_TO_1 = 44,
    AM_1_TO_0 = 55,
    AM_0_TO_PC = 66,
    AM_PC_TO_0 = 77,
    AM_0_TO_1 = 88,
    AM_1_TO_2 = 99,

    NODE_0 = 0,
    NODE_1 = 1,
    NODE_2 = 2,

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
