/**
    按键消抖模块
    输入：按键信号（低电平按下），按键扫描时钟（20/3ms），重置信号
    输出：按键处理信号（高电平按下）
*/

module key_handler
(
    input   wire    key_in,
    output  wire    key_out,
    input   wire    clk, rst_
);

reg     [2:0]   sta;

and uAnd(key_out, sta[2], sta[1], sta[0]);  // 全为1才输出高

always @ (posedge clk or negedge rst_) begin
    // 重置
    if (~rst_) begin
        sta[2:0] <= 3'b000;
    end
    // 扫描按键瞬态状态
    else begin
        sta[2:1] <= sta[1:0];
        sta[0]   <= ~key_in;    //按键信号反相
    end
end

endmodule