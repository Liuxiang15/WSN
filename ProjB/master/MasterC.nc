#include "printf.h"
#include "../aggregator.h"

module MasterC {
    uses interface Boot;
    uses interface Leds;
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

    uses interface Receive as ACKReceive;
}

implementation {

    uint16_t received_sum = 0;
    uint16_t start_seq = 0;
    uint16_t max_seq = 0;
    uint16_t confirmed_end = 0;

    uint8_t vice_num = 0;

    uint8_t received[EIGHTH_DATA_TOTAL];
    uint32_t small_heap[HALF_DATA_TOTAL + 2], big_heap[HALF_DATA_TOTAL + 2];
    uint16_t small_heap_size = 0, big_heap_size = 0;

    uint32_t max = 0, min = UINT_MAX, sum = 0, average = 0, median = 0;

    uint8_t completed = 0;
    message_t result_pkt, request_pkt;

    void send_result();
    void send_request(uint16_t);
    void insert_into_heap(uint32_t);
    void extract_small_heap();
    void adjust_big_heap();
    void extract_big_heap();
    void adjust_small_heap();

    event void Boot.booted()
    {
        uint16_t i;
        for(i = 0; i < EIGHTH_DATA_TOTAL; i++)
        {
            received[i] = 0;
        }
        call AMControl.start();
    }

    event void Timer.fired()
    {
        if(completed == 0)
        {
            if(max_seq > confirmed_end + 1)
            {
                send_request((confirmed_end + 1 + start_seq) % DATA_TOTAL);
            }
        }
        else if(completed == 1)
        {
            send_result();
        }
    }

    event void AMControl.startDone(error_t err)
    {
        if(err == SUCCESS)
        {
            call Timer.startPeriodic(20);
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
        received_sum += 1;
        //printf("%u\n", received_sum);
        //printfflush();

    	if (received_sum == 1)
    	{
    		max_seq = 0;
    		confirmed_end = 0;
            start_seq = seq;
            received[0] = 1;
    	}
    	else
    	{
            uint16_t i;

            //seq = (seq - start_seq + DATA_TOTAL) % DATA_TOTAL;
            //seq -= start_seq;
            //if (seq < 0) seq += DATA_TOTAL;
            received[seq / 8] |= (1 << (seq % 8));

    		max_seq = max_seq > seq ? max_seq : seq;

    		for (i = confirmed_end + 1; i <= max_seq; i++)
    		{
    			if ((received[i / 8] & (1 << (i % 8))) == 0)
    				break;
    		}
    		confirmed_end = i - 1;
    		//printf("confirmed_end now is %u.\n", confirmed_end);
    	}
    }

    void calculate_basic_parts(uint32_t num)
    {
        max = max > num ? max : num;
        min = min < num ? min : num;
        sum = sum + num;
    }

    void send_result()
    {
        Result_Msg* payload;
        payload = (Result_Msg*)(call ResultSendPacket.getPayload(&result_pkt, sizeof(Result_Msg)));
        if(payload != NULL)
        {
            payload->group = GROUP_ID;
            payload->max = max;
            payload->min = min;
            payload->sum = sum;
            payload->average = sum / DATA_TOTAL;
            payload->median = (big_heap[0] + small_heap[0]) / 2;

            //printf("r(%lu,%lu,%lu,%lu,%lu)\n", payload->max, payload->min, payload->sum, payload->average, payload->median);
            //printfflush();
            call ResultSend.send(TARGET_ID, &result_pkt, sizeof(Result_Msg));
        }
    }

    void send_request(uint16_t seq)
    {
        Request_Msg* payload;
        //printf("Q %u %u\n", seq, start_seq);
        //printfflush();
        payload = (Request_Msg*)(call RequestSendPacket.getPayload(&request_pkt, sizeof(Request_Msg)));
        if(payload != NULL)
        {
            payload->seq = seq;

            call RequestSend.send(TOS_NODE_ID + vice_num + 1, &request_pkt, sizeof(Request_Msg));
            vice_num = 1 - vice_num;
        }
    }

    event void ResultSend.sendDone(message_t* msg, error_t err)
    {
        if(&result_pkt == msg && err == SUCCESS)
        {
            call Leds.led2Toggle();
            //printf("Result pkt has been successfully sent.\n");
            //printfflush();
        }
    }

    event void RequestSend.sendDone(message_t* msg, error_t err)
    {
        if(&request_pkt == msg && err == SUCCESS)
        {
            call Leds.led0Toggle();
            //printf("Request pkt has been successfully sent.\n");
            //printfflush();
        }
    }

    void process_new_number(uint16_t seq, uint32_t num)
    {
        atomic
        {
            if (received_sum)
            {
                if (seq < start_seq) seq += DATA_TOTAL;
                seq -= start_seq;
            }
            //printf("num = %u %u %u.\n", seq, num, (received[seq / 8] & (1 << (seq % 8))));
            //printfflush();
            if ((received[seq / 8] & (1 << (seq % 8)))) return;

            register_new_number(seq, num);
            calculate_basic_parts(num);
            insert_into_heap(num);

            if(small_heap_size > big_heap_size + 1)
            {
                uint32_t temp = small_heap[0];
                extract_small_heap();
                big_heap[big_heap_size] = temp;
                big_heap_size += 1;
                adjust_big_heap();
            }
            else if(small_heap_size < big_heap_size - 1)
            {
                uint32_t temp = big_heap[0];
                extract_big_heap();
                small_heap[small_heap_size] = temp;
                small_heap_size += 1;
                adjust_small_heap();
            }

            if(received_sum == DATA_TOTAL)
            {
                send_result();
                completed = 1;
                //printf("C[%u,%u]\n", received_sum, DATA_TOTAL);
                //printfflush();
            }

            //printf("Done.\n");
            //printfflush();
        }
    }

    event message_t* DataReceive.receive(message_t* msg, void* payload, uint8_t len)
    {
        Data_Msg* rcv_payload;
        uint16_t seq;
        uint32_t num;

        if (completed) return msg;

        if (len == sizeof(Data_Msg))
        {
            rcv_payload = (Data_Msg*)payload;
            seq = rcv_payload->seq;
            num = rcv_payload->num;

            //printf("R[%u, %lu, %u, %lu].\n", seq, num, received_sum, sum);
            //printfflush();
            //printf("M[%u, %u, %u].\n", max_seq, confirmed_end, received_sum);
            //printfflush();
            process_new_number(seq, num);
        }
        return msg;
    }

    event message_t* ResponseReceive.receive(message_t* msg, void* payload, uint8_t len)
    {
        Response_Msg* rcv_payload;
        uint16_t seq;
        uint32_t num;
        if(completed != 0)
            return msg;
        if(len == sizeof(Response_Msg))
        {
            call Leds.led1Toggle();
            rcv_payload = (Response_Msg*) payload;
            seq = rcv_payload->seq;
            num = rcv_payload->num;
            //printf("get=%u %lu\n", seq, num);
            //printfflush();
            process_new_number(seq, num);
        }
        return msg;
    }

    event message_t* ACKReceive.receive(message_t* msg, void* payload, uint8_t len)
    {
        ACK_Msg* rcv_payload;
        if(len == sizeof(ACK_Msg))
        {
            rcv_payload = (ACK_Msg*)payload;
            if(rcv_payload->group == GROUP_ID)
            {
                completed = 2;
            }
        }
        return msg;
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

    void extract_small_heap()
    {
        uint16_t pos = 0;
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

    void extract_big_heap()
    {
        uint16_t pos = 0;
        big_heap_size -= 1;
        big_heap[0] = big_heap[big_heap_size];

        while(pos < big_heap_size)
        {
            uint16_t i = 2 * pos + 1, j = 2 * pos + 2;
            uint16_t bigger;
            uint32_t temp;

            if(i >= big_heap_size)
                break;
            else if(j == big_heap_size)
                bigger = i;
            else
                bigger = big_heap[i] > big_heap[j] ? i : j;

            if(big_heap[pos] >= big_heap[bigger])
                break;

            temp = big_heap[pos];
            big_heap[pos] = big_heap[bigger];
            big_heap[bigger] = temp;
            pos = bigger;
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
                adjust_small_heap();
            }
            else
            {
                big_heap[big_heap_size] = num;
                big_heap_size += 1;
                adjust_big_heap();
            }
        }
    }
}
