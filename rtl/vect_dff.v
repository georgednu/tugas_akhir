module vect_dff
#(
    parameter WIDTH = 43
)
(
    input wire clk, rst, en,
    input wire [`N_MAX*WIDTH-1:0] vect_in,

    output wire [`N_MAX*WIDTH-1:0] vect_out
);
genvar i, j;

wire [WIDTH-1:0] el_wires_in [0:`N_MAX-1];
wire [WIDTH-1:0] el_wires_out [0:`N_MAX-1];

generate
    for(i = 0; i<`N_MAX; i=i+1) begin
        assign el_wires_in [i] = vect_in[i*WIDTH+:WIDTH];
        assign vect_out [i* WIDTH+:WIDTH] = el_wires_out [i];
    end    
endgenerate


generate
    for(i = 0; i<`N_MAX; i=i+1) begin
        dff 
        #(
            .WIDTH(WIDTH)
        )dff_mat
        (
            .clk(clk), .en(en), .rst(rst),
            .in(el_wires_in[i]),
            .out(el_wires_out[i])
        );
    end 
endgenerate

endmodule