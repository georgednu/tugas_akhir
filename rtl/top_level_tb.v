 `timescale 1ns / 1ps
`define WIDTH 64
`define N_MAX 6
`include "def.vh"
// Core modules
`include "top_level.v"
`include "axis_interface.v"
`include "adc_interface.v"
`include "dac_interface.v"
`include "compute_blk.v"
`include "cu.v"
`include "pwm.v"
`include "mac.v"

// Vector operations
`include "vect_mul.v"
`include "vect_adder.v"

// Utilities
`include "dff.v"
`include "shift_reg.v"
`include "sync_pgen.v"
`include "pulse_gen.v"
`include "mcp.v"


module tb_top_level;

    // Clock and reset
    reg design_clk = 0;
    reg adc_clk    = 0;
    reg dac_clk    = 0;
    reg design_n_rst = 0;
    reg adc_n_rst = 0;
    reg dac_n_rst = 0;
    reg en = 1;

    // AXI Stream input signals
    reg [`DMA_WIDTH-1:0] s_axis_tdata;
    reg [7:0]        s_axis_tkeep;
    reg              s_axis_tlast;
    reg              s_axis_tvalid;
    wire             s_axis_tready;

    // ADC interface
    reg [31:0] adc_cDataAxisTdata = 0;
    reg        adc_cDataAxisTvalid = 0;
    wire       adc_cDataAxisTready;

    // DAC interface
    wire [31:0] dac_cDataAxisTdata;
    wire        dac_cDataAxisTvalid;
    reg         dac_cDataAxisTready = 1;

    // AXI Stream output
    wire [`DMA_WIDTH-1:0] m_axis_tdata;
    wire [7:0]        m_axis_tkeep;
    wire              m_axis_tlast;
    wire              m_axis_tvalid;
    reg               m_axis_tready = 1;

    // Clock generation
    always #5 design_clk = ~design_clk;
    always #5 adc_clk = ~adc_clk;
    always #5 dac_clk = ~dac_clk;

    // Data memory
    reg [`DMA_WIDTH-1:0] data_mem [0:255];
    reg  valid_mem[0:255];
    reg  last_mem[0:255];
    integer i = 0;
    integer len = 0;

    // Instantiate DUT
    top_level dut (
        .design_clk(design_clk),
        .adc_clk(adc_clk),
        .dac_clk(dac_clk),
        .adc_n_rst(adc_n_rst),
        .dac_n_rst(dac_n_rst),
        .design_n_rst(design_n_rst),
        .en(en),

        .s_axis_tdata(s_axis_tdata),
        .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),

        .adc_cDataAxisTdata(adc_cDataAxisTdata),
        .adc_cDataAxisTvalid(adc_cDataAxisTvalid),
        .adc_cDataAxisTready(adc_cDataAxisTready),

        .dac_cDataAxisTdata(dac_cDataAxisTdata),
        .dac_cDataAxisTvalid(dac_cDataAxisTvalid),
        .dac_cDataAxisTready(dac_cDataAxisTready),

        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready)
    );

    // Stimulus control
    initial begin
        $dumpfile("top_level.vcd");
        $dumpvars(0, tb_top_level);

        $readmemh("data.txt", data_mem);
        $readmemb("valid.txt", valid_mem);
        $readmemb("last.txt", last_mem);

        len = 167; // adjust this according to your file

        s_axis_tdata  = 0;
        s_axis_tkeep  = 8'hFF;
        s_axis_tlast  = 0;
        s_axis_tvalid = 0;

        #100;
        design_n_rst = 1;
        adc_n_rst = 1;
        dac_n_rst = 1;
    end

    // Data driving logic using always block
    always @(posedge design_clk or negedge design_n_rst) begin
        if (!design_n_rst) begin
            i <= 0;
            s_axis_tvalid <= 0;
            s_axis_tlast  <= 0;
            s_axis_tdata  <= 0;
        end else if (i < len) begin
            s_axis_tvalid <= valid_mem[i];
            s_axis_tlast  <= last_mem[i];
            s_axis_tdata  <= data_mem[i];
            i <= i + 1;
        end else begin
            s_axis_tvalid <= 0;
            s_axis_tlast  <= 0;
            s_axis_tdata  <= 0;
        end
    end



integer dac_file;

initial begin
    dac_file = $fopen("top_output.txt", "w");
    $fwrite(dac_file, "Time_ns\tdac_ch1\tdac_ch2\n");

end
reg [13:0] dac_ch1, dac_ch2;
always @(posedge dac_clk) begin
    if (dac_cDataAxisTvalid && dac_cDataAxisTready) begin
        
        dac_ch1 = dac_cDataAxisTdata[31:18];
        dac_ch2 = dac_cDataAxisTdata[15:2];
        $fwrite(dac_file, "%0t\t%d\t%d\n", $time, $signed(dac_ch1), $signed(dac_ch2));

    end
end

initial begin
    #10000000;
    $fclose(dac_file);
    $finish;
end

endmodule
