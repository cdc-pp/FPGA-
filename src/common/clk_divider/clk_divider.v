`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////
//Copyright (C) 2023 Lemid Technology Co.,Ltd.*
//////////////////////////////////////////////////////////////////
//clk_divider.v
//
//DESCRIPTION:
//    时钟的奇偶分频
//AUTHOR:
//    pp
//CREATED DATE:
//    2025/03/14
//REVISION:
//1.0 - 初始版本
//////////////////////////////////////////////////////////////////

module clk_divider #(

    parameter DIV_FACTOR = 100 //分频系数

)
(
    input        sys_clk    , // 100MHz主时钟
    input        rst_n      , // 低电平复位
    output       o_clk_div    // 分频输出
);


localparam CNT_WIDTH = 32;

reg         clk_div     ;

assign o_clk_div = clk_div;

generate
    if (DIV_FACTOR == 1) 
    begin
        // 分频系数为1时直通时钟
        always @(*) 
        begin
            clk_div = sys_clk;
        end
    end 
    else if (DIV_FACTOR % 2 == 0) 
    begin
        // 偶数分频逻辑
        localparam HALF_DIV = DIV_FACTOR / 2;
        reg     [CNT_WIDTH - 1:0]    counter;
        
        always @(posedge sys_clk or negedge rst_n) 
        begin
            if (!rst_n) 
            begin
                counter <= 0;
                clk_div <= 0;
            end 
            else 
            begin
                if (counter == HALF_DIV - 1) 
                begin
                    clk_div <= ~clk_div;
                    counter <= 0;
                end 
                else 
                begin
                    counter <= counter + 1;
                end
            end
        end
    end 
    else 
    begin
        // 奇数分频逻辑
        reg     [CNT_WIDTH - 1:0]    cnt_p   ;
        reg     [CNT_WIDTH - 1:0]    cnt_n   ;
        reg                          clk_p   ;
        reg                          clk_n   ;
        
        // 上升沿计数器
        always @(posedge sys_clk or negedge rst_n) 
        begin
            if (!rst_n) 
            begin
                cnt_p <= 0;
                clk_p <= 0;
            end 
            else 
            begin
                cnt_p <= (cnt_p == DIV_FACTOR-1) ? 0 : cnt_p + 1; 
                if (cnt_p == (DIV_FACTOR-1)/2 || cnt_p == DIV_FACTOR-1) 
                    clk_p <= ~clk_p;
            end
        end
        
        // 下降沿计数器
        always @(negedge sys_clk or negedge rst_n) 
        begin
            if (!rst_n) 
            begin
                cnt_n <= 0;
                clk_n <= 0;
            end 
            else 
            begin
                cnt_n <= (cnt_n == DIV_FACTOR-1) ? 0 : cnt_n + 1;
                
                if (cnt_n == (DIV_FACTOR-1)/2 || cnt_n == DIV_FACTOR-1)
                    clk_n <= ~clk_n;
            end
        end
        // 组合输出
        always @(*) clk_div = clk_p | clk_n;
    end
endgenerate

endmodule