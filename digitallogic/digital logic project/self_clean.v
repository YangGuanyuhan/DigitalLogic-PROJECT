module self_clean(
    input clk,           // 时钟信号，驱动逻辑电路运行
    input rst,           // 全局复位信号，置高时模块复位到初始状态
    input start_clean,   // 开始自清洁信号，用于触发自清洁模式
    output reg cleaning, // 自清洁状态指示，高电平表示正在进行自清洁
    output reg [7:0] countdown, // 倒计时显示的信号（格式为 MMSS，分钟和秒）
    output reg done      // 自清洁完成信号，高电平脉冲表示自清洁结束
);

    // 状态定义（使用 parameter 来表示不同状态）
    parameter IDLE      = 2'b00; // 空闲状态，等待开始自清洁的指令
    parameter START     = 2'b01; // 开始状态，用于进入自清洁模式
    parameter CLEANING  = 2'b10; // 自清洁状态，倒计时运行中
    parameter DONE      = 2'b11; // 完成状态，自清洁结束并返回空闲状态

    // 状态寄存器
    reg [1:0] state, next_state; // `state` 保存当前状态，`next_state` 保存下一个状态

    // 倒计时计数器（以秒为单位）
    reg [7:0] timer; // 用于记录剩余的倒计时时间，从初始值递减到0

    // 状态机逻辑
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE; // 复位时状态切换到初始状态（空闲）
        else
            state <= next_state; // 正常情况下切换到下一个状态
    end

    // 状态切换条件逻辑（组合逻辑）
    always @(*) begin
        case (state)
            IDLE: 
                if (start_clean) // 检测到开始信号时切换到 START 状态
                    next_state = START;
                else
                    next_state = IDLE; // 否则保持在空闲状态

            START: 
                next_state = CLEANING; // 进入清洁模式

            CLEANING: 
                if (timer == 0) // 倒计时结束后切换到 DONE 状态
                    next_state = DONE;
                else
                    next_state = CLEANING; // 否则保持在清洁状态

            DONE: 
                next_state = IDLE; // 完成后返回空闲状态

            default: 
                next_state = IDLE; // 任何未定义情况都回到空闲状态
        endcase
    end

    // 自清洁逻辑（时序逻辑）
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cleaning <= 0;        // 复位时清洁状态指示为关闭
            done <= 0;           // 复位时完成信号为低电平
            timer <= 8'd0;       // 复位时倒计时为 0
            countdown <= 8'd0;   // 复位时倒计时显示清零
        end else begin
            case (state)
                IDLE: begin
                    cleaning <= 0;        // 空闲状态不进行清洁
                    done <= 0;           // 未完成任何清洁任务
                    timer <= 8'd180;     // 初始化倒计时为 3 分钟（180 秒）
                end

                START: begin
                    cleaning <= 1;        // 开始自清洁状态
                end

                CLEANING: begin
                    if (timer > 0)       // 如果倒计时未结束
                        timer <= timer - 1; // 每个时钟周期倒计时减1秒
                    countdown <= {timer / 60, timer % 60}; // 将剩余时间转换为 MMSS 格式
                end

                DONE: begin
                    done <= 1;           // 自清洁完成信号置高
                    cleaning <= 0;       // 清洁状态指示关闭
                end
            endcase
        end
    end

endmodule
