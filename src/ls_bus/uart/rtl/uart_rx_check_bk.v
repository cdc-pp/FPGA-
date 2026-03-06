`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:54:59 10/13/2017 
// Design Name: 
// Module Name:    rx_emcc 
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

module uart_rx_check_bk
(

    input              sys_clk                 ,
    input              rst                     ,
    input    [ 1:0]    i_check_mode            ,
    input    [ 7:0]    i_data                  ,
    input              i_data_vl               ,
    input              i_rx_check_data         ,
    input    [ 3:0]    i_data_num              ,
        
    output   [ 7:0]    o_check_data            ,
    output             o_check_vl      
    
);
 
reg              rx_vl              ;
reg              rx_vl_ff1          ;
reg              rx_vl_ff2          ;
reg              rx_vl_ff3          ;
reg              rx_vl_ff4          ;
reg              rx_vl_ff5          ;
reg     [7:0]    rx_dat_buf         ;
reg     [7:0]    rx_dat_buf1        ;
wire             par_check_flag     ; //指示对比接收的奇偶校验位与自校验的对比，1'b1为对比为正确
wire             check_data         ;

assign par_check_flag = (i_rx_check_data == check_data) ? 1'b1 : 1'b0;
assign o_check_data   = rx_dat_buf1;   
assign o_check_vl     = rx_vl_ff5;

always@(posedge sys_clk or posedge rst)
begin
    if(rst)
        begin
            rx_vl       <= 1'b0;
            rx_vl_ff1   <= 1'b0;
            rx_vl_ff2   <= 1'b0;
            rx_vl_ff3   <= 1'b0;
            rx_vl_ff4   <= 1'b0;
            rx_vl_ff5   <= 1'b0;
            rx_dat_buf  <= 'b0;
            rx_dat_buf1 <= 'b0;
        end
    else
        begin
            rx_vl       <= i_data_vl;
            rx_dat_buf  <= i_data;
            rx_vl_ff1   <= rx_vl;
            rx_vl_ff2   <= rx_vl_ff1;
            rx_vl_ff3   <= rx_vl_ff2;
            rx_vl_ff4   <= rx_vl_ff3;
            rx_vl_ff5   <= ((i_check_mode[0] & par_check_flag) | (~i_check_mode[0])) & rx_vl_ff4 ;
            if(i_data_num == 4'd5)
                rx_dat_buf1 <= {3'b0,rx_dat_buf[4:0]};
            else if(i_data_num == 4'd6)
                rx_dat_buf1 <= {2'b0,rx_dat_buf[5:0]};
            else if(i_data_num == 4'd7)
                rx_dat_buf1 <= {1'b0,rx_dat_buf[6:0]};
            else if(i_data_num == 4'd8)
                rx_dat_buf1 <= rx_dat_buf;
            else
                rx_dat_buf1 <= rx_dat_buf;
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
    .i_data         (rx_dat_buf   )  //输入的需要校验的数据

);

endmodule
