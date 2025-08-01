module pulse_gen
(
    input wire clk, rst, en,
    output wire pulse
);

reg in;
reg d;

initial in = 0;
always @(posedge clk, negedge rst) begin
    if (!rst)
        d <= 0;
    else
        d <= in;
end

always @(posedge clk, negedge rst) begin
    if (!rst)
        in <= 0;
    else if (en)
        in <= ~in;
end

assign pulse = d ^ in;

endmodule