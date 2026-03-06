`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/09 13:50:59
// Design Name: 
// Module Name: tb_uart_ctrl_top
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


module tb_uart_ctrl_top();

reg                       rst              ;
reg                       clk_100mhz       ;
wire                      uart_rx          ;
wire                      uart_tx          ;
reg     [ 3:0]            uart_baud_sel    ;

wire    [ 7:0]            uart_rx_data     ;
wire                      uart_rx_vl       ;
wire                      uart_tx_busy     ;

reg     [ 7:0]            uart_tx_data     ;
reg                       uart_tx_vl       ;
 
uart_ctrl_top#
(
    .DEBUG          (0  )
)
u_uart_ctrl_top
(

    .rst                 (rst                  ),
    .clk_100mhz          (clk_100mhz           ),
    .i_uart_rx           (uart_rx              ),
    .o_uart_tx           (uart_tx              ),
    .i_rx_en             (1'b1                 ),
    .i_baud_sel          (uart_baud_sel        ),
    .i_check_mode        (2'b00                ), 
    .i_data_num          (4'd8                 ),
                         
    .o_rx_data           (uart_rx_data         ),
    .o_rx_vl             (uart_rx_vl           ),
    .o_tx_busy           (uart_tx_busy         ), //UART正在发送中
    .i_tx_data           (uart_tx_data         ),
    .i_tx_vl             (uart_tx_vl           ) 

);

assign uart_rx = uart_tx;

initial
begin
    
    rst           = 1'b1    ;
    clk_100mhz    = 1'b0    ; 
    uart_baud_sel = 4'd5    ;
    uart_tx_data  = 'd0     ;
    uart_tx_vl    = 'd0     ;
    
    #100 
    rst           = 1'b0    ;
    
    #100 
    uart_tx_data  = 8'h31   ;
    uart_tx_vl    = 1'b1    ;
    #10
    uart_tx_vl    = 1'b0    ;
 
end


always #5  clk_100mhz <= ~clk_100mhz;


endmodule
