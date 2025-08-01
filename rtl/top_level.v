`include "def.vh"
module top_level
(
    // Clock
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 design_clk CLK" *) input wire design_clk,

    input wire adc_clk,
    input wire dac_clk,
    input wire adc_n_rst,
    input wire dac_n_rst,
    input wire design_n_rst,
    input wire en,

    // AXI Stream Slave: s_axis
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis TDATA" *) input wire [`DMA_WIDTH-1:0] s_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis TKEEP" *) input wire [7:0] s_axis_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis TLAST" *) input wire s_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis TVALID" *) input wire s_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis TREADY" *) output wire s_axis_tready,

    // AXI Stream Master: adc_cDataAxis
    input wire [31:0] adc_cDataAxisTdata,
    input wire adc_cDataAxisTvalid,
    output wire adc_cDataAxisTready,

    // AXI Stream Master: dac_cDataAxis
    output wire [31:0] dac_cDataAxisTdata,
    output wire dac_cDataAxisTvalid,
    input wire dac_cDataAxisTready,

    // AXI Stream Master: m_axis
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TDATA" *) output wire [`DMA_WIDTH-1:0] m_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TKEEP" *) output wire [7:0] m_axis_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TLAST" *) output wire m_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TVALID"*) output wire m_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TREADY" *) input wire m_axis_tready
);
wire recv_data, data_incoming, load_done;

wire [`N_MAX*`N_MAX*`PARAMETER_WIDTH-1:0]Ah_on;
wire [`N_MAX*`PARAMETER_WIDTH-1:0]Bh_on;
wire [`N_MAX*`N_MAX*`PARAMETER_WIDTH-1:0]Ah_off;
wire [`N_MAX*`PARAMETER_WIDTH-1:0]Bh_off;
wire [`N_MAX*`N_MAX*`PARAMETER_WIDTH-1:0]C;
wire [7:0] size;
wire [7:0] pwm;
axis_interface axis_interface
(
    .clk(design_clk), .rst(design_n_rst), .en(en),
    
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tkeep(m_axis_tkeep),
    .m_axis_tlast(m_axis_tlast),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),

    .recv_data(recv_data),
    .data_incoming(data_incoming),
    .ready(load_done),

    .Ah_on(Ah_on),
    .Bh_on(Bh_on),
    .Ah_off(Ah_off),
    .Bh_off(Bh_off),
    .C(C),
    .size(size),
    .pwm(pwm),
    
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tkeep(s_axis_tkeep),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready)
);


wire [13:0] pwm_14;
pwm dummy_pwm
(
    .clk(design_clk), .rst(design_n_rst), .en(en),
    .duty_cycle(pwm),
    .pwm(pwm_14)
);

wire step_en, comp_ready, compute_blk_en;

wire [13:0] adc_ch1;
wire [13:0] adc_ch2;

wire [13:0] dac_ch1;
wire [13:0] dac_ch2;

wire rst_compute;
compute_blk compute_blk
(
    .clk(design_clk), .rst(rst_compute), .en(compute_blk_en), .step(step_en),
    .Ah_on(Ah_on),
    .Bh_on(Bh_on),
    .Ah_off(Ah_off),
    .Bh_off(Bh_off),
    .C(C),
    .size(size),
    .adc_ch1(pwm_14),
    .adc_ch2(adc_ch2),
    .dac_ch1(dac_ch1),
    .dac_ch2(dac_ch2),
    .comp_ready(comp_ready)
);

adc_interface adc_interface
(
    .clk_design (design_clk),
    .clk_adc(adc_clk),
    .rst(adc_n_rst),
    .en(en),

    .cDataAxisTdata(adc_cDataAxisTdata),
    .cDataAxisTvalid(adc_cDataAxisTvalid),
    .cDataAxisTready(adc_cDataAxisTready),

    .adc_ch1(adc_ch1),
    .adc_ch2(adc_ch2)
);

dac_interface dac_interface
(
    .clk_design(design_clk),
    .clk_dac(dac_clk),
    .rst(design_n_rst),
    .en(en),

    .cDataAxisTdata(dac_cDataAxisTdata),
    .cDataAxisTvalid(dac_cDataAxisTvalid),
    .cDataAxisTready(dac_cDataAxisTready),

    .dac_ch1(dac_ch1),
    .dac_ch2(pwm_14),

    .comp_ready(comp_ready)

);

wire is_running;
cu control_unit
(
    .clk(design_clk), .rst(design_n_rst), .en(en),
    .data_incoming(data_incoming),
    .receive_data(recv_data),

    .load_done(load_done),
    .compute_ready(comp_ready),
    .step(step_en),
    .rst_compute(rst_compute),
    .compute_blk_en(compute_blk_en),
    .is_running(is_running)
);


endmodule