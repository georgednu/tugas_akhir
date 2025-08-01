module adc_interface
(
    input wire clk_design, clk_adc, rst, en,

    input wire [31:0] cDataAxisTdata,
    input wire cDataAxisTvalid,
    output wire cDataAxisTready,

    output wire [13:0] adc_ch1,
    output wire [13:0] adc_ch2
);

assign cDataAxisTready = 1;

wire [31:0] data;

mcp mcp_adc
(  
    .clk1(clk_adc), .clk2(clk_design), .rst(rst), .en(en),
    .data(cDataAxisTdata), .tready(cDataAxisTvalid),
    .odata(data)
);

assign adc_ch1 = data [31:18];
assign adc_ch2 = data [15:2];


endmodule