
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
    output reg level_mode_active
);

    // 状态定义（统一为 3 位宽）
parameter IDLE        = 3'b000; // 待机模式
parameter LEVEL1      = 3'b001; // 一级档位
parameter LEVEL2      = 3'b010; // 二级档位
parameter LEVEL3      = 3'b011; // 三级档位（飓风模式）
parameter RETURN_IDLE = 3'b100; // 强制返回待机模式倒计时状态
parameter LEVEL_MODE  = 3'b101; // 挡位切换模式

reg [2:0] current_mode, next_mode; // 当前模式和下一模式（3 位宽）
reg [7:0] level3_timer;            // 飓风模式倒计时计数器
reg [7:0] return_idle_timer;       // 返回待机模式倒计时计数器
reg level3_used;                   // 飓风模式是否已使用标志位

wire clock;
clk_one_second cos(
    .clk(clk),
    .reset(~rst),
    .clock(clock) // 一秒一个上升沿
);

reg menu_key_prev;
wire menu_key_rising;
always @(posedge clk or posedge rst) begin
    if (rst)
        menu_key_prev <= 1'b0;
    else
        menu_key_prev <= menu_key;
end
assign menu_key_rising = menu_key && !menu_key_prev;

reg is_on_prev;
wire is_on_rising;
always @(posedge clk or posedge rst) begin
    if (rst)
        is_on_prev <= 1'b0;
    else
        is_on_prev <= is_on;
end
assign is_on_rising = is_on && !is_on_prev;

reg init_state;  // 添加初始化状态标志
// 添加一个电源开启初始化标志
reg power_on_init;
// 在1s时钟域(clock)中处理初始化
reg power_on_init_done;
// 状态机逻辑
always @(posedge clk or posedge rst) begin
    if (rst) begin
        power_on_init <= 1'b0;
        init_state <= 1'b0;
        current_mode <= IDLE;          // 复位时回到待机模式
        level3_used <= 1'b0;          // 飓风模式未使用
        countdown_active <= 1'b0;     // 倒计时未激活
    end
    else if (is_on_rising) begin
        init_state <= 1'b1;
    end 
    else if (init_state) begin
            init_state <= 1'b0;
            current_mode <= IDLE;
            level3_used <= 1'b0;
            countdown_active <= 1'b0;
            power_on_init <= 1'b1;
   end 
   else if (power_on_init_done)  // 需要添加一个完成信号
           power_on_init <= 1'b0;
   else begin
           current_mode <= next_mode; // 正常更新到下一状态
   end
end

