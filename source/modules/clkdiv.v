/** 
    分频模块
    输入：时钟输入，复位
    输出：时钟输出
    @Author: Johnson Liu (JourneyBean)
    @Date: 2020/8/9
*/

module clkdiv 
# ( parameter in_freq = 50000000,
              out_freq = 1,
              width = 32,
              N = in_freq/out_freq
)
(
    input   wire    clk_in,
    output  reg     clk_out,
    input   wire    rst_
);

reg     [width-1:0] cnt;

initial begin
    cnt     <= 0;
    clk_out <= 1'b0;
end

always @ (posedge clk_in or negedge rst_) begin
    if ( ~rst_ ) begin
        cnt     <= 0;
        clk_out <= 1'b0;
    end
    else if ( cnt == N/2 ) begin
        cnt     <= cnt+1;
        clk_out <= ~clk_out;
    end
    else if ( cnt == N-1 ) begin
        cnt     <= 0;
        clk_out <= ~clk_out;
    end
    else if ( cnt > N-1 ) begin
        cnt     <= 0;
    end
    else begin
        cnt     <= cnt+1;
        clk_out <= clk_out;
    end
end

endmodule