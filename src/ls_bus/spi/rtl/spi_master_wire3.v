`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:56:34 05/08/2017 
// Design Name: 
// Module Name:    spi_master_wire4 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//     ADDR + DATA，位宽可自定义
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Revision 0.02 - 拆分3线和4线
// Revision 0.03 - 增加四种模式选择
// Additional Comments: 
//////////////////////////////////////////////////////////////////////////////////
`define XILINX_CHIP
module spi_master_wire3 # 
(
    parameter   SPI_CPHA    = 0           , //0：CPOL 0, CPHA 0；CLK空闲低电平，第一个边沿，即上升沿采样
    parameter   SPI_CPOL    = 0           , //1：CPOL 0, CPHA 1；CLK空闲低电平，第二个边沿，即下降沿采样
                                            //2：CPOL 1, CPHA 0；CLK空闲高电平，第一个边沿，即下降沿采样
                                            //3：CPOL 1, CPHA 1；CLK空闲高电平，第二个边沿，即上升沿采样
    parameter   DATA_WIDTH  = 24          ,
    parameter   RDATA_WIDTH = 8           ,
    parameter   REF_RREQ    = 100_000_000 ,
    parameter   SPI_FREQ    = 5_000_000   
 
)
(

    sys_clk                 , //系统主时钟
    rst_n                   , //系统复位信号
    //应用接口
    i_rd_flag               , //读写标志位，0：写操作，1：读操作
    i_opt_data              , //操作数据{cmd（可选，与从机匹配） + addr + data}
    i_opt_start             , //操作开始
    o_rd_data               , //读数据
    o_rd_val                , //读数据有效
    o_done                  , //单次操作完成信号
    o_oe                    , //三态门开关，0为主机控制，1为从机控制
    //SPI四线信号
    o_cs_n                  , //片选信号
    o_sck                   , //总线时钟
    io_data
//    i_miso                  , //主机输入从机输出
//    o_mosi                    //主机输出从机输入
    
);

input                     sys_clk         ; //系统主时钟
input                     rst_n           ; //系统复位信号
    //应用接口
input                     i_rd_flag       ; //读写标志位，0：写操作，1：读操作
input[DATA_WIDTH-1:0]     i_opt_data      ; //操作数据{cmd（可选，与从机匹配） + addr + data}
input                     i_opt_start     ; //操作开始
output[RDATA_WIDTH-1:0]   o_rd_data       ; //读数据
output                    o_rd_val        ; //读数据有效
output                    o_done          ; //单次操作完成信号
output                    o_oe            ; //三态门开关，0为主机控制，1为从机控制
//SPI四线信号
output                    o_cs_n          ; //片选信号
output                    o_sck           ; //总线时钟
inout                     io_data         ; //三线数据总线
//input                     i_miso          ; //主机输入从机输出
//output                    o_mosi          ; //主机输出从机输入

localparam  END_CNT = REF_RREQ/SPI_FREQ -1;
localparam  MID_CNT = (END_CNT+1)/2 -1;

reg[ 7:0]            clk_cnt             ;
reg[ 7:0]            opt_cnt             ;
         
reg                  opt_start_ff1       ;
reg                  opt_start_ff2       ;
wire                 opt_start           ;

reg[DATA_WIDTH-1:0]  treg_dat            ;
reg[RDATA_WIDTH-1:0] rreg_dat            ;
reg[RDATA_WIDTH-1:0] rd_data             ;
reg                  rd_val              ;

reg                  cs_n                ;
reg                  cs_n_ff1            ;
reg                  cs_n_ff2            ;
reg                  sck                 ;
reg                  sck_ff              ;
reg                  done                ;
reg                  oe                  ;
reg                  oe_ff               ;
reg                  rd_dir              ;
reg                  clk_edg_det         ;

wire                 miso_buf            ;
reg                  mosi                ;
reg                  miso                ;

assign  o_rd_data   =  rd_data      ;
assign  o_rd_val    =  rd_val       ;
assign  o_done      =  done         ;
assign  o_cs_n      =  cs_n_ff1 & cs_n_ff2     ;
assign  o_sck       =  sck_ff       ;
assign  o_mosi      =  mosi         ;
assign  o_oe        =  oe_ff        ;

