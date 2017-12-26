#ifndef AGGREGATOR_H
#define AGGREGATOR_H

nx_struct Data
{
    nx_uint16_t seq;
    nx_uint32_t num;
};

nx_struct Result
{
    nx_uint8_t group;
    nx_uint32_t max;
    nx_uint32_t min;
    nx_uint32_t sum;
    nx_uint32_t average;
    nx_uint32_t median;
};

nx_struct Request
{
    nx_uint16_t seq;
};

nx_struct Response
{
    nx_uint8_t seq;
    nx_uint8_t num;
};

enum {
    AM_DATA_MSG= 6,
    AM_RESULT_MSG = 7,
    AM_REQUEST_MSG = 8,
    AM_RESPONSE_MSG = 9
};

#endif
