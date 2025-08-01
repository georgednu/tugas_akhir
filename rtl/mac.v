module mac
#(
    parameter X_WIDTH = 43,
    parameter X_FRAC = 32,
    parameter Y_WIDTH = 43,
    parameter Y_FRAC = 32,
    parameter OUT_WIDTH = 43,
    parameter OUT_FRAC = 32
)
(
    input wire clk, rst, en, clr,
    input wire signed [X_WIDTH-1:0] x,
    input wire signed [Y_WIDTH-1:0] y,

    output wire signed [OUT_WIDTH-1:0] out
);

wire signed [X_WIDTH+Y_WIDTH-1:0] product;

assign product = x*y;

wire signed [OUT_WIDTH-1:0] acc;
wire signed [OUT_WIDTH-1:0] feedback;

assign feedback = (clr)? product[OUT_FRAC +: OUT_WIDTH] : product[OUT_FRAC +: OUT_WIDTH]+acc;

dff#(
    .WIDTH(OUT_WIDTH)
) accumulator
(
    .clk(clk), .rst(rst), .en(en),
    .in(feedback),
    .out(acc)
);

assign out = feedback;

endmodule