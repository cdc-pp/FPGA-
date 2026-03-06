`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////
//Copyright (C) 2023 Lemid Technology Co.,Ltd.*
//////////////////////////////////////////////////////////////////
//pro_top.v
//
//DESCRIPTION:
//    jesd204B时钟模块
//AUTHOR:
//    pp
//CREATED DATE:
//    2023/11/24
//REVISION:
//1.0 - 初始版本
//////////////////////////////////////////////////////////////////
module jesd204_rx_clocking #(
    
    parameter      JESD204B_GLBCLK_EN = 0 

)
(

    input                     i_refclk_p  ,
    input                     i_refclk_n  ,
    input                     i_glbclk_p  ,
    input                     i_glbclk_n  ,
    input                     i_sysref_p  ,
    input                     i_sysref_n  ,
    output                    o_refclk    ,
    output                    o_sysref    ,
    output                    o_core_clk     

);

//refclk (p/n) – transceiver reference clock. This is always present.
//glblclk (p/n) – core clock. This is an optional input which is present if refclk is not equal to the core clock or refclk is not between the MIN and MAX frequencies
//core_clk- frequency = lane rate / 40

//parameters



//wires
wire         refclk     ;
wire         glbclk     ;
wire         core_clk   ;
wire         sysref     ;

//regs
reg          sysref_r   ;
reg          sysref_rr  ;
reg          sysref_rrr ;

//assigns
assign o_refclk   = refclk      ;
assign o_core_clk = core_clk    ;
assign o_sysref   = sysref_rrr  ;


//main body

//高速口时钟输入
IBUFDS_GTE2 ibufds_refclk0 (

    .O               (refclk             ),
    .ODIV2           (                   ),
    .CEB             (1'b0               ),
    .I               (i_refclk_p         ),
    .IB              (i_refclk_n         )

);

//帧参考时钟输入
IBUFDS#(
    .DIFF_TERM        ("TRUE"),       // Differential Termination
    .IBUF_LOW_PWR     ("FALSE"),     // Low power="TRUE", Highest performance="FALSE" 
    .IOSTANDARD       ("LVDS")     // Specify the input I/O standard
)
i_sysrefclk_ibufds(

    .I           (i_sysref_p         ),
    .IB          (i_sysref_n         ),
    .O           (sysref             )

);

//帧参考时钟打拍，通过core_clk进行打拍，保证时钟同步
always@(posedge core_clk)
begin

    sysref_r   <= sysref    ;
    sysref_rr  <= sysref_r  ;
    sysref_rrr <= sysref_rr ;
    
end


generate

//时钟模式选择
if(JESD204B_GLBCLK_EN == 1)
    begin
        //（可选）普通差分时钟输入，按实际的硬件设计进行选择
        IBUFDS#(
            .DIFF_TERM        ("TRUE"),       // Differential Termination
            .IBUF_LOW_PWR     ("FALSE"),     // Low power="TRUE", Highest performance="FALSE" 
            .IOSTANDARD       ("LVDS")     // Specify the input I/O standard
       )
       i_glblclk_ibufds(
      
            .I           (i_glbclk_p         ),
            .IB          (i_glbclk_n         ),
            .O           (glbclk             )
        
        );
    
        //使用普通差分时钟做core_clk
        BUFG coreclk_bufg
        (
            .O           (core_clk           ),
            .I           (glbclk             )
        );
    
    end
else
    begin
    
        //使用高速口时钟做core_clk
        BUFG coreclk_bufg
        (
    
            .O           (core_clk           ),
            .I           (refclk             )
    
        );
    
    end

endgenerate



endmodule
