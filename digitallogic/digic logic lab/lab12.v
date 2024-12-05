`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/26 18:06:23
// Design Name: 
// Module Name: breath_led_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module breath_led_top(
    input clk,
    input rst_n,
    output led,
    output clk_out
);
  

    counter counter1 (
        .clk(clk),
        .rst_n(rst_n),
        .clk_out(clk_out)
    );

    breath_led_control breath_led_control1 (
        .clk(clk),
        .rst_n(rst_n),
        .led(led),
        .clk_out(clk_out)
    );
endmodule

module breath_led_control(
    input clk,
    input rst_n,
    input clk_out,
    output reg led
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led <= 1'b0;
        end
        else if (clk_out) begin
            led <= ~led;
        end
    end
endmodule

module counter (
    input clk,
    input rst_n,
    output  clk_out
);
    reg [13:0] cnt_first;
    reg [13:0] cnt_second;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_first <= 14'b0;
          
        end
        else if (cnt_first == 14'd10) begin
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
        else if (cnt_second == 14'd10) begin
           
                cnt_second <= 14'b0;
                end
         
            else  if (cnt_first==14'd10)begin
                cnt_second <= cnt_second + 1;
            end
            else
            cnt_second<=cnt_second;
            end
          
           
      
    assign clk_out=cnt_second==14'd10;
endmodule

