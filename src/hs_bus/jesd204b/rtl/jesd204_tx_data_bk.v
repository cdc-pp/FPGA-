`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/23 11:25:46
// Design Name: 
// Module Name: jesd204_tx_data_bk
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


module jesd204_tx_data_bk#
(

    parameter DEBUG     = 1   ,
    parameter JESD204_L = 4   

)
(
    
    input                               i_tx_clk      ,
    input                               i_tx_data_rdy ,
    input    [JESD204_L * 32 - 1 : 0]   i_data        , //{qn-1, in-1, ... q1, i1, q0, i0}
    output   [JESD204_L * 32 - 1 : 0]   o_tx_data    
    
);

reg     [31:0]    lane0  = 'd0;
reg     [31:0]    lane1  = 'd0;
reg     [31:0]    lane2  = 'd0;
reg     [31:0]    lane3  = 'd0;

wire    [15:0]    m0s0        ;
wire    [15:0]    m0s1        ;
wire    [15:0]    m0s2        ;
wire    [15:0]    m0s3        ;

wire    [15:0]    m1s0        ;
wire    [15:0]    m1s1        ;
wire    [15:0]    m1s2        ;
wire    [15:0]    m1s3        ;

generate 

    if(JESD204_L == 4)
    begin
        
        assign m0s0 = i_data[15:0]    ; //I0
        assign m0s1 = i_data[47:32]   ; //I1
        assign m0s2 = i_data[79:64]   ; //I2
        assign m0s3 = i_data[111:96]  ; //I3
        
        assign m1s0 = i_data[31:16]   ; //Q0
        assign m1s1 = i_data[63:48]   ; //Q1
        assign m1s2 = i_data[95:80]   ; //Q2
        assign m1s3 = i_data[127:112] ; //Q3
    
        always@(posedge i_tx_clk)
        begin
            if(i_tx_data_rdy == 1'b1)
            begin
                lane0 = {m0s3[15:8], m0s2[15:8], m0s1[15:8], m0s0[15:8]};
                lane1 = {m0s3[ 7:0], m0s2[ 7:0], m0s1[ 7:0], m0s0[ 7:0]};
                lane2 = {m1s3[15:8], m1s2[15:8], m1s1[15:8], m1s0[15:8]};
                lane3 = {m1s3[ 7:0], m1s2[ 7:0], m1s1[ 7:0], m1s0[ 7:0]};
            end
            else 
            begin
                lane0 = 32'd0;
                lane1 = 32'd0;
                lane2 = 32'd0;
                lane3 = 32'd0;
            end
        end
        
        assign o_tx_data = {lane3, lane2, lane1, lane0};
        
    end
    else if(JESD204_L == 2)
    begin
        //    serdes_lane0 <= {m0s1[ 7:0], m0s1[15:8], m0s0[ 7:0], m0s0[15:8]};
        //    serdes_lane1 <= {m0s1[ 7:0], m1s1[15:8], m0s0[ 7:0], m1s0[15:8]};
        assign m0s0 = i_data[15:0]    ; //I0
        assign m0s1 = i_data[47:32]   ; //I1
        assign m0s2 = 'd0             ; //I2
        assign m0s3 = 'd0             ; //I3
        
        assign m1s0 = i_data[31:16]   ; //Q0
        assign m1s1 = i_data[63:48]   ; //Q1
        assign m1s2 = 'd0             ; //Q2
        assign m1s3 = 'd0             ; //Q3
        always@(posedge i_tx_clk)
        begin
            if(i_tx_data_rdy == 1'b1)
            begin
                lane0 = {m0s1[ 7:0], m0s1[15:8], m0s0[ 7:0], m0s0[15:8]};
                lane1 = {m0s1[ 7:0], m1s1[15:8], m0s0[ 7:0], m1s0[15:8]};
                lane2 = 'd0;
                lane3 = 'd0;
            end
            else 
            begin
                lane0 = 32'd0;
                lane1 = 32'd0;
                lane2 = 32'd0;
                lane3 = 32'd0;
            end
        end
        
        assign o_tx_data = {lane3, lane2, lane1, lane0};
        
    end
endgenerate


generate
    if(DEBUG == 1)
    begin
    
        ila_128b u_ila_128b (
            .clk        (i_tx_clk), // input wire clk
            
            
            .probe0     ({m0s0,
                          m0s1,
                          m0s2,
                          m0s3,
                          m1s0,
                          m1s1,
                          m1s2,
                          m1s3
                        }) // input wire [127:0] probe0
        );
    
    end
endgenerate

endmodule
