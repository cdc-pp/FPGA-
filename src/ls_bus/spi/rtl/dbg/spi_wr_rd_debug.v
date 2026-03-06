`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/12 17:09:30
// Design Name: 
// Module Name: spi_wr_rd_debug
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
//     SPI循环读写验证
//     读地址15'h7878
//     将读到的数据写到地址15'h3CBC
//////////////////////////////////////////////////////////////////////////////////

module spi_wr_rd_debug#(
    
    parameter DEBUG = 0
    
)
(

    input               sys_clk          ,
    input               rst_n            ,
        
    output              o_spi_clk        ,
    output              o_spi_cs_n       ,
    output              o_spi_mosi       ,
    input               i_spi_miso      

);

reg                   rd_flag     ;
reg     [23:0]        opt_data    ;
reg                   opt_start   ;
wire    [ 7:0]        rd_data     ;
wire                  rd_val      ;
wire                  done        ;

reg                   dly_start   ;
wire                  dly_done    ;

reg     [ 4:0]        cur_state   ;
reg     [ 4:0]        nex_state   ;

localparam IDLE_STA   = 5'b00000;
localparam RD_STA     = 5'b00010;
localparam RD_DLY_STA = 5'b00100;
localparam WR_STA     = 5'b01000;
localparam WR_DLY_STA = 5'b10000;

//状态机
always @(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        cur_state <= IDLE_STA;
    end
    else
    begin
        cur_state <= nex_state;
    end
end

always@ (*)
begin
    case(cur_state)
        IDLE_STA:
        begin
            nex_state = RD_STA;
        end
        RD_STA:
        begin
            if(done == 1'b1)
            begin
                nex_state = RD_DLY_STA;
            end
            else
            begin
                nex_state = RD_STA;
            end
        end
        RD_DLY_STA:
        begin
            if(dly_done == 1'b1)
            begin
                nex_state = WR_STA;
            end
            else
            begin
                nex_state = RD_DLY_STA;
            end
        end
        WR_STA:
        begin
            if(done == 1'b1)
            begin
                nex_state = WR_DLY_STA;
            end
            else
            begin
                nex_state = WR_STA;
            end
        end
        WR_DLY_STA:
        begin
            if(dly_done == 1'b1)
            begin
                nex_state = IDLE_STA;
            end
            else
            begin
                nex_state = WR_DLY_STA;
            end
        end
        default:
        begin
            nex_state = IDLE_STA;
        end
    endcase
end

//控制延时开始
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        dly_start <= 1'b0;
    end
    else 
    begin
        if(cur_state == RD_DLY_STA)
        begin
            dly_start <= 1'b1;
        end
        else if(cur_state == WR_DLY_STA)
        begin
            dly_start <= 1'b1;
        end
        else 
        begin
            dly_start <= 1'b0;
        end
    end
end

//控制SPI读写数据
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        rd_flag    <= 'd0;
        opt_data   <= 'd0;
        opt_start  <= 'd0; 
    end
    else 
    begin
        if(cur_state == RD_STA)
        begin
            rd_flag    <= 1'b1;
            opt_data   <= {1'b1, 15'h7878, 8'd0};
            opt_start  <= 1'b1;  
        end
        else if(cur_state == WR_STA)
        begin 
            rd_flag    <= 1'b0;
            opt_data   <= {1'b0, 15'h3CBC, rd_data};
            opt_start  <= 1'b1;  
        end
        else 
        begin
            rd_flag    <= rd_flag;
            opt_data   <= opt_data;
            opt_start  <= 1'b0;  
        end
    end
end
 
delay_ms #
(

    .REF_CLK_FREQ            (100         ), //参考时钟频率，单位为Mhz
    .DELAY_MS_VAL            (100         )  //单位为MS
                                          
)                                         
u_delay_ms                                
(                                         
                                          
    .clk                     (sys_clk     ), 
    .rst_n                   (dly_start   ), 
    .o_dly_ms_done           (dly_done    )
                                          
);                                        
                                          
spi_master_wire4 #                        
(                                         
                                          
    .SPI_FREQ                (1_000_000   )

)
u_spi_master_wire4
(

    .sys_clk                 (sys_clk     ), //系统主时钟
    .rst_n                   (rst_n       ), //系统复位信号
    //应用接口               
    .i_rd_flag               (rd_flag     ), //读写标志位，0：写操作，1：读操作
    .i_opt_data              (opt_data    ), //操作数据{cmd（可选，与从机匹配） + addr + data}
    .i_opt_start             (opt_start   ), //操作开始
    .o_rd_data               (rd_data     ), //读数据
    .o_rd_val                (rd_val      ), //读数据有效
    .o_done                  (done        ), //单次操作完成信号
    .o_oe                    (            ), //三态门开关，0为主机控制，1为从机控制
    //SPI四线信号            
    .o_cs_n                  (o_spi_cs_n  ), //片选信号
    .o_sck                   (o_spi_clk   ), //总线时钟
    .i_miso                  (i_spi_miso  ), //主机输入从机输出
    .o_mosi                  (o_spi_mosi  )  //主机输出从机输入
    
); 

generate
    if(DEBUG == 1)
    begin 
        ila_128b u_spi_debug (
            .clk    (sys_clk), // input wire clk
            
            
            .probe0 ({o_spi_cs_n, o_spi_clk, i_spi_miso, o_spi_mosi, rd_flag, opt_data, opt_start, 
                      rd_data, rd_val, done, cur_state}) // input wire [127:0] probe0
        );                                                             
    end                                                               
                                                                        
endgenerate                                                              
endmodule                                                                  
