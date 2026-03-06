//////////////////////////////////////////////////////////////////////////////////
// Company:     Analog Devices, Inc.
// Author:      MBB
// Simple two-register asynchronous assert, synchronous deassert reset synchronizer.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ps / 1ps

module reset_sync #(
  parameter INPUT_ACTIVE_LEVEL  = 1'b1,
  parameter OUTPUT_ACTIVE_LEVEL = 1'b1
)(
   output wire    reset_out,
   input  wire    clk,
   input  wire    reset_in
);

   (* ASYNC_REG = "TRUE" *) reg       reset_async = OUTPUT_ACTIVE_LEVEL;
   (* ASYNC_REG = "TRUE" *) reg       reset_out_int = OUTPUT_ACTIVE_LEVEL;
   
   generate
   if(INPUT_ACTIVE_LEVEL == 1'b1) begin : active_high_gen
      always @(posedge clk, posedge reset_in) begin
         if(reset_in) begin
            reset_async <= OUTPUT_ACTIVE_LEVEL;
            reset_out_int <= OUTPUT_ACTIVE_LEVEL;
         end else begin
            reset_async <= ~OUTPUT_ACTIVE_LEVEL;
            reset_out_int <= reset_async;
         end
      end
   end
   
   if(INPUT_ACTIVE_LEVEL != 1'b1) begin : active_low_gen
      always @(posedge clk, negedge reset_in) begin
         if(!reset_in) begin
            reset_async <= OUTPUT_ACTIVE_LEVEL;
            reset_out_int <= OUTPUT_ACTIVE_LEVEL;
         end else begin
            reset_async <= ~OUTPUT_ACTIVE_LEVEL;
            reset_out_int <= reset_async;
         end
      end
   end
   
   endgenerate
   
   assign reset_out = reset_out_int;

endmodule
