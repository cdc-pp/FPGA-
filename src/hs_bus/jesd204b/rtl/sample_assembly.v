`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//Copyright (C) 2023 Lemid Technology Co.,Ltd.*
//////////////////////////////////////////////////////////////////
//sample_assembly.v
//
//DESCRIPTION:
//    对ADC数据进行重映射，并按照固定的顺序输出数据
//AUTHOR:
//    lzp
//CREATED DATE:
//    2023/11/29
//REVISION:
//1.0 - 初始版本
//////////////////////////////////////////////////////////////////

module sample_assembly#(

    parameter    JESD204B_L    = 4    , //jesd204b serdes lane的个数
    parameter    ADC_CHANNEL   = 2    , //ADC实际的通道数
    parameter    ADC_WIDTH     = 14   , //ADC采样分辨率
    parameter    JESD204B_F    = 1      //jesd204b 每frame有多少个Oct（字节）

)
(
input                                  clk             ,
input                                  rst_n           ,

input  [JESD204B_L * 32 - 1:0]         rx_tdata        ,
input                                  rx_tvalid       ,
                
output                                 o_ad_data_val   ,
output [JESD204B_L * 32 - 1:0]         o_ad_data      

);

//ADC发送数据时，首先发送AD数据的高字节，即m0s0[15:8]->m0s0[7:0]。
//Xilinx接收数据时，ser*_dat[31:0] = {0ct3, 0ct2, 0ct1, 0ct0}
//F：每FRAME有多少个oct

//按照ADC的FRAME个数中，ADC的数据映射如下：
//1、ADC数据先将单个转换器（M）的所有采样点（S）进行排布，从lane0到lane n-1按照顺序排布。
//2、以下一转换器（M）开始，重复流程1，直到结束。
//即：M0 {S0-Sn-1} - Mn-1{S0 - Sn-1}。 


//others
//LMFS = 4841
//lane0 ：m0s0[15:8]     |  m0s0[ 7:0]      |  m1s0[15:8]       |  m1s0[ 7:0]       |   ADC  TX （ADC发送的数据顺序）
//        ser0_dat[7:0]  |  ser0_dat[15:8]  |  ser0_dat[23:16]  |  ser0_dat[31:24]  |   FPGA RX （FPGA JESD204B缓存的数据）
//lane1 ：m2s0[15:8]     |  m2s0[ 7:0]      |  m3s0[15:8]       |  m3s0[ 7:0]       |   ADC  TX  
//        ser1_dat[7:0]  |  ser1_dat[15:8]  |  ser1_dat[23:16]  |  ser1_dat[31:24]  |   FPGA RX   
//lane2 ：m4s0[15:8]     |  m4s0[ 7:0]      |  m5s0[15:8]       |  m5s0[ 7:0]       |   ADC  TX  
//        ser2_dat[7:0]  |  ser2_dat[15:8]  |  ser2_dat[23:16]  |  ser2_dat[31:24]  |   FPGA RX   
//lane3 ：m6s0[15:8]     |  m6s0[ 7:0]      |  m7s0[15:8]       |  m7s0[ 7:0]       |   ADC  TX  
//        ser3_dat[7:0]  |  ser3_dat[15:8]  |  ser3_dat[23:16]  |  ser3_dat[31:24]  |   FPGA RX   
//        oct0           |  oct1            |  oct2             |  oct3             |   
//        Frame1                                                                    |

reg                 rx_tvalid_f     ;
//ADC双通道
//样点个数：32 * 8 / 16 = 16个
//通道1 单个样点数据
reg [15:0]          rx_ada_p1       ; 
reg [15:0]          rx_ada_p2       ; 
reg [15:0]          rx_ada_p3       ; 
reg [15:0]          rx_ada_p4       ; 
reg [15:0]          rx_ada_p5       ; 
reg [15:0]          rx_ada_p6       ; 
reg [15:0]          rx_ada_p7       ; 
reg [15:0]          rx_ada_p8       ; 
//通道2 单个样点数据
reg [15:0]          rx_adb_p1       ; 
reg [15:0]          rx_adb_p2       ; 
reg [15:0]          rx_adb_p3       ; 
reg [15:0]          rx_adb_p4       ; 
reg [15:0]          rx_adb_p5       ; 
reg [15:0]          rx_adb_p6       ; 
reg [15:0]          rx_adb_p7       ; 
reg [15:0]          rx_adb_p8       ; 
//ADC单通道
reg [15:0]          rx_ad_p1        ;
reg [15:0]          rx_ad_p2        ;
reg [15:0]          rx_ad_p3        ;
reg [15:0]          rx_ad_p4        ;
reg [15:0]          rx_ad_p5        ;
reg [15:0]          rx_ad_p6        ;
reg [15:0]          rx_ad_p7        ;
reg [15:0]          rx_ad_p8        ;
reg [15:0]          rx_ad_p9        ;
reg [15:0]          rx_ad_p10       ;
reg [15:0]          rx_ad_p11       ;
reg [15:0]          rx_ad_p12       ;
reg [15:0]          rx_ad_p13       ;
reg [15:0]          rx_ad_p14       ;
reg [15:0]          rx_ad_p15       ;
reg [15:0]          rx_ad_p16       ;


// {oct3, oct2, oct1, oct0}
wire[31:0]          ser0_dat        ; 
wire[31:0]          ser1_dat        ; 
wire[31:0]          ser2_dat        ; 
wire[31:0]          ser3_dat        ; 
wire[31:0]          ser4_dat        ; 
wire[31:0]          ser5_dat        ; 
wire[31:0]          ser6_dat        ; 
wire[31:0]          ser7_dat        ; 

generate

if(JESD204B_L == 1)
begin
    assign ser0_dat = rx_tdata[31:0]    ;
end
else if(JESD204B_L == 2)
begin
    assign ser0_dat = rx_tdata[31:0]    ;
    assign ser1_dat = rx_tdata[63:32]   ;
end
else if(JESD204B_L == 4)
begin
    assign ser0_dat = rx_tdata[31:0]    ;
    assign ser1_dat = rx_tdata[63:32]   ;
    assign ser2_dat = rx_tdata[95:64]   ;
    assign ser3_dat = rx_tdata[127:96]  ;
end
else if(JESD204B_L == 8)
begin
    assign ser0_dat = rx_tdata[31:0]    ;
    assign ser1_dat = rx_tdata[63:32]   ;
    assign ser2_dat = rx_tdata[95:64]   ;
    assign ser3_dat = rx_tdata[127:96]  ;
    assign ser4_dat = rx_tdata[159:128] ;
    assign ser5_dat = rx_tdata[191:160] ;
    assign ser6_dat = rx_tdata[223:192] ;
    assign ser7_dat = rx_tdata[255:224] ;
end

endgenerate

assign o_ad_data_val = rx_tvalid_f  ;

//实数模式，F <= 4
generate 
//ADC M = 2
if(ADC_CHANNEL == 2)
begin

    //L = 2 
    if(JESD204B_L == 2)
    begin    
        if(ADC_WIDTH == 16)
        begin
            assign o_ad_data = {

                                    rx_adb_p2[15:0],
                                    rx_adb_p1[15:0],
                                    rx_ada_p2[15:0],
                                    rx_ada_p1[15:0]
 
                                };           
        end
        else 
        begin
            //{sb2, sb1, sa2, sa1} 
            assign o_ad_data = {
                                    {(16-ADC_WIDTH){rx_adb_p2[15]}},rx_adb_p2[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_adb_p1[15]}},rx_adb_p1[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ada_p2[15]}},rx_ada_p2[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ada_p1[15]}},rx_ada_p1[15:(16-ADC_WIDTH)]
                                                                                  
                                };                                                
        end                                                                              
        always @(posedge clk or negedge rst_n)                                
        begin                                                                 
            if(!rst_n)                                                        
            begin                                                             
                                                                              
                rx_tvalid_f   <= 'b0;                                         
                rx_ada_p1     <= 'b0;                                         
                rx_ada_p2     <= 'b0;                                         
                                                                              
                rx_adb_p1     <= 'b0;
                rx_adb_p2     <= 'b0;
            
            end
            else
            begin
                //LMFS = 2221
                //lane0 ：m0s0[15:8]     |  m0s0[ 7:0]      |  m0s1[15:8]       |  m0s1[ 7:0]       |   ADC  TX （ADC发送的数据顺序）
                //        ser0_dat[7:0]  |  ser0_dat[15:8]  |  ser0_dat[23:16]  |  ser0_dat[31:24]  |   FPGA RX （FPGA JESD204B缓存的数据）  
                //lane1 ：m0s1[15:8]     |  m0s1[ 7:0]      |  m0s2[15:8]       |  m0s2[ 7:0]       |   ADC  TX  
                //        ser1_dat[7:0]  |  ser1_dat[15:8]  |  ser1_dat[23:16]  |  ser1_dat[31:24]  |   FPGA RX   
                //        oct0           |  oct1            |  oct2             |  oct3             | 
                //        Frame1                            |  Frame2                               |
                
                //LMFS = 2242
                //lane0 ：m0s0[15:8]     |  m0s0[ 7:0]      |  m0s1[15:8]       |  m0s1[ 7:0]       |   ADC  TX （ADC发送的数据顺序）
                //        ser0_dat[7:0]  |  ser0_dat[15:8]  |  ser0_dat[23:16]  |  ser0_dat[31:24]  |   FPGA RX （FPGA JESD204B缓存的数据）  
                //lane1 ：m0s1[15:8]     |  m0s1[ 7:0]      |  m0s2[15:8]       |  m0s2[ 7:0]       |   ADC  TX  
                //        ser1_dat[7:0]  |  ser1_dat[15:8]  |  ser1_dat[23:16]  |  ser1_dat[31:24]  |   FPGA RX   
                //        oct0           |  oct1            |  oct2             |  oct3             | 
                //        Frame1                                                                    |
                //LMFS = 2221 = 2242
                rx_tvalid_f  <= rx_tvalid   ;
                rx_ada_p1    <= {ser0_dat[7:0], ser0_dat[15:8]};
                rx_ada_p2    <= {ser1_dat[7:0], ser1_dat[15:8]};
                rx_adb_p1    <= {ser2_dat[7:0], ser2_dat[15:8]};
                rx_adb_p2    <= {ser3_dat[7:0], ser3_dat[15:8]};
                
            end
        end

    end
    // L = 4
    if(JESD204B_L == 4)
    begin
        if(ADC_WIDTH == 16)
        begin
            assign o_ad_data = {

                                    rx_adb_p4[15:0],
                                    rx_adb_p3[15:0],
                                    rx_adb_p2[15:0],
                                    rx_adb_p1[15:0],
                                    rx_ada_p4[15:0],
                                    rx_ada_p3[15:0],
                                    rx_ada_p2[15:0],
                                    rx_ada_p1[15:0]
 
                                };           
        end
        else 
        begin
            //{sb4, sb3, sb2, sb1, sa4, sa3, sa2, sa1}
            assign o_ad_data = {
     
                                    {(16-ADC_WIDTH){rx_adb_p4[15]}}, rx_adb_p4[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_adb_p3[15]}}, rx_adb_p3[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_adb_p2[15]}}, rx_adb_p2[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_adb_p1[15]}}, rx_adb_p1[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ada_p4[15]}}, rx_ada_p4[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ada_p3[15]}}, rx_ada_p3[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ada_p2[15]}}, rx_ada_p2[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ada_p1[15]}}, rx_ada_p1[15:(16-ADC_WIDTH)]
                                                                                   
                                };             
        end
                                                                               
        always @(posedge clk or negedge rst_n)                                 
        begin                                                                  
            if(!rst_n)                                                         
            begin                                                              
                rx_tvalid_f   <= 'b0;                                          
                rx_ada_p1     <= 'b0;
                rx_ada_p2     <= 'b0;
                rx_ada_p3     <= 'b0;
                rx_ada_p4     <= 'b0;
                
                rx_adb_p1     <= 'b0;
                rx_adb_p2     <= 'b0;
                rx_adb_p3     <= 'b0;
                rx_adb_p4     <= 'b0;
            
            end
            else
            begin
                //LMFS = 4211 = 4222 = 4233 = 4244
                //LMFS = 4211
                //lane0 ：m0s0[15:8]     |  m0s1[15:8]      |  m0s2[15:8]       |  m0s3[15:8]       |   ADC  TX （ADC发送的数据顺序）
                //        ser0_dat[7:0]  |  ser0_dat[15:8]  |  ser0_dat[23:16]  |  ser0_dat[31:24]  |   FPGA RX （FPGA JESD204B缓存的数据）
                //lane1 ：m0s0[ 7:0]     |  m0s1[ 7:0]      |  m0s2[ 7:0]       |  m0s3[ 7:0]       |   ADC  TX  
                //        ser1_dat[7:0]  |  ser1_dat[15:8]  |  ser1_dat[23:16]  |  ser1_dat[31:24]  |   FPGA RX   
                //lane2 ：m1s0[15:8]     |  m1s1[15:8]      |  m1s2[15:8]       |  m1s3[15:8]       |   ADC  TX  
                //        ser2_dat[7:0]  |  ser2_dat[15:8]  |  ser2_dat[23:16]  |  ser2_dat[31:24]  |   FPGA RX   
                //lane3 ：m1s0[ 7:0]     |  m1s1[ 7:0]      |  m1s2[ 7:0]       |  m1s3[ 7:0]       |   ADC  TX  
                //        ser3_dat[7:0]  |  ser3_dat[15:8]  |  ser3_dat[23:16]  |  ser3_dat[31:24]  |   FPGA RX   
                //        oct0           |  oct1            |  oct2             |  oct3             |
                //        Frame1         |  Frame2          |  Frame3           |  Frame4           |                   

                rx_tvalid_f  <= rx_tvalid   ;
                rx_ada_p1    <= {ser0_dat[7:0],  ser1_dat[7:0]};
                rx_ada_p2    <= {ser0_dat[15:8], ser1_dat[15:8]};
                rx_ada_p3    <= {ser0_dat[23:16],ser1_dat[23:16]};
                rx_ada_p4    <= {ser0_dat[31:24],ser1_dat[31:24]};
                
                rx_adb_p1    <= {ser2_dat[7:0],  ser3_dat[7:0]};
                rx_adb_p2    <= {ser2_dat[15:8], ser3_dat[15:8]};
                rx_adb_p3    <= {ser2_dat[23:16],ser3_dat[23:16]};
                rx_adb_p4    <= {ser2_dat[31:24],ser3_dat[31:24]};
                
            end
        end
    end
    
    //L = 8 
    else if(JESD204B_L == 8)
    begin
        //{sb8, sb7, sb6, sb5, sb4, sb3, sb2, sb1,
        // sa8, sa7, sa6, sa5, sa4, sa3, sa2, sa1}
        if(ADC_WIDTH == 16)
        begin
            assign o_ad_data = {
                                    rx_adb_p8[15:0],
                                    rx_adb_p7[15:0],
                                    rx_adb_p6[15:0],
                                    rx_adb_p5[15:0],
                                    rx_adb_p4[15:0],
                                    rx_adb_p3[15:0],
                                    rx_adb_p2[15:0],
                                    rx_adb_p1[15:0],
                                    rx_ada_p8[15:0],
                                    rx_ada_p7[15:0],
                                    rx_ada_p6[15:0],
                                    rx_ada_p5[15:0],
                                    rx_ada_p4[15:0],
                                    rx_ada_p3[15:0],
                                    rx_ada_p2[15:0],
                                    rx_ada_p1[15:0]
 
                                };           
        end
        else 
        begin
            assign o_ad_data = {
                                    {(16-ADC_WIDTH){rx_adb_p8[15]}},rx_adb_p8[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_adb_p7[15]}},rx_adb_p7[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_adb_p6[15]}},rx_adb_p6[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_adb_p5[15]}},rx_adb_p5[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_adb_p4[15]}},rx_adb_p4[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_adb_p3[15]}},rx_adb_p3[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_adb_p2[15]}},rx_adb_p2[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_adb_p1[15]}},rx_adb_p1[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ada_p8[15]}},rx_ada_p8[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ada_p7[15]}},rx_ada_p7[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ada_p6[15]}},rx_ada_p6[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ada_p5[15]}},rx_ada_p5[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ada_p4[15]}},rx_ada_p4[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ada_p3[15]}},rx_ada_p3[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ada_p2[15]}},rx_ada_p2[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ada_p1[15]}},rx_ada_p1[15:(16-ADC_WIDTH)]
                              
                                };           
        end
        
        always @(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
            begin 

                rx_tvalid_f   <= 'b0;
                rx_ada_p1     <= 'b0;
                rx_ada_p2     <= 'b0;
                rx_ada_p3     <= 'b0;
                rx_ada_p4     <= 'b0;
                rx_ada_p5     <= 'b0;
                rx_ada_p6     <= 'b0;
                rx_ada_p7     <= 'b0;
                rx_ada_p8     <= 'b0;
                
                rx_adb_p1     <= 'b0;
                rx_adb_p2     <= 'b0;
                rx_adb_p3     <= 'b0;
                rx_adb_p4     <= 'b0;
                rx_adb_p5     <= 'b0;
                rx_adb_p6     <= 'b0;
                rx_adb_p7     <= 'b0;
                rx_adb_p8     <= 'b0;
            
            end
            else
            begin
                //LMFS = 8212 = 8224 = 8248
                //LMFS = 8212
                //lane0 ：m0s0[15:8]     |  m0s4[15:8]      |  m0s8[15:8]       |  m0s12[15:8]      |    ADC  TX （ADC发送的数据顺序）
                //        ser0_dat[7:0]  |  ser0_dat[15:8]  |  ser0_dat[23:16]  |  ser0_dat[31:24]  |    FPGA RX （FPGA JESD204B缓存的数据）  
                //lane1 ：m0s0[ 7:0]     |  m0s4[ 7:0]      |  m0s8[ 7:0]       |  m0s12[ 7:0]      |    ADC  TX  
                //        ser1_dat[7:0]  |  ser1_dat[15:8]  |  ser1_dat[23:16]  |  ser1_dat[31:24]  |    FPGA RX  
                //lane2 ：m0s1[15:8]     |  m0s5[15:8]      |  m0s9[15:8]       |  m0s13[15:8]      |    ADC  TX   
                //        ser2_dat[7:0]  |  ser2_dat[15:8]  |  ser2_dat[23:16]  |  ser2_dat[31:24]  |    FPGA RX        
                //lane3 ：m0s1[ 7:0]     |  m0s5[ 7:0]      |  m0s9[ 7:0]       |  m0s13[ 7:0]      |    ADC  TX     
                //        ser3_dat[7:0]  |  ser3_dat[15:8]  |  ser3_dat[23:16]  |  ser3_dat[31:24]  |    FPGA RX  
                //lane4 ：m1s0[15:8]     |  m1s2[15:8]      |  m1s4[15:8]       |  m1s6[15:8]       |    ADC  TX   
                //        ser4_dat[7:0]  |  ser4_dat[15:8]  |  ser4_dat[23:16]  |  ser4_dat[31:24]  |    FPGA RX     
                //lane5 ：m1s0[ 7:0]     |  m1s2[ 7:0]      |  m1s4[ 7:0]       |  m1s6[ 7:0]       |    ADC  TX   
                //        ser5_dat[7:0]  |  ser5_dat[15:8]  |  ser5_dat[23:16]  |  ser5_dat[31:24]  |    FPGA RX
                //lane6 ：m1s1[15:8]     |  m1s3[15:8]      |  m1s5[15:8]       |  m1s7[15:8]       |    ADC  TX   
                //        ser6_dat[7:0]  |  ser6_dat[15:8]  |  ser6_dat[23:16]  |  ser6_dat[31:24]  |    FPGA RX     
                //lane7 ：m1s1[ 7:0]     |  m1s3[ 7:0]      |  m1s5[ 7:0]       |  m1s7[ 7:0]       |    ADC  TX   
                //        ser7_dat[7:0]  |  ser7_dat[15:8]  |  ser7_dat[23:16]  |  ser7_dat[31:24]  |    FPGA RX
                //        oct0           |  oct1            |  oct2             |  oct3             |
                //        Frame 1        |  Frame 2         |  Frame 3          |  Frame 4          |
                rx_tvalid_f  <= rx_tvalid   ;
                rx_ada_p1    <= {ser0_dat[7:0],  ser1_dat[7:0]};
                rx_ada_p2    <= {ser0_dat[15:8], ser1_dat[15:8]};
                rx_ada_p3    <= {ser0_dat[23:16],ser1_dat[23:16]};
                rx_ada_p4    <= {ser0_dat[31:24],ser1_dat[31:24]};
                rx_ada_p5    <= {ser2_dat[7:0],  ser3_dat[7:0]};
                rx_ada_p6    <= {ser2_dat[15:8], ser3_dat[15:8]};
                rx_ada_p7    <= {ser2_dat[23:16],ser3_dat[23:16]};
                rx_ada_p8    <= {ser2_dat[31:24],ser3_dat[31:24]};
            
                rx_adb_p1    <= {ser4_dat[7:0],  ser5_dat[7:0]};
                rx_adb_p2    <= {ser4_dat[15:8], ser5_dat[15:8]};
                rx_adb_p3    <= {ser4_dat[23:16],ser5_dat[23:16]};
                rx_adb_p4    <= {ser4_dat[31:24],ser5_dat[31:24]};
                rx_adb_p5    <= {ser6_dat[7:0],  ser7_dat[7:0]};
                rx_adb_p6    <= {ser6_dat[15:8], ser7_dat[15:8]};
                rx_adb_p7    <= {ser6_dat[23:16],ser7_dat[23:16]};
                rx_adb_p8    <= {ser6_dat[31:24],ser7_dat[31:24]};
                
            end
        end
    end
end

//M = 1
else if(ADC_CHANNEL == 1)
begin
    if(JESD204B_L == 4)
    begin
        if(ADC_WIDTH == 16)
        begin
            assign o_ad_data = {
                                    rx_ad_p8[15:0],
                                    rx_ad_p7[15:0],
                                    rx_ad_p6[15:0],
                                    rx_ad_p5[15:0],
                                    rx_ad_p4[15:0],
                                    rx_ad_p3[15:0],
                                    rx_ad_p2[15:0],
                                    rx_ad_p1[15:0]
 
                                };           
        end
        else 
        begin
            //{s8, s7, s6, s5, s4, s3, s2, s1}
            assign o_ad_data = {
  
                                    {(16-ADC_WIDTH){rx_ad_p8[15]}}, rx_ad_p8[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p7[15]}}, rx_ad_p7[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p6[15]}}, rx_ad_p6[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p5[15]}}, rx_ad_p5[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p4[15]}}, rx_ad_p4[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p3[15]}}, rx_ad_p3[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p2[15]}}, rx_ad_p2[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p1[15]}}, rx_ad_p1[15:(16-ADC_WIDTH)]
                                                                                   
                                };                                                 
        end

        always @(posedge clk or negedge rst_n)                                 
        begin                                                                  
            if(!rst_n)                                                         
            begin                                                              
                rx_tvalid_f   <= 'b0;                                          
                rx_ad_p1     <= 'b0;
                rx_ad_p2     <= 'b0;
                rx_ad_p3     <= 'b0;
                rx_ad_p4     <= 'b0;
                
                rx_ad_p5     <= 'b0;
                rx_ad_p6     <= 'b0;
                rx_ad_p7     <= 'b0;
                rx_ad_p8     <= 'b0;
            
            end
            else
            begin
                if(JESD204B_F == 1)
                begin
                    //LMFS = 4112  
                    //lane0 ：m0s0[15:8]     |  m0s2[15:8]      |  m0s4[15:8]       |  m0s6[15:8]       |   ADC  TX （ADC发送的数据顺序）
                    //        ser0_dat[7:0]  |  ser0_dat[15:8]  |  ser0_dat[23:16]  |  ser0_dat[31:24]  |   FPGA RX （FPGA JESD204B缓存的数据）
                    //lane1 ：m0s0[ 7:0]     |  m0s2[ 7:0]      |  m0s4[ 7:0]       |  m0s6[ 7:0]       |   ADC  TX  
                    //        ser1_dat[7:0]  |  ser1_dat[15:8]  |  ser1_dat[23:16]  |  ser1_dat[31:24]  |   FPGA RX   
                    //lane2 ：m0s1[15:8]     |  m0s3[15:8]      |  m0s5[15:8]       |  m0s7[15:8]       |   ADC  TX  
                    //        ser2_dat[7:0]  |  ser2_dat[15:8]  |  ser2_dat[23:16]  |  ser2_dat[31:24]  |   FPGA RX   
                    //lane3 ：m0s1[ 7:0]     |  m0s3[ 7:0]      |  m0s5[ 7:0]       |  m0s7[ 7:0]       |   ADC  TX  
                    //        ser3_dat[7:0]  |  ser3_dat[15:8]  |  ser3_dat[23:16]  |  ser3_dat[31:24]  |   FPGA RX   
                    //        oct0           |  oct1            |  oct2             |  oct3             |
                    //        Frame1         |  Frame2          |  Frame3           |  Frame4           |                   
 
                    rx_tvalid_f  <= rx_tvalid   ;
                    rx_ad_p1    <= {ser0_dat[ 7: 0], ser1_dat[ 7: 0]};
                    rx_ad_p2    <= {ser2_dat[ 7: 0], ser3_dat[ 7: 0]};
                    rx_ad_p3    <= {ser0_dat[15: 8], ser1_dat[15: 8]};
                    rx_ad_p4    <= {ser2_dat[15: 8], ser3_dat[15: 8]};
                    
                    rx_ad_p5    <= {ser0_dat[23:16], ser1_dat[23:16]};
                    rx_ad_p6    <= {ser2_dat[23:16], ser3_dat[23:16]};
                    rx_ad_p7    <= {ser0_dat[31:24], ser1_dat[31:24]};
                    rx_ad_p8    <= {ser2_dat[31:24], ser3_dat[31:24]};
                end
                else if(JESD204B_F == 2)
                begin
                    //LMFS = 4124  
                    //lane0 ：m0s0[15:8]     |  m0s0[ 7:0]      |  m0s4[15:8]       |  m0s4[ 7:0]       |   ADC  TX （ADC发送的数据顺序）
                    //        ser0_dat[7:0]  |  ser0_dat[15:8]  |  ser0_dat[23:16]  |  ser0_dat[31:24]  |   FPGA RX （FPGA JESD204B缓存的数据）
                    //lane1 ：m0s1[15:8]     |  m0s1[ 7:0]      |  m0s5[15:8]       |  m0s5[ 7:0]       |   ADC  TX  
                    //        ser1_dat[7:0]  |  ser1_dat[15:8]  |  ser1_dat[23:16]  |  ser1_dat[31:24]  |   FPGA RX   
                    //lane2 ：m0s2[15:8]     |  m0s2[ 7:0]      |  m0s6[15:8]       |  m0s6[ 7:0]       |   ADC  TX  
                    //        ser2_dat[7:0]  |  ser2_dat[15:8]  |  ser2_dat[23:16]  |  ser2_dat[31:24]  |   FPGA RX   
                    //lane3 ：m0s3[15:8]     |  m0s3[ 7:0]      |  m0s7[15:8]       |  m0s7[ 7:0]       |   ADC  TX  
                    //        ser3_dat[7:0]  |  ser3_dat[15:8]  |  ser3_dat[23:16]  |  ser3_dat[31:24]  |   FPGA RX   
                    //        oct0           |  oct1            |  oct2             |  oct3             |
                    //        Frame1                            |  Frame2                               |                   
 
                    rx_tvalid_f  <= rx_tvalid   ;
                    rx_ad_p1    <= {ser0_dat[ 7: 0], ser0_dat[15: 8]};
                    rx_ad_p2    <= {ser1_dat[ 7: 0], ser1_dat[15: 8]};
                    rx_ad_p3    <= {ser2_dat[ 7: 0], ser2_dat[15: 8]};
                    rx_ad_p4    <= {ser3_dat[ 7: 0], ser3_dat[15: 8]};
                    
                    rx_ad_p5    <= {ser0_dat[23:16], ser0_dat[31:24]};
                    rx_ad_p6    <= {ser1_dat[23:16], ser1_dat[31:24]};
                    rx_ad_p7    <= {ser2_dat[31:24], ser2_dat[31:24]};
                    rx_ad_p8    <= {ser3_dat[31:24], ser3_dat[31:24]};
                end
                else if(JESD204B_F == 4)
                begin
                    //LMFS = 4148  
                    //lane0 ：m0s0[15:8]     |  m0s0[ 7:0]      |  m0s1[15:8]       |  m0s1[ 7:0]       |   ADC  TX （ADC发送的数据顺序）
                    //        ser0_dat[7:0]  |  ser0_dat[15:8]  |  ser0_dat[23:16]  |  ser0_dat[31:24]  |   FPGA RX （FPGA JESD204B缓存的数据）
                    //lane1 ：m0s2[15:8]     |  m0s2[ 7:0]      |  m0s3[15:8]       |  m0s3[ 7:0]       |   ADC  TX  
                    //        ser1_dat[7:0]  |  ser1_dat[15:8]  |  ser1_dat[23:16]  |  ser1_dat[31:24]  |   FPGA RX   
                    //lane2 ：m0s4[15:8]     |  m0s4[ 7:0]      |  m0s5[15:8]       |  m0s5[ 7:0]       |   ADC  TX  
                    //        ser2_dat[7:0]  |  ser2_dat[15:8]  |  ser2_dat[23:16]  |  ser2_dat[31:24]  |   FPGA RX   
                    //lane3 ：m0s6[15:8]     |  m0s6[ 7:0]      |  m0s7[15:8]       |  m0s7[ 7:0]       |   ADC  TX  
                    //        ser3_dat[7:0]  |  ser3_dat[15:8]  |  ser3_dat[23:16]  |  ser3_dat[31:24]  |   FPGA RX   
                    //        oct0           |  oct1            |  oct2             |  oct3             |
                    //        Frame1                                                                    |                   
 
                    rx_tvalid_f  <= rx_tvalid   ;
                    rx_ad_p1    <= {ser0_dat[ 7: 0], ser0_dat[15: 8]};
                    rx_ad_p2    <= {ser0_dat[23:16], ser0_dat[31:24]};
                    rx_ad_p3    <= {ser1_dat[ 7: 0], ser1_dat[15: 8]};
                    rx_ad_p4    <= {ser1_dat[23:16], ser1_dat[31:24]};
                    
                    rx_ad_p5    <= {ser2_dat[ 7: 0], ser2_dat[15: 8]};
                    rx_ad_p6    <= {ser2_dat[23:16], ser2_dat[31:24]};
                    rx_ad_p7    <= {ser3_dat[ 7: 0], ser3_dat[15: 8]};
                    rx_ad_p8    <= {ser3_dat[23:16], ser3_dat[31:24]};
                end
            end
        end
    end

    //L = 8
    else if(JESD204B_L == 8)
    begin
        if(ADC_WIDTH == 16)
        begin
            assign o_ad_data = {
                                    rx_ad_p16[15:0],
                                    rx_ad_p15[15:0],
                                    rx_ad_p14[15:0],
                                    rx_ad_p13[15:0],
                                    rx_ad_p12[15:0],
                                    rx_ad_p11[15:0],
                                    rx_ad_p10[15:0],
                                    rx_ad_p9[15:0],
                                    rx_ad_p8[15:0],
                                    rx_ad_p7[15:0],
                                    rx_ad_p6[15:0],
                                    rx_ad_p5[15:0],
                                    rx_ad_p4[15:0],
                                    rx_ad_p3[15:0],
                                    rx_ad_p2[15:0],
                                    rx_ad_p1[15:0]
 
                                };           
        end
        else 
        begin
            //{s16, s15, s14, s13, s12, s11, s10, s9,
            // s8,  s7,  s6,  s5,  s4,  s3,  s2, s1}
            assign o_ad_data = {
            
                                    {(16-ADC_WIDTH){rx_ad_p16[15]}}, rx_ad_p16[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p15[15]}}, rx_ad_p15[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p14[15]}}, rx_ad_p14[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p13[15]}}, rx_ad_p13[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p12[15]}}, rx_ad_p12[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p11[15]}}, rx_ad_p11[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p10[15]}}, rx_ad_p10[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p9[15]}}, rx_ad_p9[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p8[15]}}, rx_ad_p8[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p7[15]}}, rx_ad_p7[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p6[15]}}, rx_ad_p6[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p5[15]}}, rx_ad_p5[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p4[15]}}, rx_ad_p4[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p3[15]}}, rx_ad_p3[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p2[15]}}, rx_ad_p2[15:(16-ADC_WIDTH)],
                                    {(16-ADC_WIDTH){rx_ad_p1[15]}}, rx_ad_p1[15:(16-ADC_WIDTH)]
                              
                                };           
        end
        
        always @(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
            begin 

                rx_tvalid_f   <= 'b0;
                rx_ad_p1     <= 'b0;
                rx_ad_p2     <= 'b0;
                rx_ad_p3     <= 'b0;
                rx_ad_p4     <= 'b0;
                rx_ad_p5     <= 'b0;
                rx_ad_p6     <= 'b0;
                rx_ad_p7     <= 'b0;
                rx_ad_p8     <= 'b0;
                
                rx_ad_p9     <= 'b0;
                rx_ad_p10    <= 'b0;
                rx_ad_p11    <= 'b0;
                rx_ad_p12    <= 'b0;
                rx_ad_p13    <= 'b0;
                rx_ad_p14    <= 'b0;
                rx_ad_p15    <= 'b0;
                rx_ad_p16    <= 'b0;
            
            end
            else
            begin
                //LMFS = 8114
                //lane0 ：m0s0[15:8]     |  m0s4[15:8]      |  m0s8[15:8]       |  m0s12[15:8]      |    ADC  TX （ADC发送的数据顺序）
                //        ser0_dat[7:0]  |  ser0_dat[15:8]  |  ser0_dat[23:16]  |  ser0_dat[31:24]  |    FPGA RX （FPGA JESD204B缓存的数据）  
                //lane1 ：m0s0[ 7:0]     |  m0s4[ 7:0]      |  m0s8[ 7:0]       |  m0s12[ 7:0]      |    ADC  TX  
                //        ser1_dat[7:0]  |  ser1_dat[15:8]  |  ser1_dat[23:16]  |  ser1_dat[31:24]  |    FPGA RX  
                //lane2 ：m0s1[15:8]     |  m0s5[15:8]      |  m0s9[15:8]       |  m0s13[15:8]      |    ADC  TX   
                //        ser2_dat[7:0]  |  ser2_dat[15:8]  |  ser2_dat[23:16]  |  ser2_dat[31:24]  |    FPGA RX        
                //lane3 ：m0s1[ 7:0]     |  m0s5[ 7:0]      |  m0s9[ 7:0]       |  m0s13[ 7:0]      |    ADC  TX     
                //        ser3_dat[7:0]  |  ser3_dat[15:8]  |  ser3_dat[23:16]  |  ser3_dat[31:24]  |    FPGA RX  
                //lane4 ：m0s2[15:8]     |  m0s6[15:8]      |  m0s10[15:8]      |  m0s14[15:8]      |    ADC  TX   
                //        ser4_dat[7:0]  |  ser4_dat[15:8]  |  ser4_dat[23:16]  |  ser4_dat[31:24]  |    FPGA RX     
                //lane5 ：m0s2[ 7:0]     |  m0s6[ 7:0]      |  m0s10[ 7:0]      |  m0s14[ 7:0]      |    ADC  TX   
                //        ser5_dat[7:0]  |  ser5_dat[15:8]  |  ser5_dat[23:16]  |  ser5_dat[31:24]  |    FPGA RX
                //lane6 ：m0s3[15:8]     |  m0s7[15:8]      |  m0s11[15:8]      |  m0s15[15:8]      |    ADC  TX   
                //        ser6_dat[7:0]  |  ser6_dat[15:8]  |  ser6_dat[23:16]  |  ser6_dat[31:24]  |    FPGA RX     
                //lane7 ：m0s3[ 7:0]     |  m0s7[ 7:0]      |  m0s11[ 7:0]      |  m0s15[ 7:0]      |    ADC  TX   
                //        ser7_dat[7:0]  |  ser7_dat[15:8]  |  ser7_dat[23:16]  |  ser7_dat[31:24]  |    FPGA RX
                //        oct0           |  oct1            |  oct2             |  oct3             | 
                //        Frame 1        |  Frame 2         |  Frame 3          |  Frame 4          |
                rx_tvalid_f  <= rx_tvalid   ;
                rx_ad_p1    <= {ser0_dat[7:0],  ser1_dat[7:0]};
                rx_ad_p2    <= {ser0_dat[15:8], ser1_dat[15:8]};
                rx_ad_p3    <= {ser0_dat[23:16],ser1_dat[23:16]};
                rx_ad_p4    <= {ser0_dat[31:24],ser1_dat[31:24]};
                rx_ad_p5    <= {ser2_dat[7:0],  ser3_dat[7:0]};
                rx_ad_p6    <= {ser2_dat[15:8], ser3_dat[15:8]};
                rx_ad_p7    <= {ser2_dat[23:16],ser3_dat[23:16]};
                rx_ad_p8    <= {ser2_dat[31:24],ser3_dat[31:24]};
            
                rx_ad_p9    <= {ser4_dat[7:0],  ser5_dat[7:0]};
                rx_ad_p10   <= {ser4_dat[15:8], ser5_dat[15:8]};
                rx_ad_p11   <= {ser4_dat[23:16],ser5_dat[23:16]};
                rx_ad_p12   <= {ser4_dat[31:24],ser5_dat[31:24]};
                rx_ad_p13   <= {ser6_dat[7:0],  ser7_dat[7:0]};
                rx_ad_p14   <= {ser6_dat[15:8], ser7_dat[15:8]};
                rx_ad_p15   <= {ser6_dat[23:16],ser7_dat[23:16]};
                rx_ad_p16   <= {ser6_dat[31:24],ser7_dat[31:24]};
                
            end
        end
    end
end

endgenerate


endmodule
