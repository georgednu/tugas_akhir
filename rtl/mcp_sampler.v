module mcp_sampler
#(
    parameter SAMPLE_THR = 5
)
(
    input wire [31:0] adatain,
    input wire asend,
    output wire aready,
    input wire arst_n,
    input wire aclk,

    output reg [31:0] bdata,
    input wire brst_n,
    input wire bclk
);

wire a_sample, b_sample, b_ack, aack;
reg [31:0] adata;
reg a_en;

reg [7:0] counter;
always @(posedge aclk, negedge arst_n) begin
    if (!arst_n)
        counter<=0;
    else
        counter <= ((counter>=SAMPLE_THR) && aack && asend)? 0 : counter+1; 
end
assign a_ready = (counter>=SAMPLE_THR) && aack;
assign a_sample = (counter>=SAMPLE_THR && aack && asend)? 1:0;

always @(posedge aclk, negedge arst_n) begin
    if (!arst_n)
        a_en<=0;
    else
        a_en <= a_sample ^ a_en;
end

always @(posedge aclk, negedge arst_n) begin
    if (!arst_n)
        adata<=0;
    else if (a_sample)
        adata <= adatain;
end

sync_pgen feedback
(
    .clk(aclk), .rst(arst_n), .d(b_ack),
    .p(aack)
);

sync_pgen b_pulse
(
    .clk(bclk), .rst(brst_n), .d(a_en),
    .p(b_sample), .q(b_ack)
);

always @(posedge bclk, negedge brst_n) begin
    if (!brst_n)
        bdata<=0;
    else if (b_sample)
        bdata <= adata;
end


endmodule