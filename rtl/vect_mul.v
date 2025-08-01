//Vector multiplication for the state space operation
//A matrix is stored inside a register, then connected to mat input wire
//State matrix x is stored inside a register, then connected to vect input wire
//N_config wire is 8 bit wires which represents the size of the vector operand.
//Ready is asserted when computation is done
//clr is asserted for 1 clock only when input needs to be processed

module vect_mul
#(
    parameter MAT_WIDTH = 43,
    parameter MAT_FRAC = 32,
    parameter VECT_WIDTH = 43,
    parameter VECT_FRAC = 32
)
(
    input wire clk, rst, en, clr,
    input wire [`N_MAX*`N_MAX*MAT_WIDTH-1:0] mat,
    input wire [`N_MAX*VECT_WIDTH-1:0] vect,
    input wire [7:0] N_config,

    output wire [`N_MAX*VECT_WIDTH-1:0] out,
    output wire ready
);

//wire signed [`WIDTH-1:0] mat_wires [0:`N_MAX-1] [0:`N_MAX-1];
wire signed [MAT_WIDTH-1:0] mat_multiplexed [0:`N_MAX-1];
wire signed [VECT_WIDTH-1:0] vect_multiplexed;
//wire signed [`WIDTH-1:0] vect_wires [0:`N_MAX-1];
wire signed [VECT_WIDTH-1:0] out_wires [0:`N_MAX-1];
genvar i, j;
generate
    for (i = 0; i<`N_MAX ; i=i+1) begin
        assign out[i*VECT_WIDTH+:VECT_WIDTH] = out_wires[i];
    end
endgenerate

reg [7:0] count = 0;
always @(posedge clk, negedge rst) begin
    if (!rst)
        count <= 0;
    else if(en)
        count <= (clr)? 0 :
                 (count == N_config)? count : count+1;
end

generate
    for (i = 0; i<`N_MAX ; i = i+1) begin
        assign mat_multiplexed[i] = (count<`N_MAX)?mat [((i*`N_MAX)+count)*MAT_WIDTH +: MAT_WIDTH]:0;
        assign vect_multiplexed = (count<`N_MAX)? vect [count*VECT_WIDTH+:VECT_WIDTH]:0;
        mac 
        #(
            .X_WIDTH(MAT_WIDTH),
            .X_FRAC(MAT_FRAC),
            .Y_WIDTH(VECT_WIDTH),
            .Y_FRAC(VECT_FRAC),
            .OUT_WIDTH(VECT_WIDTH),
            .OUT_FRAC(VECT_FRAC)
        )mac_vect
        (
            .clk(clk), .rst(rst), .en(en), .clr(clr),
            .x(mat_multiplexed[i]),
            .y(vect_multiplexed),

            .out(out_wires[i])
        );
    end
endgenerate
assign ready = (count == N_config && !clr)? 1 : 0;
// wire done;
// assign done = (count == N_config)? 1 : 0;
// reg pulsed; 

// always @(posedge clk, negedge rst) begin
//     if (!rst)
//         pulsed <= 0;
//     else if(en)
//         pulsed <= (clr)? 0:
//                   (ready)? 1 : pulsed;
// end

// always @(posedge clk, negedge rst) begin
//     if (!rst)
//         ready <= 0;
//     else if(done && !pulsed)
//         ready <= 1;
//     else
//         ready <= 0;
// end

endmodule