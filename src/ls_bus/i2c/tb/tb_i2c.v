`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/31 14:17:01
// Design Name: 
// Module Name: tb_IIC
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
////////////////////////////////////////////// ////////////////////////////////////


module tb_i2c;


reg         sysclk      ;
reg         rst_n       ;
reg         w_en    ;
reg         r_en    ;


reg         i2c_mode    ;
reg  [ 6:0] slave_addr  ;
reg  [15:0] word_addr   ;
reg  [7:0]  i2c_data_w  ;
wire [7:0]  i2c_data_r  ;

wire        w_done     ;
wire        r_valid     ;

wire        sda         ;
wire        scl         ;

wire        opt_start   ;
reg         rd_flag     ;

wire        s_wr_val    ;
wire  [7:0] s_wr_data   ;
wire [15:0] s_wr_addr   ;
                        
reg   [7:0] s_rd_data   ;
wire [15:0] s_rd_addr   ;
 

reg  [ 7:0] addr_5      ;
reg  [ 7:0] addr_6      ;

always #2.5 sysclk = ~sysclk;

initial begin
    sysclk    = 'd0        ;
    rst_n      = 'd0        ;
    w_en   = 'd0        ;
    r_en   = 'd0        ;
    rd_flag = 1'b0          ;
                            
    i2c_mode   = 'd1        ;
    slave_addr = 7'b1010_000;
    word_addr  = 'd0        ;
    i2c_data_w = 'd0        ;
#1000
    rst_n      = 'b1        ;
#100
    w_en   = 'b1        ;
    word_addr  = 'd6        ;
    i2c_data_w = 'hab     ;
#5
    w_en   = 'b0        ;
#400000
    w_en   = 'b1        ;
    word_addr  = 'd5        ;
    i2c_data_w = 'hcd     ;
#5
    w_en   = 'b0        ;
#400000
    rd_flag = 1'b1      ;
    r_en   = 'b1        ;
    word_addr  = 'd6        ;
#5
    r_en   = 'b0        ;
#400000
    r_en   = 'b1        ;
    word_addr  = 'd5        ;
#5
    r_en   = 'b0        ;
    
    #400000
    r_en       = 'b1        ;
    word_addr  = 'd0        ;
    #5
    r_en       = 'b0        ;

    #400000
    r_en       = 'b1        ;
    word_addr  = 'd1        ;
    #5
    r_en       = 'b0        ;

    #400000
    r_en       = 'b1        ;
    word_addr  = 'd2        ;
    #5
    r_en       = 'b0        ;
    
    #400000
    r_en       = 'b1        ;
    word_addr  = 'd3        ;
    #5
    r_en       = 'b0        ;
    
    #400000
    r_en       = 'b1        ;
    word_addr  = 'd4        ;
    #5
    r_en       = 'b0        ;
end


assign opt_start = w_en | r_en;

i2c_master
#(
    .CLK_FR       ('d200_000_000),//时钟频率
    .I2C_CLK_FR   ('d200_000    ),//输出IIC时钟频率
    .REG_ADDR_NUM ('d2          ),//WORD_ADDR_NUM 为1时字地址为8位，WORD_ADDR_NUM 为2时字地址为16位
    .WR_LEN       ('d1          ),//需要写入的字节长度，字节长度等于WR_LEN,最多支持256个字节长度
    .RD_LEN       ('d1          ) //需要读取的字节长度，字节长度等于RD_LEN,最多支持256个字节长度
)u_i2c_master
(
    .sys_clk      (sysclk      ),
    .rst_n        (rst_n        ),

    .i_opt_start   (opt_start     ),
    .i_rd_flag     (rd_flag     ),

    .i_i2c_slave_addr (slave_addr   ),
    .i_i2c_reg_addr    (word_addr    ),
    .i_i2c_wr_data   (i2c_data_w   ),
    .o_i2c_rd_data   (i2c_data_r   ),

    .o_i2c_rd_val      (r_valid      ),
    
    .o_done            (                ),
    .o_busy            (               ),
    .o_err             (               ),
    .i_mode            (1'b1           ), //i2c_mode为1时进行随机读操作，i2c_mode为0时进行页读操作
 

    .io_sda          (sda          ),
    .o_scl          (scl          )
 );


i2c_slave#
(

    .REG_ADDR_NUM    ( 2 )          //REG_ADDR_NUM为1时，字节地址为8位，REG_ADDR_NUM为2时，字节地址为16位

)
u_i2c_slave
(
    .sys_clk         (sysclk),
    .rst_n           (rst_n),
    .i_slave_addr    (slave_addr),
    //写数据解析     
    .o_wr_val        (s_wr_val ),
    .o_wr_data       (s_wr_data),
    .o_wr_addr       (s_wr_addr),
    //读数据解析     
    .i_rd_data       (s_rd_data),
    .o_rd_addr       (s_rd_addr),
    //I2C接口      
    .io_sda          (sda),
    .i_scl           (scl)
   
);


//
always@(posedge sysclk or negedge rst_n)
begin
    if(!rst_n)
    begin
        addr_5 <= 8'd0;
    end
    else 
    begin
        if(s_wr_val == 1'b1 && s_wr_addr == 16'h5)
            addr_5 <= s_wr_data;
    end
end

always@(posedge sysclk or negedge rst_n)
begin
    if(!rst_n)
    begin
        addr_6 <= 8'd0;
    end
    else 
    begin
        if(s_wr_val == 1'b1 && s_wr_addr == 16'h6)
            addr_6 <= s_wr_data;
    end
end

//rom
always@(*)
begin
    case(s_rd_addr)
        16'h00: s_rd_data <= 8'h7F;
        16'h01: s_rd_data <= 8'h01;
        16'h02: s_rd_data <= 8'h02;
        16'h03: s_rd_data <= 8'h03;
        16'h04: s_rd_data <= 8'h04;
        16'h05: s_rd_data <= addr_5;
        16'h06: s_rd_data <= addr_6;
    default: s_rd_data <= 'd0;
    endcase
end



endmodule
