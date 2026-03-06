`timescale 1ns / 1ps

//`define DEF_JESD204B_CPLL
`define MULTI_CHIP
module jesd204_top#(

    parameter    JESD204B_LANE      =  4            ,
    parameter    JESD204B_GLBCLK_EN =  0            ,
    parameter    JESD204B_RX_EN     =  1            ,
    parameter    JESD204B_TX_EN     =  0            

)
(
    `ifdef MULTI_CHIP
    // GT Reference Clock
    input                              i_refclk              ,
    input                              i_sysref              ,
    input                              i_pclk                ,
    `else
    input                              glbclk_p              ,  
    input                              glbclk_n              ,
    input                              sysref_p              ,  
    input                              sysref_n              ,  
    `endif
    output                             o_core_clk            , 
    // GT Common Ports                                                  
    output                             cplllock_out          ,
//    output               common0_pll_clk_out   ,
//    output               common0_pll_refclk_out,
//    output               common0_pll_lock_out  ,
//    output               common1_pll_clk_out   ,
//    output               common1_pll_refclk_out,
//    output               common1_pll_lock_out  ,
    input                              reset                 , 
    // Rx Ports
    // Rx AXI-S interface
    output                             rx_tvalid             ,
    output [JESD204B_LANE * 32 -1:0]   rx_tdata              ,
    output                             rx_sync               ,
    input  [JESD204B_LANE - 1:0]       rxp                   ,
    input  [JESD204B_LANE - 1:0]       rxn                   ,
    output                             jesd204_reset         ,
    output [  3:0]                     rx_start_of_frame     ,
    output [  3:0]                     rx_end_of_frame       ,
    output [  3:0]                     rx_start_of_multiframe,
    output [  3:0]                     rx_end_of_multiframe  ,
    output [ 31:0]                     rx_frame_error        ,
    // Tx Ports
    // Tx AXI-S interface
    input  [JESD204B_LANE * 32 -1:0]   tx_tdata              ,
    output                             tx_tready             ,
    input                              tx_sync               ,
    output [JESD204B_LANE - 1:0]       txn                   ,
    output [JESD204B_LANE - 1:0]       txp                   ,
    output [  3:0]                     tx_start_of_frame     ,
    output [  3:0]                     tx_start_of_multiframe,
    // DRP Clock input                 
    input                              drpclk                ,
    input                              axi_aclk              ,
    input                              axi_rst               ,
    input  [  1:0]                     axi4_lite_user_wr     ,
    input  [  1:0]                     axi4_lite_user_rd     ,
    input  [ 11:0]                     axi4_lite_user_addr   ,
    input  [ 31:0]                     axi4_lite_user_wdata  ,
    input  [ 31:0]                     axi4_lite_user_wmask  ,
    output [  1:0][31:0]               axi4_lite_user_rdata  ,
    output [  1:0]                     axi4_lite_user_ready
);

// Wire declaration
    wire       refclk    ;
    wire       txoutclk  ;
    wire       aresetn   ;
//    reg  [3:0] sysref_cnt;
    wire       sysref    ;

    // GT Common I/O
    wire gt0_cplllock_out;
    wire gt1_cplllock_out;
    wire gt2_cplllock_out;
    wire gt3_cplllock_out;
    wire gt4_cplllock_out;
    wire gt5_cplllock_out;
    wire gt6_cplllock_out;
    wire gt7_cplllock_out;
     
    wire cplllock_out;
    
generate
if(JESD204B_LANE == 8)
    assign cplllock_out=gt0_cplllock_out&gt1_cplllock_out&gt2_cplllock_out&gt3_cplllock_out&gt4_cplllock_out&gt5_cplllock_out&gt6_cplllock_out&gt7_cplllock_out ;
else if(JESD204B_LANE == 4)
    assign cplllock_out=gt0_cplllock_out&gt1_cplllock_out&gt2_cplllock_out&gt3_cplllock_out ;
else if(JESD204B_LANE == 2)
    assign cplllock_out=gt0_cplllock_out&gt1_cplllock_out ;
else if(JESD204B_LANE == 1)
    assign cplllock_out=gt0_cplllock_out;        
endgenerate    

//    wire common0_qpll_refclk_i;
//    wire common0_qpll_clk_i   ;
//    wire common0_qpll_lock_i  ;
//    wire common1_qpll_refclk_i;
//    wire common1_qpll_clk_i   ;
//    wire common1_qpll_lock_i  ;

    wire rxencommaalign_i       ;
    wire rx_reset_done          ;
    wire tx_reset_done          ;

    wire        core_clk        ;
    wire        reset_gt        ;
    wire [31:0] gt0_txdata      ;
    wire [ 3:0] gt0_txcharisk   ;

    wire [31:0] gt1_txdata      ;
    wire [ 3:0] gt1_txcharisk   ;

    wire [31:0] gt2_txdata      ;
    wire [ 3:0] gt2_txcharisk   ;

    wire [31:0] gt3_txdata      ;
    wire [ 3:0] gt3_txcharisk   ;

    wire [31:0] gt4_txdata      ;
    wire [ 3:0] gt4_txcharisk   ;

    wire [31:0] gt5_txdata      ;
    wire [ 3:0] gt5_txcharisk   ;

    wire [31:0] gt6_txdata      ;
    wire [ 3:0] gt6_txcharisk   ;

    wire [31:0] gt7_txdata      ;
    wire [ 3:0] gt7_txcharisk   ;

    wire [31:0] gt0_rxdata      ;
    wire [ 3:0] gt0_rxcharisk   ;
    wire [ 3:0] gt0_rxdisperr   ;
    wire [ 3:0] gt0_rxnotintable;

    wire [31:0] gt1_rxdata      ;
    wire [ 3:0] gt1_rxcharisk   ;
    wire [ 3:0] gt1_rxdisperr   ;
    wire [ 3:0] gt1_rxnotintable;

    wire [31:0] gt2_rxdata      ;
    wire [ 3:0] gt2_rxcharisk   ;
    wire [ 3:0] gt2_rxdisperr   ;
    wire [ 3:0] gt2_rxnotintable;

    wire [31:0] gt3_rxdata      ;
    wire [ 3:0] gt3_rxcharisk   ;
    wire [ 3:0] gt3_rxdisperr   ;
    wire [ 3:0] gt3_rxnotintable;

    wire [31:0] gt4_rxdata      ;
    wire [ 3:0] gt4_rxcharisk   ;
    wire [ 3:0] gt4_rxdisperr   ;
    wire [ 3:0] gt4_rxnotintable;

    wire [31:0] gt5_txdata      ;
    wire [ 3:0] gt5_txcharisk   ;
    wire [31:0] gt5_rxdata      ;
    wire [ 3:0] gt5_rxcharisk   ;
    wire [ 3:0] gt5_rxdisperr   ;
    wire [ 3:0] gt5_rxnotintable;

    wire [31:0] gt6_rxdata      ;
    wire [ 3:0] gt6_rxcharisk   ;
    wire [ 3:0] gt6_rxdisperr   ;
    wire [ 3:0] gt6_rxnotintable;

    wire [31:0] gt7_rxdata      ;
    wire [ 3:0] gt7_rxcharisk   ;
    wire [ 3:0] gt7_rxdisperr   ;
    wire [ 3:0] gt7_rxnotintable;

// AXI-Lite Control/Status
    wire [11:0] s_axi_awaddr ;
    wire        s_axi_awvalid;
    wire        s_axi_awready;
    wire [31:0] s_axi_wdata  ;
    wire [ 3:0] s_axi_wstrb  ;
    wire        s_axi_wvalid ;
    wire        s_axi_wready ;
    wire [ 1:0] s_axi_bresp  ;
    wire        s_axi_bvalid ;
    wire        s_axi_bready ;
    wire [11:0] s_axi_araddr ;
    wire        s_axi_arvalid;
    wire        s_axi_arready;
    wire [31:0] s_axi_rdata  ;
    wire [ 1:0] s_axi_rresp  ;
    wire        s_axi_rvalid ;
    wire        s_axi_rready ;



assign o_core_clk = core_clk   ;

