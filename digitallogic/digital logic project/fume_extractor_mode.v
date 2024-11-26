module fume_extractor_mode(
    input clk,                // 时钟信号
    input rst,                // 重置信号
    input mode_sel,           // 模式选择信号 (1: 抽油烟模式)
    input [1:0] speed_sel,    // 风力档位选择 (00: 1档, 01: 2档, 10: 3档)
    input manual_return,      // 手动返回待机信号
    output reg [5:0] timer,   // 倒计时显示 (单位：秒)
    output reg [1:0] speed,   // 当前档位
    output reg in_work,       // 抽油烟模式是否工作中
    output reg  alert          // 倒计时提醒信号
);

    reg [5:0] hurricane_timer = 6'd60; // 飓风模式倒计时60秒
    reg hurricane_used = 0;            // 标志是否使用过飓风模式

    always @(posedge clk or posedge  rst) begin
        if (rst) begin
            speed <= 2'b00;
            timer <= 6'd0;
            in_work <= 1'b0;
            hurricane_used <= 1'b0;
            alert <= 1'b0;
        end else if (mode_sel) begin
            in_work <= 1'b1;
            case (speed_sel)
                2'b00: begin
                    speed <= 2'b00; // 1档
                    timer <= 6'd0;
                end
                2'b01: begin
                    speed <= 2'b01; // 2档
                    timer <= 6'd0;
                end
                2'b10: begin
                    if (!hurricane_used) begin
                        speed <= 2'b10; // 3档(飓风模式)
                        if (timer == 0) timer <= hurricane_timer;
                        hurricane_used <= 1'b1;
                    end else begin
                        speed <= 2'b01; // 飓风已用，默认进入2档
                    end
                end
                default: speed <= 2'b00;
            endcase

            // 倒计时逻辑
            if (timer > 0) begin
                timer <= timer - 1'b1;
            end else if (timer == 0 && speed == 2'b10) begin
                speed <= 2'b01; // 飓风模式结束后降档到2档
            end

            // 手动返回待机模式
            if (manual_return) begin
                in_work <= 1'b0;
                speed <= 2'b00;
                timer <= 6'd0;
            end

            // 提醒信号
            alert <= (timer == 0);
        end else begin
            in_work <= 1'b0;
            speed <= 2'b00;
            timer <= 6'd0;
        end
    end
endmodule
