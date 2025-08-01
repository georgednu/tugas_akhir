#ifndef PC_UART_HANDLER
#define PC_UART_HANDLER

#define ECHO_START_BYTE 0xBB
#define ECHO_STOP_BYTE 0xCC
#define START_BYTE_DATA_REQ 0xDD // This must be unique from ECHO_START_BYTE
#define STOP_BYTE_DATA_REQ  0xEE
#define ACK_BYTE            0x55
#define NACK_BYTE           0xAA

#include "xuartps.h"
#include "specs.h"
#include "statespace.h"

void uart_parser_new(XUartPs* Uart_Ps, StateSpace * plant, u8 matrix_id,
                     int32_t* int32_data, u16 rows, u16 cols, int* loaded_param);
int unpack_mat(int max_row, int max_col, u64* buffer, u64* mat, int size);
int uart_receive(XUartPs* Uart_Ps, u8* buffer, int expected_len);
int send_matrix_echo(XUartPs* Uart_Ps, u8 matrix_id, u16 rows, u16 cols, int32_t* data_array);
int send_ack_complete(XUartPs* Uart_Ps, const char* message);
int send_ack_start(XUartPs* Uart_Ps);

#endif