/**
    SCNU FPGA课程设计 顶层设计文件
    @Author: Johnson Liu (JourneyBean)
    @Date: 2020/8/10
*/

module cd_top
(
    input   wire    clk_50mhz ,
    output  wire    [7:0]   seg_data ,
    output  wire    [5:0]   seg_cs ,
    input   wire    [7:0]   key ,
    output  reg     [7:0]   led
);


/* -------- 分频模块 -------- */
/*  数码管动态扫描频率：300Hz
    流水线乘法器工作频率：300Hz
    按键消抖频率：100Hz
    其他按键扫描频率：100Hz
*/

wire    clk_300hz, clk_100hz, clk_2hz, clk_32khz, clk_128hz;

defparam div_50m_300.in_freq = 50000000;
defparam div_50m_300.out_freq = 517;
clkdiv div_50m_300 (clk_50mhz, clk_300hz, rst_);

defparam div_50m_100.in_freq = 50000000;
defparam div_50m_100.out_freq = 142;
clkdiv div_50m_100 (clk_50mhz, clk_100hz, rst_);

defparam div_50m_2.in_freq = 50000000;
defparam div_50m_2.out_freq = 2;
clkdiv div_50m_2   (clk_50mhz, clk_2hz,   rst_);

defparam div_50m_32k.in_freq = 50000000;
defparam div_50m_32k.out_freq = 32000;
clkdiv div_50m_32k (clk_50mhz, clk_32khz, rst_);

defparam div_50m_128.in_freq = 50000000;
defparam div_50m_128.out_freq = 128;
clkdiv div_50m_128 (clk_50mhz, clk_128hz, rst_);


/* -------- 数码管模块 -------- */

reg     [29:0]  seg_bcd_data;

seg_display segdpy (seg_bcd_data, seg_data, seg_cs, clk_300hz, rst_);

/* -------- LED显示模式模块 --------*/

reg     [1:0]   led_mode;
reg     [1:0]   led_mode_last;
reg     [9:0]   breath_counter_gate_next[8];


/* -------- 按键消抖模块 -------- */

wire    key_rst, key_2, key_incx, key_incy, key_ans, key_autoinc, key_bcd, key_ledmode;

key_handler k_rst     (key[0], key_rst,     clk_100hz, rst_);
key_handler k_2       (key[1], key_2,       clk_100hz, rst_);
key_handler k_incx    (key[2], key_incx,    clk_100hz, rst_);
key_handler k_incy    (key[3], key_incy,    clk_100hz, rst_);
key_handler k_ans     (key[4], key_ans,     clk_100hz, rst_);
key_handler k_autoinc (key[5], key_autoinc, clk_100hz, rst_);
key_handler k_bcd     (key[6], key_bcd,     clk_100hz, rst_);
key_handler k_ledmode (key[7], key_ledmode, clk_100hz, rst_);


/* -------- 重置模块 -------- */

wire    rst_;

assign rst_ = ~key_rst;

/* -------- 乘法器模块 -------- */

reg     [7:0]   px, py;
wire    [15:0]  ans;

Multiplier_Flow_8x8b u_mul (px, py, ans, clk_300hz, rst_);


/* -------- 主状态机 --------  */
/*  状态1 复位状态
    状态2 流水灯状态
    状态3 乘法状态
*/

reg     [1:0]   sta_current, sta_next;
parameter   S2 = 2'b01, S3 = 2'b11, S4 = 2'b10;

// 状态跳转部分
always @ (posedge clk_100hz or negedge rst_) begin
    // 重置，状态1
    if (~rst_) begin
        sta_current <= S2;
    end
    // 否则根据状态切换部分跳转状态
    else begin
        sta_current <= sta_next;
    end
end

// 状态切换部分和按键事件
reg     key_2_last, key_incx_last, key_incy_last, key_ans_last, key_autoinc_last, key_bcd_last, key_ledmode_last;
reg     [6:0]   autoinc_hold_time;
reg             bcd_mode;

