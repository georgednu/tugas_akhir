// #include <stdint.h>
// #include <stdio.h>
// #include <xil_types.h>
// #include <xstatus.h>
// #include <xuartps_hw.h>
// #include "xaxidma.h"
// #include "xil_printf.h"
// #include "xparameters.h"
// #include "dma_controller.h"
// #include "xuartps.h"
// #include "xscugic.h"
// #include "xbasic_types.h"

// #include "states.h"
// #include "specs.h"
// #include "math.h"
// #include <string.h>

// #include "data_acq.h"
// #include "pc_uart_handler.h"

// #include "statespace.h"

// #define UART_DEVICE_ID      0
// #define INTC_DEVICE_ID      0
// #define UART_INT_IRQ_ID     XPAR_XUARTPS_0_INTR

// #define RECEIVE_BUFFER_SIZE    1024
// #define UART_TIMEOUT 8

// #define GLOBAL_TMR_BASE_ADDR  0xF8F00200U
// #define GLOBAL_TMR_COUNTER_L  (*(volatile uint32_t *)(GLOBAL_TMR_BASE_ADDR + 0x00))
// #define GLOBAL_TMR_COUNTER_H  (*(volatile uint32_t *)(GLOBAL_TMR_BASE_ADDR + 0x04))

// uint64_t read_global_timer() {
//     uint32_t hi1, lo, hi2;
//     do {
//         hi1 = GLOBAL_TMR_COUNTER_H;
//         lo = GLOBAL_TMR_COUNTER_L;
//         hi2 = GLOBAL_TMR_COUNTER_H;
//     } while (hi1 != hi2);  // ensure consistency
//     return ((uint64_t)hi1 << 32) | lo;
// }

// void enable_global_timer()
// {
//     uint32_t val;

//     // Enable global timer by setting bit 0 of Control Register
//     volatile uint32_t* GT_CONTROL = (uint32_t*)(0xF8F00208);
//     *GT_CONTROL = 1; // enable timer, no IRQ, no auto-increment
// }


// XAxiDma AxiDma;
// XUartPs Uart_Ps;
// //static XScuGic Intc;


// int SetupUart(XUartPs *UartInstancePtr, u16 UartDeviceId) { 
// //Call once to setup Uart
//     int Status;
//     XUartPs_Config *Config;

//     Config = XUartPs_LookupConfig(UartDeviceId);
//     if(Config==NULL){
//         return XST_FAILURE;
//     }

//     Status = XUartPs_CfgInitialize(UartInstancePtr, Config, Config->BaseAddress);
//     if(Status != XST_SUCCESS){
//         return XST_FAILURE;
//     }

//     XUartPs_SetRecvTimeout(UartInstancePtr, UART_TIMEOUT);

//     return XST_SUCCESS;
// }

// int dma_payload_packing(u64* dma_tx_buffer, u64 header, u64* mat, int len){
// //Copies <mat> values into the DMA TX buffer. Sent data includes 64bits of header.
// //<len> is the amount of 8-byte words being sent.
//     dma_tx_buffer[0] = header;
//     for(int i=0 ; i<len ; i++){
//         dma_tx_buffer[i+1] = mat[i]; 
//     }
//     return 0;
// }

// int dma_to_PL (XAxiDma* AxiDma, u8* TxBufferPtr, int byte_length){
// //Transfers data to PL through DMA.
// //Loops until transfer is completed.
//     int Status;
//     Status = XAxiDma_MM2Stransfer(AxiDma, (UINTPTR) TxBufferPtr, byte_length);
//     if (Status != XST_SUCCESS){
//         //xil_printf("XAXIDMA_DMA_TO_DEVICE transfer failed...\r\n");
//         return XST_FAILURE;
//     }
//     while(XAxiDma_Busy(AxiDma,XAXIDMA_DMA_TO_DEVICE)){
//         if (XAxiDma_Busy(AxiDma,XAXIDMA_DMA_TO_DEVICE)){
//             //xil_printf("MM2S channel is busy...\r\n");
//         }
//     }
//     return XST_SUCCESS;
// }

