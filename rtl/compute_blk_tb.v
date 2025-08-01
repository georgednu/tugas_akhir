`timescale 1ns / 1ps
`define N_MAX 6
`include "def.vh"

// DUT modules
`include "compute_blk.v"
`include "vect_mul.v"
`include "vect_adder.v"
`include "mac.v"
`include "dff.v"

// Utility
`include "pwm.v"

module compute_blk_tb;

    // Local data width
    localparam DATA_WIDTH = 43;

    // Clock and control
    reg clk = 0;
    reg rst = 0;
    reg en = 0;
    reg step = 0;

    // Inputs
    reg [`N_MAX*`N_MAX*DATA_WIDTH-1:0] Ah_on;
    reg [`N_MAX*DATA_WIDTH-1:0] Bh_on;
    reg [`N_MAX*`N_MAX*DATA_WIDTH-1:0] Ah_off;
    reg [`N_MAX*DATA_WIDTH-1:0] Bh_off;
    reg [`N_MAX*`N_MAX*DATA_WIDTH-1:0] C;
    reg [7:0] size;
    wire signed [13:0] adc_ch1;
    wire signed [13:0] adc_ch2;

    // Outputs
    wire [13:0] dac_ch1;
    wire [13:0] dac_ch2;
    wire signed [42:0] OUT1;
    wire signed [42:0] OUT2;
    wire comp_ready;

    // Clock generation (100 MHz)
    always #5 clk = ~clk;

    // PWM input generator
    wire signed [13:0] pwm_out;
    reg [7:0] duty_cycle = 8'd50;

    pwm pwm_inst (
        .clk(clk),
        .rst(rst),
        .en(en),
        .duty_cycle(duty_cycle),
        .pwm(pwm_out)
    );

    assign adc_ch1 = pwm_out;
    assign adc_ch2 = 14'd0;

    // DUT instantiation
    compute_blk dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .step(step),
        .Ah_on(Ah_on),
        .Bh_on(Bh_on),
        .Ah_off(Ah_off),
        .Bh_off(Bh_off),
        .C(C),
        .size(size),
        .adc_ch1(adc_ch1),
        .adc_ch2(adc_ch2),
        .dac_ch1(dac_ch1),
        .dac_ch2(dac_ch2),
        .OUT1(OUT1),
        .OUT2(OUT2),
        .comp_ready(comp_ready)
    );

    // Step pulse every 50 cycles
    reg [5:0] step_counter = 0;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            step_counter <= 0;
            step <= 0;
        end else if (en) begin
            if (step_counter == 49) begin
                step <= 1;
                step_counter <= 0;
            end else begin
                step <= 0;
                step_counter <= step_counter + 1;
            end
        end
    end

    integer file;
    initial file = $fopen("dac_output.txt", "w");

    // === Test Logic ===
    initial begin
        $dumpfile("compute_blk_tb.vcd");
$dumpvars(0, compute_blk_tb);

        #10 rst = 0;
        #20 rst = 1;

        en = 1;
        size = 8'd2;

        // Fixed-point values:
        // Ah = [[0, -21474836.48], [21474836.48, -2147483.648]]
        // → Q11.32 → [0, -922337203685], [922337203685, -92233720369]

        Ah_on = {
            // Row 5
            {6{43'd0}},
            // Row 4
            {6{43'd0}},
            // Row 3
            {6{43'd0}},
            // Row 2
            {6{43'd0}},
            // Row 1
            43'd0, 43'd0, 43'd0, 43'd0, 43'sd4292819812, 43'sd21474836,
            // Row 0
            43'd0, 43'd0, 43'd0, 43'd0, -43'sd21474836, 43'sd4294967296
        };
        Ah_off = Ah_on;

        Bh_on = {
            43'd0, 43'd0, 43'd0, 43'd0, 43'd0, 43'sd107374182
        };
        Bh_off = {
            43'd0, 43'd0, 43'd0, 43'd0, 43'd0, 43'd0
        };

        // C = [[4294967296], [0]] → Q11.32 = 1<<32 = 4294967296
        C = {
            // Row 5
            {6{43'd0}},
            // Row 4
            {6{43'd0}},
            // Row 3
            {6{43'd0}},
            // Row 2
            {6{43'd0}},
            // Row 1
            {6{43'd0}},
            // Row 0
            43'd0, 43'd0, 43'd0, 43'd0, 43'd4294967296, 43'd0
        };

        #10000000;
        $fclose(file);
        $finish;
    end

    // Log output: DAC and raw Q11.32 values
    always @(posedge clk) begin
        if (step)
            $fwrite(file, "%d %d %d %d\n", dac_ch1, dac_ch2, OUT1, OUT2);
    end


endmodule
