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

    // 状态寄存器
    reg [1:0] state, next_state;

    // 持续信号检测计数器
    reg [2:0] start_count; // 计数 3 个时钟周期（约 3 秒）

    // 倒计时计数器（以秒为单位）
    reg [7:0] timer;

    // 状态机逻辑
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE; // 复位时切换到空闲状态
        else
            state <= next_state;
    end

    // 状态切换条件逻辑
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

    // 自清洁逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cleaning <= 0;
            done <= 0;
            timer <= 8'd0;
            countdown <= 8'd0;
            start_count <= 3'd0; // 持续信号计数清零
        end else begin
            case (state)
                IDLE: begin
                    cleaning <= 0;
                    done <= 0;
                    timer <= 8'd180; // 初始化倒计时为 180 秒
                    start_count <= 3'd0; // 复位持续信号计数
                end

                CHECK: begin
                    if (start_clean)
                        start_count <= start_count + 1; // 每秒计数
                    else
                        start_count <= 3'd0; // 信号中断，计数清零
                end

                CLEANING: begin
                    cleaning <= 1;
                    if (timer > 0)
                        timer <= timer - 1; // 倒计时减一
                    countdown <= timer; // 更新倒计时显示
                end

                DONE: begin
                    done <= 1;
                    cleaning <= 0;
                end
            endcase
        end
    end

endmodule
