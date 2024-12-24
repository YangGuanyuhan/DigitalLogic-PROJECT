module top(
input clk, rst, button,
output seg_en,
output [7:0] seg_out
    );
    wire  pos, neg;
    wire [2:0]c;
    sub1 s1(clk, rst, button, neg, pos );
    sub2 s2(clk, rst, pos,  c);
    light_7seg_ego1 seg({1'b0,c}, seg_out, seg_en );
endmodule

module light_7seg_ego1(
input [3:0] sw, output reg[7:0] seg_out, output [7:0] seg_en
    );
    assign seg_en = 8'hff;
    always@*
        case(sw)
            4'h0: seg_out = 8'b1111_1100;
            4'h1: seg_out = 8'b0110_0000;
            4'h2: seg_out = 8'b1101_1010;
            4'h3: seg_out = 8'b1111_0010;
            4'h4: seg_out = 8'b0110_0110;
            4'h5: seg_out = 8'b1011_0110;
            4'h6: seg_out = 8'b1011_1110;
            4'h7: seg_out = 8'b1110_0000;
            default: seg_out = 8'b0000_0000;
        endcase
endmodule





