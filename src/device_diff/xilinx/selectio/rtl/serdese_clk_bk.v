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
//     1、使用BUFR和BUFIO
//     2、亦可使用MMCM生成两路时钟
//////////////////////////////////////////////////////////////////////////////////

module serdese_clk_bk#
(
    parameter BUFR_DIVIDE   = "BYPASS"   , //若使用BUFR, Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8" 
    parameter BUFIO_BUFG_EN = 0          ,
    parameter BUFR_BUFG_EN  = 1          , //一般该时钟逻辑内部需要使用
    parameter DIFF_TERM     = "TRUE"       //匹配电阻
)
(

    input           i_clk_pad_p       ,
    input           i_clk_pad_n       ,
    output          o_clk_bufio       , 
    output          o_clk_bufg        ,
    output          o_clk_div_buf     ,
    output          o_clk_div_bufg
    
);
 
wire                clk_pad         ;
wire                clk_bufio       ;
wire                clk_div_buf     ;
wire                clk_bufg        ;
wire                clk_div_bufg    ;

assign o_clk_bufio    = clk_bufio     ;
assign o_clk_bufg     = clk_bufg      ;
assign o_clk_div_buf  = clk_div_buf   ;
assign o_clk_div_bufg = clk_div_bufg  ;

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

//将单端的pin时钟接入到区域时钟bufio资源中
BUFIO u_clk_bufio
(
    .O                  (clk_bufio              ),
    .I                  (clk_pad                )
);

//将单端的pin时钟接入到区域时钟bufr资源中，根据serdes串行因子对时钟进行分频
BUFR#(
    .BUFR_DIVIDE        (BUFR_DIVIDE            ), // Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8" 
    .SIM_DEVICE         ("7SERIES"              )  // Must be set to "7SERIES" 
)
u_clk_bufr
(
    .O                  (clk_div_buf            ),
    .CE                 (                       ),
    .CLR                (                       ),
    .I                  (clk_pad                )
);

generate
    if(BUFIO_BUFG_EN == 1)
    begin
        //将bufio时钟接入到全局时钟bufg中
        BUFG u_clk_bufg
        (
            .I                  (clk_bufio          ),
            .O                  (clk_bufg           )
        );
    end
    if(BUFR_BUFG_EN == 1)
    begin
        //将bufr时钟接入到全局时钟bufg中
        BUFG u_clk_div_bufg
        (
            .I                  (clk_div_buf        ),
            .O                  (clk_div_bufg       )
        );
    end
endgenerate

endmodule
