`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//Copyright (C) 2024 Lemid Technology Co.,Ltd.*
//////////////////////////////////////////////////////////////////
//uart_fdbk.v
//
//DESCRIPTION:
//    uart协议回环测试模块
//AUTHOR:
//    
//CREATED DATE:
//    2024/02/04
//REVISION:

//////////////////////////////////////////////////////////////////

module  uart_fdbk
(

    input                           sys_clk                     ,
    input                           rst_n                       ,
    input                           i_uart_tx_busy              ,
    input                           i_uart_rx_vl                ,
    input      [7:0]                i_uart_rx_data              ,
    output                          o_uart_tx_vl                ,
    output     [7:0]                o_uart_tx_data               

);

reg                                 uart_tx_busy_r1             ;
reg                                 uart_tx_busy_r2             ;
reg                                 uart_rx_vl                  ;
reg [7:0]                           uart_rx_data                ;

reg                                 tx_inpro                    ;

reg                                 uart_tx_vl                  ;
reg [7:0]                           uart_tx_data                ;

reg                                 ff_wr_vl                    ;
reg [7:0]                           ff_wr_data                  ;
reg                                 ff_rd_vl                    ;
wire[7:0]                           ff_rd_data                  ;
wire                                ff_full                     ;
wire                                ff_empty                    ;

assign      o_uart_tx_vl    =   uart_tx_vl                      ;
assign      o_uart_tx_data  =   uart_tx_data                    ;

always @(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        uart_tx_busy_r1 <=  1'b1                            ;
        uart_tx_busy_r2 <=  1'b1                            ;
    end
    else
    begin
        uart_tx_busy_r1 <=  i_uart_tx_busy                  ;
        uart_tx_busy_r2 <=  uart_tx_busy_r1                 ;
    end
end

always @(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        uart_rx_vl   <=  'd0                         ;
        uart_rx_data <=  'd0                         ;
    end
    else
    begin
        uart_rx_vl   <=  i_uart_rx_vl                ;
        uart_rx_data <=  i_uart_rx_data              ;
    end
end

always @(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        ff_wr_vl         <=  'd0                       ;
        ff_wr_data       <=  'd0                       ;
    end
    else
    begin
        ff_wr_vl         <=  uart_rx_vl                ;
        ff_wr_data       <=  uart_rx_data              ;
    end
end

always @(posedge sys_clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        tx_inpro    <=  'd0                             ;
    end
    else
    begin
        if(ff_rd_vl == 1'b1)
        begin
            tx_inpro    <=  'd1                         ;
        end
        else if(uart_tx_busy_r2 && (~uart_tx_busy_r1))
        begin
            tx_inpro    <=  'd0                         ;
        end
        else
        begin
            tx_inpro    <=  tx_inpro                    ;
        end
    end
end

//FIFO读信号
always @(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        ff_rd_vl         <=  'd0                     ;
    end
    else
    begin
        if(tx_inpro == 1'b0)
        begin
            if(ff_rd_vl == 1'b1)
            begin
                ff_rd_vl <=  'd0                     ;
            end
            else if(~ff_empty)
            begin
                ff_rd_vl <=  'd1                     ;
            end
        end
        else
        begin
            ff_rd_vl     <=  'd0                     ;
        end
    end
end

sff_i8o8d1k u_sff_i8o8d1k
(
    .clk                        (sys_clk         ), // input wire clk
    .rst                        (~rst_n          ), // input wire rst
    .din                        (ff_wr_data      ), // input wire [7 : 0] din
    .wr_en                      (ff_wr_vl        ), // input wire wr_en
    .rd_en                      (ff_rd_vl        ), // input wire rd_en
    .dout                       (ff_rd_data      ), // output wire [7 : 0] dout
    .full                       (ff_full         ), // output wire full
    .empty                      (ff_empty        )  // output wire empty
);

always @(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        uart_tx_vl     <=  'd0                             ;
        uart_tx_data   <=  'd0                             ;
    end
    else
    begin
        uart_tx_vl     <=  ff_rd_vl                         ;
        if(ff_rd_vl == 1'b1)
            uart_tx_data <= ff_rd_data                       ;
        else 
            uart_tx_data <= uart_tx_data;
    end
end

//ila_128b   u_ila_uart_fdbk
//(
//    .clk    (sys_clk),
//    .probe0  ({rst_n, ff_wr_data, ff_wr_vl, ff_rd_vl, ff_rd_data, ff_full, ff_empty})
//                                                            
//);

endmodule