// // void uart_parser(XUartPs* Uart_Ps, StateSpace * plant, int* is_load_pl, u32 uart_header, u32 uart_len){
// // //Receives data from UART and parses into StateSpace object
// //     u64 buffer[36];
    
// //     switch (uart_header) {
// //     case 0x01:
// //     uart_receive(Uart_Ps, (u8*) buffer, uart_len);
// //     unpack_mat(MAX_ROW, MAX_COL, buffer, plant->mat_A, plant->size);
// //     break;
// //     case 0x02:
// //     uart_receive(Uart_Ps, (u8*) buffer, uart_len);
// //     unpack_mat(MAX_ROW, 1, buffer, plant->mat_B, plant->size);
// //     break;
// //     case 0x03:
// //     uart_receive(Uart_Ps, (u8*) buffer, uart_len);
// //     unpack_mat(MAX_ROW, MAX_COL, buffer, plant->mat_C, plant->size);
// //     break;
// //     case 0x04:
// //     uart_receive(Uart_Ps, (u8*) buffer, uart_len);
// //     unpack_mat(MAX_ROW, 1, buffer, plant->mat_D, plant->size);
// //     break;
// //     case 0x05:
// //     uart_receive(Uart_Ps, (u8*) &(plant->u), uart_len);
// //     default:
// //     break;
// //     }
// // }

// int main(){
 
//     State curr_state = IDLE;
//     enable_global_timer();
//     int Status;
//     Status = SetupUart(&Uart_Ps, UART_DEVICE_ID);
//     if (Status != XST_SUCCESS) {
//         return XST_FAILURE;
//     }

//     XAxiDma_Config *CfgPtr;

// 	int Index;
// 	u8 *TxBufferPtr;
// 	u8 *RxBufferPtr;

// 	TxBufferPtr = (u8 *)TX_BUFFER_BASE;
// 	RxBufferPtr = (u8 *)RX_BUFFER_BASE;

// 	for(Index = 0; Index < MAX_PKT_LEN; Index ++){
// 		TxBufferPtr[Index] = 0x00;
// 		RxBufferPtr[Index] = 0x00;
// 	}

// 	// Initialize the XAxiDma device
// 	CfgPtr = XAxiDma_LookupConfig(DMA_DEV_ID);
// 	if (!CfgPtr) {
// 		//xil_printf("No config found for %d\r\n", DMA_DEV_ID);
// 		return XST_FAILURE;
// 	}

// 	Status = XAxiDma_CfgInitialize(&AxiDma, CfgPtr);
// 	if (Status != XST_SUCCESS) {
// 		//xil_printf("Initialization failed %d\r\n", Status);
// 		return XST_FAILURE;
// 	}

// 	if(XAxiDma_HasSg(&AxiDma)){
// 		//xil_printf("Device configured as SG mode \r\n");
// 		return XST_FAILURE;
// 	}

// 	XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);
// 	XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);

// 	Xil_DCacheFlushRange((UINTPTR)TxBufferPtr, MAX_PKT_LEN);
// 	Xil_DCacheFlushRange((UINTPTR)RxBufferPtr, MAX_PKT_LEN);

// 	XAxiDma_Reset(&AxiDma);

//     StateSpace plant = {0};

//     u8 uart_header;
//     // u32 uart_len;
//     int is_load_pl = 0;
//     int is_data_incoming = 0;
//     int loaded_param = 0;
//     DataAcquisitionConfig_t daq_config;
//     print("LOAD");
//     int64_t ah_on [MAX_COL*MAX_ROW];
//     int64_t ah_off [MAX_COL*MAX_ROW];
//     int64_t bh_on [MAX_ROW];
//     int64_t bh_off [MAX_ROW];
//     int64_t C [MAX_COL*MAX_ROW];

