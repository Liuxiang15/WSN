#include "printf.h"

module MasterC {
    uses interface Boot;
    uses interface Timer<TMilli> as Timer;
    uses interface SplitControl as AMControl;

    uses interface AMSend as ResultSend;
    uses interface AMSend as RequestSend;

    uses interface Packet as ResultSendPacket;
    uses interface Packet as RequestSendPacket;

    uses interface Receive as DataReceive;
    uses interface Receive as ResponseReceive;

    uses interface Packet as DataReceivePacket;
    uses interface Packet as ResponseReceivePacket;
}

implementation {
    enum {
        UINT16_MAX = 65535,
        HALF_DATA_TOTAL = 1000,
        DATA_TOTAL = 2000,
    };
    uint16_t received_sum = 0;
    uint16_t data_start = 0;
    uint16_t confirmed_end = 0;

    uint8_t received[DATA_TOTAL];
    uint32_t small_heap[HALF_DATA_TOTAL], big_heap[HALF_DATA_TOTAL];
    uint16_t small_heap_size = 0, big_heap_size = 0;

    uint32_t max = 0, min = UINT16_MAX, sum = 0, average = 0, median = 0;

    message_t result_pkt, request_pkt;

    event void Boot.booted()
    {
        uint16_t i;
        for(i = 0; i < DATA_TOTAL; i++)
        {
            received[i] = 0;
        }
        call AMControl.start();
    }

    event void Timer.fired()
    {

    }

    event void AMControl.startDone(error_t err)
    {
        if(err == SUCCESS)
        {
            call Timer.startPeriodic(100);
        }
        else
        {
            call AMControl.start();
        }
    }

    event void AMControl.stopDone(error_t err)
    {
        // NOTHING
    }

    void register_new_number(uint16_t seq, uint32_t num)
    {
        if(received[seq] == 1)
            return;

        received_sum += 1;
        received[seq] = 1;

        if(received_sum == 1)
        {
            data_start = seq;
            confirmed_end = seq;
            printf("data start is %u\n", data_start);
        }
        else
        {
            uint8_t i;
            for(i = confirmed_end + 1; i != confirmed_end; i = (i % DATA_TOTAL) + 1)
            {
                if(received[i] == 1)
                {
                    confirmed_end = i;
                }
            }
            printf("confirmed_end now is %u.\n", confirmed_end);
        }
    }

    void calculate_basic_parts(uint32_t num)
    {
        max = max > num ? max : num;
        min = min < num ? min : num;
        sum = sum + num;
    }

    void adjust_small_heap()
    {
        uint16_t pos = small_heap_size - 1;
        while(pos != 0)
        {
            uint8_t swapped = 0;
            uint16_t parent = (pos - 1) / 2;
            uint32_t temp;
            if(small_heap[parent] > small_heap[pos])
            {
                swapped = 1;
                temp = small_heap[pos];
                small_heap[pos] = small_heap[parent];
                small_heap[parent] = temp;
            }
            if(swapped == 1)
            {
                pos = parent;
            }
            else
            {
                break;
            }
        }
    }

    void adjust_big_heap()
    {
        uint16_t pos = big_heap_size - 1;
        while(pos != 0)
        {
            uint8_t swapped = 0;
            uint16_t parent = (pos - 1) / 2;
            uint32_t temp;
            if(big_heap[parent] < big_heap[pos])
            {
                swapped = 1;
                temp = big_heap[pos];
                big_heap[pos] = big_heap[parent];
                big_heap[parent] = temp;
            }
            if(swapped == 1)
            {
                pos = parent;
            }
            else
            {
                break;
            }
        }
    }

    void extract_heap(uint8_t is_small)
    {
        uint16_t pos = 0;
        if(is_small)
        {
            small_heap_size -= 1;
            small_heap[0] = small_heap[small_heap_size];

            while(pos < small_heap_size)
            {
                uint16_t i = 2 * pos + 1, j = 2 * pos + 2;
                uint16_t smaller;
                uint32_t temp;

                if(i >= small_heap_size)
                    break;
                else if(j == small_heap_size)
                    smaller = i;
                else
                    smaller = small_heap[i] < small_heap[j] ? i : j;

                if(small_heap[pos] <= small_heap[smaller])
                    break;

                temp = small_heap[pos];
                small_heap[pos] = small_heap[smaller];
                small_heap[smaller] = temp;
                pos = smaller;
            }
        }
        else
        {
            big_heap_size -= 1;
            big_heap[0] = big_heap[big_heap_size];

            while(pos < big_heap_size)
            {
                uint16_t ii = 2 * pos + 1, j = 2 * pos + 2;
                uint16_t bigger;
                uint32_t temp;

                if(i >= big_heap_size)
                    break;
                else if(j == big_heap_size)
                    bigger = i;
                else bigger = big_heap[i] > big_heap[j] ? i : j;

                if(big_heap[pos] >= big_heap[bigger])
                    break;

                temp = big_heap[pos];
                big_heap[pos] = big_heap[bigger];
                big_heap[bigger] = temp;
                pos = bigger;
            }
        }
    }

    void insert_into_heap(uint32_t num)
    {
        if(received_sum == 1)
        {
            // just for temporary use!
            small_heap[0] = num;
        }
        else if(received_sum == 2)
        {
            small_heap_size = 1;
            big_heap_size = 1;
            if(num > small_heap[0])
            {
                big_heap[0] = small_heap[0];
                small_heap[0] = num;
            }
            else
            {
                big_heap[0] = num;
            }
        }
        else
        {
            if(num > small_heap[0])
            {
                small_heap[small_heap_size] = num;
                small_heap_size += 1;
                adjust_heap(1);
            }
            else
            {
                big_heap[big_heap_size] = num;
                big_heap_size += 1;
                adjust_heap(0);
            }
        }
    }

    event void ResultSend.sendDone(message_t* msg, error_t err)
    {
        if(&result_pkt == msg && err == SUCCESS)
        {
            printf("Result pkt has been successfully sent.\n");
            printfflush();
        }
    }

    event void RequestSend.sendDone(message_t* msg, error_t err)
    {
        if(&request_pkt == msg && err == SUCCESS)
        {
            printf("Request pkt has been successfully sent.\n");
            printfflush();
        }
    }

    event message_t* DataReceive.receive(message_t* msg, void* payload, uint8_t len)
    {
        Data* rcv_payload;
        uint16_t seq;
        uint32_t num;
        if(len == sizeof(Data))
        {
            printf("New data has been successfully received.\n");
            printfflush();

            rcv_payload = (Data*)payload;
            seq = rcv_payload->seq;
            num = rcv_payload->num;
            printf("Sequence is %u and number is %u.\n", seq, num);
            printfflush();

            register_new_number(seq, num);
            calculate_basic_parts(num);
            insert_into_heap(num);

            if(small_heap_size > big_heap_size + 1)
            {
                uint32_t temp = small_heap[0];
                extract_heap(1);
                big_heap_size += 1;
                big_heap[big_heap_size - 1] = temp;
                adjust_heap(0);
            }
            else if(small_heap_size < big_heap_size - 1)
            {
                uint32_t temp = big_heap[0];
                extract_heap(0);
                small_heap_size += 1;
                small_heap[small_heap_size - 1] = temp;
                adjust_heap(1);
            }

            printf("Already adjusted heaps.\n");
            printfflush();
        }
        return msg;
    }

    event message_t* ResponseReceive.receive(message_t* msg, void* payload, uint8_t len)
    {

    }
}
