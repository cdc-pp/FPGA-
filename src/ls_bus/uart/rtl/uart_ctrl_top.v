        `timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:27:48 10/05/2014 
// Design Name: 
// Module Name:    rs422_top 
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
module uart_ctrl_top#
(
    parameter DEBUG = 0 
)
(

    input               rst          ,      
    input               clk_100mhz   , //100m 
    
    input               i_uart_rx    , //serial rx_data_in
    output              o_uart_tx    , //serial  tx_data_out
    input               i_rx_en      ,
    input     [ 3:0]    i_baud_sel   , //波特率选择
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
                                       // others 
    input     [ 1:0]    i_check_mode , //奇偶校验模式，10/00 不校验，11：奇校验，01：偶校验//
    input     [ 3:0]    i_data_num   ,
                                       
    output    [ 7:0]    o_rx_data    ,
    output              o_rx_vl      ,
    output              o_tx_busy    , //1'b1：表示当前发送正忙，1'b0：表示当前发送空闲
    input     [ 7:0]    i_tx_data    ,
    input               i_tx_vl    

); 

reg     [ 3:0]    tx_frame_num       ;
reg     [ 3:0]    rx_frame_num       ;

wire    [15:0]    baud_para          ;
wire    [15:0]    baud_mid_para      ;

//通过判断是否有校验位，计算一次UART通信的计数个数
always@(*) 
begin 
    case(i_data_num)
        4'd8:
        begin
            if(i_check_mode[0])
            begin
                tx_frame_num <= 4'd12;
                rx_frame_num <= 4'd10;
            end
            else
            begin
                tx_frame_num <= 4'd11;
                rx_frame_num <= 4'd9;
            end
        end
        4'd7:
        begin
            if(i_check_mode[0])
            begin
                tx_frame_num <= 4'd11;
                rx_frame_num <= 4'd9;
            end
            else
            begin
                tx_frame_num <= 4'd10; 
                rx_frame_num <= 4'd8;
            end
        end
        4'd6:
        begin
            if(i_check_mode[0])
            begin
                tx_frame_num <= 4'd10;
                rx_frame_num <= 4'd8;
            end
            else
            begin
                tx_frame_num <= 4'd9;
                rx_frame_num <= 4'd7;
            end
        end
        4'd5:
        begin
            if(i_check_mode[0])
            begin
                tx_frame_num <= 4'd9;
                rx_frame_num <= 4'd7;
            end
            else
            begin
                tx_frame_num <= 4'd8;
                rx_frame_num <= 4'd6;
            end
        end
        default:
        begin
            if(i_check_mode[0])
            begin
                tx_frame_num <= 4'd12;
                rx_frame_num <= 4'd10;
            end
            else
            begin
                tx_frame_num <= 4'd11;
                rx_frame_num <= 4'd9;
            end
        end
    endcase
end 

 
//波特率进行选择，并输出参数
uart_baud_sel_bk u_uart_baud_sel_bk
(

    .rst                     (rst            ), 
    .sys_clk                 (clk_100mhz     ), 
    .i_baud_sel              (i_baud_sel     ), 
    .o_baud_para             (baud_para      ), 
    .o_baud_mid_para         (baud_mid_para  )

);

//uart协议发送模块
uart_tx_bk u_uart_tx_bk
(

    .sys_clk                (clk_100mhz      ),
    .rst                    (rst             ),
    
    .o_uart_tx              (o_uart_tx       ), //串行数据输出
    
    .i_baud_para            (baud_para       ),
    .i_baud_mid_para        (baud_mid_para   ),
    .i_check_mode           (i_check_mode    ), 
    .i_data_num             (i_data_num      ),
    .i_frame_num            (tx_frame_num    ),
    .o_tx_busy              (o_tx_busy       ), //1'b1：表示当前发送正忙，1'b0：表示当前发送空闲

    .i_tx_data              (i_tx_data       ),     
    .i_tx_vl                (i_tx_vl         )  //发送开始信号  
);

//uart协议接收模块
uart_rx_bk u_uart_rx_bk
(

    .sys_clk                (clk_100mhz      ),
    .rst                    (rst             ),
    
    .i_uart_rx              (i_uart_rx       ), 
    
    .i_baud_para            (baud_para       ),
    .i_baud_mid_para        (baud_mid_para   ),
    .i_check_mode           (i_check_mode    ),
    .i_rx_en                (i_rx_en         ),
    .i_data_num             (i_data_num      ),
    .i_frame_num            (rx_frame_num    ), 
    
    .o_rx_data              (o_rx_data       ),
    .o_rx_vl                (o_rx_vl         )

);

generate

    if(DEBUG == 1)
    begin
        ila_128b u_debug_uart
        (
            .clk     (clk_100mhz),
            .probe0  ({i_uart_rx, o_uart_tx, i_tx_data, i_tx_vl, o_tx_busy, o_rx_data, o_rx_vl})
                                    
        );
    end

endgenerate

endmodule
