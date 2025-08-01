#include "data_acq.h"

#define PI 3.1415926

// Function to handle parsing the data acquisition request packet
int parse_data_acquisition_request(XUartPs* Uart_Ps, DataAcquisitionConfig_t* config) {
    u8 buffer[4]; // 4 bytes for duration, 4 bytes for frequency

    // Read DURATION_MS (4 bytes)
    if (uart_receive(Uart_Ps, &buffer[0], 4) != 0) {
        //xil_printf("❌ Failed to read duration for data acquisition.\r\n");
        return XST_FAILURE;
    }
    // Convert 4 bytes (little-endian) to u32
    config->duration_ms = *(u32 *) buffer;

    // Read SAMPLING_FREQ (4 bytes)
    // if (uart_receive(Uart_Ps, &buffer[4], 4) != 0) { // Start reading from buffer[4]
    //     xil_printf("❌ Failed to read sampling frequency for data acquisition.\r\n");
    //     return XST_FAILURE;
    // }
    // Convert 4 bytes (little-endian) to u32
    // config->sampling_freq_hz = (u32)buffer[4] | ((u32)buffer[5] << 8) |
    //                            ((u32)buffer[6] << 16) | ((u32)buffer[7] << 24);

    //xil_printf("📊 Data Acquisition Config Received: Duration=%lu ms, Freq=%lu Hz\r\n",config->duration_ms);//, config->sampling_freq_h

    return XST_SUCCESS;
}

void send_dummy_acquisition_data(XUartPs* Uart_Ps, u32 duration_ms) {
    u32 sampling_freq_hz = x`200000; // Frekuensi sampling internal Zynq (200 kHz)
    u32 num_samples = (duration_ms * sampling_freq_hz) / 1000;
    //xil_printf("DEBUG Zynq: Sending %lu dummy samples...\r\n", num_samples);

    float voltage_val = 0.0f;
    float current_val = 0.0f;
    float time_s = 0.0f;
    float time_step_s = 1.0f / (float)sampling_freq_hz; // Waktu per sampel dalam detik

    for (u32 i = 0; i < num_samples; i++) {
        time_s = i * time_step_s;

        // --- Hasilkan data dummy (misalnya, gelombang sinus untuk tegangan, kosinus untuk arus) ---
        // Tegangan: gelombang sinus 50 Hz, amplitudo +/- 3.0V
        voltage_val = 3.0f * sinf(2.0f * PI * 50.0f * time_s);
        // Arus: gelombang kosinus 100 Hz, amplitudo +/- 1.5A
        current_val = 1.5f * cosf(2.0f * PI * 100.0f * time_s);

        // Konversi float ke pola bit integer 32-bit (sesuai int32_t yang akan dikirim)
        // Ini cocok dengan cara Python mengemas float menjadi int32_t untuk transmisi
        u32 voltage_bits = *((u32*)&voltage_val); // Mengambil pola bit float
        u32 current_bits = *((u32*)&current_val); // Mengambil pola bit float

        // Kirim tegangan (4 byte)
        XUartPs_SendByte(Uart_Ps->Config.BaseAddress, (u8)(voltage_bits & 0xFF));
        XUartPs_SendByte(Uart_Ps->Config.BaseAddress, (u8)((voltage_bits >> 8) & 0xFF));
        XUartPs_SendByte(Uart_Ps->Config.BaseAddress, (u8)((voltage_bits >> 16) & 0xFF));
        XUartPs_SendByte(Uart_Ps->Config.BaseAddress, (u8)((voltage_bits >> 24) & 0xFF));

        // Kirim arus (4 byte)
        XUartPs_SendByte(Uart_Ps->Config.BaseAddress, (u8)(current_bits & 0xFF));
        XUartPs_SendByte(Uart_Ps->Config.BaseAddress, (u8)((current_bits >> 8) & 0xFF));
        XUartPs_SendByte(Uart_Ps->Config.BaseAddress, (u8)((current_bits >> 16) & 0xFF));
        XUartPs_SendByte(Uart_Ps->Config.BaseAddress, (u8)((current_bits >> 24) & 0xFF));

        // Opsional: Tambahkan delay kecil jika data dikirim terlalu cepat untuk di-buffer Python
        // usleep(1); // 1 us delay per sampel. Hati-hati, ini bisa memperlambat pengiriman data secara signifikan
                   // jika jumlah sampel sangat besar (mis. 200.000 sampel = 200 ms delay tambahan).
                   // Sebaiknya, optimalkan sisi Python untuk menerima data lebih cepat.
    }
    xil_printf("DEBUG Zynq: Finished sending dummy samples.\r\n");
}