`ifdef XILINX_CHIP
IOBUF #(
   .DRIVE(12), // Specify the output drive strength
   .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
   .IOSTANDARD("DEFAULT"), // Specify the I/O standard
   .SLEW("SLOW") // Specify the output slew rate
) IOBUF_inst (
   .O    (miso_buf),     // Buffer output
   .IO   (io_data),   // Buffer inout port (connect directly to top-level port)
   .I    (mosi),     // Buffer input
   .T    (oe_ff)      // 3-state enable input, high=input, low=output
);
`else

//三线spi
assign  io_data     =  oe_ff ? 1'bz : mosi ;
assign  miso_buf    =  oe_ff ? io_data : 1'b0;
`endif

//三态门开关，0为主机控制，1为从机控制
always @ *
begin
    if(cs_n_ff1 == 1'b0 && opt_cnt > (DATA_WIDTH - RDATA_WIDTH - 1)  && rd_dir)
        oe <= 'b1;
    else
        oe <= 'b0;
end

//片选信号打拍
always@(posedge sys_clk)
begin
    if(!rst_n)
    begin
        oe_ff <= 1'b0;
    end
    else
    begin
        oe_ff <= oe;
    end
end

//输入数据打拍
always@(posedge sys_clk)
begin
    miso <= miso_buf;
end

//开始信号边沿检测
assign  opt_start = (~opt_start_ff2 && opt_start_ff1);

always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        opt_start_ff1 <= 1'b0;
        opt_start_ff2 <= 1'b0;
    end
    else
    begin
        opt_start_ff1   <= i_opt_start;
        opt_start_ff2   <= opt_start_ff1;
    end
end

//片选信号打拍
always@(posedge sys_clk)
begin
    if(!rst_n)
    begin
        cs_n_ff1 <= 1'b1;
        cs_n_ff2 <= 1'b1;
    end
    else
    begin
        cs_n_ff1 <= cs_n;
        cs_n_ff2 <= cs_n_ff1;
    end
end

//时钟信号打拍
always@(posedge sys_clk)
begin
    if(!rst_n)
    begin
        sck_ff <= SPI_CPOL;
    end
    else
    begin
        sck_ff <= sck;
    end
end

//CLK边沿个数检测，边沿为2时使用
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        clk_edg_det <= 'd0;
    end
    else
    begin
        if(cs_n == 1'b0 && clk_cnt == MID_CNT)
            clk_edg_det <= 1'b1;
        else if(cs_n == 1'b1)
            clk_edg_det <= 'd0;
    end
end

generate
    //MID_CNT 为第一个沿
    //END_CNT 为第二个沿
    if(SPI_CPHA == 1) //第二个边沿，即使用clk_edg_det判断
    begin
        //片选信号产生
        always@(posedge sys_clk or negedge rst_n)
        begin
            if(!rst_n)
            begin
                cs_n <= 1'b1;
            end
            else
            begin
                if(opt_start)
                    cs_n <= 1'b0;
                else if(opt_cnt == DATA_WIDTH - 1 && clk_cnt == (MID_CNT -1))
                    cs_n <= 1'b1;
            end
        end
        
        //mosi信号产生计数
        always@(posedge sys_clk or negedge rst_n)
        begin
            if(!rst_n)
            begin
                opt_cnt <= 'd0;
            end
            else
            begin
                if(cs_n == 1'b0 && clk_cnt == MID_CNT && clk_edg_det == 1'b1)
                begin
                    if(opt_cnt == DATA_WIDTH - 1)
                        opt_cnt <= opt_cnt;
                    else
                        opt_cnt <= opt_cnt + 1'b1;
                end
                else if(cs_n == 1'b1 )
                    opt_cnt <= 'd0;
            end
        end
        
        //接收从机数据
        always@(posedge sys_clk or negedge rst_n)
        begin
            if(!rst_n)
            begin
                rreg_dat <= 'd0;
            end
            else                                                  
            begin                                              
                if(cs_n == 1'b0 && opt_cnt > (DATA_WIDTH - RDATA_WIDTH - 1))
                begin
                    if(clk_cnt == END_CNT)
                        rreg_dat <= {rreg_dat[RDATA_WIDTH-2:0], miso} ;
                end
            end
        end
        
    end
    else
    begin
        //片选信号产生
        always@(posedge sys_clk or negedge rst_n)
        begin
            if(!rst_n)
            begin
                cs_n <= 1'b1;
            end
            else
            begin
                if(opt_start)
                    cs_n <= 1'b0;
                else if(opt_cnt == DATA_WIDTH - 1 && clk_cnt == (END_CNT -1))
                    cs_n <= 1'b1;
            end
        end
        
        //mosi信号产生计数
        always@(posedge sys_clk or negedge rst_n)
        begin
            if(!rst_n)
            begin
                opt_cnt <= 'd0;
            end
            else
            begin
                if(cs_n == 1'b0 && clk_cnt == END_CNT)
                begin
                    if(opt_cnt == DATA_WIDTH - 1)
                        opt_cnt <= opt_cnt;
                    else
                        opt_cnt <= opt_cnt + 1'b1;
                end
                else if(cs_n == 1'b1 )
                    opt_cnt <= 'd0;
            end
        end
        
        //接收从机数据
        always@(posedge sys_clk or negedge rst_n)
        begin
            if(!rst_n)
            begin
                rreg_dat <= 'd0;
            end
            else                                                  
            begin                                              
                if(cs_n == 1'b0 && opt_cnt > (DATA_WIDTH - RDATA_WIDTH - 1))
                begin
                    if(clk_cnt == MID_CNT)
                        rreg_dat <= {rreg_dat[RDATA_WIDTH-2:0], miso} ;
                end
            end
        end
        
    end
endgenerate

//时钟分频计数，END_CNT为分频的一个周期
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        clk_cnt <= 'd0;
    end
    else
    begin
        if(cs_n == 1'b0)
        begin
            if(clk_cnt == END_CNT)
               clk_cnt <= 'd0;
            else
                clk_cnt  <= clk_cnt  + 1'b1; 
        end
        else
            clk_cnt <= 'd0; 
    end
end

//时钟信号产生，根据初始CPOL设置在MID_CNT和END_CNT进行时钟翻转，MID_CNT即半个SCK时钟周期数
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        sck <= SPI_CPOL;
    end
    else
    begin
        if(cs_n == 1'b0)
        begin
            if(clk_cnt == MID_CNT)
               sck <= ~sck;
            else if(clk_cnt == END_CNT)
               sck <= ~sck; 
        end
        else
            sck <= SPI_CPOL;
    end
end

//读标志寄存
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
        rd_dir <= 'b0;
    else if(opt_start)
        rd_dir <= i_rd_flag;
end

//MOSI信号产生
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        treg_dat <= 'd0;
        mosi     <= 1'b0;
    end
    else 
    begin
        if(opt_start)
        begin
            treg_dat       <= i_opt_data;
            mosi           <= 1'b0; 
        end
        else if(cs_n == 1'b0)
        begin
            if(SPI_CPHA == 1'b1)
            begin
                if(clk_edg_det == 1'b1)
                    mosi <= treg_dat[DATA_WIDTH - 1 - opt_cnt];
            end
            else 
                mosi <= treg_dat[DATA_WIDTH - 1 - opt_cnt];
        end
        else if(cs_n == 1'b1)
        begin
            treg_dat       <= treg_dat;
            mosi           <= 1'b0; 
        end
    end
end

//单次操作完成信号
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        done <= 1'b0;
    end
    else
    begin
        if(~cs_n_ff2 && cs_n_ff1)
        begin
            done <= 1'b1;
        end
        else
        begin
            done    <= 1'b0;
        end
    end
end

//数据读出
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        rd_val   <= 1'b0;
        rd_data  <= 'd0;
    end
    else
    begin
        if(~cs_n_ff2 && cs_n_ff1)
        begin
            if(rd_dir)
            begin
                rd_val   <= 1'b1;
                rd_data  <= rreg_dat;
            end
        end
        else
        begin
            rd_val   <= 1'b0;
            rd_data  <= rd_data;
        end
    end
end
    
endmodule