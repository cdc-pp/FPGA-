//////////////////////////////////////////////////////////////////
//Copyright (C) 2023 Lemid Technology Co.,Ltd.*
//////////////////////////////////////////////////////////////////
//pro_top.v
//
//DESCRIPTION:
//    对jesd204b进行例化，以及数据重映射模块
//    ADC与FPGA之间使用JESD204B关系，ADC做发射端，FPGA做接收端
//    时钟模块配置，并判断锁定
//    1、ADC（TX）端，通过FPGA寄存器配置，使其进行复位操作。
//    2、ADC配置完成后，FPGA（RX）端JESD204B IP对reset信号进行复位。
//AUTHOR:
//    lzp
//CREATED DATE:
//    2023/11/27
//REVISION:
//1.0 - 初始版本
//////////////////////////////////////////////////////////////////

//JESD204B IP以及JESD204B PHY IP模块调用，若参数修改，对应的参数也需修改
jesd204_top#(

    .JESD204B_LANE                     (JESD204B_LANE          ),
    .JESD204B_GLBCLK_EN                (JESD204B_GLBCLK_EN     ),
    .JESD204B_RX_EN                    (1                      ),
    .JESD204B_TX_EN                    (0                      )

)
u_adc_jesd204
(

    // GT Reference Clock
    .refclk_p                          (refclk_p               ),
    .refclk_n                          (refclk_n               ),
    .glbclk_p                          (glbclk_p               ),  
    .glbclk_n                          (glbclk_n               ), 
    .o_core_clk                        (o_core_clk             ), 
    // GT Common Ports                                                              
    .cplllock_out                      (cplllock_out           ), //debug，测试项，内部cpll/qpll锁定标志
    .reset                             (reset                  ), //jesd204 IP reset信号输入
    .sysref                            (sysref                 ),  
    // Rx Ports                        
    // Rx AXI-S interface              
    .rx_tvalid                         (rx_tvalid              ),
    .rx_tdata                          (rx_tdata               ),
    .rx_sync                           (rx_sync                ),
    .rxp                               (rxp                    ),
    .rxn                               (rxn                    ),
    .jesd204_reset                     (jesd204_reset          ), //jesd204b 复位输出，与数据相关
    .rx_start_of_frame                 (rx_start_of_frame      ),
    .rx_end_of_frame                   (rx_end_of_frame        ),
    .rx_start_of_multiframe            (rx_start_of_multiframe ),
    .rx_end_of_multiframe              (rx_end_of_multiframe   ),
    .rx_frame_error                    (rx_frame_error         ),
    // Tx Ports                         
    // Tx AXI-S interface               
    .tx_tdata                          ('d0                    ),
    .tx_tready                         (                       ),
    .tx_sync                           (1'b0                   ),
    .txn                               (                       ),
    .txp                               (                       ),
    .tx_start_of_frame                 (                       ),
    .tx_start_of_multiframe            (                       ),
    // DRP Clock input                                          
    .drpclk                            (drpclk                 ),
    .axi_aclk                          (axi_aclk               ),
    .axi_rst                           (axi_rst                ),
    .axi4_lite_user_wr                 ('d0                    ),
    .axi4_lite_user_rd                 ('d0                    ),
    .axi4_lite_user_addr               ('d0                    ),
    .axi4_lite_user_wdata              ('d0                    ),
    .axi4_lite_user_wmask              ('d0                    ),
    .axi4_lite_user_rdata              (                       ),   
    .axi4_lite_user_ready              (                       )    

);

//ADC数据重映射模块，将ADC（TX）发送的数据，通过在JESD204B RX端解析数据，该模块持续更新中
sample_assembly#(

    .JESD204B_L                        (JESD204B_LANE          ), 
    .ADC_CHANNEL                       (ADC_CHANNEL            ),
    .ADC_WIDTH                         (ADC_WIDTH              ),
    .JESD204B_F                        (JESD204B_F             )
                                                               
)                                                              
u_sample_assembly                                              
(                                                              
    .clk                               (o_core_clk             ),
    .rst_n                             (~jesd204_reset         ),
                                                               
    .rx_tdata                          (rx_tdata               ), // IP核缓存的ADC数据
    .rx_tvalid                         (rx_tvalid              ), // IP核缓存的ADC数据
                                                               
    .o_ad_data_val                     (o_ad_data_val          ), // 解析后的数据
    .o_ad_data                         (o_ad_data              )  // 解析后的数据

);