always @ (posedge clk_100hz or negedge rst_) begin

    if (~rst_) begin
        key_2_last <= 1'b0;
        key_incx_last <= 1'b0;
        key_incy_last <= 1'b0;
        key_ans_last <= 1'b0;
        key_autoinc_last <= 1'b0;
        key_bcd_last <= 1'b0;
        key_ledmode_last <= 1'b0;

        autoinc_hold_time <= 4'b0;
        bcd_mode <= 1'b0;
        led_mode <= 2'b00;

        px <= 8'b0;
        py <= 8'b0;

        sta_next = S2;
    end
    else begin

        // 切换模式按键
        if (key_2) begin
            key_2_last <= 1'b1;
            // 上升沿
            if (~key_2_last) begin
                sta_next = (sta_current==S2)?S3:S2;
            end
        end
        else begin
            key_2_last <= 1'b0;
        end

        // 增x按键
        if (key_incx) begin
            key_incx_last <= 1'b1;
            if (~key_incx_last && sta_current==S3) begin
                px = px+1;
            end
        end
        else begin
            key_incx_last <= 1'b0;
        end

        // 增y按键
        if (key_incy) begin
            key_incy_last <= 1'b1;
            if (~key_incy_last && sta_current==S3) begin
                py = py+1;
            end
        end
        else begin
            key_incy_last <= 1'b0;
        end

        // 求解按键
        if (key_ans) begin
            key_ans_last <= 1'b1;
            if (~key_ans_last && sta_current==S3) begin
                sta_next = S4;
            end
            else if (~key_ans_last && sta_current==S4) begin
                sta_next = S3;
            end
        end
        else begin
            key_ans_last <= 1'b0;
        end

        // 自增按键
        if (key_autoinc) begin
            key_autoinc_last <= 1'b1;
            // 保持按下
            if (key_autoinc_last && sta_current==S3) begin
                if (autoinc_hold_time > 100) begin
                    autoinc_hold_time <= 0;
                    sta_next = S4;
                end
                else begin
                    autoinc_hold_time <= autoinc_hold_time+1;
                end
            end
            else if (key_autoinc_last && sta_current==S4) begin
                if (autoinc_hold_time > 100) begin
                    autoinc_hold_time <= 0;
                    px = px+1;
                    py = py+1;
                    sta_next = S3;
                end
                else begin
                    autoinc_hold_time <= autoinc_hold_time+1;
                end
            end
        end
        else begin
            key_autoinc_last <= 1'b0;
        end

        // BCD模式切换按键
        if (key_bcd) begin
            key_bcd_last <= 1'b1;
            if (~key_bcd_last && (sta_current==S3 || sta_current==S4)) begin
                bcd_mode <= ~bcd_mode;
            end
        end
        else begin
            key_bcd_last <= 1'b0;
        end

        // LED模式切换按键
        if (key_ledmode) begin
            key_ledmode_last <= 1'b1;
            if (~key_ledmode_last && sta_current==S2) begin
                if (led_mode == 2'b00) begin
                    breath_counter_gate_next[0] = 10'd0;
                    breath_counter_gate_next[1] = 10'd0;
                    breath_counter_gate_next[2] = 10'd0;
                    breath_counter_gate_next[3] = 10'd0;
                    breath_counter_gate_next[4] = 10'd0;
                    breath_counter_gate_next[5] = 10'd0;
                    breath_counter_gate_next[6] = 10'd0;
                    breath_counter_gate_next[7] = 10'd0;
                    led_mode <= 2'b01;
                end
                else if (led_mode == 2'b01) begin
                    breath_counter_gate_next[0] = 10'd0;
                    breath_counter_gate_next[1] = 10'd0;
                    breath_counter_gate_next[2] = 10'd0;
                    breath_counter_gate_next[3] = 10'd24;
                    breath_counter_gate_next[4] = 10'd32;
                    breath_counter_gate_next[5] = 10'd40;
                    breath_counter_gate_next[6] = 10'd48;
                    breath_counter_gate_next[7] = 10'd56;
                    led_mode <= 2'b11;
                end
                else if (led_mode == 2'b11) begin
                    breath_counter_gate_next[0] = 10'd0;
                    breath_counter_gate_next[1] = 10'd32;
                    breath_counter_gate_next[2] = 10'd0;
                    breath_counter_gate_next[3] = 10'd32;
                    breath_counter_gate_next[4] = 10'd0;
                    breath_counter_gate_next[5] = 10'd32;
                    breath_counter_gate_next[6] = 10'd0;
                    breath_counter_gate_next[7] = 10'd32;
                    led_mode <= 2'b10;
                end
                else if (led_mode == 2'b10) begin
                    breath_counter_gate_next[0] = 10'd0;
                    breath_counter_gate_next[1] = 10'd8;
                    breath_counter_gate_next[2] = 10'd16;
                    breath_counter_gate_next[3] = 10'd24;
                    breath_counter_gate_next[4] = 10'd32;
                    breath_counter_gate_next[5] = 10'd40;
                    breath_counter_gate_next[6] = 10'd48;
                    breath_counter_gate_next[7] = 10'd56;
                    led_mode <= 2'b00;
                end
            end
        end
        else begin
            key_ledmode_last <= 1'b0;
        end

    end
end

reg     [11:0]  px_bcd, py_bcd;
reg     [19:0]  ans_bcd;
reg     [11:0]   px_bcd_temp, py_bcd_temp;
reg     [19:0]  ans_bcd_temp;

// BCD 生成模块
always @ (*) begin
    px_bcd[3:0] = px%10;
    px_bcd_temp = px/10;
    px_bcd[7:4] = px_bcd_temp%10;
    px_bcd[11:8] = px_bcd_temp/10;

    py_bcd[3:0] = py%10;
    py_bcd_temp = py/10;
    py_bcd[7:4] = py_bcd_temp%10;
    py_bcd[11:8] = py_bcd_temp/10;

    ans_bcd[3:0] = ans%10;
    ans_bcd_temp = ans/10;
    ans_bcd[7:4] = ans_bcd_temp%10;
    ans_bcd_temp = ans_bcd_temp/10;
    ans_bcd[11:8] = ans_bcd_temp%10;
    ans_bcd_temp = ans_bcd_temp/10;
    ans_bcd[15:12] = ans_bcd_temp%10;
    ans_bcd[19:16] = ans_bcd_temp/10;
end

// 数码管输出逻辑
always @ (*) begin
    if (sta_current == S2) seg_bcd_data = {5'h3, 5'h3, 5'h4, 5'h0, 5'h1, 5'h8};
    else if (sta_current == S3 && bcd_mode==1'b0) seg_bcd_data = {5'h10, 1'h0, px[7:4], 1'h0, px[3:0], 5'h10, 1'h0, py[7:4], 1'h0, py[3:0]};
    else if (sta_current == S4 && bcd_mode==1'b0) seg_bcd_data = {5'h10, 5'h10, 1'h0, ans[15:12], 1'h0, ans[11:8], 1'h0, ans[7:4], 1'h0, ans[3:0]};
    else if (sta_current == S3 && bcd_mode==1'b1) begin
        seg_bcd_data = {1'h0, px_bcd[11:8], 1'h0, px_bcd[7:4], 1'h0, px_bcd[3:0], 1'h0, py_bcd[11:8], 1'h0, py_bcd[7:4], 1'h0, py_bcd[3:0]};
    end
    else if (sta_current == S4 && bcd_mode==1'b1) begin
        seg_bcd_data = {5'h10, 1'h0, ans_bcd[19:16], 1'h0, ans_bcd[15:12], 1'h0, ans_bcd[11:8], 1'h0, ans_bcd[7:4], 1'h0, ans_bcd[3:0]};
    end 
end


// LED逻辑
reg     [7:0]   led_flow;
reg     [7:0]   led_breath;

// LED 输出选择
always @ (*) begin
    if (sta_current == S2) begin
        if (led_mode == 2'b0) begin
            led = led_flow;
        end
        else begin
            led = led_breath;
        end
    end
    else begin
        led = 8'b1111_1111;
    end
end

// 流水灯输出逻辑
reg     [2:0]   sta_led;
always @ (posedge clk_2hz or negedge rst_) begin
    if (~rst_) begin
        sta_led <= 3'b000;
    end
    else if (sta_current == S2) begin
        case (sta_led)
            3'h0: begin
                led_flow <= 8'b0111_1111;
                sta_led <= 3'h1;
            end
            3'h1: begin
                led_flow <= 8'b1011_1111;
                sta_led <= 3'h2;
            end
            3'h2: begin
                led_flow <= 8'b1101_1111;
                sta_led <= 3'h3;
            end
            3'h3: begin
                led_flow <= 8'b1110_1111;
                sta_led <= 3'h4;
            end
            3'h4: begin
                led_flow <= 8'b1111_0111;
                sta_led <= 3'h5;
            end
            3'h5: begin
                led_flow <= 8'b1111_1011;
                sta_led <= 3'h6;
            end
            3'h6: begin
                led_flow <= 8'b1111_1101;
                sta_led <= 3'h7;
            end
            3'h7: begin
                led_flow <= 8'b1111_1110;
                sta_led <= 3'h0;
            end
        endcase
    end
    else if (sta_current == S3) begin
        led_flow <= 8'b1111_1111;
    end
end


// 呼吸灯模块
reg     [9:0]   breath_counter_max;
reg     [9:0]   breath_counter_current;
reg     [9:0]   breath_counter_gate[8];

// current counter controller
always @ (posedge clk_32khz or negedge rst_) begin
    if (~rst_) begin
        breath_counter_max <= 10'd64;
        breath_counter_current <= 10'd0;
    end
    else if (clk_300hz) begin
        if (breath_counter_current == breath_counter_max) begin
            breath_counter_current <= 10'd0;
        end
        else begin
            breath_counter_current <= breath_counter_current+1;
        end
    end
end

// gate counter controller
reg     [7:0]   breath_gate_control;        // 0 increase 1 decrease
always @ (posedge clk_128hz or negedge rst_) begin
    if (~rst_) begin
        breath_gate_control <= 8'b0000_0000;

        breath_counter_gate[0] <= 10'd0;
        breath_counter_gate[1] <= 10'd8;
        breath_counter_gate[2] <= 10'd16;
        breath_counter_gate[3] <= 10'd24;
        breath_counter_gate[4] <= 10'd32;
        breath_counter_gate[5] <= 10'd40;
        breath_counter_gate[6] <= 10'd48;
        breath_counter_gate[7] <= 10'd56;

        led_mode_last <= 2'b00;
    end
    else begin

        // update breath mode
        led_mode_last <= led_mode;

        if (led_mode_last != led_mode) begin
            breath_counter_gate[0] <= breath_counter_gate_next[0];
            breath_counter_gate[1] <= breath_counter_gate_next[1];
            breath_counter_gate[2] <= breath_counter_gate_next[2];
            breath_counter_gate[3] <= breath_counter_gate_next[3];
            breath_counter_gate[4] <= breath_counter_gate_next[4];
            breath_counter_gate[5] <= breath_counter_gate_next[5];
            breath_counter_gate[6] <= breath_counter_gate_next[6];
            breath_counter_gate[7] <= breath_counter_gate_next[7];
        end
        else begin
        
            // channel 0
            if (~breath_gate_control[0]) begin       // increase
                if (breath_counter_gate[0] == breath_counter_max) begin     // increase end
                    breath_gate_control[0] <= 1'b1;     // to decrease
                end
                else begin                                                  // increase not full
                    breath_counter_gate[0] <= breath_counter_gate[0] + 1;
                end
            end
            else begin                              // decrease
                if (breath_counter_gate[0] == 0) begin                      // decrease end
                    breath_gate_control[0] <= 1'b0;     // to increase
                end
                else begin
                    breath_counter_gate[0] <= breath_counter_gate[0] - 1;
                end
            end

            // channel 1
            if (~breath_gate_control[1]) begin       // increase
                if (breath_counter_gate[1] == breath_counter_max) begin     // increase end
                    breath_gate_control[1] <= 1'b1;     // to decrease
                end
                else begin                                                  // increase not full
                    breath_counter_gate[1] <= breath_counter_gate[1] + 1;
                end
            end
            else begin                              // decrease
                if (breath_counter_gate[1] == 0) begin                      // decrease end
                    breath_gate_control[1] <= 1'b0;     // to increase
                end
                else begin
                    breath_counter_gate[1] <= breath_counter_gate[1] - 1;
                end
            end

            // channel 2
            if (~breath_gate_control[2]) begin       // increase
                if (breath_counter_gate[2] == breath_counter_max) begin     // increase end
                    breath_gate_control[2] <= 1'b1;     // to decrease
                end
                else begin                                                  // increase not full
                    breath_counter_gate[2] <= breath_counter_gate[2] + 1;
                end
            end
            else begin                              // decrease
                if (breath_counter_gate[2] == 0) begin                      // decrease end
                    breath_gate_control[2] <= 1'b0;     // to increase
                end
                else begin
                    breath_counter_gate[2] <= breath_counter_gate[2] - 1;
                end
            end

            // channel 3
            if (~breath_gate_control[3]) begin       // increase
                if (breath_counter_gate[3] == breath_counter_max) begin     // increase end
                    breath_gate_control[3] <= 1'b1;     // to decrease
                end
                else begin                                                  // increase not full
                    breath_counter_gate[3] <= breath_counter_gate[3] + 1;
                end
            end
            else begin                              // decrease
                if (breath_counter_gate[3] == 0) begin                      // decrease end
                    breath_gate_control[3] <= 1'b0;     // to increase
                end
                else begin
                    breath_counter_gate[3] <= breath_counter_gate[3] - 1;
                end
            end

            // channel 4
            if (~breath_gate_control[4]) begin       // increase
                if (breath_counter_gate[4] == breath_counter_max) begin     // increase end
                    breath_gate_control[4] <= 1'b1;     // to decrease
                end
                else begin                                                  // increase not full
                    breath_counter_gate[4] <= breath_counter_gate[4] + 1;
                end
            end
            else begin                              // decrease
                if (breath_counter_gate[4] == 0) begin                      // decrease end
                    breath_gate_control[4] <= 1'b0;     // to increase
                end
                else begin
                    breath_counter_gate[4] <= breath_counter_gate[4] - 1;
                end
            end

            // channel 5
            if (~breath_gate_control[5]) begin       // increase
                if (breath_counter_gate[5] == breath_counter_max) begin     // increase end
                    breath_gate_control[5] <= 1'b1;     // to decrease
                end
                else begin                                                  // increase not full
                    breath_counter_gate[5] <= breath_counter_gate[5] + 1;
                end
            end
            else begin                              // decrease
                if (breath_counter_gate[5] == 0) begin                      // decrease end
                    breath_gate_control[5] <= 1'b0;     // to increase
                end
                else begin
                    breath_counter_gate[5] <= breath_counter_gate[5] - 1;
                end
            end

            // channel 6
            if (~breath_gate_control[6]) begin       // increase
                if (breath_counter_gate[6] == breath_counter_max) begin     // increase end
                    breath_gate_control[6] <= 1'b1;     // to decrease
                end
                else begin                                                  // increase not full
                    breath_counter_gate[6] <= breath_counter_gate[6] + 1;
                end
            end
            else begin                              // decrease
                if (breath_counter_gate[6] == 0) begin                      // decrease end
                    breath_gate_control[6] <= 1'b0;     // to increase
                end
                else begin
                    breath_counter_gate[6] <= breath_counter_gate[6] - 1;
                end
            end

            // channel 7
            if (~breath_gate_control[7]) begin       // increase
                if (breath_counter_gate[7] == breath_counter_max) begin     // increase end
                    breath_gate_control[7] <= 1'b1;     // to decrease
                end
                else begin                                                  // increase not full
                    breath_counter_gate[7] <= breath_counter_gate[7] + 1;
                end
            end
            else begin                              // decrease
                if (breath_counter_gate[7] == 0) begin                      // decrease end
                    breath_gate_control[7] <= 1'b0;     // to increase
                end
                else begin
                    breath_counter_gate[7] <= breath_counter_gate[7] - 1;
                end
            end

        end

    end
end


// breath output controller
always @ (*) begin
    led_breath[0] <= (breath_counter_gate[0] > breath_counter_current) ? 1'b1 : 1'b0;
    led_breath[1] <= (breath_counter_gate[1] > breath_counter_current) ? 1'b1 : 1'b0;
    led_breath[2] <= (breath_counter_gate[2] > breath_counter_current) ? 1'b1 : 1'b0;
    led_breath[3] <= (breath_counter_gate[3] > breath_counter_current) ? 1'b1 : 1'b0;
    led_breath[4] <= (breath_counter_gate[4] > breath_counter_current) ? 1'b1 : 1'b0;
    led_breath[5] <= (breath_counter_gate[5] > breath_counter_current) ? 1'b1 : 1'b0;
    led_breath[6] <= (breath_counter_gate[6] > breath_counter_current) ? 1'b1 : 1'b0;
    led_breath[7] <= (breath_counter_gate[7] > breath_counter_current) ? 1'b1 : 1'b0;
end


endmodule