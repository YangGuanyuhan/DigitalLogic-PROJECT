
module exhaust_function (
    input clk,                  // 时钟信号
    input rst,                  // 全局复位信号
    input menu_key,             // 菜单键，切换到待机模式或切换模式
    input level1_key,           // 1档按键
    input level2_key,           // 2档按键
    input level3_key,           // 3档按键（飓风模式）
    input is_on,                // 抽油烟机开机状态信号，高电平表示开机
    output reg [1:0] mode,      // 当前工作模式（00：待机，01：1档，10：2档，11：3档飓风）
    output reg [7:0] countdown, // 倒计时输出（用于飓风模式或返回待机模式）
    output reg busy,            // 工作状态指示（0：空闲，1：正在工作）
    output reg countdown_active, // 倒计时激活标志（高电平表示处于 LEVEL3 或 RETURN_IDLE 且倒计时有效）
    output reg in_switch_mode   // 是否处于 SWITCH_MODE 状态的信号
);

    // 状态定义（统一为 3 位宽）
    parameter IDLE        = 3'b000; // 待机模式
    parameter LEVEL1      = 3'b001; // 一级档位
    parameter LEVEL2      = 3'b010; // 二级档位
    parameter LEVEL3      = 3'b011; // 三级档位（飓风模式）
    parameter SWITCH_MODE = 3'b100; // 模式切换模式
    parameter RETURN_IDLE = 3'b111; // 强制返回待机模式倒计时状态

    reg [2:0] current_mode, next_mode; // 当前模式和下一模式（3 位宽）
    reg [7:0] level3_timer;            // 飓风模式倒计时计数器
    reg [7:0] return_idle_timer;       // 返回待机模式倒计时计数器
    reg level3_used;                   // 飓风模式是否已使用标志位
    reg is_on_prev;                    // 用于检测 is_on 上升边的前一状态

    // 检测 is_on 上升边
    wire is_on_rising = is_on && !is_on_prev; // 定义一个信号，表示 is_on 的上升沿

    // 状态机逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_mode <= IDLE;          // 复位时回到待机模式
            level3_timer <= 8'd0;         // 飓风倒计时清零
            return_idle_timer <= 8'd0;    // 返回待机倒计时清零
            level3_used <= 1'b0;          // 飓风模式未使用
            countdown_active <= 1'b0;     // 倒计时未激活
            is_on_prev <= 1'b0;           // 初始化 is_on_prev
            in_switch_mode <= 1'b0;       // 初始化为非 SWITCH_MODE 状态
        end else begin
            is_on_prev <= is_on;          // 更新 is_on_prev 以检测下一次的边沿变化
            if (is_on_rising) begin
                // 检测到 is_on 上升边，初始化模块
                current_mode <= IDLE;
                level3_timer <= 8'd60;
                return_idle_timer <= 8'd60;
                level3_used <= 1'b0;
                countdown_active <= 1'b0;
                in_switch_mode <= 1'b0;
            end else begin
                current_mode <= next_mode; // 正常更新到下一状态
                in_switch_mode <= (next_mode == SWITCH_MODE); // 判断是否进入 SWITCH_MODE 状态
            end
        end
    end

    // 状态切换逻辑
    always @(*) begin
        if (!is_on) begin
            // 如果关机，强制进入待机模式
            next_mode = IDLE;
        end else begin
            // 正常的状态切换逻辑
            case (current_mode)
                IDLE: begin
                    if (menu_key)
                        next_mode = SWITCH_MODE; // 按菜单键进入模式切换模式
                    else
                        next_mode = IDLE; // 保持在待机
                end
                SWITCH_MODE: begin
                    if (level1_key)
                        next_mode = LEVEL1; // 进入一级档位
                    else if (level2_key)
                        next_mode = LEVEL2; // 进入二级档位
                    else if (level3_key)
                        next_mode = LEVEL3; // 进入三级档位（飓风模式）
                    else
                        next_mode = SWITCH_MODE; // 保持模式切换状态
                end
                LEVEL1: begin
                    if (menu_key)
                        next_mode = IDLE; // 切换到待机
                    else if (level2_key)
                        next_mode = LEVEL2; // 切换到二档
                        
                        

                    else
                        next_mode = LEVEL1; // 保持一级档位
                end
                LEVEL2: begin
                    if (menu_key)
                        next_mode = IDLE; // 切换到待机
                    else if (level1_key)
                        next_mode = LEVEL1; // 切换到一级档位
                    else
                        next_mode = LEVEL2; // 保持二级档位
                end
                LEVEL3: begin
                    if (level3_timer == 0)
                        next_mode = LEVEL2; // 倒计时结束后切换到二档
                    else if (menu_key)
                        next_mode = RETURN_IDLE; // 强制返回待机模式倒计时
                    else
                        next_mode = LEVEL3; // 保持飓风模式
                end
                RETURN_IDLE: begin
                    if (return_idle_timer == 0)
                        next_mode = IDLE; // 倒计时结束后进入待机模式
                    else
                        next_mode = RETURN_IDLE; // 保持倒计时状态
                end
                default: next_mode = IDLE; // 默认回到待机
            endcase
        end
    end


    // 逻辑实现
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            countdown <= 8'd0;        // 倒计时清零
            busy <= 1'b0;             // 空闲状态
            mode <= IDLE[1:0];        // 初始化模式
            countdown_active <= 1'b0; // 倒计时未激活
        end else begin
            mode <= current_mode[1:0]; // 将当前模式的低两位赋值给 mode
            case (current_mode)
                IDLE: begin
                    busy <= 1'b0;      // 待机状态下不工作
                    countdown <= 8'd0; // 无倒计时
                    countdown_active <= 1'b0; // 倒计时未激活
                end

                LEVEL1: begin
                    busy <= 1'b1;      // 一级档位工作状态
                    countdown_active <= 1'b0; // 倒计时未激活
                end

                LEVEL2: begin
                    busy <= 1'b1;      // 二级档位工作状态
                    countdown_active <= 1'b0; // 倒计时未激活
                end

                LEVEL3: begin
                    busy <= 1'b1; // 飓风模式工作状态
                    if (level3_timer > 0)
                        level3_timer <= level3_timer - 1; // 倒计时递减
                    else
                        level3_used <= 1'b1; // 标记飓风模式已用
                    countdown <= level3_timer; // 更新倒计时输出
                    countdown_active <= 1'b1; // 倒计时激活
                end

                RETURN_IDLE: begin
                    busy <= 1'b1; // 倒计时期间不工作
                    if (return_idle_timer > 0)
                        return_idle_timer <= return_idle_timer - 1; // 倒计时递减
                    countdown <= return_idle_timer; // 更新倒计时输出
                    countdown_active <= 1'b1; // 倒计时激活
                end
            endcase
        end
    end
    
endmodule
