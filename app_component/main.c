#include <stdint.h>
#include <stdio.h>
#include <xil_types.h>
#include <xstatus.h>
#include <xuartps_hw.h>
#include "xaxidma.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "dma_controller.h"
#include "xuartps.h"
#include "xscugic.h"
#include "xbasic_types.h"

#include "states.h"
#include "specs.h"
#include "math.h"
#include <string.h>

#include "data_acq.h"
#include "pc_uart_handler.h"

#include "statespace.h"

#define UART_DEVICE_ID      0
#define INTC_DEVICE_ID      0
#define UART_INT_IRQ_ID     XPAR_XUARTPS_0_INTR

#define RECEIVE_BUFFER_SIZE    1024
#define UART_TIMEOUT 8


XAxiDma AxiDma;
XUartPs Uart_Ps;
//static XScuGic Intc;


int SetupUart(XUartPs *UartInstancePtr, u16 UartDeviceId) { 
//Call once to setup Uart
    int Status;
    XUartPs_Config *Config;

    Config = XUartPs_LookupConfig(UartDeviceId);
    if(Config==NULL){
        return XST_FAILURE;
    }

    Status = XUartPs_CfgInitialize(UartInstancePtr, Config, Config->BaseAddress);
    if(Status != XST_SUCCESS){
        return XST_FAILURE;
    }

    XUartPs_SetRecvTimeout(UartInstancePtr, UART_TIMEOUT);

    return XST_SUCCESS;
}

int dma_payload_packing(u64* dma_tx_buffer, u64 header, u64* mat, int len){
//Copies <mat> values into the DMA TX buffer. Sent data includes 64bits of header.
//<len> is the amount of 8-byte words being sent.
    dma_tx_buffer[0] = header;
    for(int i=0 ; i<len ; i++){
        dma_tx_buffer[i+1] = mat[i]; 
    }
    return 0;
}

int dma_to_PL (XAxiDma* AxiDma, u8* TxBufferPtr, int byte_length){
//Transfers data to PL through DMA.
//Loops until transfer is completed.
    int Status;
    Status = XAxiDma_MM2Stransfer(AxiDma, (UINTPTR) TxBufferPtr, byte_length);
    if (Status != XST_SUCCESS){
        //xil_printf("XAXIDMA_DMA_TO_DEVICE transfer failed...\r\n");
        return XST_FAILURE;
    }
    while(XAxiDma_Busy(AxiDma,XAXIDMA_DMA_TO_DEVICE)){
        if (XAxiDma_Busy(AxiDma,XAXIDMA_DMA_TO_DEVICE)){
            //xil_printf("MM2S channel is busy...\r\n");
        }
    }
    return XST_SUCCESS;
}

// void uart_parser(XUartPs* Uart_Ps, StateSpace * plant, int* is_load_pl, u32 uart_header, u32 uart_len){
// //Receives data from UART and parses into StateSpace object
//     u64 buffer[36];
    
//     switch (uart_header) {
//     case 0x01:
//     uart_receive(Uart_Ps, (u8*) buffer, uart_len);
//     unpack_mat(MAX_ROW, MAX_COL, buffer, plant->mat_A, plant->size);
//     break;
//     case 0x02:
//     uart_receive(Uart_Ps, (u8*) buffer, uart_len);
//     unpack_mat(MAX_ROW, 1, buffer, plant->mat_B, plant->size);
//     break;
//     case 0x03:
//     uart_receive(Uart_Ps, (u8*) buffer, uart_len);
//     unpack_mat(MAX_ROW, MAX_COL, buffer, plant->mat_C, plant->size);
//     break;
//     case 0x04:
//     uart_receive(Uart_Ps, (u8*) buffer, uart_len);
//     unpack_mat(MAX_ROW, 1, buffer, plant->mat_D, plant->size);
//     break;
//     case 0x05:
//     uart_receive(Uart_Ps, (u8*) &(plant->u), uart_len);
//     default:
//     break;
//     }
// }

