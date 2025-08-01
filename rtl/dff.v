`include "def.vh"

module dff
#(
    parameter WIDTH = 32
)
(
    input wire clk, rst, en,
    input wire [WIDTH-1:0] in,
    
    output reg [WIDTH-1:0] out
);

    initial out = 0;

    always @(posedge clk, negedge rst) begin
        if (!rst)
            out<=0;
        else if (en)
            out<= in;
    end

endmodule