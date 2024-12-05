module lab13(
    input clk,
    input rst,
    input trig,
    output reg light
);
    wire clk_out, pos;

    // 实例化 trigTest 模块
    trigTest t1 (
        .clk(clk_out),
        .rst(rst),
        .trig(trig),
        .pos(pos)
    );

    // 实例化 counter 模块
    counter c1 (
        .clk(clk),
        .rst_n(rst),
        .clk_out(clk_out)
    );

    // 控制 light 的逻辑
    always @(posedge clk_out or negedge rst)
    begin
        if (!rst)
            light <= 1;
        else if (pos)
            light <= ~light;
            else
            light <= light;

    end

endmodule




 module trigTest(
    input clk,
    input rst,
    input trig,
    output pos
);
    reg trig1, trig2, trig3;
    
    always @(posedge clk or negedge rst) 
    begin
        if (!rst) 
            {trig1, trig2, trig3} <= 3'b000;
        else begin
            trig1 <= trig;
            trig2 <= trig1;
            trig3 <= trig2;
        end
    end
    
    assign pos = (~trig3) & trig2;
    
endmodule


module counter (
    input clk,
    input rst_n,
    output  clk_out
);
parameter period =14'd10 ;
    reg [13:0] cnt_first;
    reg [13:0] cnt_second;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_first <= 14'b0;
          
        end
        else if (cnt_first == period) begin
            cnt_first <= 14'b0;
        
        end
        else begin
            cnt_first <= cnt_first + 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_second <= 14'b0;
        end
        else if (cnt_second == period) begin
           
                cnt_second <= 14'b0;
                end
         
            else  if (cnt_first==period)begin
                cnt_second <= cnt_second + 1;
            end
            else
            cnt_second<=cnt_second;
            end
          
           
      
    assign clk_out=cnt_second==period;
endmodule