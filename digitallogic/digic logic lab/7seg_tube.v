module scan_seg(
    input rst_n,        // Reset: low effective
    input clk,          // System clock (100MHz)
    output reg [7:0] seg_en,  // Selection for 7-segment tubes (0-7)
    output [7:0] seg_out0,    // Output for segment 0
    output [7:0] seg_out1     // Output for segment 1
);

// Internal registers
reg clkout;             // Clock output after division
reg [31:0] cnt;         // Counter for clock division
reg [2:0] scan_cnt;     // Scan counter

// Parameter for clock division period (500KHz stable)
parameter period = 200000;  // You can adjust this value for different frequencies

// Clock division logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt <= 0;
        clkout <= 0;
    end else if (cnt == (period>>2) - 1) begin
        clkout <= ~clkout;
        cnt <= 0;
    end else begin
        cnt <= cnt + 1;
    end
end

// Scan tube logic based on clkout
always @(posedge clkout or negedge rst_n) begin
    if (!rst_n) begin
        scan_cnt <= 0;
    end else if (scan_cnt == 3'b111) begin
        scan_cnt <= 0;
    end else begin
        scan_cnt <= scan_cnt + 1;
    end
end

// Select 7-segment tube and output corresponding signals
always @(scan_cnt) begin
    case (scan_cnt)
        3'b000: seg_en = 8'h01;
        3'b001: seg_en = 8'h02;
        3'b010: seg_en = 8'h04;
        3'b011: seg_en = 8'h08;
        3'b100: seg_en = 8'h10;
        3'b101: seg_en = 8'h20;
        3'b110: seg_en = 8'h40;
        3'b111: seg_en = 8'h80;
        default: seg_en = 8'h00;
    endcase
end

wire [7:0] useless1, useless2;  // Unused wires for 7-segment display outputs


// Instantiate 7-segment display drivers for each tube
light_7seg_egol u0(
    .in_data({1'b0, scan_cnt}),
    .seg_out(seg_out0),
    .seg_en(useless1)  // Unused, already controlled by seg_en
);

light_7seg_egol u1(
    .in_data({1'b0, scan_cnt}),
    .seg_out(seg_out1),
    .seg_en(useless2)  // Unused, already controlled by seg_en
);

endmodule

// Light 7-segment display module (using switch input to display numbers)
module light_7seg_egol(
    input [3:0] in_data,  // 3-bit input data for 7-segment (switched)
    output reg [7:0] seg_out,  // Output segments
    output [7:0] seg_en    // Segment enable signals
);

assign seg_en = 8'hFF;  // Enable all segments
// 7-segment decoding logic for displaying digits
always @(in_data) begin
    case (in_data)
        4'b00000: seg_out = 8'b11111100; // Display "0"
        4'b00001: seg_out = 8'b01100000; // Display "1"
        4'b00010: seg_out = 8'b11011010; // Display "2"
        4'b00011: seg_out = 8'b11110010; // Display "3"
        4'b00100: seg_out = 8'b01100110; // Display "4"
        4'b00101: seg_out = 8'b10110110; // Display "5"
        4'b00110: seg_out = 8'b10111110; // Display "6"
        4'b00111: seg_out = 8'b11100000; // Display "7"
        4'b01000: seg_out = 8'b11111110; // Display "8"
        4'b01001: seg_out = 8'b11110110; // Display "9"
        4'b01010: seg_out = 8'b11111010; // Display "A"
        4'b01011: seg_out = 8'b00111110; // Display "b"
        4'b01100: seg_out = 8'b10011100; // Display "C"
        4'b01101: seg_out = 8'b01111010; // Display "d"
        4'b01110: seg_out = 8'b10011110; // Display "E"
        4'b01111: seg_out = 8'b10010110; // Display "F"
        default: seg_out = 8'b00000000; // Default: off
    endcase
end

endmodule
