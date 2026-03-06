
`timescale 1ns / 1ps

module tb_spi_master_wire3();

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
wire                io_data      ;
wire                o_oe         ;

reg                 io_data_reg  ;

assign io_data = o_oe ? io_data_reg : 1'bz;

spi_master_wire3 #  //下降沿沿变数，上升沿采数//
(
    .SPI_CPOH    (0   ),
    .SPI_CPOL    (1   )
 
)
u_spi_master_wire3
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
    .io_data                 (io_data     )
    
);


initial
begin

    sys_clk      = 1'b0;
    rst_n        = 1'b0;
    i_opt_data   = 24'b1010_1010_1010_1010_1010_1010;
    i_opt_start  = 1'b0;
    i_rd_flag    = 1'b1;


    #100
    rst_n        = 1'b1;
    
    #100
    i_opt_start  = 1'b1;
    #10
    i_opt_start  = 1'b0;

end

always #5 sys_clk <= ~sys_clk;

always@(posedge sys_clk)
begin
    if(o_oe == 1'b1)
        io_data_reg <= 1'b1;
    else 
        io_data_reg <= 1'b0;
end


endmodule