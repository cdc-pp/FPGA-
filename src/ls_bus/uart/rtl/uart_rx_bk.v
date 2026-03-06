`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:40:03 03/24/2015 
// Design Name: 
// Module Name:    uart_rx_bk 
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
//     20250108：rx_module -> uart_rx_bk，修改模块接口和代码内部命名，将波特率
//               计数部分和波特选择模块放入模块中，增加关键代码注释 
//
//////////////////////////////////////////////////////////////////////////////////

module uart_rx_bk
(

    input               sys_clk         ,
    input               rst             ,
    input     [15:0]    i_baud_para     ,
    input     [15:0]    i_baud_mid_para ,
    input     [ 1:0]    i_check_mode    ,
    input               i_rx_en         ,
    input     [ 3:0]    i_data_num      ,
    input     [ 3:0]    i_frame_num     ,
    input               i_uart_rx       , 
    output    [ 7:0]    o_rx_data       ,
    output              o_rx_vl    

);
 
reg     [ 2:0]    uart_rx_reg    ; 
reg     [15:0]    clk_cnt        ;
reg               clk_mid_vl     ;
reg     [ 3:0]    rx_cnt         ;
reg               rx_busy        ;
reg               rx_check_data  ; //校验位数据
reg     [ 7:0]    rx_temp_data   ;
reg               rx_temp_vl     ; 

wire    [ 7:0]    rx_data        ;
wire              rx_vl          ;
wire              uart_rx_neg    ; //数据线接收到下降沿

assign o_rx_data    = rx_data   ;
assign o_rx_vl      = rx_vl     ;


//对UART RX总线信号进行打拍，消除亚稳态
always @(posedge sys_clk or posedge rst)
begin
    if(rst)
    begin
        uart_rx_reg <= 3'b0; 
    end 
    else 
    begin
        uart_rx_reg <= {uart_rx_reg[1:0], i_uart_rx};
    end
end

//获取UART接收总线的下降沿，检测通信的起始位
assign uart_rx_neg = i_rx_en & (uart_rx_reg[2] & ~uart_rx_reg[1]);

//计算波特率整个翻转周期的计数，在一次翻转后或未在发送状态时将计数清零
always@(posedge sys_clk or posedge rst)
begin
    if(rst) 
        clk_cnt <= 16'd0;
    else 
    begin
        if((clk_cnt == i_baud_para - 1'b1) || (~rx_busy)) 
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

always @(posedge sys_clk or posedge rst)
begin
    if(rst)
    begin 
        rx_busy <= 1'b0;
    end
    else if(uart_rx_neg)
    begin 
        rx_busy <= 1'b1;
    end
    else if(rx_cnt == i_frame_num)
    begin 
        rx_busy <= 1'b0;
    end 
end 

always @(posedge sys_clk or posedge rst)
begin
    if(rst)
    begin
        rx_temp_data   <= 8'd0;
        rx_temp_vl     <= 1'b0;
        rx_cnt         <= 4'd0; 
        rx_check_data  <= 1'b0;
    end
    else if(rx_busy)
    begin
        if(clk_mid_vl) //根据该信号计数增加，输出数据赋值
        begin
            rx_cnt <= rx_cnt + 1'b1;
            if(rx_cnt == 4'd1)  
                rx_temp_data[0] <= uart_rx_reg[2];
            if(rx_cnt == 4'd2)  
                rx_temp_data[1] <= uart_rx_reg[2];
            if(rx_cnt == 4'd3)  
                rx_temp_data[2] <= uart_rx_reg[2];
            if(rx_cnt == 4'd4)  
                rx_temp_data[3] <= uart_rx_reg[2];
            if(rx_cnt == 4'd5)  
                rx_temp_data[4] <= uart_rx_reg[2];
            if(rx_cnt == 4'd6)  
                rx_temp_data[5] <= uart_rx_reg[2];
            if(rx_cnt == 4'd7)  
                rx_temp_data[6] <= uart_rx_reg[2];
            if(rx_cnt == 4'd8)  
                rx_temp_data[7] <= uart_rx_reg[2];
            if(rx_cnt + 1'd1 == i_frame_num)  
                rx_check_data <= uart_rx_reg[2];
        end
        else if(rx_cnt == i_frame_num)
        begin
            rx_cnt        <= 4'd0;
            rx_temp_data  <= rx_temp_data;
            rx_temp_vl    <= 1'b1;
        end
    end
    else 
    begin
        rx_cnt         <= 4'd0;
        rx_temp_data   <= rx_temp_data;
        rx_temp_vl     <= 1'b0;
        rx_check_data  <= 1'b0;
    end
end 

//如果使能校验：将接收到奇偶校验位和接收到的数据进行奇偶校验，两者进行比对，
//若成功则输出数据，否则丢弃数据
uart_rx_check_bk u_uart_rx_check_bk
(

    .sys_clk           (sys_clk         ),
    .rst               (rst             ),
    .i_check_mode      (i_check_mode    ),
    .i_data            (rx_temp_data    ),
    .i_data_vl         (rx_temp_vl      ),
    .i_rx_check_data   (rx_check_data   ),
    .i_data_num        (i_data_num      ),
    
    .o_check_data      (rx_data         ),
    .o_check_vl        (rx_vl           )
    
);

endmodule
