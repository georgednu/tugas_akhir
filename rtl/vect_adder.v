module vect_adder
#(
    parameter WIDTH = 43,
    parameter FRAC = 32
)
(
    input wire [`N_MAX*WIDTH-1:0] vect_a,
    input wire [`N_MAX*WIDTH-1:0] vect_b,

    output wire [`N_MAX*WIDTH-1:0] vect_out

);
genvar i, j;

wire signed [WIDTH-1:0] a_wires  [0:`N_MAX-1];
wire signed [WIDTH-1:0] b_wires [0:`N_MAX-1];
wire signed [WIDTH-1:0] out_wires [0:`N_MAX-1];

generate
    for(i = 0; i<`N_MAX; i=i+1) begin
        assign a_wires [i] = vect_a[i* WIDTH+:WIDTH];
        assign b_wires [i] = vect_b[i* WIDTH+:WIDTH];
        assign vect_out [i* WIDTH+:WIDTH] = out_wires [i];
    end    
endgenerate


generate
    for(i = 0; i<`N_MAX; i=i+1) begin
        assign out_wires[i] = a_wires[i] + b_wires[i];
    end 
endgenerate

endmodule