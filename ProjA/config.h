#ifndef CONFIG_H
#define CONFIG_H

enum {
    AM_SENSOR = 44,
    AM_MODIFY = 55,
    TIMER_PERIOD_MILLI = 100,
    QUEUE_SIZE = 32
};

typedef nx_struct SensorMsg {
    nx_uint16_t nodeid;
    nx_uint16_t counter;
    nx_uint16_t timepoint;
    nx_uint16_t temperature;
    nx_uint16_t humidity;
    nx_uint16_t illumination;
} SensorMsg;

typedef nx_struct ModifyMsg {
    nx_uint16_t frequency;
} ModifyMsg;

#endif
