module self_clean( 
    input clk,           // 时钟信号，驱动逻辑电路运行
    input rst,           // 全局复位信号，置高时模块复位到初始状态
    input start_clean,   // 开始自清洁信号，用于触发自清洁模式
    input is_on,         // 抽油烟机开机状态信号，高电平表示开机
    output reg cleaning, // 自清洁状态指示，高电平表示正在进行自清洁
    output reg [7:0] countdown, // 倒计时显示的信号（格式为 MMSS，分钟和秒）
    output reg done      // 自清洁完成信号，高电平脉冲表示自清洁结束
);

    // 状态定义
    parameter IDLE      = 2'b00; // 空闲状态
    parameter CHECK     = 2'b01; // 检查 `start_clean` 持续信号状态
    parameter CLEANING  = 2'b10; // 自清洁状态
    parameter DONE      = 2'b11; // 自清洁完成

    // 状态寄存器，保存当前状态和下一个状态
    reg [1:0] state, next_state;

    // 持续信号检测计数器
    reg [2:0] start_count; // 计数 3 个时钟周期（约 3 秒）

    // 倒计时计数器（以秒为单位）
    reg [7:0] timer;

    // 为检测 is_on 上升沿设置的前一状态
    reg is_on_prev;

    // 检测 is_on 上升沿
    wire is_on_rising = is_on && !is_on_prev;

    // 时钟信号
    wire clock;
    clk_one_second cos(
        .clk(clk),
        .reset(~rst),
        .clock(clock) // 一秒一个上升沿
    );

    // 1. 状态转移逻辑（组合逻辑）
    always @(*) begin
        case (state)
            IDLE: 
                if (is_on && start_clean) 
                    next_state = CHECK; // 检测 `start_clean` 持续状态
                else
                    next_state = IDLE;

            CHECK: 
                if (start_count >= 3) // 检测到信号持续 3 秒
                    next_state = CLEANING;
                else if (!start_clean) // 信号中断返回空闲状态
                    next_state = IDLE;
                else
                    next_state = CHECK;

            CLEANING: 
                if (timer == 0)
                    next_state = DONE; // 倒计时结束切换到完成状态
                else
                    next_state = CLEANING;

            DONE: 
                next_state = IDLE; // 返回空闲状态

            default: 
                next_state = IDLE;
        endcase
    end

    // 2. 状态寄存器更新（时序逻辑）
    always @(posedge clock or posedge rst) begin
        if (rst) begin
            state <= IDLE;      // 复位时切换到空闲状态
            is_on_prev <= 1'b0; // 初始化 is_on_prev
            start_count <= 3'd0; // 持续信号计数清零
            timer <= 8'd180;   // 倒计时计数器设置为 180 秒
            cleaning <= 0;      // 复位时自清洁状态清零
            done <= 0;          // 复位时完成信号清零
            countdown <= 8'd0;  // 复位时倒计时显示清零
        end else begin
            is_on_prev <= is_on; // 更新 is_on_prev
            state <= next_state; // 更新状态寄存器
        end
    end

    // 3. 时序逻辑（计数器更新）
    always @(posedge clock or posedge rst) begin
        if (rst) begin
            cleaning <= 0;           // 复位时自清洁状态清零
            done <= 0;               // 复位时完成信号清零
            timer <= 8'd0;           // 复位时倒计时清零
            countdown <= 8'd0;       // 复位时倒计时显示清零
            start_count <= 3'd0;     // 持续信号计数清零
        end else begin
            case (state)
                IDLE: begin
                    cleaning <= 0;      // 空闲状态时未处于清洁模式
                    done <= 0;          // 空闲状态时完成信号清零
                    countdown <= 8'd0;  // 清零倒计时显示
                    start_count <= 3'd0; // 复位持续信号计数
                end

                CHECK: begin
                    if (start_clean)
                        start_count <= start_count + 1; // 每秒计数
                    else
                        start_count <= 3'd0; // 信号中断，计数清零
                end

                CLEANING: begin
                    cleaning <= 1;      // 清洁状态激活
                    if (timer > 0)
                        timer <= timer - 1; // 倒计时减一
                    countdown <= timer; // 更新倒计时显示
                end

                DONE: begin
                    done <= 1;          // 完成信号设置为高
                    cleaning <= 0;      // 清洁状态停止
                end
            endcase
        end
    end

endmodule
