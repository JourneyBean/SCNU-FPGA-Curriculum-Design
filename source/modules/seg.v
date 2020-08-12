/** 
    BCD码 转 共阴数码管编码
    输入：4位 BCD码
    输出：8位 数码管编码
    @Author: Johnson Liu (JourneyBean)
    @Date: 2020/8/9
*/
module bcd2seg_ck(
    input   wire    bcd_code,
    output  reg     seg_code
);

always @ (bcd_code) begin
    case (bcd_code)
        4'h1: seg_code <= 8'b0000_0110;
        4'h2: seg_code <= 8'b0101_1011;
        4'h3: seg_code <= 8'b0100_1111;
        4'h4: seg_code <= 8'b0110_0110;
        4'h5: seg_code <= 8'b0110_0101;
        4'h6: seg_code <= 8'b0111_1101;
        4'h7: seg_code <= 8'b0000_0111;
        4'h8: seg_code <= 8'b0111_1111;
        4'h9: seg_code <= 8'b0110_0111;
        4'ha: seg_code <= 8'b0111_0111;
        4'hb: seg_code <= 8'b0111_1100;
        4'hc: seg_code <= 8'b0011_1001;
        4'hd: seg_code <= 8'b0101_1110;
        4'he: seg_code <= 8'b0111_1001;
        4'hf: seg_code <= 8'b0111_0001;
        4'h0: seg_code <= 8'b0011_1111;
    endcase
end

endmodule

/** 
    BCD码 转 共阳数码管编码 （2020/6/1实验板）
    输入：4位 BCD码
    输出：8位 数码管编码
    @Author: Johnson Liu (JourneyBean)
    @Date: 2020/8/9
*/
module bcd2seg_ca(
    input   wire    [3:0]   bcd_code,
    output  reg     [7:0]   seg_code
);

always @ (bcd_code) begin
    case (bcd_code)
        4'h1: seg_code <= 8'b1111_1001;
        4'h2: seg_code <= 8'b1010_0100;
        4'h3: seg_code <= 8'b1011_0000;
        4'h4: seg_code <= 8'b1001_1001;
        4'h5: seg_code <= 8'b1001_0010;
        4'h6: seg_code <= 8'b1000_0010;
        4'h7: seg_code <= 8'b1111_1000;
        4'h8: seg_code <= 8'b1000_0000;
        4'h9: seg_code <= 8'b1001_0000;
        4'ha: seg_code <= 8'b1000_1000;
        4'hb: seg_code <= 8'b1000_0011;
        4'hc: seg_code <= 8'b1100_0110;
        4'hd: seg_code <= 8'b1010_0001;
        4'he: seg_code <= 8'b1000_0110;
        4'hf: seg_code <= 8'b1000_1110; //1000_1110
        4'h0: seg_code <= 8'b1100_0000;
    endcase
end

endmodule

/**
    6位数码管动态刷新驱动模块（使用1个bcd2seg模块）
    输入：6*4位 BCD码，1位 时钟，1位 重置
    输出：8位 数码管数据，N位 数码管段选端
*/
module seg_display
(
    input   wire    [23:0]  bcd_data,
    output  wire    [7:0]   seg_data,
    output  reg     [5:0]   seg_cs,
    input   wire    clk, rst_
);

reg     [3:0]   bcd, cnt;

bcd2seg_ca segdec(bcd, seg_data);

initial begin
    cnt <= 4'b0;
end

always @ (posedge clk or negedge rst_) begin
    if ( ~rst_ ) begin
        cnt <= 4'b0;
        bcd <= 4'hf;
    end
    else
        case (cnt)
            4'h0: begin 
                seg_cs <= 6'b011111; 
                bcd <= bcd_data[3:0];   
                cnt <= cnt+1; end
            4'h1: begin 
                seg_cs <= 6'b101111; 
                bcd <= bcd_data[7:4];   
                cnt <= cnt+1; end
            4'h2: begin 
                seg_cs <= 6'b110111; 
                bcd <= bcd_data[11:8];  
                cnt <= cnt+1; end
            4'h3: begin 
                seg_cs <= 6'b111011; 
                bcd <= bcd_data[15:12]; 
                cnt <= cnt+1; end
            4'h4: begin 
                seg_cs <= 6'b111101; 
                bcd <= bcd_data[19:16]; 
                cnt <= cnt+1; end
            4'h5: begin 
                seg_cs <= 6'b111110; 
                bcd <= bcd_data[23:20]; 
                cnt <= 0;     end
            default: cnt <= 0;
        endcase
end

endmodule