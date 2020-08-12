/**
    8bx8b流水线乘法器
    输入：8位被乘数，8位乘数，时钟，复位
    输出：16位结果
    时序：6T出结果，输入端寄存启用
    @Author: Johnson Liu (JourneyBean)
    @Date: 2020/5/10
*/

module Multiplier_Flow_8x8b
(
	input	wire	[7:0]	A, B,
	output	wire	[15:0]	P,
	input	wire			CP, CLR_
);

	// 线网 乘数寄存器输出
	// 7x8b，2组
	reg		[7:0]	A_reg [6:0];
	reg		[7:0]	B_reg [6:0];
	
	// 线网 部分积输出
	// 8b，8组
	wire	[7:0]	PP [7:0];
	
	// 线网 加法器结果输出
	// 9b，6组
	wire	[8:0]	PPSum [6:1];
	
	// 线网 级间寄存器输出
	// 16b，6组
	wire	[15:0]	PPSum_reg [6:1];
	
	// 乘数寄存器
	// 移位，4b/Tick，共12b，两片
	// 乘数A寄存器
	always @ ( posedge CP or negedge CLR_ )
		if ( ~CLR_ )
		begin
			A_reg[0] <= 8'b0;
			A_reg[1] <= 8'b0;
			A_reg[2] <= 8'b0;
			A_reg[3] <= 8'b0;
			A_reg[4] <= 8'b0;
			A_reg[5] <= 8'b0;
			A_reg[6] <= 8'b0;
		end
		else
		begin
			A_reg[0] <= A;
			A_reg[1] <= A_reg[0];
			A_reg[2] <= A_reg[1];
			A_reg[3] <= A_reg[2];
			A_reg[4] <= A_reg[3];
			A_reg[5] <= A_reg[4];
			A_reg[6] <= A_reg[5];
		end
	// 乘数B寄存器
	always @ ( posedge CP or negedge CLR_ )
		if ( ~CLR_ )
		begin
			B_reg[0] <= 8'b0;
			B_reg[1] <= 8'b0;
			B_reg[2] <= 8'b0;
			B_reg[3] <= 8'b0;
			B_reg[4] <= 8'b0;
			B_reg[5] <= 8'b0;
			B_reg[6] <= 8'b0;
		end
		else
		begin
			B_reg[0] <= B;
			B_reg[1] <= B_reg[0];
			B_reg[2] <= B_reg[1];
			B_reg[3] <= B_reg[2];
			B_reg[4] <= B_reg[3];
			B_reg[5] <= B_reg[4];
			B_reg[6] <= B_reg[5];
		end
	
	// 部分积生成
	assign PP[0] = A_reg[0] & {8{B_reg[0][0]}};
	assign PP[1] = A_reg[0] & {8{B_reg[0][1]}};
	assign PP[2] = A_reg[1] & {8{B_reg[1][2]}};
	assign PP[3] = A_reg[2] & {8{B_reg[2][3]}};
	assign PP[4] = A_reg[3] & {8{B_reg[3][4]}};
	assign PP[5] = A_reg[4] & {8{B_reg[4][5]}};
	assign PP[6] = A_reg[5] & {8{B_reg[5][6]}};
	assign PP[7] = A_reg[6] & {8{B_reg[6][7]}};
	
	// 半加器
	// 移位相加，输出保存在寄存器
	// 第1级：{1'b0, PP0[7:1]} + PP[1] = PPSum[1]
	HalfAdder #(8) HA_1 ( .A({1'b0,PP[0][7:1]}), .B(PP[1]), .S(PPSum[1][7:0]), .CO(PPSum[1][8]) );
	Register #(10) REG_1 ( .DI({PPSum[1], PP[0][0]}), .Q(PPSum_reg[1][9:0]), 
							.CP(CP), .CLR_(CLR_) );
	
	// 第2级
	// 半加器 {PPSum[2], PPSum_reg[2]} + PP[2] = PPSum[2]
	HalfAdder #(8) HA_2 ( .A(PPSum_reg[1][9:2]), .B(PP[2]), .S(PPSum[2][7:0]), .CO(PPSum[2][8]) );
	Register #(11) REG_2 ( .DI({PPSum[2], PPSum_reg[1][1:0]}), .Q(PPSum_reg[2][10:0]), 
							.CP(CP), .CLR_(CLR_) );
	
	// 第3级
	// 半加器 {PPSum[3], PPSum_reg[3]} + PP[3] = PPSum[3]
	HalfAdder #(8) HA_3 ( .A(PPSum_reg[2][10:3]), .B(PP[3]), .S(PPSum[3][7:0]), .CO(PPSum[3][8]) );
	Register #(12) REG_3 ( .DI({PPSum[3], PPSum_reg[2][2:0]}), .Q(PPSum_reg[3][11:0]), 
							.CP(CP), .CLR_(CLR_) );
	
	// 第4级
	HalfAdder #(8) HA_4 ( .A(PPSum_reg[3][11:4]), .B(PP[4]), .S(PPSum[4][7:0]), .CO(PPSum[4][8]) );
	Register #(13) REG_4 ( .DI({PPSum[4], PPSum_reg[3][3:0]}), .Q(PPSum_reg[4][12:0]), 
							.CP(CP), .CLR_(CLR_) );
	
	// 第5级
	HalfAdder #(8) HA_5 ( .A(PPSum_reg[4][12:5]), .B(PP[5]), .S(PPSum[5][7:0]), .CO(PPSum[5][8]) );
	Register #(14) REG_5 ( .DI({PPSum[5], PPSum_reg[4][4:0]}), .Q(PPSum_reg[5][13:0]), 
							.CP(CP), .CLR_(CLR_) );
	
	// 第6级
	HalfAdder #(8) HA_6 ( .A(PPSum_reg[5][13:6]), .B(PP[6]), .S(PPSum[6][7:0]), .CO(PPSum[6][8]) );
	Register #(15) REG_6 ( .DI({PPSum[6], PPSum_reg[5][5:0]}), .Q(PPSum_reg[6][14:0]), 
							.CP(CP), .CLR_(CLR_) );
	
	// 第7级
	HalfAdder #(8) HA_7 ( .A(PPSum_reg[6][14:7]), .B(PP[7]), .S(P[14:7]), .CO(P[15]) );
	assign P[6:0] = PPSum_reg[6][6:0];
	
endmodule