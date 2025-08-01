`include "def.vh"

module compute_blk
#(
    parameter PARAMETER_WIDTH = 43,
    parameter STATE_WIDTH = 43,
    parameter STATE_FRAC = 32,
    parameter PARAMETER_FRAC = 32
)
(
    input wire clk, rst, en, step, 
    input wire [`N_MAX*`N_MAX*PARAMETER_WIDTH-1:0]Ah_on,
    input wire [`N_MAX*PARAMETER_WIDTH-1:0]Bh_on,
    input wire [`N_MAX*`N_MAX*PARAMETER_WIDTH-1:0]Ah_off,
    input wire [`N_MAX*PARAMETER_WIDTH-1:0]Bh_off,
    input wire [`N_MAX*`N_MAX*PARAMETER_WIDTH-1:0]C,
    input wire [7:0] size,

    input wire signed [13:0] adc_ch1,
    input wire signed [13:0] adc_ch2,

    output wire [13:0] dac_ch1,
    output wire [13:0] dac_ch2,
    output wire signed [STATE_WIDTH-1:0] OUT1,
    output wire signed [STATE_WIDTH-1:0] OUT2,

    output wire comp_ready    
);

localparam signed [31:0] dac_scaling = 32'sh3333_3333;  // Q1.31 representation of 0.2

reg [`N_MAX*STATE_WIDTH-1:0] x_reg = 0;
wire [`N_MAX*STATE_WIDTH-1:0] x_new;

wire x_new_ready;
wire res_ready;

always @(posedge clk, negedge rst) begin
    if (!rst)
        x_reg<=0;
    else if (en && x_new_ready)
        x_reg <= x_new; 
end

wire [`N_MAX*`N_MAX*PARAMETER_WIDTH-1:0] Ah;
wire [`N_MAX*PARAMETER_WIDTH-1:0] Bh;

wire switch_on;
assign switch_on = (adc_ch1 > 14'h20D)? 1:0;

reg switch_reg;
reg delay_step;
always @(posedge clk, negedge rst) begin
    if (!rst) begin
        switch_reg <= 0;
    end
    else if (en && step) begin
        switch_reg <= switch_on;
    end
end

assign Ah = (switch_reg)? Ah_on : Ah_off;
assign Bh = (switch_reg)? Bh_on : Bh_off;

always @(posedge clk, negedge rst) begin
    if (!rst) begin
        delay_step <= 0;
    end
    else if (en) begin
        delay_step <= step;
    end
end

wire [`N_MAX*STATE_WIDTH-1:0] Ax;
wire [`N_MAX*STATE_WIDTH-1:0] Cx;

vect_mul #(
    .MAT_WIDTH(PARAMETER_WIDTH),
    .MAT_FRAC(PARAMETER_FRAC),
    .VECT_WIDTH(STATE_WIDTH),
    .VECT_FRAC(STATE_FRAC)
)ax_mul
(
    .clk(clk), .rst(rst), .en(en), .clr(delay_step),
    .mat(Ah),
    .vect(x_reg),
    .N_config(size),
    .out(Ax),
    .ready(x_new_ready)
);

vect_adder #(
    .WIDTH(STATE_WIDTH),
    .FRAC(STATE_FRAC)
)x_add
(
    .vect_a(Ax),
    .vect_b(Bh),
    .vect_out(x_new)
);

vect_mul#(
    .MAT_WIDTH(PARAMETER_WIDTH),
    .MAT_FRAC(PARAMETER_FRAC),
    .VECT_WIDTH(STATE_WIDTH),
    .VECT_FRAC(STATE_FRAC)
)cx_mul
(
    .clk(clk), .rst(rst), .en(en), .clr(delay_step),
    .mat(C),
    .vect(x_reg),
    .N_config(size),
    .out(Cx),
    .ready(res_ready)
);

wire [`N_MAX*STATE_WIDTH-1:0] out_wires;

assign out_wires = Cx;

// === Stage 1: Extract raw output vectors ===
reg signed [STATE_WIDTH-1:0] out_1_reg, out_2_reg;
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        out_1_reg <= 0;
        out_2_reg <= 0;
    end else if (en && res_ready) begin
        out_1_reg <= out_wires[0+:STATE_WIDTH];
        out_2_reg <= out_wires[STATE_WIDTH+:STATE_WIDTH];
    end
end

assign OUT1 = out_1_reg;
assign OUT2 = out_2_reg;

// === Stage 2: Scaled multiplication ===
reg signed [2*STATE_WIDTH-1:0] out_1_scaled_reg, out_2_scaled_reg;
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        out_1_scaled_reg <= 0;
        out_2_scaled_reg <= 0;
    end else if (en) begin
        out_1_scaled_reg <= out_1_reg * dac_scaling;
        out_2_scaled_reg <= out_2_reg * dac_scaling;
    end
end

// === Stage 3: Bit slicing ===
reg signed [STATE_WIDTH-1-STATE_FRAC:0] out_1_int_reg, out_2_int_reg;
reg out_1_sign, out_2_sign;
reg [12:0] out_1_mag, out_2_mag;
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        out_1_int_reg <= 0;
        out_2_int_reg <= 0;
        out_1_sign <= 0;
        out_2_sign <= 0;
        out_1_mag <= 0;
        out_2_mag <= 0;
    end else if (en) begin
        out_1_sign <= out_1_scaled_reg[2*STATE_WIDTH-1];
        out_2_sign <= out_2_scaled_reg[2*STATE_WIDTH-1];

        out_1_int_reg <= out_1_scaled_reg[STATE_WIDTH+STATE_FRAC-1 -: (STATE_WIDTH - STATE_FRAC)];
        out_2_int_reg <= out_2_scaled_reg[STATE_WIDTH+STATE_FRAC-1 -: (STATE_WIDTH - STATE_FRAC)];

        out_1_mag <= out_1_scaled_reg[2*STATE_FRAC-1 -: 13];
        out_2_mag <= out_2_scaled_reg[2*STATE_FRAC-1 -: 13];
    end
end

// === Stage 4: Saturation and DAC output ===
reg [13:0] dac_ch1_reg, dac_ch2_reg;
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        dac_ch1_reg <= 14'd0;
        dac_ch2_reg <= 14'd0;
    end else if (en) begin
        // DAC 1
        if (!out_1_sign && out_1_int_reg > 0)
            dac_ch1_reg <= 14'sh1FFF;
        else if (out_1_sign && out_1_int_reg < -1)
            dac_ch1_reg <= 14'sh2000;
        else
            dac_ch1_reg <= {out_1_sign, out_1_mag};

        // DAC 2
        if (!out_2_sign && out_2_int_reg > 0)
            dac_ch2_reg <= 14'sh1FFF;
        else if (out_2_sign && out_2_int_reg < -1)
            dac_ch2_reg <= 14'sh2000;
        else
            dac_ch2_reg <= {out_2_sign, out_2_mag};
    end
end

assign dac_ch1 = dac_ch1_reg;
assign dac_ch2 = dac_ch2_reg;

reg [3:0] ready_pipeline;
always @(posedge clk or negedge rst) begin
    if (!rst)
        ready_pipeline <= 4'd0;
    else
        ready_pipeline <= {ready_pipeline[2:0], x_new_ready && res_ready};
end

assign comp_ready = ready_pipeline[3];


endmodule