`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/25 11:02:43
// Design Name: 
// Module Name: top_spi
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


module spi_master_slave_sel# 
(
    parameter   SPI_CPOH    = 0           , //0：CPOL 0, CPOH 0；CLK空闲低电平，第一个边沿，即上升沿采样
    parameter   SPI_CPOL    = 0           , //1：CPOL 0, CPOH 1；CLK空闲低电平，第二个边沿，即下降沿采样
                                            //2：CPOL 1, CPOH 0；CLK空闲高电平，第一个边沿，即下降沿采样
                                            //3：CPOL 1, CPOH 1；CLK空闲高电平，第二个边沿，即上升沿采样
    parameter   DATA_WIDTH  = 24          ,
    parameter   RDATA_WIDTH = 8           ,
    parameter   REF_RREQ    = 100_000_000 ,
    parameter   SPI_FREQ    = 5_000_000   
 
)
(
input                       sysclk          ,
input                       rst_n           ,
                                
input                       i_spi_sel       ,//i_spi_sel为0时做SPI主机，i_spi_sel为1时做SPI从机
/*做SPI主机时，下列信号有效*/
input                       i_rd_flag       , //读写标志位，0：写操作，1：读操作
input[DATA_WIDTH-1:0]       i_opt_data      , //操作数据{cmd（可选，与从机匹配） + addr + data}
input                       i_opt_start     , //操作开始
output[RDATA_WIDTH-1:0]     o_rd_data       , //读数据
output                      o_rd_val        , //读数据有效
output                      o_done          , //单次操作完成信号
/*SPI物理接口*/
output                      o_spi_dir0      ,
output                      o_spi_dir1      ,
inout                       io_csn          ,
inout                       io_spi_clk      ,
inout                       io_mosi         ,
inout                       io_miso
);




wire        i_csn     ;
wire        i_spi_clk ;
wire        i_mosi    ;
wire        o_miso    ;
 
wire        o_csn     ;
wire        o_spi_clk ;
wire        o_mosi    ;
wire        i_miso    ;

wire        o_oe      ;

assign o_spi_dir0 = i_spi_sel ? 1'b0 : 1'b1     ;
assign o_spi_dir1 = !o_spi_dir0                 ;

assign io_csn     = i_spi_sel ? 1'bz : o_csn    ;
assign io_spi_clk = i_spi_sel ? 1'bz : o_spi_clk;
assign io_mosi    = i_spi_sel ? 1'bz : o_mosi   ;
assign io_miso    = i_spi_sel ? o_miso : 1'bz   ;

assign i_csn      = io_csn     ;
assign i_spi_clk  = io_spi_clk ;
assign i_mosi     = io_mosi    ;

assign i_miso     = io_miso    ;



spi_master_wire4 #(
    .SPI_CPOH    (SPI_CPOH       ),
    .SPI_CPOL    (SPI_CPOL       ),
    .DATA_WIDTH  (DATA_WIDTH     ),
    .RDATA_WIDTH (RDATA_WIDTH    ),
    .REF_RREQ    (REF_RREQ       ),
    .SPI_FREQ    (SPI_FREQ       )
) u_spi_master_wire4 (
    .sys_clk     (sysclk         ),
    .rst_n       (rst_n          ),
    .i_rd_flag   (i_rd_flag      ),
    .i_opt_data  (i_opt_data     ),
    .i_opt_start (i_opt_start    ),
    .o_rd_data   (o_rd_data      ),
    .o_rd_val    (o_rd_val       ),
    .o_done      (o_done         ),
    .o_oe        (o_oe           ),
    .o_cs_n      (o_csn          ),
    .o_sck       (o_spi_clk      ),
    .i_miso      (i_miso         ),
    .o_mosi      (o_mosi         )
);

spi_slave_wire4 u_spi_slave_wire4
(
    .sysclk      (sysclk          ),
    .i_csn       (i_csn           ),
    .i_spi_clk   (i_spi_clk       ),
    .i_mosi      (i_mosi          ),
    .o_miso      (o_miso          )
);


endmodule
