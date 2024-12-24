module self_clean( 
    input clk,           // 时钟信号，驱动逻辑电路运行
    input rst,           // 全局复位信号，置低时模块复位到初始状态
    input start_clean,   // 开始自清洁信号，用于触发自清洁模式
    input is_on,         // 抽油烟机开机状态信号，高电平表示开机
    output reg cleaning, // 自清洁状态指示，高电平表示正在进行自清洁
    output reg [7:0] countdown, // 倒计时显示的信号（格式为 MMSS，分钟和秒）
    output reg done      // 自清洁完成信号，高电平脉冲表示自清洁结束
);

    // 状态定义
    parameter IDLE      = 2'b00; // 空闲状态
    parameter CLEANING  = 2'b01; // 自清洁状态
    parameter DONE      = 2'b10; // 自清洁完成状态

    // 状态寄存器，保存当前状态和下一个状态
    reg [1:0] state, next_state;

    // 倒计时计数器（以秒为单位）
    reg [7:0] timer;

    // 时钟信号 (一秒钟一个上升沿)
    wire clock;
    clk_one_second cos(
        .clk(clk),
        .reset(~rst),  // 低电平有效，故将 rst 取反传递给 clk_one_second 模块
        .clock(clock)   // 一秒一个上升沿
    );


    // 状态转移逻辑（组合逻辑）
    always @(*) begin
        case (state)
            IDLE: 
                if (is_on && start_clean) 
                    next_state = CLEANING; // 开始自清洁
                else
                    next_state = IDLE;

            CLEANING: 
                if (timer == 0)
                    next_state = DONE; // 倒计时结束，进入完成状态
                else
                    next_state = CLEANING;

            DONE: 
                next_state = IDLE; // 完成后返回空闲状态

            default: 
                next_state = IDLE;
        endcase
    end

    // 状态机更新
    always @(posedge clk or negedge rst) begin  
        if (~rst) begin  // 低电平有效的复位信号
            state <= IDLE;      // 复位时回到空闲状态
            timer <= 8'd18;     // 初始化倒计时为 18 秒
            cleaning <= 0;      // 清除自清洁状态
            done <= 0;          // 清除完成信号
            countdown <= 8'd0;  // 清除倒计时显示
        end else begin
            state <= next_state; // 更新状态寄存器
        end
    end

    // 自清洁倒计时逻辑
    always @(posedge clock or negedge rst) begin  
            case (state)
                CLEANING: begin
                    if (timer > 0)
                        timer <= timer - 1; // 每秒倒计时
                    countdown <= timer; // 更新倒计时显示
                end
                DONE: begin
                    done <= 1'b1; // 自清洁完成信号激活
                end

                default: begin
                    done <= 1'b0; // 其他状态清除完成信号
                end
            endcase
        end

    // 控制自清洁状态和完成信号
    always @(posedge clk or negedge rst)  // 修改为 negedge rst
        begin
            case (state)
                CLEANING: cleaning <= 1'b1; // 自清洁模式时，清洁信号置高
                DONE: cleaning <= 1'b0;      // 完成时清除清洁信号
                default: cleaning <= 0;      // 其他状态下清除清洁信号
            endcase
        end

endmodule
