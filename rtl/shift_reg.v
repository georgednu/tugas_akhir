//This module act as an input buffer for either parallel or serial input.
//Can be used to acquire input of matrices through AXI stream interface
//serial_en triggers a mux which transforms module into shift registers
//When serial_en de-asserted can be used as normal register with parallel input

module shift_reg
#(
    parameter len = `N_MAX*`N_MAX,
    parameter WIDTH = 32
)
(
    input wire clk, rst, en,
    input wire [WIDTH-1:0] serial_in,

    output wire [len*WIDTH-1:0] out
);

wire [WIDTH-1:0] dff_in [0:len-1];
wire [WIDTH-1:0] dff_out [0:len-1];
wire [WIDTH-1:0] shift_wire [0:len];

genvar i;
generate
    for ( i = 0; i<len ; i=i+1) begin
        assign out [i*WIDTH +: WIDTH] = dff_out [i];
        assign dff_in [i] = shift_wire[i+1];
    end
endgenerate

assign shift_wire [len] = serial_in;

generate
    for ( i = 0; i<len ; i=i+1) begin
        dff #(
            .WIDTH(WIDTH)
        )mat_reg
        (
            .clk(clk), .rst(rst), .en(en),
            .in(dff_in[i]),
            .out(shift_wire[i])
        );
        assign dff_out[i] = shift_wire[i];
    end
endgenerate


endmodule