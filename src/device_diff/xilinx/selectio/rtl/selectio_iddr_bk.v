`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:26:36 10/27/2017 
// Design Name: 
// Module Name:    adio_bk 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Revision 1.01 - 优化代码，该模块只涉及对双沿进行解析，数据拼接部分不涉及
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module selectio_iddr_bk#
(
    parameter IDELAYCTRL_EN =  1         ,
    parameter IDELAY_VALUE  =  3         , //数据延时值，单位为0-31，参考时钟为ref_clk
    parameter DIFF_TERM     =  "TRUE"    , //匹配电阻
    parameter DATA_WIDTH    =  8           //输入数据位宽
)
(

    input                               ref_clk         , //用于对数据延时的参考时钟，200Mhz信号
    input                               clk_bufr        , //用于对数据处理的区域时钟
    input                               rst             , //内部复位信号
                                                        
    input    [DATA_WIDTH - 1 : 0]       i_lvds_data_p   , //实际为硬件管脚
    input    [DATA_WIDTH - 1 : 0]       i_lvds_data_n   , //实际为硬件管脚
                                                    
    output   [DATA_WIDTH - 1 : 0]       o_pos_data      , //双沿数据解析，上升沿数据
    output   [DATA_WIDTH - 1 : 0]       o_neg_data        //双沿数据解析，下降沿数据
    
);

genvar                              i               ;
wire    [DATA_WIDTH - 1 : 0]        data_pin        ;
wire    [DATA_WIDTH - 1 : 0]        data_dly        ;
wire    [DATA_WIDTH - 1 : 0]        pos_data        ;
wire    [DATA_WIDTH - 1 : 0]        neg_data        ;
wire                                delay_locked    ;

assign o_pos_data = pos_data;
assign o_neg_data = neg_data;

//IDELAYE2 + IDELAYCTRL基本的逻辑资源调用
generate
    if(IDELAYCTRL_EN == 1)
    begin
        //idelayctrl模块
        (* IODELAY_GROUP = "selectio_wiz_0_group" *)
        IDELAYCTRL delayctrl 
        (
            .RDY            (delay_locked   ),
            .REFCLK         (ref_clk        ),
            .RST            (rst            )
        );
    end
endgenerate

generate
    for( i = 0; i <= DATA_WIDTH -1 ; i = i + 1 )
    begin:GEN_IN
        //对差分数据源进行转单端操作，并且默认添加100欧姆终端匹配
        IBUFDS#
        (
            .DIFF_TERM      (DIFF_TERM),       // Differential Termination
            .IBUF_LOW_PWR   ("FALSE"),     // Low power="TRUE", Highest performance="FALSE" 
            .IOSTANDARD     ("LVDS")     // Specify the input I/O standard
        ) 
        u_inbufds
        (
            .O      (data_pin[i]         ),  // Buffer output
            .I      (i_lvds_data_p[i]    ),  // Diff_p buffer input (connect directly to top-level port)
            .IB     (i_lvds_data_n[i]    )   // Diff_n buffer input (connect directly to top-level port)
        );
        
        //对输入的数据源根据参考时钟进行延时，调整内部逻辑时序。设置延时模式为FIXED，设置其参考时钟为200Mhz。
        (* IODELAY_GROUP = "selectio_wiz_0_group" *)
        IDELAYE2#
        (
            .CINVCTRL_SEL           ("FALSE"),                            // TRUE, FALSE
            .DELAY_SRC              ("IDATAIN"),                          // IDATAIN, DATAIN
            .HIGH_PERFORMANCE_MODE  ("FALSE"),                            // TRUE, FALSE
            .IDELAY_TYPE            ("FIXED"),              // FIXED, VARIABLE, or VAR_LOADABLE
            .IDELAY_VALUE           (IDELAY_VALUE),                  // 0 to 31
            .REFCLK_FREQUENCY       (200.0),
            .PIPE_SEL               ("FALSE"),
            .SIGNAL_PATTERN         ("DATA")                    // CLOCK, DATA
        )                              
        idelaye2_bus
        (
            .DATAOUT                (data_dly[i]),
            .DATAIN                 (1'b0),                               // Data from FPGA logic
            .C                      (1'b0),
            .CE                     (),
            .INC                    (),
            .IDATAIN                (data_pin[i]), // Driven by IOB
            .LD                     (1'b0),
            .REGRST                 (),
            .LDPIPEEN               (1'b0),
            .CNTVALUEIN             (5'b00000),
            .CNTVALUEOUT            (),
            .CINVCTRL               (1'b0)
        );
    end
endgenerate

generate
    for( i = 0; i <= DATA_WIDTH - 1; i = i + 1 )
    begin:GEN_IDDR
        //对延时后的数据进行双沿转单沿操作，n0_data为上升沿数据，n1_data为下降沿数据
        //SAME_EDGE_PIPELINED：时序略有延时，但能保证上升沿与下降沿数据与时钟初始值同步
        IDDR#
        (
            .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // "OPPOSITE_EDGE", "SAME_EDGE" 
            //.DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE", "SAME_EDGE" 
                                            //    or "SAME_EDGE_PIPELINED" 
            .INIT_Q1(1'b0), // Initial value of Q1: 1'b0 or 1'b1
            .INIT_Q2(1'b0), // Initial value of Q2: 1'b0 or 1'b1
            .SRTYPE("ASYNC") // Set/Reset type: "SYNC" or "ASYNC" 
        ) 
        IDDR_inst 
        (
            .Q1   (pos_data[i]), // 1-bit output for positive edge of clock 
            .Q2   (neg_data[i]), // 1-bit output for negative edge of clock
            .C    (clk_bufr),   // 1-bit clock input
            .CE   (1'b1), // 1-bit clock enable input
            .D    (data_dly[i]),   // 1-bit DDR data input
            .R    (rst),   // 1-bit reset
            .S    (1'b0)    // 1-bit set
        );
    end
endgenerate

endmodule
