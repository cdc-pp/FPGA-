`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/27 17:55:27
// Design Name: 
// Module Name: tb_multi_ch_data_sync_bk
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


module tb_multi_ch_data_sync_bk();

parameter CHIP_NUM   = 2  ;
parameter CHIP_CH    = 4  ;
parameter DATA_WIDTH = 16 ;


reg                                             rst_n                       ; 
wire                                            o_sync                      ;
                                                                            
reg                                             i_sync_clk                  ;
reg     [CHIP_NUM - 1 : 0]                      i_data_clk                  ;
                                                                         
wire    [DATA_WIDTH*CHIP_CH - 1 : 0]            i_data                      ;
reg     [CHIP_CH - 1 : 0]                       i_data_val                  ;
                                                                         
reg     [15:0]                                  data_ch0                    ;
reg     [15:0]                                  data_ch1                    ;
reg     [15:0]                                  data_ch2                    ;
reg     [15:0]                                  data_ch3                    ;

multi_ch_sync_bk#
(
    .CHIP_NUM       (CHIP_NUM   ),
    .CHIP_CH        (CHIP_CH    ),
    .DATA_WIDTH     (DATA_WIDTH ) 
)                               
u_multi_ch_sync_bk
(

    .rst_n                 (rst_n           ), 
    .o_sync                (o_sync          ),
                                            
    .i_sync_clk            (i_sync_clk      ),
    .i_data_clk            (i_data_clk      ),
                                            
    .i_data                (i_data          ),
    .i_data_val            (i_data_val      ),
                                            
    .o_sync_data           (                ),
    .o_sync_data_val       (                ) 
    
);

initial
begin


    rst_n            <= 1'b0    ; 
    i_sync_clk       <= 1'b0    ;
    i_data_clk[0]    <= 1'b0    ;
    i_data_clk[1]    <= 1'b0    ;
    i_data_val[0]    <= 1'b0    ;
    i_data_val[1]    <= 1'b0    ;
    i_data_val[2]    <= 1'b0    ;
    i_data_val[3]    <= 1'b0    ;

#100
    rst_n            <= 1'b1    ;
    
#100
    i_data_val[0]    <= 1'b1    ;
    i_data_val[1]    <= 1'b1    ;
    i_data_val[2]    <= 1'b1    ;
    i_data_val[3]    <= 1'b1    ;

end

always #5 i_sync_clk <= ~i_sync_clk;
always #5 i_data_clk[0] <= ~i_data_clk[0];
always #5 i_data_clk[1] <= ~i_data_clk[1];

always@(posedge i_data_clk[0] or negedge rst_n)
begin
    if(!rst_n)
    begin
        data_ch0 <= 16'd0;
        data_ch1 <= 16'd1;
    end
    else 
    begin
        data_ch0 <= data_ch0 + 1'b1;
        data_ch1 <= data_ch1 + 1'b1;
    end
end

always@(posedge i_data_clk[1] or negedge rst_n)
begin
    if(!rst_n)
    begin
        data_ch2 <= 16'd2;
        data_ch3 <= 16'd3;
    end
    else 
    begin
        data_ch2 <= data_ch2 + 1'b1;
        data_ch3 <= data_ch3 + 1'b1;
    end
end

assign i_data = {data_ch3, data_ch2, data_ch1, data_ch0};

endmodule