// JESD204 Core
generate
if(JESD204B_RX_EN == 1)
    begin
        if(JESD204B_LANE == 8)
            begin

                assign gt0_txdata    = 'd0;
                assign gt0_txcharisk = 'd0;
                assign gt1_txdata    = 'd0;
                assign gt1_txcharisk = 'd0;
                assign gt2_txdata    = 'd0;
                assign gt2_txcharisk = 'd0;
                assign gt3_txdata    = 'd0;
                assign gt3_txcharisk = 'd0;
                assign gt4_txdata    = 'd0;
                assign gt4_txcharisk = 'd0;
                assign gt5_txdata    = 'd0;
                assign gt5_txcharisk = 'd0;
                assign gt6_txdata    = 'd0;
                assign gt6_txcharisk = 'd0;
                assign gt7_txdata    = 'd0;
                assign gt7_txcharisk = 'd0;

                jesd204_0 jesd204_i (
                
                    .rx_reset              (reset                 ),
                    .rx_core_clk           (core_clk              ),
                
                    .rx_sysref             (sysref                ),
                    .rx_sync               (rx_sync               ),
                
                    // Ports Required for GT
                    .rx_reset_gt           (reset_gt              ),
                
                    .rxencommaalign_out    (rxencommaalign_i      ),
                    .rx_reset_done         (rx_reset_done         ),
                
                    // Lane 0
                    .gt0_rxdata            (gt0_rxdata            ),
                    .gt0_rxcharisk         (gt0_rxcharisk         ),
                    .gt0_rxdisperr         (gt0_rxdisperr         ),
                    .gt0_rxnotintable      (gt0_rxnotintable      ),
                
                    // Lane 1
                    .gt1_rxdata            (gt1_rxdata            ),
                    .gt1_rxcharisk         (gt1_rxcharisk         ),
                    .gt1_rxdisperr         (gt1_rxdisperr         ),
                    .gt1_rxnotintable      (gt1_rxnotintable      ),
                
                    // Lane 2
                    .gt2_rxdata            (gt2_rxdata            ),
                    .gt2_rxcharisk         (gt2_rxcharisk         ),
                    .gt2_rxdisperr         (gt2_rxdisperr         ),
                    .gt2_rxnotintable      (gt2_rxnotintable      ),
                
                    // Lane 3
                    .gt3_rxdata            (gt3_rxdata            ),
                    .gt3_rxcharisk         (gt3_rxcharisk         ),
                    .gt3_rxdisperr         (gt3_rxdisperr         ),
                    .gt3_rxnotintable      (gt3_rxnotintable      ),
                
                    // Lane 4
                    .gt4_rxdata            (gt4_rxdata            ),
                    .gt4_rxcharisk         (gt4_rxcharisk         ),
                    .gt4_rxdisperr         (gt4_rxdisperr         ),
                    .gt4_rxnotintable      (gt4_rxnotintable      ),
                
                    // Lane 5
                    .gt5_rxdata            (gt5_rxdata            ),
                    .gt5_rxcharisk         (gt5_rxcharisk         ),
                    .gt5_rxdisperr         (gt5_rxdisperr         ),
                    .gt5_rxnotintable      (gt5_rxnotintable      ),
                
                    // Lane 6
                    .gt6_rxdata            (gt6_rxdata            ),
                    .gt6_rxcharisk         (gt6_rxcharisk         ),
                    .gt6_rxdisperr         (gt6_rxdisperr         ),
                    .gt6_rxnotintable      (gt6_rxnotintable      ),
                
                    // Lane 7
                    .gt7_rxdata            (gt7_rxdata            ),
                    .gt7_rxcharisk         (gt7_rxcharisk         ),
                    .gt7_rxdisperr         (gt7_rxdisperr         ),
                    .gt7_rxnotintable      (gt7_rxnotintable      ),
                
                    // Rx AXI-S interface for each lane
                    .rx_aresetn            (aresetn               ),
                
                    .rx_start_of_frame     (rx_start_of_frame     ),
                    .rx_end_of_frame       (rx_end_of_frame       ),
                    .rx_start_of_multiframe(rx_start_of_multiframe),
                    .rx_end_of_multiframe  (rx_end_of_multiframe  ),
                    .rx_frame_error        (rx_frame_error        ),
                
                    .rx_tdata              (rx_tdata              ),
                    .rx_tvalid             (rx_tvalid             ),
                
                    // AXI-Lite Control/Status
                    .s_axi_aclk            (axi_aclk              ),
                    .s_axi_aresetn         (~axi_rst              ),
                    .s_axi_awaddr          (s_axi_awaddr          ),
                    .s_axi_awvalid         (s_axi_awvalid         ),
                    .s_axi_awready         (s_axi_awready         ),
                    .s_axi_wdata           (s_axi_wdata           ),
                    .s_axi_wstrb           (s_axi_wstrb           ),
                    .s_axi_wvalid          (s_axi_wvalid          ),
                    .s_axi_wready          (s_axi_wready          ),
                    .s_axi_bresp           (s_axi_bresp           ),
                    .s_axi_bvalid          (s_axi_bvalid          ),
                    .s_axi_bready          (s_axi_bready          ),
                    .s_axi_araddr          (s_axi_araddr          ),
                    .s_axi_arvalid         (s_axi_arvalid         ),
                    .s_axi_arready         (s_axi_arready         ),
                    .s_axi_rdata           (s_axi_rdata           ),
                    .s_axi_rresp           (s_axi_rresp           ),
                    .s_axi_rvalid          (s_axi_rvalid          ),
                    .s_axi_rready          (s_axi_rready          )
                );
            end
        else if(JESD204B_LANE == 4)
            begin

                assign gt0_txdata    = 'd0;
                assign gt0_txcharisk = 'd0;
                assign gt1_txdata    = 'd0;
                assign gt1_txcharisk = 'd0;
                assign gt2_txdata    = 'd0;
                assign gt2_txcharisk = 'd0;
                assign gt3_txdata    = 'd0;
                assign gt3_txcharisk = 'd0;

                jesd204_0 jesd204_i (
                
                    .rx_reset              (reset                 ),
                    .rx_core_clk           (core_clk              ),
                
                    .rx_sysref             (sysref                ),
                    .rx_sync               (rx_sync               ),
                
                    // Ports Required for GT
                    .rx_reset_gt           (reset_gt              ),
                
                    .rxencommaalign_out    (rxencommaalign_i      ),
                    .rx_reset_done         (rx_reset_done         ),
                
                    // Lane 0
                    .gt0_rxdata            (gt0_rxdata            ),
                    .gt0_rxcharisk         (gt0_rxcharisk         ),
                    .gt0_rxdisperr         (gt0_rxdisperr         ),
                    .gt0_rxnotintable      (gt0_rxnotintable      ),
                
                    // Lane 1
                    .gt1_rxdata            (gt1_rxdata            ),
                    .gt1_rxcharisk         (gt1_rxcharisk         ),
                    .gt1_rxdisperr         (gt1_rxdisperr         ),
                    .gt1_rxnotintable      (gt1_rxnotintable      ),
                
                    // Lane 2
                    .gt2_rxdata            (gt2_rxdata            ),
                    .gt2_rxcharisk         (gt2_rxcharisk         ),
                    .gt2_rxdisperr         (gt2_rxdisperr         ),
                    .gt2_rxnotintable      (gt2_rxnotintable      ),
                
                    // Lane 3
                    .gt3_rxdata            (gt3_rxdata            ),
                    .gt3_rxcharisk         (gt3_rxcharisk         ),
                    .gt3_rxdisperr         (gt3_rxdisperr         ),
                    .gt3_rxnotintable      (gt3_rxnotintable      ),
                
                    // Rx AXI-S interface for each lane
                    .rx_aresetn            (aresetn               ),
                
                    .rx_start_of_frame     (rx_start_of_frame     ),
                    .rx_end_of_frame       (rx_end_of_frame       ),
                    .rx_start_of_multiframe(rx_start_of_multiframe),
                    .rx_end_of_multiframe  (rx_end_of_multiframe  ),
                    .rx_frame_error        (rx_frame_error        ),
                
                    .rx_tdata              (rx_tdata              ),
                    .rx_tvalid             (rx_tvalid             ),
                
                    // AXI-Lite Control/Status
                    .s_axi_aclk            (axi_aclk              ),
                    .s_axi_aresetn         (~axi_rst              ),
                    .s_axi_awaddr          (s_axi_awaddr          ),
                    .s_axi_awvalid         (s_axi_awvalid         ),
                    .s_axi_awready         (s_axi_awready         ),
                    .s_axi_wdata           (s_axi_wdata           ),
                    .s_axi_wstrb           (s_axi_wstrb           ),
                    .s_axi_wvalid          (s_axi_wvalid          ),
                    .s_axi_wready          (s_axi_wready          ),
                    .s_axi_bresp           (s_axi_bresp           ),
                    .s_axi_bvalid          (s_axi_bvalid          ),
                    .s_axi_bready          (s_axi_bready          ),
                    .s_axi_araddr          (s_axi_araddr          ),
                    .s_axi_arvalid         (s_axi_arvalid         ),
                    .s_axi_arready         (s_axi_arready         ),
                    .s_axi_rdata           (s_axi_rdata           ),
                    .s_axi_rresp           (s_axi_rresp           ),
                    .s_axi_rvalid          (s_axi_rvalid          ),
                    .s_axi_rready          (s_axi_rready          )
                );
            end
        else if(JESD204B_LANE == 2)
            begin

                assign gt0_txdata    = 'd0;
                assign gt0_txcharisk = 'd0;
                assign gt1_txdata    = 'd0;
                assign gt1_txcharisk = 'd0;

                jesd204_0 jesd204_i (
                
                    .rx_reset              (reset                 ),
                    .rx_core_clk           (core_clk              ),
                
                    .rx_sysref             (sysref                ),
                    .rx_sync               (rx_sync               ),
                
                    // Ports Required for GT
                    .rx_reset_gt           (reset_gt              ),
                
                    .rxencommaalign_out    (rxencommaalign_i      ),
                    .rx_reset_done         (rx_reset_done         ),
                
                    // Lane 0
                    .gt0_rxdata            (gt0_rxdata            ),
                    .gt0_rxcharisk         (gt0_rxcharisk         ),
                    .gt0_rxdisperr         (gt0_rxdisperr         ),
                    .gt0_rxnotintable      (gt0_rxnotintable      ),
                
                    // Lane 1
                    .gt1_rxdata            (gt1_rxdata            ),
                    .gt1_rxcharisk         (gt1_rxcharisk         ),
                    .gt1_rxdisperr         (gt1_rxdisperr         ),
                    .gt1_rxnotintable      (gt1_rxnotintable      ),
                
                    // Rx AXI-S interface for each lane
                    .rx_aresetn            (aresetn               ),
                
                    .rx_start_of_frame     (rx_start_of_frame     ),
                    .rx_end_of_frame       (rx_end_of_frame       ),
                    .rx_start_of_multiframe(rx_start_of_multiframe),
                    .rx_end_of_multiframe  (rx_end_of_multiframe  ),
                    .rx_frame_error        (rx_frame_error        ),
                
                    .rx_tdata              (rx_tdata              ),
                    .rx_tvalid             (rx_tvalid             ),
                
                    // AXI-Lite Control/Status
                    .s_axi_aclk            (axi_aclk              ),
                    .s_axi_aresetn         (~axi_rst              ),
                    .s_axi_awaddr          (s_axi_awaddr          ),
                    .s_axi_awvalid         (s_axi_awvalid         ),
                    .s_axi_awready         (s_axi_awready         ),
                    .s_axi_wdata           (s_axi_wdata           ),
                    .s_axi_wstrb           (s_axi_wstrb           ),
                    .s_axi_wvalid          (s_axi_wvalid          ),
                    .s_axi_wready          (s_axi_wready          ),
                    .s_axi_bresp           (s_axi_bresp           ),
                    .s_axi_bvalid          (s_axi_bvalid          ),
                    .s_axi_bready          (s_axi_bready          ),
                    .s_axi_araddr          (s_axi_araddr          ),
                    .s_axi_arvalid         (s_axi_arvalid         ),
                    .s_axi_arready         (s_axi_arready         ),
                    .s_axi_rdata           (s_axi_rdata           ),
                    .s_axi_rresp           (s_axi_rresp           ),
                    .s_axi_rvalid          (s_axi_rvalid          ),
                    .s_axi_rready          (s_axi_rready          )
                );
            end
        else if(JESD204B_LANE == 1)
            begin

                assign gt0_txdata    = 'd0;
                assign gt0_txcharisk = 'd0;

                jesd204_0 jesd204_i (
                
                    .rx_reset              (reset                 ),
                    .rx_core_clk           (core_clk              ),
                
                    .rx_sysref             (sysref                ),
                    .rx_sync               (rx_sync               ),
                
                    // Ports Required for GT
                    .rx_reset_gt           (reset_gt              ),
                
                    .rxencommaalign_out    (rxencommaalign_i      ),
                    .rx_reset_done         (rx_reset_done         ),
                
                    // Lane 0
                    .gt0_rxdata            (gt0_rxdata            ),
                    .gt0_rxcharisk         (gt0_rxcharisk         ),
                    .gt0_rxdisperr         (gt0_rxdisperr         ),
                    .gt0_rxnotintable      (gt0_rxnotintable      ),
                
                    // Rx AXI-S interface for each lane
                    .rx_aresetn            (aresetn               ),
                
                    .rx_start_of_frame     (rx_start_of_frame     ),
                    .rx_end_of_frame       (rx_end_of_frame       ),
                    .rx_start_of_multiframe(rx_start_of_multiframe),
                    .rx_end_of_multiframe  (rx_end_of_multiframe  ),
                    .rx_frame_error        (rx_frame_error        ),
                
                    .rx_tdata              (rx_tdata              ),
                    .rx_tvalid             (rx_tvalid             ),
                
                    // AXI-Lite Control/Status
                    .s_axi_aclk            (axi_aclk              ),
                    .s_axi_aresetn         (~axi_rst              ),
                    .s_axi_awaddr          (s_axi_awaddr          ),
                    .s_axi_awvalid         (s_axi_awvalid         ),
                    .s_axi_awready         (s_axi_awready         ),
                    .s_axi_wdata           (s_axi_wdata           ),
                    .s_axi_wstrb           (s_axi_wstrb           ),
                    .s_axi_wvalid          (s_axi_wvalid          ),
                    .s_axi_wready          (s_axi_wready          ),
                    .s_axi_bresp           (s_axi_bresp           ),
                    .s_axi_bvalid          (s_axi_bvalid          ),
                    .s_axi_bready          (s_axi_bready          ),
                    .s_axi_araddr          (s_axi_araddr          ),
                    .s_axi_arvalid         (s_axi_arvalid         ),
                    .s_axi_arready         (s_axi_arready         ),
                    .s_axi_rdata           (s_axi_rdata           ),
                    .s_axi_rresp           (s_axi_rresp           ),
                    .s_axi_rvalid          (s_axi_rvalid          ),
                    .s_axi_rready          (s_axi_rready          )
                );
            end
    end
