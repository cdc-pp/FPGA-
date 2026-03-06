`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:40:03 03/24/2015 
// Design Name: 
// Module Name:    uart_tx_bk 
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
//     20250108：tx_module -> uart_tx_bk，修改模块接口和代码内部命名，将波特率
//               计数部分和波特选择模块放入模块中，增加关键代码注释 
//
//////////////////////////////////////////////////////////////////////////////////
module uart_tx_bk(

    input               sys_clk         ,
    input               rst             ,
              
    input     [15:0]    i_baud_para     ,
    input     [15:0]    i_baud_mid_para ,
    
    input     [ 1:0]    i_check_mode    , //奇偶校验使能
    input     [ 3:0]    i_data_num      ,
    input     [ 3:0]    i_frame_num     ,
    input     [ 7:0]    i_tx_data       ,
    input               i_tx_vl         ,   
    output              o_uart_tx       , 
    output              o_tx_busy

);

reg               tx_flag_r         ;
reg               tx_flag_rr        ;
wire              tx_flag_pos       ;
reg     [ 3:0]    tx_cnt            ; 
wire              check_data        ;
reg     [ 7:0]    tx_data_reg       ;
reg               uart_tx           ; 
reg               tx_busy           ;
reg               clk_mid_vl        ;
 
reg     [15:0]    clk_cnt           ;

assign o_uart_tx   = uart_tx   ; 
assign o_tx_busy   = tx_busy   ;
 
//计算波特率整个翻转周期的计数，在一次翻转后或未在发送状态时将计数清零
always@(posedge sys_clk or posedge rst)
begin
    if(rst) 
        clk_cnt <= 16'd0;
    else 
    begin
        if((clk_cnt == i_baud_para - 1'b1) || (~tx_busy)) 
            clk_cnt <= 16'd0;
        else 
            clk_cnt <= clk_cnt + 1'b1;
    end
end     

//根据参考时钟计算的波特率中间计数参数的有效信号，用于总线数据赋值
always@(posedge sys_clk or posedge rst)
begin
    if(rst) 
        clk_mid_vl <= 1'b0;
    else if (clk_cnt == i_baud_mid_para - 1'b1) 
        clk_mid_vl <= 1'b1;
    else 
        clk_mid_vl <= 1'b0;
end 

//发送数据有效打拍
always@(posedge sys_clk or posedge rst)
begin
    if(rst)
    begin
        tx_flag_r  <= 1'b0;
        tx_flag_rr <= 1'b0;
    end               
    else              
    begin             
        tx_flag_r  <= i_tx_vl;
        tx_flag_rr <= tx_flag_r;
    end
end 

//抓取发送数据有效上升沿，用于单次发送的开始标志
assign tx_flag_pos = ~tx_flag_rr & tx_flag_r;

//表示当前处于发送状态中，期间不可接收外部发送请求
always@(posedge sys_clk or posedge rst)
begin
    if(rst)
    begin
        tx_busy   <= 1'b0; 
    end
    else if(tx_flag_pos)
    begin
        tx_busy   <= 1'b1; 
    end
    else if(tx_cnt == i_frame_num)
    begin
        tx_busy   <= 1'b0; 
    end
end

//根据外部数据有效，将需要发送的数据进行寄存，保证单次发送数据保持不变
always@(posedge sys_clk or posedge rst)
begin
    if(rst)
    begin
        tx_data_reg <= 8'd0;
    end
    else if(i_tx_vl)
    begin
        tx_data_reg <= i_tx_data;
    end
end

//通过波特率计算，根据中间参数的有效信号对TX数据总线赋值
always@(posedge sys_clk or posedge rst)
begin
    if(rst)
    begin
        uart_tx <= 1'b1;
        tx_cnt  <= 4'd0; 
    end
    else if(tx_busy)
    begin
        if(clk_mid_vl) //根据该信号计数增加，输出数据赋值
        begin
            tx_cnt <= tx_cnt + 1'b1;
            if(tx_cnt == 4'h0) 
                uart_tx <= 0;
            if(tx_cnt == 4'h1) 
                uart_tx <= tx_data_reg[0];
            if(tx_cnt == 4'h2) 
                uart_tx <= tx_data_reg[1];
            if(tx_cnt == 4'h3) 
                uart_tx <= tx_data_reg[2];
            if(tx_cnt == 4'h4) 
                uart_tx <= tx_data_reg[3];
            if(tx_cnt == 4'h5) 
                uart_tx <= tx_data_reg[4];
            if(tx_cnt == 4'h6) 
                uart_tx <= tx_data_reg[5];
            if(tx_cnt == 4'h7) 
                uart_tx <= tx_data_reg[6];
            if(tx_cnt == 4'h8) 
                uart_tx <= tx_data_reg[7];
            if(i_check_mode[0])
            begin
                if(tx_cnt + 3'd3 == i_frame_num)
                    uart_tx <= check_data;
            end
            if(tx_cnt + 2'd2 == i_frame_num)
                uart_tx <= 1'b1;
        end
        else if(tx_cnt == i_frame_num) //如果data_num小于8
        begin
            tx_cnt  <= 4'd0;
            uart_tx <= 1'b1;
        end
    end
    else
    begin
        tx_cnt  <= 4'd0;
        uart_tx <= 1'b1;
    end
end

//奇偶校验模块
parity_check_bk u_parity_check_bk 
(

    .rst_n          (~rst         ), 
    .sys_clk        (sys_clk      ), 
    .i_check_mode   (i_check_mode ), //奇偶校验模式，10/00 不校验，11：奇校验，01：偶校验//
    .i_data_num     (i_data_num   ), //需要奇偶校验的数据个数 
    .o_check_data   (check_data   ), //奇偶校验数据
    .i_data         (tx_data_reg  )  //输入的需要校验的数据

);

endmodule