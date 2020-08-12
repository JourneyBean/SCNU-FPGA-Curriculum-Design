/**
	文件说明：各种加法器
	输入：N位加数，N位被加数（，1位进位输入）
	输出：N位和，1位进位输出
	@Author: Johnson Liu (JourneyBean)
	@Date: 2020/5/6
*/

module HalfAdder_1b ( A, B, S, CO );

	input			A, B;
	output			S, CO;
	
	assign {CO, S} = A + B;
	
endmodule

module FullAdder_1b ( A, B, CI, S, CO );

	input			A, B, CI;
	output			S, CO;
	
	assign {CO, S} = A + B + CI;
	
endmodule

module HalfAdder_4b ( A, B, S, CO );

	input	[3:0]	A, B;
	output	[3:0]	S;
	output			CO;
	
	wire	[2:0]	C;
	
	HalfAdder_1b a0 ( .A(A[0]), .B(B[0]),            .S(S[0]), .CO(C[0]) );
	FullAdder_1b a1 ( .A(A[1]), .B(B[1]), .CI(C[0]), .S(S[1]), .CO(C[1]) );
	FullAdder_1b a2 ( .A(A[2]), .B(B[2]), .CI(C[1]), .S(S[2]), .CO(C[2]) );
	FullAdder_1b a7 ( .A(A[3]), .B(B[3]), .CI(C[2]), .S(S[3]), .CO(CO) );

endmodule

module HalfAdder

	# ( parameter N=8 )

(
	input	wire	[N-1:0]	A, B,
	output	wire	[N-1:0]	S,
	output	wire			CO
);

	assign {CO, S} = A + B;

endmodule

module FullAdder

	# ( parameter N=8 )

(
	input	wire	[N-1:0]	A, B,
	input	wire			CI,
	output	wire	[N-1:0]	S,
	output	wire			CO
);

	assign {CO, S} = A + B + CI;

endmodule