if(JESD204B_TX_EN == 1)
    begin
        assign rxencommaalign_i = 1'b0;
        if(JESD204B_LANE == 8)
            begin
                jesd204_0 u_jesd204_0 (

                    // Lane 0
                    .gt0_txdata            (gt0_txdata            ),   
                    .gt0_txcharisk         (gt0_txcharisk         ),   

                    // Lane 1
                    .gt1_txdata            (gt1_txdata            ),   
                    .gt1_txcharisk         (gt1_txcharisk         ),   

                    // Lane 2
                    .gt2_txdata            (gt2_txdata            ),   
                    .gt2_txcharisk         (gt2_txcharisk         ),   

                    // Lane 3
                    .gt3_txdata            (gt3_txdata            ),   
                    .gt3_txcharisk         (gt3_txcharisk         ),   

                    // Lane 4
                    .gt4_txdata            (gt4_txdata            ),   
                    .gt4_txcharisk         (gt4_txcharisk         ),   

                    // Lane 5
                    .gt5_txdata            (gt5_txdata            ),   
                    .gt5_txcharisk         (gt5_txcharisk         ),   

                    // Lane 6
                    .gt6_txdata            (gt6_txdata            ),   
                    .gt6_txcharisk         (gt6_txcharisk         ),   

                    // Lane 7
                    .gt7_txdata            (gt7_txdata            ),   
                    .gt7_txcharisk         (gt7_txcharisk         ), 

                    .tx_reset_done         (tx_reset_done         ),   

                    .gt_prbssel_out        (                      ),   
                    .tx_reset_gt           (reset_gt              ),   
                    .tx_core_clk           (core_clk              ),  

                    .s_axi_aclk            (axi_aclk            ),   
                    .s_axi_aresetn         (~axi_rst              ),   
                    .s_axi_awaddr          (s_axi_awaddr          ),   
                    .s_axi_awvalid         (s_axi_awvalid         ),   
                    .s_axi_awready         (s_axi_awready         ),   
                    .s_axi_wdata           (s_axi_wdata           ),   
                    .s_axi_wstrb           (s_axi_wstrb           ),   
                    .s_axi_wvalid          (s_axi_wvalid          ),   
                    .s_axi_wready          (s_axi_wready          ),   
                    .s_axi_bresp           (s_axi_bresp           ),   
                    .s_axi_bvalid          (s_axi_bvalid          ),   
                    .s_axi_bready          (s_axi_bready          ),   
                    .s_axi_araddr          (s_axi_araddr          ),   
                    .s_axi_arvalid         (s_axi_arvalid         ),   
                    .s_axi_arready         (s_axi_arready         ),   
                    .s_axi_rdata           (s_axi_rdata           ),   
                    .s_axi_rresp           (s_axi_rresp           ),   
                    .s_axi_rvalid          (s_axi_rvalid          ),   
                    .s_axi_rready          (s_axi_rready          ),   

                    .tx_reset              (reset                 ),   

                    .tx_sysref             (sysref                ),   
                    .tx_start_of_frame     (tx_start_of_frame     ),   
                    .tx_start_of_multiframe(tx_start_of_multiframe),   
                    .tx_aresetn            (aresetn               ),   
                    .tx_tdata              (tx_tdata              ),   
                    .tx_tready             (tx_tready             ),   
                    .tx_sync               (tx_sync               )    
                );                                                     
            end
        else if(JESD204B_LANE == 4)
            begin
                jesd204_0 u_jesd204_0 (

                    // Lane 0
                    .gt0_txdata            (gt0_txdata            ),   
                    .gt0_txcharisk         (gt0_txcharisk         ),   

                    // Lane 1
                    .gt1_txdata            (gt1_txdata            ),   
                    .gt1_txcharisk         (gt1_txcharisk         ),   

                    // Lane 2
                    .gt2_txdata            (gt2_txdata            ),   
                    .gt2_txcharisk         (gt2_txcharisk         ),   

                    // Lane 3
                    .gt3_txdata            (gt3_txdata            ),   
                    .gt3_txcharisk         (gt3_txcharisk         ),   

                    .tx_reset_done         (tx_reset_done         ),   

                    .gt_prbssel_out        (                      ),   
                    .tx_reset_gt           (reset_gt              ),   
                    .tx_core_clk           (core_clk              ),  

                    .s_axi_aclk            (axi_aclk            ),   
                    .s_axi_aresetn         (~axi_rst              ),   
                    .s_axi_awaddr          (s_axi_awaddr          ),   
                    .s_axi_awvalid         (s_axi_awvalid         ),   
                    .s_axi_awready         (s_axi_awready         ),   
                    .s_axi_wdata           (s_axi_wdata           ),   
                    .s_axi_wstrb           (s_axi_wstrb           ),   
                    .s_axi_wvalid          (s_axi_wvalid          ),   
                    .s_axi_wready          (s_axi_wready          ),   
                    .s_axi_bresp           (s_axi_bresp           ),   
                    .s_axi_bvalid          (s_axi_bvalid          ),   
                    .s_axi_bready          (s_axi_bready          ),   
                    .s_axi_araddr          (s_axi_araddr          ),   
                    .s_axi_arvalid         (s_axi_arvalid         ),   
                    .s_axi_arready         (s_axi_arready         ),   
                    .s_axi_rdata           (s_axi_rdata           ),   
                    .s_axi_rresp           (s_axi_rresp           ),   
                    .s_axi_rvalid          (s_axi_rvalid          ),   
                    .s_axi_rready          (s_axi_rready          ),   

                    .tx_reset              (reset                 ),   

                    .tx_sysref             (sysref                ),   
                    .tx_start_of_frame     (tx_start_of_frame     ),   
                    .tx_start_of_multiframe(tx_start_of_multiframe),   
                    .tx_aresetn            (aresetn               ),   
                    .tx_tdata              (tx_tdata              ),   
                    .tx_tready             (tx_tready             ),   
                    .tx_sync               (tx_sync               )    
                ); 
            end
        else if(JESD204B_LANE == 2)
            begin
                jesd204_0 u_jesd204_0 (

                    // Lane 0
                    .gt0_txdata            (gt0_txdata            ),   
                    .gt0_txcharisk         (gt0_txcharisk         ),   

                    // Lane 1
                    .gt1_txdata            (gt1_txdata            ),   
                    .gt1_txcharisk         (gt1_txcharisk         ),   

                    .tx_reset_done         (tx_reset_done         ),   

                    .gt_prbssel_out        (                      ),   
                    .tx_reset_gt           (reset_gt              ),   
                    .tx_core_clk           (core_clk              ),  

                    .s_axi_aclk            (axi_aclk              ),   
                    .s_axi_aresetn         (~axi_rst              ),   
                    .s_axi_awaddr          (s_axi_awaddr          ),   
                    .s_axi_awvalid         (s_axi_awvalid         ),   
                    .s_axi_awready         (s_axi_awready         ),   
                    .s_axi_wdata           (s_axi_wdata           ),   
                    .s_axi_wstrb           (s_axi_wstrb           ),   
                    .s_axi_wvalid          (s_axi_wvalid          ),   
                    .s_axi_wready          (s_axi_wready          ),   
                    .s_axi_bresp           (s_axi_bresp           ),   
                    .s_axi_bvalid          (s_axi_bvalid          ),   
                    .s_axi_bready          (s_axi_bready          ),   
                    .s_axi_araddr          (s_axi_araddr          ),   
                    .s_axi_arvalid         (s_axi_arvalid         ),   
                    .s_axi_arready         (s_axi_arready         ),   
                    .s_axi_rdata           (s_axi_rdata           ),   
                    .s_axi_rresp           (s_axi_rresp           ),   
                    .s_axi_rvalid          (s_axi_rvalid          ),   
                    .s_axi_rready          (s_axi_rready          ),   

                    .tx_reset              (reset                 ),   

                    .tx_sysref             (sysref                ),   
                    .tx_start_of_frame     (tx_start_of_frame     ),   
                    .tx_start_of_multiframe(tx_start_of_multiframe),   
                    .tx_aresetn            (aresetn               ),   
                    .tx_tdata              (tx_tdata              ),   
                    .tx_tready             (tx_tready             ),   
                    .tx_sync               (tx_sync               )    
                ); 
            end
        else if(JESD204B_LANE == 1)
            begin
                jesd204_0 u_jesd204_0 (

                    // Lane 0
                    .gt0_txdata            (gt0_txdata            ),   
                    .gt0_txcharisk         (gt0_txcharisk         ),   

                    .tx_reset_done         (tx_reset_done         ),   

                    .gt_prbssel_out        (                      ),   
                    .tx_reset_gt           (reset_gt              ),   
                    .tx_core_clk           (core_clk              ),  

                    .s_axi_aclk            (axi_aclk            ),   
                    .s_axi_aresetn         (~axi_rst              ),   
                    .s_axi_awaddr          (s_axi_awaddr          ),   
                    .s_axi_awvalid         (s_axi_awvalid         ),   
                    .s_axi_awready         (s_axi_awready         ),   
                    .s_axi_wdata           (s_axi_wdata           ),   
                    .s_axi_wstrb           (s_axi_wstrb           ),   
                    .s_axi_wvalid          (s_axi_wvalid          ),   
                    .s_axi_wready          (s_axi_wready          ),   
                    .s_axi_bresp           (s_axi_bresp           ),   
                    .s_axi_bvalid          (s_axi_bvalid          ),   
                    .s_axi_bready          (s_axi_bready          ),   
                    .s_axi_araddr          (s_axi_araddr          ),   
                    .s_axi_arvalid         (s_axi_arvalid         ),   
                    .s_axi_arready         (s_axi_arready         ),   
                    .s_axi_rdata           (s_axi_rdata           ),   
                    .s_axi_rresp           (s_axi_rresp           ),   
                    .s_axi_rvalid          (s_axi_rvalid          ),   
                    .s_axi_rready          (s_axi_rready          ),   

                    .tx_reset              (reset                 ),   

                    .tx_sysref             (sysref                ),   
                    .tx_start_of_frame     (tx_start_of_frame     ),   
                    .tx_start_of_multiframe(tx_start_of_multiframe),   
                    .tx_aresetn            (aresetn               ),   
                    .tx_tdata              (tx_tdata              ),   
                    .tx_tready             (tx_tready             ),   
                    .tx_sync               (tx_sync               )    
                ); 
            end
    end
endgenerate

