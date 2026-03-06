`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/07 14:02:53
// Design Name: 
// Module Name: serdes_out
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - serdes_out name to dac_serdes_io_bk
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//                   _    _    _    _                           
//dci_clk:        __| |__| |__| |__| |__                        
//DATA_P/DATA_N: | I0 | Q0 | I1 | Q1 |        
module dac_serdes_io_bk#
(parameter SYS_W = 16,
   // width of the data for the device
   parameter DEV_W = 64)
 (
  // From the device out to the system
  input  [DEV_W-1:0] data_out_from_device,
  output [SYS_W-1:0] data_out_to_pins_p  ,
  output [SYS_W-1:0] data_out_to_pins_n  ,
  input              clk_dci             ,    
  input              clk_div             ,   // Slow clock output
  input              io_reset
);

localparam         num_serial_bits = DEV_W/SYS_W;
wire clock_enable = 1'b1;
// Signal declarations
wire   [SYS_W-1:0] data_out_to_pins_int;
// Between the delay and serdes
wire   [SYS_W-1:0] data_out_to_pins_predelay;
// Array to use intermediately from the serdes to the internal
//  devices. bus "0" is the leftmost bus
wire [SYS_W-1:0]  oserdes_d[0:13];   // fills in starting with 13 
 
// We have multiple bits- step over every bit, instantiating the required elements
genvar pin_count;
genvar slice_count;
generate for (pin_count = 0; pin_count < SYS_W; pin_count = pin_count + 1) begin: pins
  // Instantiate the buffers
  ////------------------------------
  // Instantiate a buffer for every bit of the data bus
  OBUFDS
    #(   
        .IOSTANDARD          ("LVDS_25")
    )
   obufds_inst
     (  
        .O          (data_out_to_pins_p  [pin_count]),
        .OB         (data_out_to_pins_n  [pin_count]),
        .I          (data_out_to_pins_int[pin_count])
    );

  // Pass through the delay
  ////-------------------------------
 assign data_out_to_pins_int[pin_count]    = data_out_to_pins_predelay[pin_count];

   // Instantiate the serdes primitive
   ////------------------------------

   // declare the oserdes
  OSERDESE2
    # (
        .DATA_RATE_OQ   ("DDR"),
        .DATA_RATE_TQ   ("DDR"),
        .DATA_WIDTH     (4),
        .TRISTATE_WIDTH (4),
        .SERDES_MODE    ("MASTER")
    )
    oserdese2_master (
        .D1             (oserdes_d[13][pin_count]),
        .D2             (oserdes_d[12][pin_count]),
        .D3             (oserdes_d[11][pin_count]),
        .D4             (oserdes_d[10][pin_count]),
        .D5             (oserdes_d[9][pin_count]),
        .D6             (oserdes_d[8][pin_count]),
        .D7             (oserdes_d[7][pin_count]),
        .D8             (oserdes_d[6][pin_count]),
        .T1             (1'b0),
        .T2             (1'b0),
        .T3             (1'b0),
        .T4             (1'b0),
        .SHIFTIN1       (1'b0),
        .SHIFTIN2       (1'b0),
        .SHIFTOUT1      (),
        .SHIFTOUT2      (),
        .OCE            (clock_enable),
        .CLK            (clk_dci),
        .CLKDIV         (clk_div),
        .OQ             (data_out_to_pins_predelay[pin_count]),
        .TQ             (),
        .OFB            (),
        .TFB            (),
        .TBYTEIN        (1'b0),
        .TBYTEOUT       (),
        .TCE            (1'b0),
        .RST            (io_reset)
    );

   // Concatenate the serdes outputs together. Keep the timesliced
   //   bits together, and placing the earliest bits on the right
   //   ie, if data comes in 0, 1, 2, 3, 4, 5, 6, 7, ...
   //       the output will be 3210, 7654, ...
   ////---------------------------------------------------------
   for (slice_count = 0; slice_count < num_serial_bits; slice_count = slice_count + 1) begin: out_slices
      // This places the first data in time on the right
      assign oserdes_d[14-slice_count-1] =
         data_out_from_device[slice_count*SYS_W+:SYS_W];
      // To place the first data in time on the left, use the
      //   following code, instead
      // assign oserdes_d[slice_count] =
      //    data_out_from_device[slice_count*SYS_W+:SYS_W];
   end
end

endgenerate

endmodule
