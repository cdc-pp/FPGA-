`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:26:36 09/27/2024 
// Design Name: 
// Module Name:    iddr_data_bk 
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

module iddr_data_bk#
(
    parameter           IDELAYCTRL_EN =  1 ,
    parameter           IDELAY_VALUE  =  0 ,
    parameter           DATA_WIDTH    =  8 
)
(
    input                               ref_clk                ,
    input                               io_rst                 ,
    input                               data_rst               ,
    input                               clk_bufr               ,
    input                               clk_bufg               ,
    input    [DATA_WIDTH-1:0]           i_lvds_data_p          ,
    input    [DATA_WIDTH-1:0]           i_lvds_data_n          ,
    output   [DATA_WIDTH*2-1:0]         o_data                 ,
    output                              o_data_val
);

//pos_data: {D14, D12, D10, D8, D6, D4, D2, D0}
//neg_data: {D15, D13, D11, D9, D7, D5, D3, D1}
wire    [DATA_WIDTH-1:0]          pos_data          ;
wire    [DATA_WIDTH-1:0]          neg_data          ;
wire    [DATA_WIDTH*2-1:0]        data              ;
reg     [DATA_WIDTH*2-1:0]        ff_wr_data        ;

reg                               ff_wr_en          ;
reg                               ff_rd_en          ;
wire                              ff_empty          ;
wire    [DATA_WIDTH*2-1:0]        ff_rd_data        ;
reg     [DATA_WIDTH*2-1:0]        ff_rd_data_r      ;

assign o_data     = ff_rd_data ; 
assign o_data_val = ~ff_empty  ;

//解析双倍速率数据，解析出上升沿和下降沿两组与clk_bufr同时钟域的数据
selectio_iddr_bk#
(
    .IDELAYCTRL_EN      (IDELAYCTRL_EN          ),
    .IDELAY_VALUE       (IDELAY_VALUE           ), //数据延时值，单位为0-31，参考时钟为ref_clk
    .DATA_WIDTH         (DATA_WIDTH             )  //输入数据位宽
)
u_selectio_iddr_bk_ch0
(

    .ref_clk            (ref_clk                ), //用于对数据延时的参考时钟，200Mhz信号
    .clk_bufr           (clk_bufr               ), //用于对数据处理的区域时钟
    .rst                (io_rst                 ), //内部复位信号
                     
    .i_lvds_data_p      (i_lvds_data_p          ), //实际为硬件管脚
    .i_lvds_data_n      (i_lvds_data_n          ), //实际为硬件管脚
                        
    .o_pos_data         (pos_data               ), //双沿数据解析，上升沿数据
    .o_neg_data         (neg_data               )  //双沿数据解析，下降沿数据
    
);

genvar i ;
genvar j ;

generate
    //将时钟上升沿的数据，赋值给偶数位数据
    for(i = 0; i <= DATA_WIDTH*2 - 2; i = i + 2)
    begin:POS_DATA
        assign data[i] = pos_data[i/2];
    end
    //将时钟下降沿的数据，赋值给奇数位数据
    for(j = 1; j <= DATA_WIDTH*2 - 1; j = j + 2)
    begin:NEG_DATA
        assign data[j] = neg_data[(j-1)/2];
    end
endgenerate

always@(posedge clk_bufr)
begin
    if(data_rst == 1'b1)
    begin
        ff_wr_en        <= 1'b0            ;
    end
    else
    begin
        ff_wr_en        <= 1'b1            ;
    end
end

always@(posedge clk_bufg)
begin
    ff_rd_en      <= ~ff_empty  ;
    ff_rd_data_r  <= ff_rd_data ;
end

//数据输入打拍
always@(posedge clk_bufr )
begin
    ff_wr_data <= data;
end

generate
    if(DATA_WIDTH == 8)
    begin
        dff_i16o16d1k u_dff_i16o16d1k (
            .rst          (data_rst                     ), // input rst
            .wr_clk       (clk_bufr                     ), // input wr_clk
            .rd_clk       (clk_bufg                     ), // input rd_clk
            .din          (ff_wr_data                   ), // input [15 : 0] din
            .wr_en        (ff_wr_en                     ), // input wr_en
            .rd_en        (ff_rd_en                     ), // input rd_en
            .dout         (ff_rd_data                   ), // output [15 : 0] dout
            .full         (                             ), // output full
            .empty        (ff_empty                     )  // output empty
        );
    end
    else 
    begin
    
    end
endgenerate

endmodule
