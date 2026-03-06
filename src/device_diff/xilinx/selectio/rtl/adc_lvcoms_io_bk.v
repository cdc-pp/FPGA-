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
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module adc_lvcoms_io_bk#
(

    parameter DATA_WIDTH   = 16 ,
    parameter IDELAY_VALUE = 0

)
(

    input    [DATA_WIDTH - 1:0]     din_p           ,//AD芯片传过来的8位数据
    input    [DATA_WIDTH - 1:0]     din_n           ,//AD芯片传过来的8位数据
    
    input                           clk_ref         ,//clkin_200mhz时钟信号
    input                           io_reset        ,//pll锁定后的复位信号
    input                           clkin_sys       ,///也用的是adclk_bufg时钟信号/
    input                           clkin_bufr      ,//ad输出时钟经过buff后的时钟信号
    
    output   [DATA_WIDTH - 1:0]     o_dout_pin      //转换后的16bit输出位宽数据
    
);

genvar                         i               ;
wire    [DATA_WIDTH - 1:0]     data_in         ;
wire    [DATA_WIDTH - 1:0]     data_dly        ;
reg     [DATA_WIDTH - 1:0]     dout_pin        ;
wire                           delay_locked    ;

assign o_dout_pin = dout_pin;

(* IODELAY_GROUP = "selectio_wiz_0_group" *)
IDELAYCTRL delayctrl 
(
    .RDY    (delay_locked),
    .REFCLK (clk_ref),
    .RST    (io_reset)
);

generate
    for(i=0; i<DATA_WIDTH; i = i+1)
    begin:GEN_IN
        IBUFDS #(
            .DIFF_TERM("TRUE"),       // Differential Termination
            .IBUF_LOW_PWR("FALSE"),     // Low power="TRUE", Highest performance="FALSE" 
            .IOSTANDARD("LVDS")     // Specify the input I/O standard
        ) 
        u_inbufds
        (
            .O(data_in[i]),  // Buffer output
            .I(din_p[i]),  // Diff_p buffer input (connect directly to top-level port)
            .IB(din_n[i]) // Diff_n buffer input (connect directly to top-level port)
        );
        
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
            .SIGNAL_PATTERN         ("DATA")
        )                                      // CLOCK, DATA
        idelaye2_bus
        (
            .DATAOUT                (data_dly[i]),
            .DATAIN                 (1'b0),                               // Data from FPGA logic
            .C                      (1'b0),
            .CE                     (),
            .INC                    (),
            .IDATAIN                (data_in[i]), // Driven by IOB
            .LD                     (1'b0),
            .REGRST                 (),
            .LDPIPEEN               (1'b0),
            .CNTVALUEIN             (5'b00000),
            .CNTVALUEOUT            (),
            .CINVCTRL               (1'b0)
        );
    end
endgenerate

always@(posedge clkin_bufr)
begin
    dout_pin <= data_dly; 
end
endmodule
