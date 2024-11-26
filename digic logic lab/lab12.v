module breath_led_top(
    input clk,
    input rst_n,
    output led
);
    wire clk_out;

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
    output reg clk_out
);
    reg [13:0] cnt_first;
    reg [13:0] cnt_second;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_first <= 14'b0;
            clk_out <= 1'b0;
        end
        else if (cnt_first == 14'd10000) begin
            cnt_first <= 14'b0;
            clk_out <= ~clk_out;
        end
        else begin
            cnt_first <= cnt_first + 1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_second <= 14'b0;
        end
        else if (cnt_first == 14'd10000) begin
            if (cnt_second == 14'd10000) begin
                cnt_second <= 14'b0;
            end
            else begin
                cnt_second <= cnt_second + 1;
            end
        end
    end
endmodule