reg start_return_timer;
//reg start_return_timer2;
// 状态切换逻辑
always @(*) begin
    if (!is_on) begin
        next_mode = IDLE; // 关机时强制进入待机模式
        start_return_timer=1'b0;
    end else begin
        case (current_mode)
            IDLE: begin
                if (menu_key_rising)
                    next_mode = LEVEL_MODE; // 进入档位切换模式
                else
                    next_mode = IDLE;
            end

            LEVEL_MODE: begin
                // 按键控制切换档位
                if (level1_key)
                    next_mode = LEVEL1;
                else if (level2_key)
                    next_mode = LEVEL2;
                else if (level3_key && ~level3_used)
                    next_mode = LEVEL3;
                else
                    next_mode = LEVEL_MODE;
            end

            LEVEL1: begin
                // 1档模式切换逻辑
                if (menu_key_rising)
                    next_mode = IDLE; // 切换到待机模式
                else if (level2_key)
                    next_mode = LEVEL2; // 切换到2档
                else
                    next_mode = LEVEL1;
            end

            LEVEL2: begin
                // 2档模式切换逻辑
                if (menu_key_rising)
                    next_mode = IDLE; // 切换到待机模式
                else if (level1_key)
                    next_mode = LEVEL1; // 切换到1档
                else
                    next_mode = LEVEL2;
            end

            LEVEL3: begin
                // 3档模式（飓风模式）切换逻辑
                if (menu_key_rising) begin
                   // next_mode = RETURN_IDLE; // 强制返回待机模式倒计时
                    start_return_timer=1'b1;
                end
                else if(start_return_timer&&level3_timer == 8'b0) begin
                     next_mode = IDLE; // 倒计时结束切换到2档
                     level3_used = 1'b1;
                 end
                 else if (~start_return_timer&&level3_timer == 8'b0) begin
                                     next_mode = LEVEL2; // 倒计时结束切换到2档
                                     level3_used = 1'b1;
                                 end
                else
                    next_mode = LEVEL3;
            end

/*            RETURN_IDLE: begin
                // 返回待机模式倒计时
                if (start_return_timer2&&return_idle_timer == 8'b0) begin
                    next_mode = IDLE; // 倒计时结束后进入待机模式
                    level3_used = 1'b1;
                    start_return_timer1=1'b0;
                end
                else
                    next_mode = RETURN_IDLE;
            end*/

            default: next_mode = IDLE; // 默认回到待机
        endcase
    end
end

// 逻辑实现
always @(posedge clk or posedge rst) begin
    if (rst) begin
        countdown <= 8'd0;
        busy <= 1'b0;
        mode <= 2'b00;
        countdown_active <= 1'b0;
        level_mode_active <= 1'b0;
    end else begin
        case (current_mode)
            IDLE: begin
                busy <= 1'b0;
                countdown <= 8'd0;
                countdown_active <= 1'b0;
                mode <= 2'b00;
                level_mode_active <= 1'b0;
            end

            LEVEL_MODE: begin
                busy <= 1'b0;
                countdown <= 8'd0;
                countdown_active <= 1'b0;
                mode <= 2'b00;
                level_mode_active <= 1'b1;
            end

            LEVEL1: begin
                busy <= 1'b1;
                countdown_active <= 1'b0;
                mode <= 2'b01;
                level_mode_active <= 1'b0;
            end

            LEVEL2: begin
                busy <= 1'b1;
                countdown_active <= 1'b0;
                mode <= 2'b10;
                level_mode_active <= 1'b0;
            end

            LEVEL3: begin
                busy <= 1'b1;
                mode <= 2'b11;
                level_mode_active <= 1'b0;
                countdown_active <= 1'b1;
                countdown <= level3_timer;
            end

/*            RETURN_IDLE: begin
                busy <= 1'b1;
                mode <= 2'b11;
                level_mode_active <= 1'b0;
                countdown_active <= 1'b1;
                countdown <= return_idle_timer;
            end*/
        endcase
    end
end

reg hello;
//  计时器
always @(posedge clock or posedge rst) begin
    if (rst) begin
        level3_timer <= 8'd10;
        power_on_init_done <= 1'b0;
        hello<=1'b1;
    end 
    else if (power_on_init) begin
        level3_timer <= 8'd10;
        power_on_init_done <= 1'b1;
    end
    else if(start_return_timer&&hello) begin
         level3_timer <= 8'd10;
         hello<=1'b0;
     end
    else begin
        power_on_init_done <= 1'b0;
        if (current_mode == LEVEL3 && level3_timer > 0)
            level3_timer <= level3_timer - 1;
    end
end

/*always @(posedge clock or posedge rst) begin
    if (rst) begin
        return_idle_timer <= 8'd0;
        start_return_timer2<=1'b0;
    end 
    else if (power_on_init) begin
        return_idle_timer <= 8'd0;
    end
    else if(start_return_timer1&&return_idle_timer==8'b0) begin
        return_idle_timer <= 8'd10;
        start_return_timer2<=1'b1;
        //start_return_timer1<=1'b0;
    end
    else if (current_mode == RETURN_IDLE && return_idle_timer > 0)
        return_idle_timer <= return_idle_timer - 1;
end*/
endmodule
