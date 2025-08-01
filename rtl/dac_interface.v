module dac_interface
(
    input wire clk_design, clk_dac, rst, en,

    output wire [31:0] cDataAxisTdata,
    output wire cDataAxisTvalid,
    input wire cDataAxisTready,

    input wire [13:0] dac_ch1,
    input wire [13:0] dac_ch2,

    input wire comp_ready
);

assign cDataAxisTvalid = 1;
wire [31:0] data;
assign data = {dac_ch1, 2'b00, dac_ch2, 2'b00};

mcp mcp_dac
(
    .clk1(clk_design), .clk2(clk_dac), .rst(rst), .en(en),
    .data(data), .tready(comp_ready),
    .odata(cDataAxisTdata)
);

endmodule