//     // Send A_on matrix
//     dma_payload_packing((u64*) TxBufferPtr, A_ON_HEADER, (u64*)ah_on, A_SIZE);
//     Xil_DCacheFlushRange((INTPTR) TxBufferPtr, 8 + 8*(A_SIZE));
//     Status = dma_to_PL(&AxiDma, TxBufferPtr, 8 + 8*(A_SIZE));
//     if(Status!=XST_SUCCESS){
//     //xil_printf("Matrix A_on Transmission Failed %d\r\n", Status);
//     }
//     // Send B_on matrix  
//     dma_payload_packing((u64*) TxBufferPtr, B_ON_HEADER, (u64*)bh_on, B_SIZE);
//     Xil_DCacheFlushRange((INTPTR) TxBufferPtr, 8+8*B_SIZE);
//     Status = dma_to_PL(&AxiDma, TxBufferPtr, 8+8*B_SIZE);
//     if(Status!=XST_SUCCESS){
//     //xil_printf("Matrix B_on Transmission Failed %d\r\n", Status);
//     }

//     // Send A_off matrix
//     dma_payload_packing((u64*) TxBufferPtr, A_OFF_HEADER, (u64*)ah_off, A_SIZE);
//     Xil_DCacheFlushRange((INTPTR) TxBufferPtr, 8 + 8*(A_SIZE));
//     Status = dma_to_PL(&AxiDma, TxBufferPtr, 8 + 8*(A_SIZE));
//     if(Status!=XST_SUCCESS){
//     //xil_printf("Matrix A_off Transmission Failed %d\r\n", Status);
//     }
//     // Send B_off matrix
//     dma_payload_packing((u64*) TxBufferPtr, B_OFF_HEADER, (u64*)bh_off, B_SIZE);
//     Xil_DCacheFlushRange((INTPTR) TxBufferPtr, 8+8*B_SIZE);
//     Status = dma_to_PL(&AxiDma, TxBufferPtr, 8+8*B_SIZE);
//     if(Status!=XST_SUCCESS){
//     //xil_printf("Matrix B_off Transmission Failed %d\r\n", Status);
//     }

//     // Send C matrix
//     dma_payload_packing((u64*) TxBufferPtr, C_HEADER, (u64*)C, C_SIZE);
//     Xil_DCacheFlushRange((INTPTR) TxBufferPtr, 8 + 8*(C_SIZE));
//     Status = dma_to_PL(&AxiDma, TxBufferPtr, 8 + 8*(C_SIZE));
//     if(Status!=XST_SUCCESS){
//     //xil_printf("Matrix C Transmission Failed %d\r\n", Status);
//     }

//     // Send size
//     dma_payload_packing((u64*) TxBufferPtr, SIZE_HEADER, (u64*)&(plant.size), 1);
//     Xil_DCacheFlushRange((INTPTR) TxBufferPtr, 8 + 8);
//     Status = dma_to_PL(&AxiDma, TxBufferPtr, 8 + 8);
//     if(Status!=XST_SUCCESS){
//     //xil_printf("Matrix C Transmission Failed %d\r\n", Status);
//     }

//     int64_t pwm = 13;
//     // Send size
//     dma_payload_packing((u64*) TxBufferPtr, PWM_HEADER, (u64*)&pwm, 1);
//     Xil_DCacheFlushRange((INTPTR) TxBufferPtr, 8 + 8);



    
//     uint64_t start = read_global_timer();
//     // === Code to be timed ===
//     Status = dma_to_PL(&AxiDma, TxBufferPtr, 8 + 8);
//     if(Status!=XST_SUCCESS){
//     //xil_printf("Matrix C Transmission Failed %d\r\n", Status);
//     }
//     Status = XAxiDma_S2MMtransfer(&AxiDma, (UINTPTR) TxBufferPtr, 4);
    
//     while(XAxiDma_Busy(&AxiDma,XAXIDMA_DEVICE_TO_DMA)){
//     }
//     // ========================

//     uint64_t end = read_global_timer();
//     uint64_t delta = end - start;

//     double time_sec = (double)delta / 666666666.6;
//     printf("\nExecution time: %.6f seconds\n", time_sec);
//     while (1); // Stop here

    


//     return 0;
// }   