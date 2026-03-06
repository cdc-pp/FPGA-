`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/11 17:54:59
// Design Name: 
// Module Name: uart_loop_bk
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_loop_bk(
    
    input                   sys_clk     ,
    input                   rst_n       ,

    //uart 
    input                   i_uart_rx   ,
    output                  o_uart_tx   ,
    //波特率选择
    input     [ 3:0]        i_baud_sel   //波特率选择
                                         //0x0:9600
                                         //0x1:14400
                                         //0x2:19200
                                         //0x3:38400  
                                         //0x4:57600  
                                         //0x5:115200 
                                         //0x6:230400 
                                         //0x7:460800 
                                         //0x8:921600 
                                         //0x9:2400
                                         //0xa:4800
                                         //0xb:76800
                                         
);

wire    [ 7:0]    uart_rx_data    ;
wire              uart_rx_vl      ;
wire              uart_tx_busy    ;
wire    [ 7:0]    uart_tx_data    ;
wire              uart_tx_vl      ;

//回环自测                         
uart_fdbk u_uart_fdbk    
(                                  
    .sys_clk                        (sys_clk              ),
    .rst_n                          (rst_n                ),
    .i_uart_tx_busy                 (uart_tx_busy         ),
    .i_uart_rx_vl                   (uart_rx_vl           ),
    .i_uart_rx_data                 (uart_rx_data         ),
    .o_uart_tx_vl                   (uart_tx_vl           ),
    .o_uart_tx_data                 (uart_tx_data         )
    
    
);

//UART通信
uart_ctrl_top u_uart_ctrl_top
(

    .rst                            (~rst_n               ),
    .clk_100mhz                     (sys_clk              ),
    .i_uart_rx                      (i_uart_rx            ),
    .o_uart_tx                      (o_uart_tx            ),
    .i_rx_en                        (1'b1                 ),
    .i_baud_sel                     (i_baud_sel           ),
    .i_check_mode                   (2'b00                ), 
    .i_data_num                     (4'd8                 ),

    .o_rx_data                      (uart_rx_data         ),
    .o_rx_vl                        (uart_rx_vl           ),
    .o_tx_busy                      (uart_tx_busy         ), //UART正在发送中
    .i_tx_data                      (uart_tx_data         ),
    .i_tx_vl                        (uart_tx_vl           ) 

);

endmodule
