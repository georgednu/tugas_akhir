module pwm 
(
    input wire clk, rst, en,
    input wire [7:0] duty_cycle,
    output wire [13:0] pwm
);

localparam CLK_DIV = 25;
reg clk_divided = 0;
reg [7:0] clk_counter = 0;

always @(posedge clk, negedge rst) begin
    if (!rst) 
        clk_counter <= 0;
    else if (en)
        clk_counter <= (clk_counter==CLK_DIV-1)? 0 : clk_counter + 1;
end

always @(posedge clk, negedge rst) begin
    if (!rst)
        clk_divided <= 0;
    else if (en)
        clk_divided <= (clk_counter==CLK_DIV-1)? ~clk_divided : clk_divided;
end

reg [7:0] pwm_counter = 0;

always @(posedge clk_divided, negedge rst) begin
    if (!rst)
        pwm_counter <= 0;
    else if (en)
        pwm_counter <= (pwm_counter==99)? 0 : pwm_counter + 1;
end

assign pwm = (pwm_counter < duty_cycle) ? 14'b01_1111_1111_1111 : 0;

endmodule