// Shared Clocking Module
// Clocks from this module can be used to
// share with other CL modules
    `ifdef MULTI_CHIP
    
    assign refclk   = i_refclk;
    assign sysref   = i_sysref;
    assign core_clk = i_pclk;
    
    `else
    jesd204_rx_clocking#(
    
        .JESD204B_GLBCLK_EN      (JESD204B_GLBCLK_EN   )

    )
    u_jesd204_rx_clocking
    ( 

        .i_refclk_p              (refclk_p             ),
        .i_refclk_n              (refclk_n             ),
        .i_glbclk_p              (glbclk_p             ),
        .i_glbclk_n              (glbclk_n             ),
        .i_sysref_p              (sysref_p             ),
        .i_sysref_n              (sysref_n             ),
        .o_refclk                (refclk               ),
        .o_core_clk              (core_clk             ),
        .o_sysref                (sysref               )

    );
    `endif
// Instantiate the JESD204 PHY core
generate 
begin
if(JESD204B_LANE == 8)
    begin
        jesd204_0_phy i_jesd204_phy (
            // Loopback
            .gt0_loopback_in         (3'b000               ),
        
            // GT Reset Done Outputs
            .gt0_txresetdone_out     (                     ),
            .gt0_rxresetdone_out     (                     ),
        
            .gt0_cplllock_out        (gt0_cplllock_out     ),
        
            // Power Down Ports
            .gt0_rxpd_in             (2'b00                ),
            .gt0_txpd_in             (2'b00                ),
        
            // RX Margin Analysis Ports
            .gt0_eyescandataerror_out(                     ),
            .gt0_eyescantrigger_in   (1'b0                 ),
            .gt0_eyescanreset_in     (1'b0                 ),
        
            // Tx Control
            .gt0_txpostcursor_in     (5'b00000             ),
            .gt0_txprecursor_in      (5'b00000             ),
            .gt0_txdiffctrl_in       (4'b1000              ),
            .gt0_txpolarity_in       (1'b0                 ),
            .gt0_txinhibit_in        (1'b0                 ),
        
            // TX Pattern Checker ports
            .gt0_txprbsforceerr_in   (1'b0                 ),
        
            // TX Initialization
            .gt0_txpcsreset_in       (1'b0                 ),
            .gt0_txpmareset_in       (1'b0                 ),
        
            // TX Buffer Ports
            .gt0_txbufstatus_out     (                     ),
        
            // Rx CDR Ports
            .gt0_rxcdrhold_in        (1'b0                 ),
        
            // Rx Polarity
            .gt0_rxpolarity_in       (1'b0                 ),
        
            // Receive Ports - Pattern Checker ports
            .gt0_rxprbserr_out       (                     ),
            .gt0_rxprbssel_in        (3'b0                 ),
            .gt0_rxprbscntreset_in   (1'b0                 ),
        
            // RX Buffer Bypass Ports
            .gt0_rxbufreset_in       (1'b0                 ),
            .gt0_rxbufstatus_out     (                     ),
            .gt0_rxstatus_out        (                     ),
        
            // RX Byte and Word Alignment Ports
            .gt0_rxbyteisaligned_out (                     ),
            .gt0_rxbyterealign_out   (                     ),
            .gt0_rxcommadet_out      (                     ),
        
            // Digital Monitor Ports
            .gt0_dmonitorout_out     (                     ),
        
        
            // RX Initialization and Reset Ports
            .gt0_rxpcsreset_in       (1'b0                 ),
            .gt0_rxpmareset_in       (1'b0                 ),
        
            // Receive Ports - RX Equalizer Ports
            .gt0_rxlpmen_in          (1'b1                 ),
            .gt0_rxdfelpmreset_in    (1'b0                 ),
            .gt0_rxmonitorout_out    (                     ),
            .gt0_rxmonitorsel_in     (2'b0                 ),
        
            // Loopback
            .gt1_loopback_in         (3'b000               ),
        
            // GT Reset Done Outputs
            .gt1_txresetdone_out     (                     ),
            .gt1_rxresetdone_out     (                     ),
        
            .gt1_cplllock_out        (gt1_cplllock_out     ),
        
            // Power Down Ports
            .gt1_rxpd_in             (2'b00                ),
            .gt1_txpd_in             (2'b00                ),
        
            // RX Margin Analysis Ports
            .gt1_eyescandataerror_out(                     ),
            .gt1_eyescantrigger_in   (1'b0                 ),
            .gt1_eyescanreset_in     (1'b0                 ),
        
            // Tx Control
            .gt1_txpostcursor_in     (5'b00000             ),
            .gt1_txprecursor_in      (5'b00000             ),
            .gt1_txdiffctrl_in       (4'b1000              ),
            .gt1_txpolarity_in       (1'b0                 ),
            .gt1_txinhibit_in        (1'b0                 ),
        
            // TX Pattern Checker ports
            .gt1_txprbsforceerr_in   (1'b0                 ),
        
            // TX Initialization
            .gt1_txpcsreset_in       (1'b0                 ),
            .gt1_txpmareset_in       (1'b0                 ),
        
            // TX Buffer Ports
            .gt1_txbufstatus_out     (                     ),
        
            // Rx CDR Ports
            .gt1_rxcdrhold_in        (1'b0                 ),
        
            // Rx Polarity
            .gt1_rxpolarity_in       (1'b0                 ),
        
            // Receive Ports - Pattern Checker ports
            .gt1_rxprbserr_out       (                     ),
            .gt1_rxprbssel_in        (3'b0                 ),
            .gt1_rxprbscntreset_in   (1'b0                 ),
        
            // RX Buffer Bypass Ports
            .gt1_rxbufreset_in       (1'b0                 ),
            .gt1_rxbufstatus_out     (                     ),
            .gt1_rxstatus_out        (                     ),
        
            // RX Byte and Word Alignment Ports
            .gt1_rxbyteisaligned_out (                     ),
            .gt1_rxbyterealign_out   (                     ),
            .gt1_rxcommadet_out      (                     ),
        
            // Digital Monitor Ports
            .gt1_dmonitorout_out     (                     ),
        
        
            // RX Initialization and Reset Ports
            .gt1_rxpcsreset_in       (1'b0                 ),
            .gt1_rxpmareset_in       (1'b0                 ),
        
            // Receive Ports - RX Equalizer Ports
            .gt1_rxlpmen_in          (1'b1                 ),
            .gt1_rxdfelpmreset_in    (1'b0                 ),
            .gt1_rxmonitorout_out    (                     ),
            .gt1_rxmonitorsel_in     (2'b0                 ),
        
            // Loopback
            .gt2_loopback_in         (3'b000               ),
        
            // GT Reset Done Outputs
            .gt2_txresetdone_out     (                     ),
            .gt2_rxresetdone_out     (                     ),
        
            .gt2_cplllock_out        (gt2_cplllock_out     ),
        
            // Power Down Ports
            .gt2_rxpd_in             (2'b00                ),
            .gt2_txpd_in             (2'b00                ),
        
            // RX Margin Analysis Ports
            .gt2_eyescandataerror_out(                     ),
            .gt2_eyescantrigger_in   (1'b0                 ),
            .gt2_eyescanreset_in     (1'b0                 ),
        
            // Tx Control
            .gt2_txpostcursor_in     (5'b00000             ),
            .gt2_txprecursor_in      (5'b00000             ),
            .gt2_txdiffctrl_in       (4'b1000              ),
            .gt2_txpolarity_in       (1'b0                 ),
            .gt2_txinhibit_in        (1'b0                 ),
        
            // TX Pattern Checker ports
            .gt2_txprbsforceerr_in   (1'b0                 ),
        
            // TX Initialization
            .gt2_txpcsreset_in       (1'b0                 ),
            .gt2_txpmareset_in       (1'b0                 ),
        
            // TX Buffer Ports
            .gt2_txbufstatus_out     (                     ),
        
            // Rx CDR Ports
            .gt2_rxcdrhold_in        (1'b0                 ),
        
            // Rx Polarity
            .gt2_rxpolarity_in       (1'b0                 ),
        
            // Receive Ports - Pattern Checker ports
            .gt2_rxprbserr_out       (                     ),
            .gt2_rxprbssel_in        (3'b0                 ),
            .gt2_rxprbscntreset_in   (1'b0                 ),
        
            // RX Buffer Bypass Ports
            .gt2_rxbufreset_in       (1'b0                 ),
            .gt2_rxbufstatus_out     (                     ),
            .gt2_rxstatus_out        (                     ),
        
            // RX Byte and Word Alignment Ports
            .gt2_rxbyteisaligned_out (                     ),
            .gt2_rxbyterealign_out   (                     ),
            .gt2_rxcommadet_out      (                     ),
        
            // Digital Monitor Ports
            .gt2_dmonitorout_out     (                     ),
        
        
            // RX Initialization and Reset Ports
            .gt2_rxpcsreset_in       (1'b0                 ),
            .gt2_rxpmareset_in       (1'b0                 ),
        
            // Receive Ports - RX Equalizer Ports
            .gt2_rxlpmen_in          (1'b1                 ),
            .gt2_rxdfelpmreset_in    (1'b0                 ),
            .gt2_rxmonitorout_out    (                     ),
            .gt2_rxmonitorsel_in     (2'b0                 ),
        
            // Loopback
            .gt3_loopback_in         (3'b000               ),
        
            // GT Reset Done Outputs
            .gt3_txresetdone_out     (                     ),
            .gt3_rxresetdone_out     (                     ),
        
            .gt3_cplllock_out        (  gt3_cplllock_out   ),
        
            // Power Down Ports
            .gt3_rxpd_in             (2'b00                ),
            .gt3_txpd_in             (2'b00                ),
        
            // RX Margin Analysis Ports
            .gt3_eyescandataerror_out(                     ),
            .gt3_eyescantrigger_in   (1'b0                 ),
            .gt3_eyescanreset_in     (1'b0                 ),
        
            // Tx Control
            .gt3_txpostcursor_in     (5'b00000             ),
            .gt3_txprecursor_in      (5'b00000             ),
            .gt3_txdiffctrl_in       (4'b1000              ),
            .gt3_txpolarity_in       (1'b0                 ),
            .gt3_txinhibit_in        (1'b0                 ),
        
            // TX Pattern Checker ports
            .gt3_txprbsforceerr_in   (1'b0                 ),
        
            // TX Initialization
            .gt3_txpcsreset_in       (1'b0                 ),
            .gt3_txpmareset_in       (1'b0                 ),
        
            // TX Buffer Ports
            .gt3_txbufstatus_out     (                     ),
        
            // Rx CDR Ports
            .gt3_rxcdrhold_in        (1'b0                 ),
        
            // Rx Polarity
            .gt3_rxpolarity_in       (1'b0                 ),
        
            // Receive Ports - Pattern Checker ports
            .gt3_rxprbserr_out       (                     ),
            .gt3_rxprbssel_in        (3'b0                 ),
            .gt3_rxprbscntreset_in   (1'b0                 ),
        
            // RX Buffer Bypass Ports
            .gt3_rxbufreset_in       (1'b0                 ),
            .gt3_rxbufstatus_out     (                     ),
            .gt3_rxstatus_out        (                     ),
        
            // RX Byte and Word Alignment Ports
            .gt3_rxbyteisaligned_out (                     ),
            .gt3_rxbyterealign_out   (                     ),
            .gt3_rxcommadet_out      (                     ),
        
            // Digital Monitor Ports
            .gt3_dmonitorout_out     (                     ),
        
        
            // RX Initialization and Reset Ports
            .gt3_rxpcsreset_in       (1'b0                 ),
            .gt3_rxpmareset_in       (1'b0                 ),
        
            // Receive Ports - RX Equalizer Ports
            .gt3_rxlpmen_in          (1'b1                 ),
            .gt3_rxdfelpmreset_in    (1'b0                 ),
            .gt3_rxmonitorout_out    (                     ),
            .gt3_rxmonitorsel_in     (2'b0                 ),
        
            // Loopback
            .gt4_loopback_in         (3'b000               ),
        
            // GT Reset Done Outputs
            .gt4_txresetdone_out     (                     ),
            .gt4_rxresetdone_out     (                     ),
        
            .gt4_cplllock_out        (  gt4_cplllock_out   ),
        
            // Power Down Ports
            .gt4_rxpd_in             (2'b00                ),
            .gt4_txpd_in             (2'b00                ),
        
            // RX Margin Analysis Ports
            .gt4_eyescandataerror_out(                     ),
            .gt4_eyescantrigger_in   (1'b0                 ),
            .gt4_eyescanreset_in     (1'b0                 ),
        
            // Tx Control
            .gt4_txpostcursor_in     (5'b00000             ),
            .gt4_txprecursor_in      (5'b00000             ),
            .gt4_txdiffctrl_in       (4'b1000              ),
            .gt4_txpolarity_in       (1'b0                 ),
            .gt4_txinhibit_in        (1'b0                 ),
        
            // TX Pattern Checker ports
            .gt4_txprbsforceerr_in   (1'b0                 ),
        
            // TX Initialization
            .gt4_txpcsreset_in       (1'b0                 ),
            .gt4_txpmareset_in       (1'b0                 ),
        
            // TX Buffer Ports
            .gt4_txbufstatus_out     (                     ),
        
            // Rx CDR Ports
            .gt4_rxcdrhold_in        (1'b0                 ),
        
            // Rx Polarity
            .gt4_rxpolarity_in       (1'b0                 ),
        
            // Receive Ports - Pattern Checker ports
            .gt4_rxprbserr_out       (                     ),
            .gt4_rxprbssel_in        (3'b0                 ),
            .gt4_rxprbscntreset_in   (1'b0                 ),
        
            // RX Buffer Bypass Ports
            .gt4_rxbufreset_in       (1'b0                 ),
            .gt4_rxbufstatus_out     (                     ),
            .gt4_rxstatus_out        (                     ),
        
            // RX Byte and Word Alignment Ports
            .gt4_rxbyteisaligned_out (                     ),
            .gt4_rxbyterealign_out   (                     ),
            .gt4_rxcommadet_out      (                     ),
        
            // Digital Monitor Ports
            .gt4_dmonitorout_out     (                     ),
        
        
            // RX Initialization and Reset Ports
            .gt4_rxpcsreset_in       (1'b0                 ),
            .gt4_rxpmareset_in       (1'b0                 ),
        
            // Receive Ports - RX Equalizer Ports
            .gt4_rxlpmen_in          (1'b1                 ),
            .gt4_rxdfelpmreset_in    (1'b0                 ),
            .gt4_rxmonitorout_out    (                     ),
            .gt4_rxmonitorsel_in     (2'b0                 ),
        
            // Loopback
            .gt5_loopback_in         (3'b000               ),
        
            // GT Reset Done Outputs
            .gt5_txresetdone_out     (                     ),
            .gt5_rxresetdone_out     (                     ),
        
            .gt5_cplllock_out        (  gt5_cplllock_out   ),
        
            // Power Down Ports
            .gt5_rxpd_in             (2'b00                ),
            .gt5_txpd_in             (2'b00                ),
        
            // RX Margin Analysis Ports
            .gt5_eyescandataerror_out(                     ),
            .gt5_eyescantrigger_in   (1'b0                 ),
            .gt5_eyescanreset_in     (1'b0                 ),
        
            // Tx Control
            .gt5_txpostcursor_in     (5'b00000             ),
            .gt5_txprecursor_in      (5'b00000             ),
            .gt5_txdiffctrl_in       (4'b1000              ),
            .gt5_txpolarity_in       (1'b0                 ),
            .gt5_txinhibit_in        (1'b0                 ),
        
            // TX Pattern Checker ports
            .gt5_txprbsforceerr_in   (1'b0                 ),
        
            // TX Initialization
            .gt5_txpcsreset_in       (1'b0                 ),
            .gt5_txpmareset_in       (1'b0                 ),
        
            // TX Buffer Ports
            .gt5_txbufstatus_out     (                     ),
        
            // Rx CDR Ports
            .gt5_rxcdrhold_in        (1'b0                 ),
        
            // Rx Polarity
            .gt5_rxpolarity_in       (1'b0                 ),
        
            // Receive Ports - Pattern Checker ports
            .gt5_rxprbserr_out       (                     ),
            .gt5_rxprbssel_in        (3'b0                 ),
            .gt5_rxprbscntreset_in   (1'b0                 ),
        
            // RX Buffer Bypass Ports
            .gt5_rxbufreset_in       (1'b0                 ),
            .gt5_rxbufstatus_out     (                     ),
            .gt5_rxstatus_out        (                     ),
        
            // RX Byte and Word Alignment Ports
            .gt5_rxbyteisaligned_out (                     ),
            .gt5_rxbyterealign_out   (                     ),
            .gt5_rxcommadet_out      (                     ),
        
            // Digital Monitor Ports
            .gt5_dmonitorout_out     (                     ),
        
        
            // RX Initialization and Reset Ports
            .gt5_rxpcsreset_in       (1'b0                 ),
            .gt5_rxpmareset_in       (1'b0                 ),
        
            // Receive Ports - RX Equalizer Ports
            .gt5_rxlpmen_in          (1'b1                 ),
            .gt5_rxdfelpmreset_in    (1'b0                 ),
            .gt5_rxmonitorout_out    (                     ),
            .gt5_rxmonitorsel_in     (2'b0                 ),
        
            // Loopback
            .gt6_loopback_in         (3'b000               ),
        
            // GT Reset Done Outputs
            .gt6_txresetdone_out     (                     ),
            .gt6_rxresetdone_out     (                     ),
        
            .gt6_cplllock_out        (  gt6_cplllock_out   ),
        
            // Power Down Ports
            .gt6_rxpd_in             (2'b00                ),
            .gt6_txpd_in             (2'b00                ),
        
            // RX Margin Analysis Ports
            .gt6_eyescandataerror_out(                     ),
            .gt6_eyescantrigger_in   (1'b0                 ),
            .gt6_eyescanreset_in     (1'b0                 ),
        
            // Tx Control
            .gt6_txpostcursor_in     (5'b00000             ),
            .gt6_txprecursor_in      (5'b00000             ),
            .gt6_txdiffctrl_in       (4'b1000              ),
            .gt6_txpolarity_in       (1'b0                 ),
            .gt6_txinhibit_in        (1'b0                 ),
        
            // TX Pattern Checker ports
            .gt6_txprbsforceerr_in   (1'b0                 ),
        
            // TX Initialization
            .gt6_txpcsreset_in       (1'b0                 ),
            .gt6_txpmareset_in       (1'b0                 ),
        
            // TX Buffer Ports
            .gt6_txbufstatus_out     (                     ),
        
            // Rx CDR Ports
            .gt6_rxcdrhold_in        (1'b0                 ),
        
            // Rx Polarity
            .gt6_rxpolarity_in       (1'b0                 ),
        
            // Receive Ports - Pattern Checker ports
            .gt6_rxprbserr_out       (                     ),
            .gt6_rxprbssel_in        (3'b0                 ),
            .gt6_rxprbscntreset_in   (1'b0                 ),
        
            // RX Buffer Bypass Ports
            .gt6_rxbufreset_in       (1'b0                 ),
            .gt6_rxbufstatus_out     (                     ),
            .gt6_rxstatus_out        (                     ),
        
            // RX Byte and Word Alignment Ports
            .gt6_rxbyteisaligned_out (                     ),
            .gt6_rxbyterealign_out   (                     ),
            .gt6_rxcommadet_out      (                     ),
        
            // Digital Monitor Ports
            .gt6_dmonitorout_out     (                     ),
        
        
            // RX Initialization and Reset Ports
            .gt6_rxpcsreset_in       (1'b0                 ),
            .gt6_rxpmareset_in       (1'b0                 ),
        
            // Receive Ports - RX Equalizer Ports
            .gt6_rxlpmen_in          (1'b1                 ),
            .gt6_rxdfelpmreset_in    (1'b0                 ),
            .gt6_rxmonitorout_out    (                     ),
            .gt6_rxmonitorsel_in     (2'b0                 ),
        
            // Loopback
            .gt7_loopback_in         (3'b000               ),
        
            // GT Reset Done Outputs
            .gt7_txresetdone_out     (                     ),
            .gt7_rxresetdone_out     (                     ),
        
            .gt7_cplllock_out        (  gt7_cplllock_out   ),
        
            // Power Down Ports
            .gt7_rxpd_in             (2'b00                ),
            .gt7_txpd_in             (2'b00                ),
        
            // RX Margin Analysis Ports
            .gt7_eyescandataerror_out(                     ),
            .gt7_eyescantrigger_in   (1'b0                 ),
            .gt7_eyescanreset_in     (1'b0                 ),
        
            // Tx Control
            .gt7_txpostcursor_in     (5'b00000             ),
            .gt7_txprecursor_in      (5'b00000             ),
            .gt7_txdiffctrl_in       (4'b1000              ),
            .gt7_txpolarity_in       (1'b0                 ),
            .gt7_txinhibit_in        (1'b0                 ),
        
            // TX Pattern Checker ports
            .gt7_txprbsforceerr_in   (1'b0                 ),
        
            // TX Initialization
            .gt7_txpcsreset_in       (1'b0                 ),
            .gt7_txpmareset_in       (1'b0                 ),
        
            // TX Buffer Ports
            .gt7_txbufstatus_out     (                     ),
        
            // Rx CDR Ports
            .gt7_rxcdrhold_in        (1'b0                 ),
        
            // Rx Polarity
            .gt7_rxpolarity_in       (1'b0                 ),
        
            // Receive Ports - Pattern Checker ports
            .gt7_rxprbserr_out       (                     ),
            .gt7_rxprbssel_in        (3'b0                 ),
            .gt7_rxprbscntreset_in   (1'b0                 ),
        
            // RX Buffer Bypass Ports
            .gt7_rxbufreset_in       (1'b0                 ),
            .gt7_rxbufstatus_out     (                     ),
            .gt7_rxstatus_out        (                     ),
        
            // RX Byte and Word Alignment Ports
            .gt7_rxbyteisaligned_out (                     ),
            .gt7_rxbyterealign_out   (                     ),
            .gt7_rxcommadet_out      (                     ),
        
            // Digital Monitor Ports
            .gt7_dmonitorout_out     (                     ),
        
        
            // RX Initialization and Reset Ports
            .gt7_rxpcsreset_in       (1'b0                 ),
            .gt7_rxpmareset_in       (1'b0                 ),
        
            // Receive Ports - RX Equalizer Ports
            .gt7_rxlpmen_in          (1'b1                 ),
            .gt7_rxdfelpmreset_in    (1'b0                 ),
            .gt7_rxmonitorout_out    (                     ),
            .gt7_rxmonitorsel_in     (2'b0                 ),
        
            // Reset Inputs for each direction
            .tx_reset_gt             (reset_gt             ),
            .rx_reset_gt             (reset_gt             ),
            .tx_sys_reset            (reset                ),
            .rx_sys_reset            (reset                ),
        
            // Reset Done for each direction
            .tx_reset_done           (tx_reset_done        ),
            .rx_reset_done           (rx_reset_done        ),
        
        
            // GT Common 0 I/O
`ifdef DEF_JESD204B_CPLL
//                .qpll_refclk             (refclk               ),
                 .cpll_refclk             (refclk               ),
