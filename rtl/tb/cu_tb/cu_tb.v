`define 1ns/1ns
`include "../../cu.v"

module cu_tb;

reg clk, rst, en;
initial clk = 0;

forever begin
 #10 clk = ~clk;
end

initial begin
    rst = 0 ;
    en = 0 ;
    #10 en = 1;
    #20 rst = 1;
end

reg data_inc

endmodule