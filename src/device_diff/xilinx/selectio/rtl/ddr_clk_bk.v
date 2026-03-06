`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:04:36 09/03/2024
// Design Name: 
// Module Name:    io_clk_bk 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//    
//////////////////////////////////////////////////////////////////////////////////

module ddr_clk_bk#
(
    parameter BUFR_DIVIDE   = "BYPASS"   , //若使用BUFR, Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8" 
    parameter BUFR_BUFG_EN  = 1          , //一般该时钟逻辑内部需要使用
    parameter DIFF_TERM     = "TRUE"       //匹配电阻
)
(

    input           i_clk_pad_p       ,
    input           i_clk_pad_n       ,
    output          o_clk_bufr        , 
    output          o_clk_bufg         
    
);
 
wire                clk_pad         ;
wire                clk_bufr        ; 
wire                clk_bufg        ; 

assign o_clk_bufr     = clk_bufr      ;
assign o_clk_bufg     = clk_bufg      ; 

//差分时钟转为单端（必要）
IBUFDS#(
   .DIFF_TERM           (DIFF_TERM              ), // Differential Termination
   .IBUF_LOW_PWR        ("FALSE"                ), // Low power="TRUE", Highest performance="FALSE" 
   .IOSTANDARD          ("LVDS"                 )  // Specify the input I/O standard
) 
u_clk_ibufd
(
    .I                  (i_clk_pad_p            ),
    .IB                 (i_clk_pad_n            ),
    .O                  (clk_pad                )
);

//将单端的pin时钟接入到区域时钟bufr资源中，根据serdes串行因子对时钟进行分频
BUFR#(
    .BUFR_DIVIDE        (BUFR_DIVIDE            ), // Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8" 
    .SIM_DEVICE         ("7SERIES"              )  // Must be set to "7SERIES" 
)
u_clk_bufr
(
    .O                  (clk_bufr              ),
    .CE                 (                       ),
    .CLR                (                       ),
    .I                  (clk_pad                )
);

generate
    if(BUFR_BUFG_EN == 1)
    begin
        //将bufr时钟接入到全局时钟bufg中
        BUFG u_clk_div_bufg
        (
            .I                  (clk_bufr        ),
            .O                  (clk_bufg        )
        );
    end
endgenerate

endmodule
