module mcp
(
    input wire clk1, clk2, rst, en,
    input wire [31:0] data,
    input wire tready,
    output reg [31:0] odata
);

reg [7:0] counter = 0;
localparam threshold = 3;
always @(posedge clk1, negedge rst) begin
    if (!rst)
        counter<=0;
    else if (en)
        counter <= (counter>=threshold && tready)? 0 : counter+1; 
end

reg [31:0] send_reg;
always @(posedge clk1, negedge rst) begin
    if (!rst)
        send_reg<=0;
    else if (en && counter>=3 && tready)
        send_reg <= data; 
end

wire send_pulse_en, pulse;
assign send_pulse_en = en && counter >= 3 && tready;
pulse_gen rdy_pulse
(
    .clk(clk1), .rst(rst), .en(send_pulse_en),
    .pulse(pulse)
);

reg t = 0;
always @(posedge clk1, negedge rst) begin
    if (!rst)
        t<=0;
    else if (en)
        t <= (pulse)? ~t : t; 
end

wire receive_en;
sync_pgen receiver_pulse_detector
(
    .clk(clk2), .rst(rst), .d(t),
    .p(receive_en)
);

always @(posedge clk2, negedge rst) begin
    if(!rst)
        odata<=0;
    else
        odata<=(receive_en)? send_reg : odata; 
end




endmodule