`else
                .qpll_refclk             (refclk               ),
//                 .cpll_refclk             (refclk               ),
`endif
//            .common0_qpll_lock_out   (common0_qpll_lock_i  ),
//            .common0_qpll_refclk_out (common0_qpll_refclk_i),
//            .common0_qpll_clk_out    (common0_qpll_clk_i   ),
//            .common1_qpll_lock_out   (common1_qpll_lock_i  ),
//            .common1_qpll_refclk_out (common1_qpll_refclk_i),
//            .common1_qpll_clk_out    (common1_qpll_clk_i   ),
        
            .rxencommaalign          (rxencommaalign_i     ),
        
            // Clocks
            .tx_core_clk             (core_clk             ),
            .txoutclk                (txoutclk             ),
        
            .rx_core_clk             (core_clk             ),
        
            .rxoutclk                (                     ),
        
            .drpclk                  (drpclk               ),
        
        
            .gt_prbssel              (3'b000               ),
        
            // DRP Ports
            .gt0_drpaddr             (9'd0                 ),
            .gt0_drpdi               (16'd0                ),
            .gt0_drpen               (1'b0                 ),
            .gt0_drpwe               (1'b0                 ),
            .gt0_drpdo               (                     ),
            .gt0_drprdy              (                     ),
        
            .gt1_drpaddr             (9'd0                 ),
            .gt1_drpdi               (16'd0                ),
            .gt1_drpen               (1'b0                 ),
            .gt1_drpwe               (1'b0                 ),
            .gt1_drpdo               (                     ),
            .gt1_drprdy              (                     ),
        
            .gt2_drpaddr             (9'd0                 ),
            .gt2_drpdi               (16'd0                ),
            .gt2_drpen               (1'b0                 ),
            .gt2_drpwe               (1'b0                 ),
            .gt2_drpdo               (                     ),
            .gt2_drprdy              (                     ),
        
            .gt3_drpaddr             (9'd0                 ),
            .gt3_drpdi               (16'd0                ),
            .gt3_drpen               (1'b0                 ),
            .gt3_drpwe               (1'b0                 ),
            .gt3_drpdo               (                     ),
            .gt3_drprdy              (                     ),
        
            .gt4_drpaddr             (9'd0                 ),
            .gt4_drpdi               (16'd0                ),
            .gt4_drpen               (1'b0                 ),
            .gt4_drpwe               (1'b0                 ),
            .gt4_drpdo               (                     ),
            .gt4_drprdy              (                     ),
        
            .gt5_drpaddr             (9'd0                 ),
            .gt5_drpdi               (16'd0                ),
            .gt5_drpen               (1'b0                 ),
            .gt5_drpwe               (1'b0                 ),
            .gt5_drpdo               (                     ),
            .gt5_drprdy              (                     ),
        
            .gt6_drpaddr             (9'd0                 ),
            .gt6_drpdi               (16'd0                ),
            .gt6_drpen               (1'b0                 ),
            .gt6_drpwe               (1'b0                 ),
            .gt6_drpdo               (                     ),
            .gt6_drprdy              (                     ),
        
            .gt7_drpaddr             (9'd0                 ),
            .gt7_drpdi               (16'd0                ),
            .gt7_drpen               (1'b0                 ),
            .gt7_drpwe               (1'b0                 ),
            .gt7_drpdo               (                     ),
            .gt7_drprdy              (                     ),
        
            // Tie off Tx Ports
            // Lane 0
            .gt0_txdata              (gt0_txdata           ),
            .gt0_txcharisk           (gt0_txcharisk        ),
            .gt0_rxdata              (gt0_rxdata           ),
            .gt0_rxcharisk           (gt0_rxcharisk        ),
            .gt0_rxdisperr           (gt0_rxdisperr        ),
            .gt0_rxnotintable        (gt0_rxnotintable     ),
        
            // Lane 1
            .gt1_txdata              (gt1_txdata           ),
            .gt1_txcharisk           (gt1_txcharisk        ),
            .gt1_rxdata              (gt1_rxdata           ),
            .gt1_rxcharisk           (gt1_rxcharisk        ),
            .gt1_rxdisperr           (gt1_rxdisperr        ),
            .gt1_rxnotintable        (gt1_rxnotintable     ),
        
            // Lane 2
            .gt2_txdata              (gt2_txdata           ),
            .gt2_txcharisk           (gt2_txcharisk        ),
            .gt2_rxdata              (gt2_rxdata           ),
            .gt2_rxcharisk           (gt2_rxcharisk        ),
            .gt2_rxdisperr           (gt2_rxdisperr        ),
            .gt2_rxnotintable        (gt2_rxnotintable     ),
        
            // Lane 3
            .gt3_txdata              (gt3_txdata           ),
            .gt3_txcharisk           (gt3_txcharisk        ),
            .gt3_rxdata              (gt3_rxdata           ),
            .gt3_rxcharisk           (gt3_rxcharisk        ),
            .gt3_rxdisperr           (gt3_rxdisperr        ),
            .gt3_rxnotintable        (gt3_rxnotintable     ),
        
            // Lane 4
            .gt4_txdata              (gt4_txdata           ),
            .gt4_txcharisk           (gt4_txcharisk        ),
            .gt4_rxdata              (gt4_rxdata           ),
            .gt4_rxcharisk           (gt4_rxcharisk        ),
            .gt4_rxdisperr           (gt4_rxdisperr        ),
            .gt4_rxnotintable        (gt4_rxnotintable     ),
        
            // Lane 5
            .gt5_txdata              (gt5_txdata           ),
            .gt5_txcharisk           (gt5_txcharisk        ),
            .gt5_rxdata              (gt5_rxdata           ),
            .gt5_rxcharisk           (gt5_rxcharisk        ),
            .gt5_rxdisperr           (gt5_rxdisperr        ),
            .gt5_rxnotintable        (gt5_rxnotintable     ),
        
            // Lane 6
            .gt6_txdata              (gt6_txdata           ),
            .gt6_txcharisk           (gt6_txcharisk        ),
            .gt6_rxdata              (gt6_rxdata           ),
            .gt6_rxcharisk           (gt6_rxcharisk        ),
            .gt6_rxdisperr           (gt6_rxdisperr        ),
            .gt6_rxnotintable        (gt6_rxnotintable     ),
        
            // Lane 7
            .gt7_txdata              (gt7_txdata           ),
            .gt7_txcharisk           (gt7_txcharisk        ),
            .gt7_rxdata              (gt7_rxdata           ),
            .gt7_rxcharisk           (gt7_rxcharisk        ),
            .gt7_rxdisperr           (gt7_rxdisperr        ),
            .gt7_rxnotintable        (gt7_rxnotintable     ),
        
            // Serial ports
            .rxn_in                  (rxn                  ),
            .rxp_in                  (rxp                  ),
            .txn_out                 (txn                  ),
            .txp_out                 (txp                  )
        );
    end
else if(JESD204B_LANE == 4)
    begin
        jesd204_0_phy i_jesd204_phy (
            // Loopback
            .gt0_loopback_in         (3'b000               ),
        
            // GT Reset Done Outputs
            .gt0_txresetdone_out     (                     ),
            .gt0_rxresetdone_out     (                     ),
        
            .gt0_cplllock_out        (gt0_cplllock_out     ),
        
            // Power Down Ports
            .gt0_rxpd_in             (2'b00                ),
            .gt0_txpd_in             (2'b00                ),
        
            // RX Margin Analysis Ports
            .gt0_eyescandataerror_out(                     ),
            .gt0_eyescantrigger_in   (1'b0                 ),
            .gt0_eyescanreset_in     (1'b0                 ),
        
            // Tx Control
            .gt0_txpostcursor_in     (5'b00000             ),
            .gt0_txprecursor_in      (5'b00000             ),
            .gt0_txdiffctrl_in       (4'b1000              ),
            .gt0_txpolarity_in       (1'b0                 ),
            .gt0_txinhibit_in        (1'b0                 ),
        
            // TX Pattern Checker ports
            .gt0_txprbsforceerr_in   (1'b0                 ),
        
            // TX Initialization
            .gt0_txpcsreset_in       (1'b0                 ),
            .gt0_txpmareset_in       (1'b0                 ),
        
            // TX Buffer Ports
            .gt0_txbufstatus_out     (                     ),
        
            // Rx CDR Ports
            .gt0_rxcdrhold_in        (1'b0                 ),
        
            // Rx Polarity
            .gt0_rxpolarity_in       (1'b0                 ),
        
            // Receive Ports - Pattern Checker ports
            .gt0_rxprbserr_out       (                     ),
            .gt0_rxprbssel_in        (3'b0                 ),
            .gt0_rxprbscntreset_in   (1'b0                 ),
        
            // RX Buffer Bypass Ports
            .gt0_rxbufreset_in       (1'b0                 ),
            .gt0_rxbufstatus_out     (                     ),
            .gt0_rxstatus_out        (                     ),
        
            // RX Byte and Word Alignment Ports
            .gt0_rxbyteisaligned_out (                     ),
            .gt0_rxbyterealign_out   (                     ),
            .gt0_rxcommadet_out      (                     ),
        
            // Digital Monitor Ports
            .gt0_dmonitorout_out     (                     ),
        
        
            // RX Initialization and Reset Ports
            .gt0_rxpcsreset_in       (1'b0                 ),
            .gt0_rxpmareset_in       (1'b0                 ),
        
            // Receive Ports - RX Equalizer Ports
            .gt0_rxlpmen_in          (1'b1                 ),
            .gt0_rxdfelpmreset_in    (1'b0                 ),
            .gt0_rxmonitorout_out    (                     ),
            .gt0_rxmonitorsel_in     (2'b0                 ),
        
            // Loopback
            .gt1_loopback_in         (3'b000               ),
        
            // GT Reset Done Outputs
            .gt1_txresetdone_out     (                     ),
            .gt1_rxresetdone_out     (                     ),
        
            .gt1_cplllock_out        (gt1_cplllock_out     ),
        
            // Power Down Ports
            .gt1_rxpd_in             (2'b00                ),
            .gt1_txpd_in             (2'b00                ),
        
            // RX Margin Analysis Ports
            .gt1_eyescandataerror_out(                     ),
            .gt1_eyescantrigger_in   (1'b0                 ),
            .gt1_eyescanreset_in     (1'b0                 ),
        
            // Tx Control
            .gt1_txpostcursor_in     (5'b00000             ),
            .gt1_txprecursor_in      (5'b00000             ),
            .gt1_txdiffctrl_in       (4'b1000              ),
            .gt1_txpolarity_in       (1'b0                 ),
            .gt1_txinhibit_in        (1'b0                 ),
        
            // TX Pattern Checker ports
            .gt1_txprbsforceerr_in   (1'b0                 ),
        
            // TX Initialization
            .gt1_txpcsreset_in       (1'b0                 ),
            .gt1_txpmareset_in       (1'b0                 ),
        
            // TX Buffer Ports
            .gt1_txbufstatus_out     (                     ),
        
            // Rx CDR Ports
            .gt1_rxcdrhold_in        (1'b0                 ),
        
            // Rx Polarity
            .gt1_rxpolarity_in       (1'b0                 ),
        
            // Receive Ports - Pattern Checker ports
            .gt1_rxprbserr_out       (                     ),
            .gt1_rxprbssel_in        (3'b0                 ),
            .gt1_rxprbscntreset_in   (1'b0                 ),
        
            // RX Buffer Bypass Ports
            .gt1_rxbufreset_in       (1'b0                 ),
            .gt1_rxbufstatus_out     (                     ),
            .gt1_rxstatus_out        (                     ),
        
            // RX Byte and Word Alignment Ports
            .gt1_rxbyteisaligned_out (                     ),
            .gt1_rxbyterealign_out   (                     ),
            .gt1_rxcommadet_out      (                     ),
        
            // Digital Monitor Ports
            .gt1_dmonitorout_out     (                     ),
        
        
            // RX Initialization and Reset Ports
            .gt1_rxpcsreset_in       (1'b0                 ),
            .gt1_rxpmareset_in       (1'b0                 ),
        
            // Receive Ports - RX Equalizer Ports
            .gt1_rxlpmen_in          (1'b1                 ),
            .gt1_rxdfelpmreset_in    (1'b0                 ),
            .gt1_rxmonitorout_out    (                     ),
            .gt1_rxmonitorsel_in     (2'b0                 ),
        
            // Loopback
            .gt2_loopback_in         (3'b000               ),
        
            // GT Reset Done Outputs
            .gt2_txresetdone_out     (                     ),
            .gt2_rxresetdone_out     (                     ),
        
            .gt2_cplllock_out        (gt2_cplllock_out     ),
        
            // Power Down Ports
            .gt2_rxpd_in             (2'b00                ),
            .gt2_txpd_in             (2'b00                ),
        
            // RX Margin Analysis Ports
            .gt2_eyescandataerror_out(                     ),
            .gt2_eyescantrigger_in   (1'b0                 ),
            .gt2_eyescanreset_in     (1'b0                 ),
        
            // Tx Control
            .gt2_txpostcursor_in     (5'b00000             ),
            .gt2_txprecursor_in      (5'b00000             ),
            .gt2_txdiffctrl_in       (4'b1000              ),
            .gt2_txpolarity_in       (1'b0                 ),
            .gt2_txinhibit_in        (1'b0                 ),
        
            // TX Pattern Checker ports
            .gt2_txprbsforceerr_in   (1'b0                 ),
        
            // TX Initialization
            .gt2_txpcsreset_in       (1'b0                 ),
            .gt2_txpmareset_in       (1'b0                 ),
        
            // TX Buffer Ports
            .gt2_txbufstatus_out     (                     ),
        
            // Rx CDR Ports
            .gt2_rxcdrhold_in        (1'b0                 ),
        
            // Rx Polarity
            .gt2_rxpolarity_in       (1'b0                 ),
        
            // Receive Ports - Pattern Checker ports
            .gt2_rxprbserr_out       (                     ),
            .gt2_rxprbssel_in        (3'b0                 ),
            .gt2_rxprbscntreset_in   (1'b0                 ),
        
            // RX Buffer Bypass Ports
            .gt2_rxbufreset_in       (1'b0                 ),
            .gt2_rxbufstatus_out     (                     ),
            .gt2_rxstatus_out        (                     ),
        
            // RX Byte and Word Alignment Ports
            .gt2_rxbyteisaligned_out (                     ),
            .gt2_rxbyterealign_out   (                     ),
            .gt2_rxcommadet_out      (                     ),
        
            // Digital Monitor Ports
            .gt2_dmonitorout_out     (                     ),
        
        
            // RX Initialization and Reset Ports
            .gt2_rxpcsreset_in       (1'b0                 ),
            .gt2_rxpmareset_in       (1'b0                 ),
        
            // Receive Ports - RX Equalizer Ports
            .gt2_rxlpmen_in          (1'b1                 ),
            .gt2_rxdfelpmreset_in    (1'b0                 ),
            .gt2_rxmonitorout_out    (                     ),
            .gt2_rxmonitorsel_in     (2'b0                 ),
        
            // Loopback
            .gt3_loopback_in         (3'b000               ),
        
            // GT Reset Done Outputs
            .gt3_txresetdone_out     (                     ),
            .gt3_rxresetdone_out     (                     ),
        
            .gt3_cplllock_out        (  gt3_cplllock_out   ),
        
            // Power Down Ports
            .gt3_rxpd_in             (2'b00                ),
            .gt3_txpd_in             (2'b00                ),
        
            // RX Margin Analysis Ports
            .gt3_eyescandataerror_out(                     ),
            .gt3_eyescantrigger_in   (1'b0                 ),
            .gt3_eyescanreset_in     (1'b0                 ),
        
            // Tx Control
            .gt3_txpostcursor_in     (5'b00000             ),
            .gt3_txprecursor_in      (5'b00000             ),
            .gt3_txdiffctrl_in       (4'b1000              ),
            .gt3_txpolarity_in       (1'b0                 ),
            .gt3_txinhibit_in        (1'b0                 ),
        
            // TX Pattern Checker ports
            .gt3_txprbsforceerr_in   (1'b0                 ),
        
            // TX Initialization
            .gt3_txpcsreset_in       (1'b0                 ),
            .gt3_txpmareset_in       (1'b0                 ),
        
            // TX Buffer Ports
            .gt3_txbufstatus_out     (                     ),
        
            // Rx CDR Ports
            .gt3_rxcdrhold_in        (1'b0                 ),
        
            // Rx Polarity
            .gt3_rxpolarity_in       (1'b0                 ),
        
            // Receive Ports - Pattern Checker ports
            .gt3_rxprbserr_out       (                     ),
            .gt3_rxprbssel_in        (3'b0                 ),
            .gt3_rxprbscntreset_in   (1'b0                 ),
        
            // RX Buffer Bypass Ports
            .gt3_rxbufreset_in       (1'b0                 ),
            .gt3_rxbufstatus_out     (                     ),
            .gt3_rxstatus_out        (                     ),
        
            // RX Byte and Word Alignment Ports
            .gt3_rxbyteisaligned_out (                     ),
            .gt3_rxbyterealign_out   (                     ),
            .gt3_rxcommadet_out      (                     ),
        
            // Digital Monitor Ports
            .gt3_dmonitorout_out     (                     ),

            // RX Initialization and Reset Ports
            .gt3_rxpcsreset_in       (1'b0                 ),
            .gt3_rxpmareset_in       (1'b0                 ),
        
            // Receive Ports - RX Equalizer Ports
            .gt3_rxlpmen_in          (1'b1                 ),
            .gt3_rxdfelpmreset_in    (1'b0                 ),
            .gt3_rxmonitorout_out    (                     ),
            .gt3_rxmonitorsel_in     (2'b0                 ),
        
            // Reset Inputs for each direction
            .tx_reset_gt             (reset_gt             ),
            .rx_reset_gt             (reset_gt             ),
            .tx_sys_reset            (reset                ),
            .rx_sys_reset            (reset                ),
        
            // Reset Done for each direction
            .tx_reset_done           (tx_reset_done        ),
            .rx_reset_done           (rx_reset_done        ),
        
        
            // GT Common 0 I/O
`ifdef DEF_JESD204B_CPLL
//                .qpll_refclk             (refclk               ),
            .cpll_refclk             (refclk               ),
`else
            .qpll_refclk             (refclk               ),
//                 .cpll_refclk             (refclk               ),
`endif
//            .common0_qpll_lock_out   (common0_qpll_lock_i  ),
//            .common0_qpll_refclk_out (common0_qpll_refclk_i),
//            .common0_qpll_clk_out    (common0_qpll_clk_i   ),
//            .common1_qpll_lock_out   (common1_qpll_lock_i  ),
//            .common1_qpll_refclk_out (common1_qpll_refclk_i),
//            .common1_qpll_clk_out    (common1_qpll_clk_i   ),
        
            .rxencommaalign          (rxencommaalign_i     ),
        
            // Clocks
            .tx_core_clk             (core_clk             ),
            .txoutclk                (txoutclk             ),
        
            .rx_core_clk             (core_clk             ),
        
            .rxoutclk                (                     ),
        
            .drpclk                  (drpclk               ),
        
        
            .gt_prbssel              (3'b000               ),
        
            // DRP Ports
            .gt0_drpaddr             (9'd0                 ),
            .gt0_drpdi               (16'd0                ),
            .gt0_drpen               (1'b0                 ),
            .gt0_drpwe               (1'b0                 ),
            .gt0_drpdo               (                     ),
            .gt0_drprdy              (                     ),
        
            .gt1_drpaddr             (9'd0                 ),
            .gt1_drpdi               (16'd0                ),
            .gt1_drpen               (1'b0                 ),
            .gt1_drpwe               (1'b0                 ),
            .gt1_drpdo               (                     ),
            .gt1_drprdy              (                     ),
        
            .gt2_drpaddr             (9'd0                 ),
            .gt2_drpdi               (16'd0                ),
            .gt2_drpen               (1'b0                 ),
            .gt2_drpwe               (1'b0                 ),
            .gt2_drpdo               (                     ),
            .gt2_drprdy              (                     ),
        
            .gt3_drpaddr             (9'd0                 ),
            .gt3_drpdi               (16'd0                ),
            .gt3_drpen               (1'b0                 ),
            .gt3_drpwe               (1'b0                 ),
            .gt3_drpdo               (                     ),
            .gt3_drprdy              (                     ),

            // Tie off Tx Ports
            // Lane 0
            .gt0_txdata              (gt0_txdata           ),
            .gt0_txcharisk           (gt0_txcharisk        ),
            .gt0_rxdata              (gt0_rxdata           ),
            .gt0_rxcharisk           (gt0_rxcharisk        ),
            .gt0_rxdisperr           (gt0_rxdisperr        ),
            .gt0_rxnotintable        (gt0_rxnotintable     ),
        
            // Lane 1
            .gt1_txdata              (gt1_txdata           ),
            .gt1_txcharisk           (gt1_txcharisk        ),
            .gt1_rxdata              (gt1_rxdata           ),
            .gt1_rxcharisk           (gt1_rxcharisk        ),
            .gt1_rxdisperr           (gt1_rxdisperr        ),
            .gt1_rxnotintable        (gt1_rxnotintable     ),
        
            // Lane 2
            .gt2_txdata              (gt2_txdata           ),
            .gt2_txcharisk           (gt2_txcharisk        ),
            .gt2_rxdata              (gt2_rxdata           ),
            .gt2_rxcharisk           (gt2_rxcharisk        ),
            .gt2_rxdisperr           (gt2_rxdisperr        ),
            .gt2_rxnotintable        (gt2_rxnotintable     ),
        
            // Lane 3
            .gt3_txdata              (gt3_txdata           ),
            .gt3_txcharisk           (gt3_txcharisk        ),
            .gt3_rxdata              (gt3_rxdata           ),
            .gt3_rxcharisk           (gt3_rxcharisk        ),
            .gt3_rxdisperr           (gt3_rxdisperr        ),
            .gt3_rxnotintable        (gt3_rxnotintable     ),

            // Serial ports
            .rxn_in                  (rxn                  ),
            .rxp_in                  (rxp                  ),
            .txn_out                 (txn                  ),
            .txp_out                 (txp                  )
        );
    end
    else if(JESD204B_LANE == 2)
        begin
            jesd204_0_phy i_jesd204_phy (
                // Loopback
                .gt0_loopback_in         (3'b000               ),
            
                // GT Reset Done Outputs
                .gt0_txresetdone_out     (                     ),
                .gt0_rxresetdone_out     (                     ),
            
                .gt0_cplllock_out        (gt0_cplllock_out     ),
            
                // Power Down Ports
                .gt0_rxpd_in             (2'b00                ),
                .gt0_txpd_in             (2'b00                ),
            
                // RX Margin Analysis Ports
                .gt0_eyescandataerror_out(                     ),
                .gt0_eyescantrigger_in   (1'b0                 ),
                .gt0_eyescanreset_in     (1'b0                 ),
            
                // Tx Control
                .gt0_txpostcursor_in     (5'b00000             ),
                .gt0_txprecursor_in      (5'b00000             ),
                .gt0_txdiffctrl_in       (4'b1000              ),
                .gt0_txpolarity_in       (1'b0                 ),
                .gt0_txinhibit_in        (1'b0                 ),
            
                // TX Pattern Checker ports
                .gt0_txprbsforceerr_in   (1'b0                 ),
            
                // TX Initialization
                .gt0_txpcsreset_in       (1'b0                 ),
                .gt0_txpmareset_in       (1'b0                 ),
            
                // TX Buffer Ports
                .gt0_txbufstatus_out     (                     ),
            
                // Rx CDR Ports
                .gt0_rxcdrhold_in        (1'b0                 ),
            
                // Rx Polarity
                .gt0_rxpolarity_in       (1'b0                 ),
            
                // Receive Ports - Pattern Checker ports
                .gt0_rxprbserr_out       (                     ),
                .gt0_rxprbssel_in        (3'b0                 ),
                .gt0_rxprbscntreset_in   (1'b0                 ),
            
                // RX Buffer Bypass Ports
                .gt0_rxbufreset_in       (1'b0                 ),
                .gt0_rxbufstatus_out     (                     ),
                .gt0_rxstatus_out        (                     ),
            
                // RX Byte and Word Alignment Ports
                .gt0_rxbyteisaligned_out (                     ),
                .gt0_rxbyterealign_out   (                     ),
                .gt0_rxcommadet_out      (                     ),
            
                // Digital Monitor Ports
                .gt0_dmonitorout_out     (                     ),
            
            
                // RX Initialization and Reset Ports
                .gt0_rxpcsreset_in       (1'b0                 ),
                .gt0_rxpmareset_in       (1'b0                 ),
            
                // Receive Ports - RX Equalizer Ports
                .gt0_rxlpmen_in          (1'b1                 ),
                .gt0_rxdfelpmreset_in    (1'b0                 ),
                .gt0_rxmonitorout_out    (                     ),
                .gt0_rxmonitorsel_in     (2'b0                 ),
            
                // Loopback
                .gt1_loopback_in         (3'b000               ),
            
                // GT Reset Done Outputs
                .gt1_txresetdone_out     (                     ),
                .gt1_rxresetdone_out     (                     ),
            
                .gt1_cplllock_out        (gt1_cplllock_out     ),
            
                // Power Down Ports
                .gt1_rxpd_in             (2'b00                ),
                .gt1_txpd_in             (2'b00                ),
            
                // RX Margin Analysis Ports
                .gt1_eyescandataerror_out(                     ),
                .gt1_eyescantrigger_in   (1'b0                 ),
                .gt1_eyescanreset_in     (1'b0                 ),
            
                // Tx Control
                .gt1_txpostcursor_in     (5'b00000             ),
                .gt1_txprecursor_in      (5'b00000             ),
                .gt1_txdiffctrl_in       (4'b1000              ),
                .gt1_txpolarity_in       (1'b0                 ),
                .gt1_txinhibit_in        (1'b0                 ),
            
                // TX Pattern Checker ports
                .gt1_txprbsforceerr_in   (1'b0                 ),
            
                // TX Initialization
                .gt1_txpcsreset_in       (1'b0                 ),
                .gt1_txpmareset_in       (1'b0                 ),
            
                // TX Buffer Ports
                .gt1_txbufstatus_out     (                     ),
            
                // Rx CDR Ports
                .gt1_rxcdrhold_in        (1'b0                 ),
            
                // Rx Polarity
                .gt1_rxpolarity_in       (1'b0                 ),
            
                // Receive Ports - Pattern Checker ports
                .gt1_rxprbserr_out       (                     ),
                .gt1_rxprbssel_in        (3'b0                 ),
                .gt1_rxprbscntreset_in   (1'b0                 ),
            
                // RX Buffer Bypass Ports
                .gt1_rxbufreset_in       (1'b0                 ),
                .gt1_rxbufstatus_out     (                     ),
                .gt1_rxstatus_out        (                     ),
            
                // RX Byte and Word Alignment Ports
                .gt1_rxbyteisaligned_out (                     ),
                .gt1_rxbyterealign_out   (                     ),
                .gt1_rxcommadet_out      (                     ),
            
                // Digital Monitor Ports
                .gt1_dmonitorout_out     (                     ),
            
            
                // RX Initialization and Reset Ports
                .gt1_rxpcsreset_in       (1'b0                 ),
                .gt1_rxpmareset_in       (1'b0                 ),
            
                // Receive Ports - RX Equalizer Ports
                .gt1_rxlpmen_in          (1'b1                 ),
                .gt1_rxdfelpmreset_in    (1'b0                 ),
                .gt1_rxmonitorout_out    (                     ),
                .gt1_rxmonitorsel_in     (2'b0                 ),
            
                // Reset Inputs for each direction
                .tx_reset_gt             (reset_gt             ),
                .rx_reset_gt             (reset_gt             ),
                .tx_sys_reset            (reset                ),
                .rx_sys_reset            (reset                ),
            
                // Reset Done for each direction
                .tx_reset_done           (tx_reset_done        ),
                .rx_reset_done           (rx_reset_done        ),
            
            
                // GT Common 0 I/O
`ifdef DEF_JESD204B_CPLL
//                .qpll_refclk             (refclk               ),
                 .cpll_refclk             (refclk               ),
`else
                .qpll_refclk             (refclk               ),
//                 .cpll_refclk             (refclk               ),
`endif
//                .common0_qpll_lock_out   (common0_qpll_lock_i  ),
//                .common0_qpll_refclk_out (common0_qpll_refclk_i),
//                .common0_qpll_clk_out    (common0_qpll_clk_i   ),
//                .common1_qpll_lock_out   (common1_qpll_lock_i  ),
//                .common1_qpll_refclk_out (common1_qpll_refclk_i),
//                .common1_qpll_clk_out    (common1_qpll_clk_i   ),
            
                .rxencommaalign          (rxencommaalign_i     ),
            
                // Clocks
                .tx_core_clk             (core_clk             ),
                .txoutclk                (txoutclk             ),
            
                .rx_core_clk             (core_clk             ),
            
                .rxoutclk                (                     ),
            
                .drpclk                  (drpclk               ),
            
            
                .gt_prbssel              (3'b000               ),
            
                // DRP Ports
                .gt0_drpaddr             (9'd0                 ),
                .gt0_drpdi               (16'd0                ),
                .gt0_drpen               (1'b0                 ),
                .gt0_drpwe               (1'b0                 ),
                .gt0_drpdo               (                     ),
                .gt0_drprdy              (                     ),
            
                .gt1_drpaddr             (9'd0                 ),
                .gt1_drpdi               (16'd0                ),
                .gt1_drpen               (1'b0                 ),
                .gt1_drpwe               (1'b0                 ),
                .gt1_drpdo               (                     ),
                .gt1_drprdy              (                     ),
            
                // Tie off Tx Ports
                // Lane 0
                .gt0_txdata              (gt0_txdata           ),
                .gt0_txcharisk           (gt0_txcharisk        ),
                .gt0_rxdata              (gt0_rxdata           ),
                .gt0_rxcharisk           (gt0_rxcharisk        ),
                .gt0_rxdisperr           (gt0_rxdisperr        ),
                .gt0_rxnotintable        (gt0_rxnotintable     ),
            
                // Lane 1
                .gt1_txdata              (gt1_txdata           ),
                .gt1_txcharisk           (gt1_txcharisk        ),
                .gt1_rxdata              (gt1_rxdata           ),
                .gt1_rxcharisk           (gt1_rxcharisk        ),
                .gt1_rxdisperr           (gt1_rxdisperr        ),
                .gt1_rxnotintable        (gt1_rxnotintable     ),
            
                // Serial ports
                .rxn_in                  (rxn                  ),
                .rxp_in                  (rxp                  ),
                .txn_out                 (txn                  ),
                .txp_out                 (txp                  )
            );
        end
    else if(JESD204B_LANE == 1)
        begin
            jesd204_0_phy i_jesd204_phy (
                // Loopback
                .gt0_loopback_in         (3'b000               ),
            
                // GT Reset Done Outputs
                .gt0_txresetdone_out     (                     ),
                .gt0_rxresetdone_out     (                     ),
            
                .gt0_cplllock_out        (gt0_cplllock_out     ),
            
                // Power Down Ports
                .gt0_rxpd_in             (2'b00                ),
                .gt0_txpd_in             (2'b00                ),
            
                // RX Margin Analysis Ports
                .gt0_eyescandataerror_out(                     ),
                .gt0_eyescantrigger_in   (1'b0                 ),
                .gt0_eyescanreset_in     (1'b0                 ),
            
                // Tx Control
                .gt0_txpostcursor_in     (5'b00000             ),
                .gt0_txprecursor_in      (5'b00000             ),
                .gt0_txdiffctrl_in       (4'b1000              ),
                .gt0_txpolarity_in       (1'b0                 ),
                .gt0_txinhibit_in        (1'b0                 ),
            
                // TX Pattern Checker ports
                .gt0_txprbsforceerr_in   (1'b0                 ),
            
                // TX Initialization
                .gt0_txpcsreset_in       (1'b0                 ),
                .gt0_txpmareset_in       (1'b0                 ),
            
                // TX Buffer Ports
                .gt0_txbufstatus_out     (                     ),
            
                // Rx CDR Ports
                .gt0_rxcdrhold_in        (1'b0                 ),
            
                // Rx Polarity
                .gt0_rxpolarity_in       (1'b0                 ),
            
                // Receive Ports - Pattern Checker ports
                .gt0_rxprbserr_out       (                     ),
                .gt0_rxprbssel_in        (3'b0                 ),
                .gt0_rxprbscntreset_in   (1'b0                 ),
            
                // RX Buffer Bypass Ports
                .gt0_rxbufreset_in       (1'b0                 ),
                .gt0_rxbufstatus_out     (                     ),
                .gt0_rxstatus_out        (                     ),
            
                // RX Byte and Word Alignment Ports
                .gt0_rxbyteisaligned_out (                     ),
                .gt0_rxbyterealign_out   (                     ),
                .gt0_rxcommadet_out      (                     ),
            
                // Digital Monitor Ports
                .gt0_dmonitorout_out     (                     ),
            
            
                // RX Initialization and Reset Ports
                .gt0_rxpcsreset_in       (1'b0                 ),
                .gt0_rxpmareset_in       (1'b0                 ),
            
                // Receive Ports - RX Equalizer Ports
                .gt0_rxlpmen_in          (1'b1                 ),
                .gt0_rxdfelpmreset_in    (1'b0                 ),
                .gt0_rxmonitorout_out    (                     ),
                .gt0_rxmonitorsel_in     (2'b0                 ),
            
                // Reset Inputs for each direction
                .tx_reset_gt             (reset_gt             ),
                .rx_reset_gt             (reset_gt             ),
                .tx_sys_reset            (reset                ),
                .rx_sys_reset            (reset                ),
            
                // Reset Done for each direction
                .tx_reset_done           (tx_reset_done        ),
                .rx_reset_done           (rx_reset_done        ),
            
            
                // GT Common 0 I/O
`ifdef DEF_JESD204B_CPLL
//                .qpll_refclk             (refclk               ),
                 .cpll_refclk             (refclk               ),
`else
                .qpll_refclk             (refclk               ),
//                 .cpll_refclk             (refclk               ),
`endif
//                .common0_qpll_lock_out   (common0_qpll_lock_i  ),
//                .common0_qpll_refclk_out (common0_qpll_refclk_i),
//                .common0_qpll_clk_out    (common0_qpll_clk_i   ),
//                .common1_qpll_lock_out   (common1_qpll_lock_i  ),
//                .common1_qpll_refclk_out (common1_qpll_refclk_i),
//                .common1_qpll_clk_out    (common1_qpll_clk_i   ),
            
                .rxencommaalign          (rxencommaalign_i     ),
            
                // Clocks
                .tx_core_clk             (core_clk             ),
                .txoutclk                (txoutclk             ),
            
                .rx_core_clk             (core_clk             ),
            
                .rxoutclk                (                     ),
            
                .drpclk                  (drpclk               ),
            
            
                .gt_prbssel              (3'b000               ),
            
                // DRP Ports
                .gt0_drpaddr             (9'd0                 ),
                .gt0_drpdi               (16'd0                ),
                .gt0_drpen               (1'b0                 ),
                .gt0_drpwe               (1'b0                 ),
                .gt0_drpdo               (                     ),
                .gt0_drprdy              (                     ),
            
                // Tie off Tx Ports
                // Lane 0
                .gt0_txdata              (gt0_txdata           ),
                .gt0_txcharisk           (gt0_txcharisk        ),
                .gt0_rxdata              (gt0_rxdata           ),
                .gt0_rxcharisk           (gt0_rxcharisk        ),
                .gt0_rxdisperr           (gt0_rxdisperr        ),
                .gt0_rxnotintable        (gt0_rxnotintable     ),

                // Serial ports
                .rxn_in                  (rxn                  ),
                .rxp_in                  (rxp                  ),
                .txn_out                 (txn                  ),
                .txp_out                 (txp                  )
            );
        end
end
endgenerate

    // Change the polarity of rx_aresetn to reduce the use of active-low reset
    reset_sync #(
        .INPUT_ACTIVE_LEVEL (1'b0),
        .OUTPUT_ACTIVE_LEVEL(1'b1)
    ) i_reset_sync (
        .reset_out(jesd204_reset),
        .clk      (core_clk     ),
        .reset_in (aresetn      )
    );


//    // Generate SYSREF
//    always @(posedge core_clk) begin
//        if(jesd204_reset) begin
//            sysref_cnt <= 4'b0;
//        end else if(sysref_cnt != 4'hF) begin
//            sysref_cnt <= sysref_cnt + 1;
//        end
//    end
//
//    always @(posedge core_clk) begin
//        if(jesd204_reset) begin
//            sysref <= 1'b0;
//        end else begin
//            sysref <= (sysref_cnt == 4'hE);
//        end
//    end


    //Assign common PLL signals to output ports for sharing
//    assign common0_pll_clk_out    = common0_qpll_clk_i;
//    assign common0_pll_refclk_out = common0_qpll_refclk_i;
//    assign common0_pll_lock_out   = common0_qpll_lock_i;
//    assign common1_pll_clk_out    = common1_qpll_clk_i;
//    assign common1_pll_refclk_out = common1_qpll_refclk_i;
//    assign common1_pll_lock_out   = common1_qpll_lock_i;



    axi4_lite_simple_master #(
        .AXI_ADDR_WID(12),
        .AXI_DATA_WID(32)
    ) i_axi4_lite_simple_master_0 (
        // Global signals
        .axi_aclk   (axi_aclk               ),
        .axi_reset  (axi_rst                ),

        // Simple rd/wr interface
        .user_wr    (axi4_lite_user_wr[0]   ),
        .user_rd    (axi4_lite_user_rd[0]   ),
        .user_addr  (axi4_lite_user_addr    ),
        .user_wdata (axi4_lite_user_wdata   ),
        .user_wmask (axi4_lite_user_wmask   ),
        .user_rdata (axi4_lite_user_rdata[0]),
        .user_ready (axi4_lite_user_ready[0]),
        .user_error (                       ),

        // Write address channel
        .axi_awready(s_axi_awready          ),
        .axi_awaddr (s_axi_awaddr           ),
        .axi_awvalid(s_axi_awvalid          ),
        // Write data channel
        .axi_wready (s_axi_wready           ),
        .axi_wdata  (s_axi_wdata            ),
        .axi_wstrb  (s_axi_wstrb            ),
        .axi_wvalid (s_axi_wvalid           ),
        // Write response channel
        .axi_bresp  (s_axi_bresp            ),
        .axi_bvalid (s_axi_bvalid           ),
        .axi_bready (s_axi_bready           ),
        // Read address channel
        .axi_arready(s_axi_arready          ),
        .axi_araddr (s_axi_araddr           ),
        .axi_arvalid(s_axi_arvalid          ),
        // Read data channel
        .axi_rdata  (s_axi_rdata            ),
        .axi_rresp  (s_axi_rresp            ),
        .axi_rvalid (s_axi_rvalid           ),
        .axi_rready (s_axi_rready           )
    );

    assign axi4_lite_user_rdata[1] = 0;
    assign axi4_lite_user_ready[1] = 0;

//    ila_204b_gt u_ila_204b_gt (
//        .clk    (core_clk        ),
//        .probe0 (gt0_rxdata      ),
//        .probe1 (gt0_rxcharisk   ),
//        .probe2 (gt0_rxdisperr   ),
//        .probe3 (gt0_rxnotintable),
//        .probe4 (gt1_rxdata      ),
//        .probe5 (gt1_rxcharisk   ),
//        .probe6 (gt1_rxdisperr   ),
//        .probe7 (gt1_rxnotintable),
//        .probe8 (gt2_rxdata      ),
//        .probe9 (gt2_rxcharisk   ),
//        .probe10(gt2_rxdisperr   ),
//        .probe11(gt2_rxnotintable),
//        .probe12(gt3_rxdata      ),
//        .probe13(gt3_rxcharisk   ),
//        .probe14(gt3_rxdisperr   ),
//        .probe15(gt3_rxnotintable) 
////        .probe16(gt4_rxdata      ),
////        .probe17(gt4_rxcharisk   ),
////        .probe18(gt4_rxdisperr   ),
////        .probe19(gt4_rxnotintable),
////        .probe20(gt5_rxdata      ),
////        .probe21(gt5_rxcharisk   ),
////        .probe22(gt5_rxdisperr   ),
////        .probe23(gt5_rxnotintable),
////        .probe24(gt6_rxdata      ),
////        .probe25(gt6_rxcharisk   ),
////        .probe26(gt6_rxdisperr   ),
////        .probe27(gt6_rxnotintable),
////        .probe28(gt7_rxdata      ),
////        .probe29(gt7_rxcharisk   ),
////        .probe30(gt7_rxdisperr   ),
////        .probe31(gt7_rxnotintable)
//    );
endmodule
