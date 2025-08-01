#include "pc_uart_handler.h"

void copy_int32_data(int32_t* source_data, int32_t* dest_array, u16 rows, u16 cols){
    // Direct copy since data is already in correct format
    for(int i = 0; i < rows * cols; i++){
        dest_array[i] = source_data[i];
    }
}

void copy_mat(int32_t* source_mat, int32_t* dest_mat, u16 rows, u16 cols){

    for(int i = 0 ; i<MAX_ROW ; i++){
        for(int j = 0 ; j<MAX_COL ; j++){
            if (i<rows && j<cols) {
                dest_mat[i*MAX_COL+j] = source_mat[i*rows + j];
            }
        }
    }


}

int send_ack_start(XUartPs* Uart_Ps) {
    // Kirim ACK_START (0x55)
    XUartPs_SendByte(Uart_Ps->Config.BaseAddress, 0x41);
    return XST_SUCCESS;
}

int send_ack_complete(XUartPs* Uart_Ps, const char* message) {
    // Kirim ACK_COMPLETE (0xAA) + message
    // XUartPs_SendByte(Uart_Ps->Config.BaseAddress, 0x41);
    
    // Kirim message
    int len = strlen(message);
    for(int i = 0; i < len; i++) {
        XUartPs_SendByte(Uart_Ps->Config.BaseAddress, message[i]);
    }
    XUartPs_SendByte(Uart_Ps->Config.BaseAddress, '\n'); // Line ending
    // 
    
    return XST_SUCCESS;
}

int send_matrix_echo(XUartPs* Uart_Ps, u8 matrix_id, u16 rows, u16 cols, int32_t* data_array) {
    XUartPs_SendByte(Uart_Ps->Config.BaseAddress, ECHO_START_BYTE); // Sends ECHO_START_BYTE
    XUartPs_SendByte(Uart_Ps->Config.BaseAddress, matrix_id);      // Original Matrix ID

    // Send ROWS (2 bytes, little-endian)
    XUartPs_SendByte(Uart_Ps->Config.BaseAddress, (u8)(rows & 0xFF));
    XUartPs_SendByte(Uart_Ps->Config.BaseAddress, (u8)((rows >> 8) & 0xFF));

    // Send COLS (2 bytes, little-endian)
    XUartPs_SendByte(Uart_Ps->Config.BaseAddress, (u8)(cols & 0xFF));
    XUartPs_SendByte(Uart_Ps->Config.BaseAddress, (u8)((cols >> 8) & 0xFF));

    for(int i = 0 ; i<MAX_ROW ; i++){
        for(int j = 0 ; j<MAX_COL ; j++){
            if (i<rows && j<cols) {
                XUartPs_SendByte(Uart_Ps->Config.BaseAddress, (u8)(data_array[i*MAX_ROW+j] & 0xFF));
                XUartPs_SendByte(Uart_Ps->Config.BaseAddress, (u8)((data_array[i*MAX_ROW+j] >> 8) & 0xFF));
                XUartPs_SendByte(Uart_Ps->Config.BaseAddress, (u8)((data_array[i*MAX_ROW+j] >> 16) & 0xFF));
                XUartPs_SendByte(Uart_Ps->Config.BaseAddress, (u8)((data_array[i*MAX_ROW+j] >> 24) & 0xFF));
            }
        }
    }

    XUartPs_SendByte(Uart_Ps->Config.BaseAddress, ECHO_STOP_BYTE); // Sends ECHO_STOP_BYTE
    XUartPs_SendByte(Uart_Ps->Config.BaseAddress, '\n'); // Newline after each echo
    return XST_SUCCESS;
}

int uart_receive(XUartPs* Uart_Ps, u8* buffer, int expected_len){
//Reads data received in RX Buffer. Received data will be stored in <buffer>. <expected_len> is the amount of bytes
//to be read. Function will loop until <expected_len> bytes is read.
    int received_len = 0;
    while(received_len<expected_len){
        received_len += XUartPs_Recv(Uart_Ps, &(buffer[received_len]), (expected_len - received_len));
    }
    return 0;
}

int unpack_mat(int max_row, int max_col, u64* buffer, u64* mat, int size){
//Function unpack matrix or vectors (max_col = 1) from a buffer and store it into <mat>.
//<size> is the size of row or col.
    for (int i = 0; i<max_row ; i++){
        for(int j = 0; j<max_col ; j++){
            if(i<size && j<size){
                mat[i*max_col + j] = *buffer++;
            }else{
                mat[i*max_col + j] = 0;
            }
        }
    }
    return 0;
}


void uart_parser_new(XUartPs* Uart_Ps, StateSpace * plant, u8 matrix_id,
                     int32_t* int32_data, u16 rows, u16 cols, int* loaded_param){
    // Store int32 data directly - no conversion needed
    switch (matrix_id) {
        case 0x01: // A_on
            copy_mat(int32_data, plant->mat_Aon, rows, cols);
            // After storing, send echo
            send_matrix_echo(Uart_Ps, matrix_id, rows, cols, plant->mat_Aon);
            plant->size = rows;
            *loaded_param = 0;
            *loaded_param +=1;
            break;
        case 0x02: // B_on
            copy_mat(int32_data, plant->mat_Bon, rows, cols);
            // After storing, send echo
            send_matrix_echo(Uart_Ps, matrix_id, rows, cols, plant->mat_Bon);
            *loaded_param +=1;
            break;
        case 0x03: // A_off
            copy_mat(int32_data, plant->mat_Aoff, rows, cols);
            // After storing, send echo
            send_matrix_echo(Uart_Ps, matrix_id, rows, cols, plant->mat_Aoff);
            *loaded_param+=1;
            break;
        case 0x04: // B_off
            copy_mat(int32_data, plant->mat_Boff, rows, cols);
            // After storing, send echo
            send_matrix_echo(Uart_Ps, matrix_id, rows, cols, plant->mat_Boff);
            *loaded_param+=1;
            break;
        case 0x05: // C
            copy_mat(int32_data, plant->mat_C, rows, cols);
            // After storing, send echo
            send_matrix_echo(Uart_Ps, matrix_id, rows, cols, plant->mat_C);
            *loaded_param+=1;
            *loaded_param = *loaded_param;
            break;
        case 0x06: // D
            //printf("%d\n", *loaded_param);
            // copy_int32_data(int32_data, plant->mat_D, rows, cols);
            // // After storing, send echo
            // send_matrix_echo(Uart_Ps, matrix_id, rows, cols, plant->mat_D);
            break;
        default:
            break;
    }
}