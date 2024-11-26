module self_cleaning_mode(
    input clk,                // 时钟信号
    input rst,                // 重置信号
    input mode_sel,           // 模式选择信号 (1: 自清洁模式)
    output reg [7:0] timer,   // 倒计时显示 (单位：秒)
    output reg cleaning_done, // 自清洁完成标志
    output reg alert          // 清洁完成提醒信号
);

    reg [7:0] cleaning_time = 8'd180; // 自清洁倒计时3分钟

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            timer <= 8'd0;
            cleaning_done <= 1'b0;
            alert <= 1'b0;
        end else if (mode_sel) begin
            if (timer == 0) begin
                timer <= cleaning_time; // 初始化倒计时
                cleaning_done <= 1'b0;
                alert <= 1'b0;
            end else if (timer > 0) begin
                timer <= timer - 1'b1; // 倒计时递减
            end

            // 倒计时结束逻辑
            if (timer == 1) begin
                cleaning_done <= 1'b1;
                alert <= 1'b1;
            end
        end else begin
            timer <= 8'd0;
            cleaning_done <= 1'b0;
            alert <= 1'b0;
        end
    end
endmodule
