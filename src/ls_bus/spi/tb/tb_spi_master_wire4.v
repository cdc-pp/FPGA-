
`timescale 1ns / 1ps

module tb_spi_master_wire4();

reg                 sys_clk      ;
reg                 rst_n        ;
reg     [23:0]      i_opt_data   ;
reg                 i_opt_start  ;
wire    [ 7:0]      o_rd_data    ;
wire                o_rd_val     ;
wire                o_done       ;
reg                 i_rd_flag    ;
wire                o_cs_n       ;
wire                o_sck        ;
reg                 i_miso       ;
wire                o_mosi       ;
wire                o_oe         ;

spi_master_wire4 #  //下降沿沿变数，上升沿采数//
(
    .SPI_CPOH    (0   ),
    .SPI_CPOL    (1   )
 
)
u_spi_master_wire4
(
    .sys_clk                 (sys_clk     ),  //100mhz
    .rst_n                   (rst_n       ),
    .i_opt_data              (i_opt_data  ),
    .i_opt_start             (i_opt_start ),
    .o_rd_data               (o_rd_data   ),
    .o_rd_val                (o_rd_val    ),
    .o_done                  (o_done      ),
    .o_oe                    (o_oe        ),
    .i_rd_flag               (i_rd_flag   ),
    .o_cs_n                  (o_cs_n      ),
    .o_sck                   (o_sck       ),
    .i_miso                  (i_miso      ),
    .o_mosi                  (o_mosi      )
);


initial
begin

    sys_clk      = 1'b0;
    rst_n        = 1'b0;
    i_opt_data   = 24'b1010_1010_1010_1010_1010_1010;
    i_opt_start  = 1'b0;
    i_rd_flag    = 1'b1;
    i_miso       = 1'b1;


    #100
    rst_n        = 1'b1;
    
    #100
    i_opt_start  = 1'b1;
    #10
    i_opt_start  = 1'b0;

end

always #5 sys_clk <= ~sys_clk;


endmodule