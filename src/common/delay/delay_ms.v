`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//Copyright (C) 2023 Lemid Technology Co.,Ltd.*
//////////////////////////////////////////////////////////////////
//delay_ms.v
//
//DESCRIPTION:
//    功能描述，针对MS级延时
//AUTHOR:
//    pp
//CREATED DATE:
//    2024/04/19
//REVISION:
//1.0 - 初始版本
//1.1 - 修复计数多一个周期
//////////////////////////////////////////////////////////////////

module delay_ms #
(

    parameter REF_CLK_FREQ = 100 , //参考时钟频率，单位为Mhz
    parameter DELAY_MS_VAL = 1     //单位为MS

) 
(

    input               clk              , 
    input               rst_n            , 
    output              o_dly_ms_done

);

reg             delay_done      ; //延时结束标志
reg    [31:0]   counter         ;

assign o_dly_ms_done = delay_done;

//MS的周期数计算
parameter DELAY_CYCLES = REF_CLK_FREQ * 1000000 / 1000 * DELAY_MS_VAL; 

always @(posedge clk or negedge rst_n) 
begin
    if (~rst_n) 
    begin
        counter <= 0;
        delay_done <= 0;
    end  
    else if (counter == (DELAY_CYCLES - 1)) 
    begin
        counter <= counter; 
        delay_done <= 1'b1;
    end 
    else 
    begin
        counter <= counter + 1'b1;
        delay_done <= 0;
    end
end

endmodule