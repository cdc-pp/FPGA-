`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/10 17:55:27
// Design Name: 
// Module Name: cfg_top
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


module chip_cfg_top#
(
    parameter INTERFACE_SEL = 1        ,

    parameter DATA_WIDTH    = 16        ,
    parameter RDATA_WIDTH   = 8         ,
    parameter CFG_WIDTH     = 10        ,
    parameter WDLY_PAR      = 255       ,
    parameter RDLY_PAR      = 65535     ,
    parameter DLY_PAR       = 2000000   ,

    parameter SPI_CPHA      = 0         ,
    parameter SPI_CPOL      = 0         ,
    parameter REF_RREQ      = 100000000 ,
    parameter SPI_FREQ      = 5000000
    
)
(
    input                      sys_clk          ,
    input                      rst_n            ,
    input [(DATA_WIDTH-1)+2:0] i_cfg_data       ,
    input [CFG_WIDTH-1:0]      i_cfg_end_num    ,
    input                      i_re_cfg_en      , //重新配置使能
    input  [CFG_WIDTH-1:0]     i_re_cfg_addr    , //重新配置地址起始
    output                     o_re_cfg_done    ,
    input                      i_rd_done        ,
    input                      i_wait_done      ,
    output [CFG_WIDTH-1:0]     o_cfg_addr       ,
    output                     o_cfg_over       ,
    output [RDATA_WIDTH-1:0]   o_rd_data        ,
    output                     o_rd_val         ,
    output                     o_cs_n           ,
    output                     o_sck            ,
    //四线模式  
    output                     o_mosi           ,
    input                      i_miso           ,
    //三线模式  
    input                      io_data          ,
        
    //用户配置接口    
    input [(DATA_WIDTH+2)-1:0] i_usr_cfg_data   ,
    input                      i_usr_cfg_en     ,
    input                      i_usr_cfg_val    ,
    output                     o_usr_cfg_done   ,
    output [RDATA_WIDTH-1:0]   o_usr_rd_data    ,
    output                     o_usr_rd_val      

);

wire  [DATA_WIDTH-1:0]             cmd_data            ;
wire                               opt_start           ;
wire                               opt_done            ;
wire                               cfg_rd_flag         ;
wire  [RDATA_WIDTH-1:0]            rd_data             ;
wire                               rd_val              ;

//debug 预留用户配置接口

wire  [(DATA_WIDTH+2)-1:0]         i_usr_cfg_data      ;
wire                               i_usr_cfg_en        ;
wire                               i_usr_cfg_val       ;
wire                               o_usr_cfg_done      ;

assign o_rd_data = rd_data ;
assign o_rd_val  = rd_val  ;

chip_cfg_bk #(
    .DATA_WIDTH     (DATA_WIDTH    ),
    .RDATA_WIDTH    (RDATA_WIDTH   ),
    .CFG_WIDTH      (CFG_WIDTH     ),
    .WDLY_PAR       (WDLY_PAR      ),
    .RDLY_PAR       (RDLY_PAR      ),
    .DLY_PAR        (DLY_PAR       )
) 
u_chip_cfg_bk 
(
    .sys_clk        (sys_clk       ),
    .rst_n          (rst_n         ),
    .o_cmd_data     (cmd_data      ),
    .o_opt_start    (opt_start     ),
    .i_opt_done     (opt_done      ),
    .o_cfg_addr     (o_cfg_addr    ),
    .i_cfg_data     (i_cfg_data    ),
    .o_cfg_over     (o_cfg_over    ),
    .i_rd_done      (i_rd_done     ),
    .i_wait_done    (i_wait_done   ),
    .o_cfg_rd_flag  (cfg_rd_flag   ),
    .i_rd_data      (rd_data       ),
    .i_rd_val       (rd_val        ),
    .i_cfg_end_num  (i_cfg_end_num ),
    .i_re_cfg_en    (i_re_cfg_en   ),
    .i_re_cfg_addr  (i_re_cfg_addr ),
    .o_re_cfg_done  (o_re_cfg_done ),
    .i_usr_cfg_data (i_usr_cfg_data),
    .i_usr_cfg_en   (i_usr_cfg_en  ),
    .i_usr_cfg_val  (i_usr_cfg_val ),
    .o_usr_cfg_done (o_usr_cfg_done),
    .o_usr_rd_data  (o_usr_rd_data ),
    .o_usr_rd_val   (o_usr_rd_val  )
);

generate
   if (INTERFACE_SEL == 1) begin: spi_wire4
        spi_master_wire4 #(
            .SPI_CPHA    (SPI_CPHA        ),
            .SPI_CPOL    (SPI_CPOL        ),
            .DATA_WIDTH  (DATA_WIDTH      ),
            .RDATA_WIDTH (RDATA_WIDTH     ),
            .REF_RREQ    (REF_RREQ        ),
            .SPI_FREQ    (SPI_FREQ        )
        )                                 
        u_spi_master_wire4                
        (                                 
            .sys_clk     (sys_clk         ),
            .rst_n       (rst_n           ),
            .i_rd_flag   (cfg_rd_flag     ),
            .i_opt_data  (cmd_data        ),
            .i_opt_start (opt_start       ),
            .o_rd_data   (rd_data         ),
            .o_rd_val    (rd_val          ),
            .o_done      (opt_done        ),
            .o_oe        (o_oe            ),
            .o_cs_n      (o_cs_n          ),
            .o_sck       (o_sck           ),
            .i_miso      (i_miso          ),
            .o_mosi      (o_mosi          )
        );
   end 
   else begin: spi_wire3
        spi_master_wire3 #(
            .SPI_CPHA    (SPI_CPHA        ),
            .SPI_CPOL    (SPI_CPOL        ),
            .DATA_WIDTH  (DATA_WIDTH      ),
            .RDATA_WIDTH (RDATA_WIDTH     ),
            .REF_RREQ    (REF_RREQ        ),
            .SPI_FREQ    (SPI_FREQ        )
        ) 
        u_spi_master_wire3 
        (
            .sys_clk     (sys_clk         ),
            .rst_n       (rst_n           ),
            .i_rd_flag   (cfg_rd_flag     ),
            .i_opt_data  (cmd_data        ),
            .i_opt_start (opt_start       ),
            .o_rd_data   (rd_data         ),
            .o_rd_val    (rd_val          ),
            .o_done      (opt_done        ),
            .o_oe        (o_oe            ),
            .o_cs_n      (o_cs_n          ),
            .o_sck       (o_sck           ),
            .io_data     (io_data         )
        );
   end
endgenerate

endmodule