int main(){
 
    State curr_state = IDLE;
    
    int Status;
    Status = SetupUart(&Uart_Ps, UART_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    XAxiDma_Config *CfgPtr;

	int Index;
	u8 *TxBufferPtr;
	u8 *RxBufferPtr;

	TxBufferPtr = (u8 *)TX_BUFFER_BASE;
	RxBufferPtr = (u8 *)RX_BUFFER_BASE;

	for(Index = 0; Index < MAX_PKT_LEN; Index ++){
		TxBufferPtr[Index] = 0x00;
		RxBufferPtr[Index] = 0x00;
	}

	// Initialize the XAxiDma device
	CfgPtr = XAxiDma_LookupConfig(DMA_DEV_ID);
	if (!CfgPtr) {
		//xil_printf("No config found for %d\r\n", DMA_DEV_ID);
		return XST_FAILURE;
	}

	Status = XAxiDma_CfgInitialize(&AxiDma, CfgPtr);
	if (Status != XST_SUCCESS) {
		//xil_printf("Initialization failed %d\r\n", Status);
		return XST_FAILURE;
	}

	if(XAxiDma_HasSg(&AxiDma)){
		//xil_printf("Device configured as SG mode \r\n");
		return XST_FAILURE;
	}

	XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);
	XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);

	Xil_DCacheFlushRange((UINTPTR)TxBufferPtr, MAX_PKT_LEN);
	Xil_DCacheFlushRange((UINTPTR)RxBufferPtr, MAX_PKT_LEN);

	XAxiDma_Reset(&AxiDma);

    StateSpace plant = {0};

    u8 uart_header;
    // u32 uart_len;
    int is_load_pl = 0;
    int is_data_incoming = 0;
    int loaded_param = 0;
    DataAcquisitionConfig_t daq_config;
    while(1){
        switch (curr_state) {
            case IDLE:
            //print("IDLE");
            break;

            case RECEIVING:
            // HANDSHAKE PHASE
            u8 start_byte;
            // xil_printf("DEBUG Zynq: Waiting for start byte...\r\n"); // Keep this if needed, but it comes AFTER Python sends
            uart_receive(&Uart_Ps, &start_byte, 1);
            // xil_printf("DEBUG Zynq: Received start byte: 0x%02X\r\n", start_byte); // Keep if needed, but may interfere with ACK

            if(start_byte == START_BYTE_DATA_REQ) {
                // xil_printf("DEBUG Zynq: Detected DAQ request.\r\n"); // Keep if needed for Zynq console

                DataAcquisitionConfig_t temp_daq_config; // Use a temp struct for parsing
                int parse_status = parse_data_acquisition_request(&Uart_Ps, &temp_daq_config); // Call parsing function

                u8 stop_byte_daq;
                int stop_byte_status = uart_receive(&Uart_Ps, &stop_byte_daq, 1); // Read stop byte

                // Determine ACK/NACK status first
                if (parse_status == XST_SUCCESS && stop_byte_status == 0 && stop_byte_daq == STOP_BYTE_DATA_REQ) {
                    // All good, send ACK
                    XUartPs_SendByte(Uart_Ps.Config.BaseAddress, ACK_BYTE); // Send ACK immediately
                    // xil_printf("✅ Data Acquisition Request Acknowledged.\r\n"); // Then print message
                    // xil_printf("📊 DAQ Config: Duration=%lu ms\r\n", temp_daq_config.duration_ms); // Print config after ACK
                    // You can store temp_daq_config to the global daq_config here if needed for later use
                    daq_config = temp_daq_config; // Ensure daq_config is declared global or passed back if needed
                    send_dummy_acquisition_data(&Uart_Ps, daq_config.duration_ms);

                } else {
                    // Something failed, send NACK
                    XUartPs_SendByte(Uart_Ps.Config.BaseAddress, NACK_BYTE); // Send NACK immediately
                    if (parse_status != XST_SUCCESS) {
                        //xil_printf("❌ Failed to parse data acquisition request.\r\n");
                    } else if (stop_byte_status != 0) {
                        //xil_printf("❌ Failed to read DAQ stop byte.\r\n");
                    } else { // (stop_byte_daq != STOP_BYTE_DATA_REQ)
                        //xil_printf("❌ Invalid DAQ stop byte: 0x%02X (Expected 0x%02X)\r\n", stop_byte_daq, STOP_BYTE_DATA_REQ);
                    }
                }
                
                break; // Exit this receiving cycle
            }

            else if (start_byte == 0xAA)
            { 
                // Kirim ACK_START
                send_ack_start(&Uart_Ps);
                //xil_printf("🤝 Handshake sent for incoming matrix\r\n");

                // RECEIVE PACKET PHASE
                u8 stop_byte;
                u16 rows, cols;
                u32 size;

                // 1. Read MATRIX_ID (START_BYTE sudah dibaca di handshake)
                uart_receive(&Uart_Ps, &uart_header, 1);

                // 2. Read ROWS (2 bytes)
                uart_receive(&Uart_Ps, (u8*)&rows, 2);

                // 3. Read COLS (2 bytes)  
                uart_receive(&Uart_Ps, (u8*)&cols, 2);

                // 4. Read SIZE (4 bytes)
                uart_receive(&Uart_Ps, (u8*)&size, 4);

                // 5. Read INT32 DATA
                int32_t temp_buffer[36];
                uart_receive(&Uart_Ps, (u8*)temp_buffer, size * 4);

                // 6. Read STOP_BYTE
                uart_receive(&Uart_Ps, &stop_byte, 1);

                if(stop_byte != 0xFF) {
                send_ack_complete(&Uart_Ps, "ERROR: Invalid stop byte");
                    //xil_printf("❌ Invalid stop byte: 0x%02X\r\n", stop_byte); 
                    break;
                }

                
                // 7. Store data
                uart_parser_new(&Uart_Ps, &plant, uart_header, temp_buffer, rows, cols, &loaded_param);

                // 8. Send FINAL ACK with success message
                char ack_msg[50];
                const char* matrix_names[] = {"", "A_on", "B_on", "A_off", "B_off", "C", "D"};
                if(uart_header >= 1 && uart_header <= 6) {
                    snprintf(ack_msg, sizeof(ack_msg), "OK: %s received (%dx%d)", matrix_names[uart_header], rows, cols);
                } else {
                    snprintf(ack_msg, sizeof(ack_msg), "OK: Matrix ID %d received", uart_header);
                }

                send_ack_complete(&Uart_Ps,ack_msg);
                //xil_printf("✅ Matrix processed successfully\r\n");
            }else { // Handle start_byte yang tidak dikenal
                //xil_printf("❌ Invalid or unknown start byte received: 0x%02X\r\n", start_byte);
                // Anda bisa tambahkan XUartPs_SendByte(Uart_Ps.Config.BaseAddress, NACK_BYTE_DAQ); di sini
                // atau hanya biarkan, tergantung protokol Anda.
            }


            break;

            case LOAD_PL:
            print("LOAD");
            int64_t ah_on [MAX_COL*MAX_ROW];
            int64_t ah_off [MAX_COL*MAX_ROW];
            int64_t bh_on [MAX_ROW];
            int64_t bh_off [MAX_ROW];
            int64_t C [MAX_COL*MAX_ROW];

            discretize(&plant, ah_on, ah_off, bh_on, bh_off, C);

            // Send A_on matrix
            dma_payload_packing((u64*) TxBufferPtr, A_ON_HEADER, (u64*)ah_on, A_SIZE);
            Xil_DCacheFlushRange((INTPTR) TxBufferPtr, 8 + 8*(A_SIZE));
            Status = dma_to_PL(&AxiDma, TxBufferPtr, 8 + 8*(A_SIZE));
            if(Status!=XST_SUCCESS){
                //xil_printf("Matrix A_on Transmission Failed %d\r\n", Status);
            }

            // Send B_on matrix  
            dma_payload_packing((u64*) TxBufferPtr, B_ON_HEADER, (u64*)bh_on, B_SIZE);
            Xil_DCacheFlushRange((INTPTR) TxBufferPtr, 8+8*B_SIZE);
            Status = dma_to_PL(&AxiDma, TxBufferPtr, 8+8*B_SIZE);
            if(Status!=XST_SUCCESS){
                //xil_printf("Matrix B_on Transmission Failed %d\r\n", Status);
            }

            // Send A_off matrix
            dma_payload_packing((u64*) TxBufferPtr, A_OFF_HEADER, (u64*)ah_off, A_SIZE);
            Xil_DCacheFlushRange((INTPTR) TxBufferPtr, 8 + 8*(A_SIZE));
            Status = dma_to_PL(&AxiDma, TxBufferPtr, 8 + 8*(A_SIZE));
            if(Status!=XST_SUCCESS){
                //xil_printf("Matrix A_off Transmission Failed %d\r\n", Status);
            }

            // Send B_off matrix
            dma_payload_packing((u64*) TxBufferPtr, B_OFF_HEADER, (u64*)bh_off, B_SIZE);
            Xil_DCacheFlushRange((INTPTR) TxBufferPtr, 8+8*B_SIZE);
            Status = dma_to_PL(&AxiDma, TxBufferPtr, 8+8*B_SIZE);
            if(Status!=XST_SUCCESS){
                //xil_printf("Matrix B_off Transmission Failed %d\r\n", Status);
            }

            // Send C matrix
            dma_payload_packing((u64*) TxBufferPtr, C_HEADER, (u64*)C, C_SIZE);
            Xil_DCacheFlushRange((INTPTR) TxBufferPtr, 8 + 8*(C_SIZE));
            Status = dma_to_PL(&AxiDma, TxBufferPtr, 8 + 8*(C_SIZE));
            if(Status!=XST_SUCCESS){
                //xil_printf("Matrix C Transmission Failed %d\r\n", Status);
            }

            // Send size
            dma_payload_packing((u64*) TxBufferPtr, SIZE_HEADER, (u64*)&(plant.size), 1);
            Xil_DCacheFlushRange((INTPTR) TxBufferPtr, 8 + 8);
            Status = dma_to_PL(&AxiDma, TxBufferPtr, 8 + 8);
            if(Status!=XST_SUCCESS){
                //xil_printf("Matrix C Transmission Failed %d\r\n", Status);
            }

            int64_t pwm = 13;
            // Send size
            dma_payload_packing((u64*) TxBufferPtr, PWM_HEADER, (u64*)&pwm, 1);
            Xil_DCacheFlushRange((INTPTR) TxBufferPtr, 8 + 8);
            Status = dma_to_PL(&AxiDma, TxBufferPtr, 8 + 8);
            if(Status!=XST_SUCCESS){
                //xil_printf("Matrix C Transmission Failed %d\r\n", Status);
            }

            break;

            case RUN:
            break;

            default:
            break;

        }
        if(loaded_param == 5){
            is_load_pl = 1;
            loaded_param = 0;            
        }
        is_data_incoming = XUartPs_IsReceiveData(Uart_Ps.Config.BaseAddress);
        update_state(&curr_state, &is_data_incoming, &is_load_pl);
    }
    
    return 0;
}   