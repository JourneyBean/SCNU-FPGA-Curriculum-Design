/**
	模块名称：N位寄存器
	输入：N位输入，时钟，复位
	输出：N位输出
	@Author: Johnson Liu (JourneyBean)
	@Date: 2020/5/6
*/

module Register

# ( parameter N=8 )

(
	output	reg		[N-1:0]	Q,
	input	wire	[N-1:0]	DI,
	input	wire	CP, CLR_
);

always @ ( posedge CP or negedge CLR_ )
	if ( ~CLR_ )
		Q <= 0;
	else if ( CP )
		Q <= DI;

endmodule

module ShiftReg

# ( parameter N=8 )

(
	output	reg		[N-1:0]	Q,
	input	wire	DI,
	input	wire	CP, CLR_
);

always @ ( posedge CP or negedge CLR_ )
	if ( ~CLR_ )
		Q <= {N{1'b0}};
	else
	begin
		Q[0]     <= DI;
		Q[N-1:1] <= Q[N-2:0];
	end

endmodule
