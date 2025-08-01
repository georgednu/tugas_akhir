`include "def.vh"


module axis_interface
#(
    parameter DMA_WIDTH = 64,
    parameter PARAMETER_WIDTH = 43
)
(
    input wire clk, rst, en,

    input wire [DMA_WIDTH-1:0] s_axis_tdata,
    input wire  [7:0] s_axis_tkeep,
    input wire s_axis_tlast,
    input wire s_axis_tvalid,
    output wire s_axis_tready,

    input wire recv_data,
    output wire data_incoming, ready,
    
    output wire [`N_MAX*`N_MAX*PARAMETER_WIDTH-1:0]Ah_on,
    output wire [`N_MAX*PARAMETER_WIDTH-1:0]Bh_on,
    output wire [`N_MAX*`N_MAX*PARAMETER_WIDTH-1:0]Ah_off,
    output wire [`N_MAX*PARAMETER_WIDTH-1:0]Bh_off,
    output wire [`N_MAX*`N_MAX*PARAMETER_WIDTH-1:0]C,
    output wire [7:0] size,
    output wire [7:0] pwm,
    
    output wire [DMA_WIDTH-1:0] m_axis_tdata,
    output wire  [7:0] m_axis_tkeep,
    output wire m_axis_tlast,
    output wire m_axis_tvalid,
    input wire m_axis_tready

);

localparam IDLE = 0;
localparam GET_TYPE = 1;
localparam RECEIVING = 2;
localparam DEBUGGING = 3;

localparam GET_AH_ON = 1;
localparam GET_BH_ON = 2;
localparam GET_AH_OFF = 3;
localparam GET_BH_OFF = 4;
localparam GET_C = 5;
localparam GET_SIZE = 6;
localparam DEBUG = 7;
localparam PWM = 8;

wire debug_done;

reg [`DMA_WIDTH-1:0] type = 0;
reg [2:0] state = 0; 
always @(posedge clk) begin
    if (!rst)
        state<= IDLE;
    if (en)
        case (state)
            IDLE: state <= (recv_data) ? GET_TYPE :
                           (type == DEBUG)? DEBUGGING : state;
            GET_TYPE: state <= (s_axis_tlast && s_axis_tdata != 7) ? IDLE :
                               (s_axis_tlast && s_axis_tdata == 7) ? DEBUGGING :
                               ((!s_axis_tlast) && s_axis_tvalid) ? RECEIVING : state;
            RECEIVING: state <= (s_axis_tlast) ? IDLE : state;
            DEBUGGING: state <= (debug_done)? IDLE: state;
            default: state <= IDLE;
        endcase 
end

assign data_incoming = (state == IDLE) && (s_axis_tvalid==1);

assign s_axis_tready = ((en==1) && (state != IDLE))? 1:0;

always @(posedge clk, negedge rst) begin
    if (!rst)
        type<=0;
    else if (en && state==GET_TYPE)
        type<=s_axis_tdata;
end

wire Ah_on_en, Bh_on_en, Ah_off_en, Bh_off_en, C_en, size_en, pwm_en;

assign Ah_on_en = ((en==1) && (state==RECEIVING) && (type ==  GET_AH_ON)) ? 1 : 0;
assign Bh_on_en = ((en==1) && (state==RECEIVING) && (type ==  GET_BH_ON)) ? 1 : 0;
assign Ah_off_en = ((en==1) && (state==RECEIVING) && (type ==  GET_AH_OFF)) ? 1 : 0;
assign Bh_off_en = ((en==1) && (state==RECEIVING) && (type ==  GET_BH_OFF)) ? 1 : 0;
assign C_en = ((en==1) && (state==RECEIVING) && (type ==  GET_C)) ? 1 : 0;
assign size_en = ((en==1) && (state==RECEIVING) && (type ==  GET_SIZE)) ? 1 : 0;
assign pwm_en = ((en==1) && (state==RECEIVING) && (type ==  PWM)) ? 1 : 0;
 
wire [PARAMETER_WIDTH-1:0] tdata_truncated;
assign tdata_truncated = s_axis_tdata[PARAMETER_WIDTH-1:0];

