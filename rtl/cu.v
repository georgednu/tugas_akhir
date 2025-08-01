`include "def.vh"

module cu
(
    input wire clk, rst, en,
    input wire data_incoming,
    output wire receive_data,

    input wire start,
    input wire load_done, compute_ready,
    output wire compute_blk_en,
    output wire step, rst_compute,
    output wire is_running
);

reg [2:0] state_reg;
localparam IDLE = 0;
localparam LOAD = 1;
localparam RUNNING = 2;

wire receive_data_en, step_en, rst_compute_en;

always @(posedge clk, negedge rst) begin
    if (!rst)
        state_reg<=IDLE;
    else if (en) begin
        case (state_reg)
            IDLE: state_reg <= (data_incoming)? LOAD : 
                               (start && !data_incmoing && load_done)? RUN : state_reg;
            LOAD: state_reg <= (load_done)? IDLE : state_reg;
            RUNNING: state_reg <= (!start || data_incmoing) IDLE : state_reg; 
            default: state_reg <= IDLE;
        endcase 
    end
end

reg [9:0] counter;

always @(posedge clk, negedge rst) begin
    if(!rst)
        counter<=0;
    else if (en&& (state_reg == RUNNING))
        counter<=(counter==`CLK_COUNTER)? 0 : counter+1; 
    else if (state_reg != RUNNING)
        counter <= 0;
end

assign receive_data_en = ((state_reg!=LOAD) && data_incoming)? 1 : 0;
assign step_en = ((state_reg == RUNNING) && (counter==`CLK_COUNTER))? 1:0;
assign rst_compute_en = (data_incoming)? 1:0;
assign compute_blk_en = (state_reg == RUNNING)? 1:0;

pulse_gen recv_data_pulser
(
    .clk(clk), .rst(rst), .en(receive_data_en),
    .pulse(receive_data)
);

pulse_gen step_pulser
(
    .clk(clk), .rst(rst), .en(step_en),
    .pulse(step)
);

wire rst_neg;
pulse_gen rst_compute_pulser
(
    .clk(clk), .rst(rst), .en(rst_compute_en),
    .pulse(rst_neg)
);

assign is_running = (state_reg == RUNNING) ? 1:0;

assign rst_compute = ~rst_neg;

endmodule