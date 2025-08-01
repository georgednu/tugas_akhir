module sync_pgen
(
    input wire clk, rst, d,
    output wire p, q
);

(* ASYNC_REG = "TRUE" *) reg d1;
(* ASYNC_REG = "TRUE" *) reg d2;
reg d3;

always @(posedge clk, negedge rst) begin
    if (!rst)
        d1<=0;
    else
        d1<=d; 
end


always @(posedge clk, negedge rst) begin
    if (!rst)
        d2<=0;
    else
        d2<=d1; 
end


always @(posedge clk, negedge rst) begin
    if (!rst)
        d3<=0;
    else
        d3<=d2; 
end

assign q = d3;
assign p = d3^d2;


endmodule