shift_reg
//Ah_ON
#(
    .len(`N_MAX*`N_MAX),
    .WIDTH(PARAMETER_WIDTH)
) reg_Ah_on
(
    .clk(clk), .rst(rst), .en(Ah_on_en),
    .serial_in(tdata_truncated),
    .out(Ah_on)
);

shift_reg 
//Bh_ON
#(
    .len(`N_MAX),
    .WIDTH(PARAMETER_WIDTH)
)reg_Bh_on
(
    .clk(clk), .rst(rst), .en(Bh_on_en),
    .serial_in(tdata_truncated),
    .out(Bh_on)
);

shift_reg
//Ah_off
#(
    .len(`N_MAX*`N_MAX),
    .WIDTH(PARAMETER_WIDTH)
) reg_Ah_off
(
    .clk(clk), .rst(rst), .en(Ah_off_en),
    .serial_in(tdata_truncated),
    .out(Ah_off)
);

shift_reg 
//Bh_off
#(
    .len(`N_MAX),
    .WIDTH(PARAMETER_WIDTH)
)reg_Bh_off
(
    .clk(clk), .rst(rst), .en(Bh_off_en),
    .serial_in(tdata_truncated),
    .out(Bh_off)
);

shift_reg
//C 
#(
    .len(`N_MAX*`N_MAX),
    .WIDTH(PARAMETER_WIDTH)
)reg_C
(
    .clk(clk), .rst(rst), .en(C_en),
    .serial_in(tdata_truncated),
    .out(C)
);

wire [DMA_WIDTH-1:0] size_64;
shift_reg 
//SIZE
#(
    .len(1),
    .WIDTH(DMA_WIDTH)
)reg_size
(
    .clk(clk), .rst(rst), .en(size_en),
    .serial_in(s_axis_tdata),
    .out(size_64)
);
assign size = size_64 [7:0];


wire [DMA_WIDTH-1:0] pwm_64;
shift_reg 
//PWM
#(
    .len(1),
    .WIDTH(DMA_WIDTH)
)reg_pwm
(
    .clk(clk), .rst(rst), .en(pwm_en),
    .serial_in(s_axis_tdata),
    .out(pwm_64)
);
assign pwm = pwm_64 [7:0];


assign ready = (state ==  IDLE)? 1:0;



// assign m_axis_tvalid = (state == DEBUGGING) ? 1:0;
// assign m_axis_tkeep = 8'hFF;
// assign m_axis_tlast = (debug_counter == END_OF_DEBUG)? 1:0;
// assign debug_done = (debug_counter == END_OF_DEBUG)? 1:0;

// wire [(2*(`N_MAX*`N_MAX) + 2*`N_MAX + 2)*`WIDTH-1:0] debug_wires;
// assign debug_wires = {size, u, mat_D, mat_C, mat_B, mat_A};

// assign m_axis_tdata = debug_wires [debug_counter*`WIDTH+:`WIDTH];

// Hardcoded matrix and vector data (flattened row-major with [0][0] as LSB)
// assign Ah_on = {
//     // Row 5
//     {6{43'd0}},
//     // Row 4
//     {6{43'd0}},
//     // Row 3
//     {6{43'd0}},
//     // Row 2
//     {6{43'd0}},
//     // Row 1
//     43'd0, 43'd0, 43'd0, 43'd0, 43'sd4292819812, 43'sd21474836,
//     // Row 0
//     43'd0, 43'd0, 43'd0, 43'd0, -43'sd21474836, 43'sd4294967296
// };

// assign Ah_off = Ah_on;

// assign Bh_on = {
//     43'd0, 43'd0, 43'd0, 43'd0, 43'd0, 43'sd107374182
// };

// assign Bh_off = {
//     43'd0, 43'd0, 43'd0, 43'd0, 43'd0, 43'd0
// };

// assign C = {
//     // Row 5
//     {6{43'd0}},
//     // Row 4
//     {6{43'd0}},
//     // Row 3
//     {6{43'd0}},
//     // Row 2
//     {6{43'd0}},
//     // Row 1
//     {6{43'd0}},
//     // Row 0
//     43'd0, 43'd0, 43'd0, 43'd0, 43'd4294967296, 43'd0
// };

// assign size = 8'd2;
// assign pwm = 8'd5

endmodule       