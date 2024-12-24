module self_clean( 
    input clk,           // 时钟信号，驱动逻辑电路运行
    input rst,           // 全局复位信号，置高时模块复位到初始状态
    input start_clean,   // 开始自清洁信号，用于触发自清洁模式
    input is_on,         // 抽油烟机开机状态信号，高电平表示开机
    output reg cleaning, // 自清洁状态指示，高电平表示正在进行自清洁
    output reg [7:0] countdown, // 倒计时显示的信号（格式为 MMSS，分钟和秒）
    output reg done      // 自清洁完成信号，高电平脉冲表示自清洁结束
);

    
    // 时钟信号 (一秒钟一个上升沿)
    wire clock;
    clk_one_second cos(
        .clk(clk),
        .reset(~rst),
        .clock(clock) // 一秒一个上升沿
    );

    always @(*) begin
        if (start_clean) begin
            cleaning <= 1;
        end
        else begin
            cleaning <= 0;        
        end

    end
    always @(posedge clock or negedge rst) begin
        if (~rst) begin
            countdown <= 8'd9;
            done <= 0;
        end
        else begin
            if (cleaning) begin
                if (countdown == 8'd0) begin
                    done <= 1;
                    countdown <= 8'd0;
                end
                else begin
                    countdown <= countdown - 8'd1;
                end
            end
            else begin
                done <= 0;
                countdown <= 8'd18;
            end
        end
    end

endmodule
