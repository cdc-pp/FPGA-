`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/27 16:55:53
// Design Name: 
// Module Name: multi_ch_sync_bk
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


module multi_ch_sync_bk#
(
    parameter CHIP_NUM   = 2  ,
    parameter CHIP_CH    = 4  ,
    parameter DATA_WIDTH = 16  
)
(

    input                                    rst_n                              , 
    output                                   o_sync                             ,
                                                             
    input                                    i_sync_clk                         ,
    input    [CHIP_NUM - 1 : 0]              i_data_clk                         ,
                                    
    input    [DATA_WIDTH*CHIP_CH - 1 : 0]    i_data                             ,
    input    [CHIP_CH - 1 : 0]               i_data_val                         ,
                                    
    output   [DATA_WIDTH*CHIP_CH  - 1 : 0]   o_sync_data                        , //同步到i_sync_clk
    output                                   o_sync_data_val        
    
);

//一个器件对应CHIP_CH/CHIP_NUM个通道
reg     [CHIP_NUM - 1 : 0]        data_val_r          ;
reg     [CHIP_NUM - 1 : 0]        data_val_rr         ;
reg     [31:0]                    sync_shift          ;
wire                              sync_shift_in       ;
reg                               sync                ;
wire    [CHIP_CH  - 1 : 0]        fifo_empty          ;
reg                               sync_detect         ;
wire                              data_en             ;

assign sync_shift_in   = &data_val_rr  ;
assign o_sync_data_val = &(~fifo_empty);
assign o_sync          = sync ;

always@(posedge i_sync_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        sync_shift <= 'b0;
    end
    else
    begin
        sync_shift <= {sync_shift[30:0],sync_shift_in}  ;
    end
end

//同步信号产生
always@(posedge i_sync_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        sync <= 'b0;
    end
    else
    begin
        if((~sync_shift[31]) && sync_shift[2])
            sync <= 'b1;
        else
            sync <= 'b0;
    end
end

//第一次sync检测
always@(posedge i_sync_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        sync_detect <= 1'b0;
    end
    else 
    begin
        if(sync == 1'b1)
            sync_detect <= 1'b1;
        else 
            sync_detect <= sync_detect; 
    end
end

always@(posedge i_sync_clk )
begin
    data_val_r  <= i_data_val;
    data_val_rr <= data_val_r;
end

delay_ms #
(

    .DELAY_MS_VAL       (1   )  //单位为MS

)
u_delay_1ms
(

    .clk                (i_sync_clk         ), 
    .rst_n              (sync_detect        ), 
    .o_dly_ms_done      (data_en            )

);


genvar i;
genvar j;

generate 
    for(i = 0; i <= CHIP_NUM - 1; i = i + 1)
    begin:for_chip
        for(j = 0; j <= CHIP_CH / CHIP_NUM - 1; j = j + 1) 
        begin:datawidth16
            dff_i16o16d1k  u_dff_i16o16d1k
            (
                .wr_clk             (i_data_clk[i]                                 ),  
                .rd_clk             (i_sync_clk                                    ),  
                .rst                (~data_en                                      ),  
                .din                (i_data[(i*(CHIP_CH/CHIP_NUM)+j)*16+:16]       ),  
                .wr_en              (i_data_val[i*(CHIP_CH/CHIP_NUM)+j]            ),  
                .rd_en              (~fifo_empty[i*(CHIP_CH/CHIP_NUM)+j]           ),  
                .dout               (o_sync_data[(i*(CHIP_CH/CHIP_NUM)+j)*16+:16]  ), 
                .empty              (fifo_empty[i*(CHIP_CH/CHIP_NUM)+j]            ),
                .full               (                                              )
            );
        end
    end
endgenerate

endmodule
