#include "xil_types.h"
#include "xuartps.h"
#include "math.h"
#include "pc_uart_handler.h"

#ifndef DATA_ACQ
#define DATA_ACQ

// Define the new DataAcquisitionConfig_t struct
typedef struct DataAcquisitionConfig_t{
    u32 duration_ms;
    // u32 sampling_freq_hz;
} DataAcquisitionConfig_t;

void send_dummy_acquisition_data(XUartPs* Uart_Ps, u32 duration_ms);
int parse_data_acquisition_request(XUartPs* Uart_Ps, DataAcquisitionConfig_t* config);


#endif