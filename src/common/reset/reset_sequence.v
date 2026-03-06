`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////
//Copyright (C) 2023 Lemid Technology Co.,Ltd.*
//////////////////////////////////////////////////////////////////
//    reset_sequence.v
//DESCRIPTION:
//    完成复位序列                 ____                        _______ _______      ________
//                  ________ ______|   |______      或                        |____|   
//                     IDLE    1    2   3                        ILDE     1    2    3
//              INITAL_LEVEL = 0, RESET_LEVEL = 1          INITAL_LEVEL = 1, RESET_LEVEL = 0
//    该模块可实现，1、参数化初始化值。2、参数化复位前延时。3、参数化复位后延时。
//AUTHOR:
//    BSP
//CREATED DATE:
//    2024/04/07
//REVISION:
//1.0 - 初始版本

//////////////////////////////////////////////////////////////////

module reset_sequence#
(
    // 参数定义   
    // 1s  = 10^9ns = 10^6us = 10^4ms; 10_0000_0000
    // 1ms = 10^6ns; 100_0000
    parameter FIRST_PERIOD_NS     = 100_0000                         , // 第一阶段持续时间，单位：纳秒
    parameter SECOND_PERIOD_NS    = 100_0000                         , // 第二阶段持续时间，单位：纳秒
    parameter THIRD_PERIOD_NS     = 100_0000                         , // 第三阶段持续时间，单位：纳秒
    parameter RESET_LEVEL         = 1                                , // 确认是低电平复位还是高电平复位
    parameter INITAL_LEVEL        = 0                                , // 确认模块的初始化值是多少，即rst_n置1前的值
    parameter CLK_FREQ_MHZ        = 100                              , // 主时钟频率，单位：MHz
    parameter COUNT_WIDTH         = 32                                 // 计数器位宽可自定义，但使用时需注意是否操作最大的位宽大小

)
(
    input               clk             , // 主时钟输入
    input               rst_n           , // 模块复位信号
    output              o_rst           , // reset信号输出
    output              o_rst_done   
);

//内部参数定义
parameter CLK_PERIOD_NS       = (1000000000 / (CLK_FREQ_MHZ * 1000000)) ;  
parameter FIRST_COUNT         = FIRST_PERIOD_NS / CLK_PERIOD_NS  ;
parameter SECOND_COUNT        = SECOND_PERIOD_NS / CLK_PERIOD_NS ;
parameter THIRD_COUNT         = THIRD_PERIOD_NS / CLK_PERIOD_NS ;

// 内部状态机定义
localparam IDLE_STA   = 5'b00000  ;
localparam FIRST_STA  = 5'b00010  ;
localparam SECOND_STA = 5'b00100  ;
localparam THIRD_STA  = 5'b01000  ;
localparam DONE_STA   = 5'b10000  ;

reg [ 4:0]                  current_state ;
reg [ 4:0]                  next_state    ;
reg [COUNT_WIDTH - 1:0]     counter       ; // 定义计数计数器
reg                         rst           ; // 复位信号
reg                         rst_done      ;

assign o_rst = rst;
assign o_rst_done = rst_done;

always @(posedge clk or negedge rst_n) 
begin
    if (~rst_n) 
    begin
        current_state <= IDLE_STA;
    end 
    else 
    begin
        current_state <= next_state;
    end
end

always @(*) 
begin
    case (current_state)
        IDLE_STA: 
        begin
            if (rst_n) 
            begin
                next_state = FIRST_STA;
            end 
            else 
            begin
                next_state = IDLE_STA;
            end
        end
        FIRST_STA: 
        begin
            if (counter == FIRST_COUNT - 1) 
            begin
                next_state = SECOND_STA;
            end 
            else 
            begin
                next_state = FIRST_STA;
            end
        end
        SECOND_STA: 
        begin
            if (counter == SECOND_COUNT - 1) 
            begin
                next_state = THIRD_STA;
            end 
            else 
            begin
                next_state = SECOND_STA;
            end
        end
        THIRD_STA: 
        begin
            if (counter == THIRD_COUNT - 1) 
            begin
                next_state = DONE_STA;
            end 
            else 
            begin
                next_state = THIRD_STA;
            end
        end
        DONE_STA:
        begin
            next_state = next_state;
        end
    endcase
end

// 计数模块，在不同状态根据计算的最大计数值进行计数
always @(posedge clk or negedge rst_n) 
begin
    if (~rst_n) 
    begin
        counter <= 32'd0;
    end
    else
    begin
        case (current_state)
            IDLE_STA: 
            begin
                counter <= 32'd0;
            end
            FIRST_STA:
            begin
                if (counter == FIRST_COUNT - 1) 
                begin
                    counter <= 32'd0;
                end
                else
                begin
                    counter <= counter + 1'b1;
                end
            end
            SECOND_STA: 
            begin
                if (counter == SECOND_COUNT - 1) 
                begin
                    counter <= 32'd0;
                end
                else
                begin
                    counter <= counter + 1'b1;
                end
            end
            THIRD_STA: 
            begin
                if (counter == THIRD_COUNT - 1)
                begin
                    counter <= 32'd0;
                end
                else
                begin
                    counter <= counter + 1'b1;  
                end
            end
            default:
            begin
                counter <= 32'd0;
            end
        endcase
    end
end

// 通过初始化的值确定是高电平复位还是低电平复位
always @(posedge clk or negedge rst_n) 
begin
    if (~rst_n) 
    begin
        rst <= INITAL_LEVEL;
    end
    else 
    begin
        if (current_state == IDLE_STA)
        begin
            rst <= INITAL_LEVEL;
        end
        else if (current_state == SECOND_STA)
        begin
            rst <= RESET_LEVEL;
        end
        else 
        begin
            rst <= ~RESET_LEVEL;
        end
    end
end
 
// 复位完成
always @(posedge clk or negedge rst_n) 
begin
    if (~rst_n) 
    begin
        rst_done <= 1'b0;
    end
    else 
    begin
        if (current_state == DONE_STA)
        begin
            rst_done <= 1'b1;
        end
        else 
        begin
            rst_done <= 1'b0;
        end
    end
end

endmodule