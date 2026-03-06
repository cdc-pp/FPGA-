//////////////////////////////////////////////////////////////////////////////////
// Company:        Analog Devices, Inc.
// Engineer:       MBB
// Create Date:    28 February 2014
//////////////////////////////////////////////////////////////////////////////////
module axi4_lite_simple_master
#(
  parameter AXI_ADDR_WID = 8,
  parameter AXI_DATA_WID = 32
)
(
  // Global signals
  input  wire                            axi_aclk,
  input  wire                            axi_reset,

  // Simple rd/wr interface
  input  wire                            user_wr,
  input  wire                            user_rd,
  input  wire [AXI_ADDR_WID-1:0]         user_addr,
  input  wire [AXI_DATA_WID-1:0]         user_wdata,
  // For bits in user_wmask = 0, the corresponding bits in the data bus
  // will be set by reading the current value before writing
  input  wire [AXI_DATA_WID-1:0]         user_wmask,
  output reg  [AXI_DATA_WID-1:0]         user_rdata,
  // user_ready goes low during a transaction
  // In the case of a read, user_rdata is valid when user_ready rises
  output reg                             user_ready,
  output reg                             user_error,

  // AXI Write address channel
  input  wire                            axi_awready,
  output wire [AXI_ADDR_WID-1:0]         axi_awaddr,
  output wire                            axi_awvalid,

  // AXI Write data channel
  input  wire                            axi_wready,
  output wire [AXI_DATA_WID-1:0]         axi_wdata,
  output wire [(AXI_DATA_WID/8)-1:0]     axi_wstrb,
  output wire                            axi_wvalid,

  // AXI Write response channel
  input  wire [1:0]                      axi_bresp,
  input  wire                            axi_bvalid,
  output wire                            axi_bready,

  // AXI Read address channel
  input  wire                            axi_arready,
  output wire [AXI_ADDR_WID-1:0]         axi_araddr,
  output wire                            axi_arvalid,

  // AXI Read data channel
  input  wire [AXI_DATA_WID-1:0]         axi_rdata,
  input  wire [1:0]                      axi_rresp,
  input  wire                            axi_rvalid,
  output wire                            axi_rready
);


   //==========================================================================
   //Localparams
   //==========================================================================
   localparam AXI_WSTRB_WID = AXI_DATA_WID/8;

   //==========================================================================
   // Define states
   //==========================================================================
   localparam S_IDLE        = 3'd1;   // Idle state
   localparam S_WR_A        = 3'd2;   // Write address
   localparam S_WR_WAIT_A   = 3'd3;   // Wait for write ready signals
   localparam S_WR_WAIT_R   = 3'd4;   // Wait for write response
   localparam S_RD_A        = 3'd5;   // Read address
   localparam S_RD_WAIT_A   = 3'd6;   // Wait for read ready signals
   localparam S_RD_WAIT_R   = 3'd7;   // Wait for read response

   //==========================================================================
   // Signals
   //==========================================================================
   reg  [2:0]                      current_state;
   reg                             rmw; // Current operation is a read-modify-write
   reg  [AXI_ADDR_WID-1:0]         user_addr_reg;
   reg  [AXI_DATA_WID-1:0]         user_wdata_reg;
   reg  [AXI_DATA_WID-1:0]         user_wmask_reg;
   
   reg  [AXI_ADDR_WID-1:0]         axi_awaddr_int = 'b0;
   reg                             axi_awvalid_int = 'b0;
   reg  [AXI_DATA_WID-1:0]         axi_wdata_int = 'b0;
   reg                             axi_wvalid_int = 'b0;
   reg  [AXI_ADDR_WID-1:0]         axi_araddr_int = 'b0;
   reg                             axi_arvalid_int = 'b0;
   reg                             axi_rready_int = 'b0;
   

   //==========================================================================
   // Assignments
   //==========================================================================
   assign axi_bready  = 1'b1;
   // assign axi_rready  = 1'b1;
   assign axi_wstrb   = {AXI_WSTRB_WID{1'b1}};

   assign axi_awaddr  = axi_awaddr_int;
   assign axi_awvalid = axi_awvalid_int;
   assign axi_wdata   = axi_wdata_int;
   assign axi_wvalid  = axi_wvalid_int;
   assign axi_araddr  = axi_araddr_int;
   assign axi_arvalid = axi_arvalid_int;
   assign axi_rready  = axi_rready_int;

   //==========================================================================
   // AXI Master State Machine
   //==========================================================================
   always @(posedge axi_aclk) begin
      if(axi_reset) begin
         axi_awvalid_int   <= 1'b0;
         axi_arvalid_int   <= 1'b0;
         axi_wvalid_int    <= 1'b0;
         axi_rready_int    <= 1'b0;
         axi_araddr_int    <= 'b0;
         axi_awaddr_int    <= 'b0;
         axi_wdata_int     <= 'b0;
         rmw           <= 1'b0;
         user_ready    <= 1'b0;
         user_error    <= 1'b0;
         current_state <= S_IDLE;
      end else begin
         case(current_state)
            S_IDLE:
               begin
                  axi_awvalid_int <= 1'b0;
                  axi_arvalid_int <= 1'b0;
                  axi_wvalid_int  <= 1'b0;
                  axi_rready_int  <= 1'b0;
                  user_ready  <= 1'b1;
                  if(user_wr) begin
                    user_addr_reg <= user_addr;
                    user_wmask_reg <= user_wmask;
                    user_wdata_reg <= user_wdata;
                    user_ready <= 1'b0;
                    if(user_wmask == {AXI_DATA_WID{1'b1}}) begin
                      rmw <= 1'b0;
                      current_state <= S_WR_A;
                    end else begin
                      rmw <= 1'b1;
                      current_state <= S_RD_A;
                    end
                  end else if(user_rd) begin
                    user_addr_reg <= user_addr;
                    user_ready <= 1'b0;
                    rmw <= 1'b0;
                    current_state <= S_RD_A;
                  end
               end

            // Write address and data
            S_WR_A:
               begin
                  axi_awvalid_int <= 1'b1;
                  axi_wvalid_int  <= 1'b1;
                  axi_awaddr_int  <= user_addr_reg;
                  if(rmw) begin
                    axi_wdata_int   <= (user_wdata_reg & user_wmask_reg) | (user_rdata & ~user_wmask_reg);
                  end else begin
                    axi_wdata_int   <= user_wdata_reg;
                  end
                  current_state <= S_WR_WAIT_A;
               end

            // Wait for write ready signals
            S_WR_WAIT_A:
               begin
                   if(axi_awready) begin
                       axi_awvalid_int <= 1'b0;
                    end

                   if(axi_wready) begin
                      axi_wvalid_int <= 1'b0;
                   end
                   if((axi_awready || !axi_awvalid_int) && (axi_wready || !axi_wvalid_int)) begin
                      if(axi_bvalid) begin
                         user_error <= axi_bresp[0];
                         user_ready <= 1'b1;
                         current_state <= S_IDLE;
                      end else begin
                         current_state <= S_WR_WAIT_R;
                      end
                   end
               end

            // Wait for write response
            S_WR_WAIT_R:
               begin
                  if(axi_bvalid) begin
                     user_error <= axi_bresp[0];
                     user_ready <= 1'b1;
                     current_state <= S_IDLE;
                  end
               end

             // Read address
            S_RD_A:
               begin
                  axi_arvalid_int <= 1'b1;
                  axi_araddr_int  <= user_addr_reg;
                  current_state <= S_RD_WAIT_A;
               end

            // Wait for read ready signals
            S_RD_WAIT_A:
               begin
                   if(axi_arready) begin
                       axi_arvalid_int <= 1'b0;
                      if(axi_rvalid) begin
                         user_error <= axi_rresp[0];
                         user_rdata <= axi_rdata;
                         if(rmw) begin
                            current_state <= S_WR_A;
                         end else begin
                            user_ready <= 1'b1;
                            current_state <= S_IDLE;
                         end
                      end else begin
                         axi_rready_int <= 1'b1;
                         current_state <= S_RD_WAIT_R;
                      end
                   end
               end

            // Wait for read response
            S_RD_WAIT_R:
               begin
                  if(axi_rvalid) begin
                     user_error <= axi_rresp[0];
                     user_rdata <= axi_rdata;
                     axi_rready_int <= 1'b0;
                     if(rmw) begin
                        current_state <= S_WR_A;
                     end else begin
                        user_ready <= 1'b1;
                        current_state <= S_IDLE;
                     end
                  end
               end

            default:
               begin
                  axi_awvalid_int   <= 1'b0;
                  axi_arvalid_int   <= 1'b0;
                  axi_wvalid_int    <= 1'b0;
                  axi_araddr_int    <= 12'b0;
                  axi_awaddr_int    <= 12'b0;
                  axi_wdata_int     <= 32'b0;
                  user_ready    <= 1'b0;
                  user_error    <= 1'b0;
                  current_state <= S_IDLE;
              end
         endcase
      end
   end

endmodule
