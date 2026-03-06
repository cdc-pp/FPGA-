`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/31 17:22:22
// Design Name: 
// Module Name: spi_slave_4wire
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - 修改接口命令，并将内部rom移出模块，将寄存器读写部分放在模块外，提高模块应用的灵活度
// Additional Comments:
//    该模块当前只支持主机SPI为模式0，SPI_CPOH = 0，SPI_CPOL = 0
//    每次通信为24位的信息传输，1位读写控制位（0写1读），15位地址位，8位数据位
//    WR/RD     ADDR    DATA
//    1bit      15bit   8bit
//    WR：1'b0
//    RD：1'b1
//////////////////////////////////////////////////////////////////////////////////

module spi_slave_wire3#
(
    parameter DEBUG          = 1'b0  ,
    parameter REG_ADDR_WIDTH = 8'd16 ,
    parameter REG_DATA_WIDTH = 8'd8
    
)
(
    input                                 sys_clk        , 
    input                                 i_spi_cs_n     ,
    input                                 i_spi_clk      ,
    inout                                 io_spi_data    ,
    //读数据解析                         
    input     [REG_DATA_WIDTH - 1 : 0]    i_rd_data      ,
    output    [REG_ADDR_WIDTH - 2 : 0]    o_rd_addr      ,
    //写数据解析
    output    [REG_DATA_WIDTH - 1 : 0]    o_wr_data      ,
    output    [REG_ADDR_WIDTH - 2 : 0]    o_wr_addr      ,
    output                                o_wr_vl 
    
);

/*spi从机默认设定：i_spi_clk的第一个上升沿开始采样，每次通信为24位的信息传输，1位读写控制位（0写1读），15位地址位，8位数据位*/

reg     [7:0]                       cnt             ;
reg                                 wr_flag         ;
                                                    
reg                                 rd_flag         ;
reg                                 spi_clk_d0      ;
reg                                 spi_clk_d1      ;
reg                                 spi_clk_d2      ;
reg                                 spi_cs_n_d1     ;
reg                                 spi_cs_n_d2     ;
reg     [REG_ADDR_WIDTH - 1 : 0]    spi_addr        ;
reg     [REG_ADDR_WIDTH - 2 : 0]    rd_addr = 'd0   ;
reg     [REG_DATA_WIDTH - 1 : 0]    wr_data         ;
                                
wire                                spi_clk_pe      ;
wire                                spi_clk_ne      ;
wire                                ena             ;
reg                                 spi_miso        ;
reg                                 spi_dir = 'd1   ;
assign ena = cnt == 8'd255 & spi_cs_n_d2;
assign o_spi_miso = spi_miso   ;
 
assign o_rd_addr = rd_addr;
assign o_wr_data = (wr_flag && ena) ? wr_data  : 'd0 ;
assign o_wr_addr = (wr_flag && ena) ? spi_addr[REG_ADDR_WIDTH - 2 : 0] : 'd0 ;
assign o_wr_vl   = wr_flag && ena  ;

//采集spi时钟上升沿与下降沿
assign spi_clk_pe =  spi_clk_d1 & !spi_clk_d2;
assign spi_clk_ne = !spi_clk_d1 &  spi_clk_d2;

//异步时钟信号采集去除亚稳态
always @(posedge sys_clk)
begin
    spi_clk_d0 <= i_spi_clk ;
    spi_clk_d1 <= spi_clk_d0;
    spi_clk_d2 <= spi_clk_d1;
end

always @(posedge sys_clk)
begin
    spi_cs_n_d1 <= i_spi_cs_n;
    spi_cs_n_d2 <= spi_cs_n_d1;
end
//方向控制
   IOBUF #(
      .DRIVE(12), // Specify the output drive strength
      .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
      .IOSTANDARD("DEFAULT"), // Specify the I/O standard
      .SLEW("SLOW") // Specify the output slew rate
   ) IOBUF_inst (
      .O(i_spi_mosi),     // Buffer output
      .IO(io_spi_data),   // Buffer inout port (connect directly to top-level port)
      .I(spi_miso),     // Buffer input
      .T(spi_dir)      // 3-state enable input, high=input, low=output
   );


always @(posedge sys_clk) 
begin
    if(spi_cs_n_d2)
        spi_dir <= 1'b1;
    else if(rd_flag && (cnt == (REG_DATA_WIDTH - 1)))
    begin 
        spi_dir <= 1'b0;
    end
end
//默认设定：地址最高位为0主机向从机写入数据，地址最高位为1主机向从机读取数据
always @(posedge sys_clk) 
begin
    if (spi_cs_n_d2) 
    begin
        wr_flag  <= 1'b0;
    end
    else 
    begin
        wr_flag <= ~spi_addr[REG_ADDR_WIDTH - 1];
    end
end
always @(posedge sys_clk) 
begin
    if (spi_cs_n_d2) 
    begin
        rd_flag  <= 1'b0;
    end
    else 
    begin
        rd_flag <= spi_addr[REG_ADDR_WIDTH - 1];
    end
end

//通过计数器辨别寻址阶段与数据读写阶段
always @(posedge sys_clk)
begin
    if (spi_cs_n_d2) 
    begin
        cnt <= REG_ADDR_WIDTH + REG_DATA_WIDTH - 1;
    end

    else if (spi_clk_pe)
    begin
        cnt <= cnt + 8'd255;
    end
    else begin
        cnt <= cnt;
    end
end


//寄存主机要访问的地址
always @(posedge sys_clk) 
begin
    if (spi_cs_n_d2) 
    begin
        spi_addr <= {REG_ADDR_WIDTH{1'b0}};
    end
    else if (spi_clk_pe & cnt > (REG_DATA_WIDTH - 1) )
    begin
        spi_addr[cnt - REG_DATA_WIDTH]<= i_spi_mosi;
    end
    else 
    begin
        spi_addr <= spi_addr;
    end
end

always @(posedge sys_clk) 
begin
    if(rd_flag && (cnt == (REG_DATA_WIDTH - 1)))
    begin 
        rd_addr <= spi_addr[REG_ADDR_WIDTH - 2 : 0];
    end
    else 
    begin
        rd_addr <= rd_addr;
    end
end

//寄存主机需要写入的数据
always @(posedge sys_clk) 
begin
    if (spi_cs_n_d2) 
    begin
        wr_data <= {REG_DATA_WIDTH{1'b0}};
    end
    else if (spi_clk_pe & cnt < REG_DATA_WIDTH ) 
    begin
        wr_data[cnt] <= i_spi_mosi;
    end
    else 
    begin
        wr_data <= wr_data;
    end
end

//输出主机需要读取的数据
always @(posedge sys_clk) 
begin
    if (spi_cs_n_d2) 
    begin
        spi_miso <= 1'b0;
    end
    else if (spi_clk_ne & cnt < REG_DATA_WIDTH & rd_flag )
    begin
        spi_miso <= i_rd_data[cnt];
    end
    else begin
        spi_miso <= spi_miso;
    end
end

//generate
//    if(DEBUG)
//    begin
//        ila_64b_16k u_ila_64b_16k 
//        (
//        
//            .clk        (sys_clk), // input wire clk
//            .probe0     ({spi_cs_n_d2, i_spi_clk, i_spi_mosi, o_spi_miso, i_rd_data, o_rd_addr, o_wr_data, o_wr_addr, o_wr_vl, cnt}) // input wire [63:0] probe0
//        );                  
//    end
//endgenerate

endmodule