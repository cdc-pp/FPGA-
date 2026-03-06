`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:09:01 08/04/2017 
// Design Name: 
// Module Name:    band_sel 
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
//     20250108：band_sel -> uart_baud_sel_bk，修改接口名，统一当前模块为100Mhz
//               下的参数
//
//////////////////////////////////////////////////////////////////////////////////
module uart_baud_sel_bk
(
    input               rst             , 
    input               sys_clk         , //100m 
    input    [ 3:0]     i_baud_sel      , //baud rate select reg
                                          //0x0:9600
                                          //0x1:14400
                                          //0x2:19200  
                                          //0x3:38400  
                                          //0x4:57600  
                                          //0x5:115200 
                                          //0x6:230400 
                                          //0x7:460800 
                                          //0x8:921600 
                                          //0x9:2400   
                                          //0xa:4800
                                          //0xb:76800
                                          // others 
    output    [15:0]    o_baud_para      , 
    output    [15:0]    o_baud_mid_para  

);
    
    
reg     [15:0]    para_nm     ; 
reg     [15:0]    param_nmd   ; 

assign  o_baud_para     = para_nm;
assign  o_baud_mid_para = param_nmd;

always@(posedge sys_clk or posedge rst)
begin
    if(rst)
    begin
        para_nm     <= 'd2083   ;
        param_nmd   <= 'd1042   ;
    end
    else
    begin
        case(i_baud_sel)
            4'd0:
            begin //9600 
                para_nm     <= 'd10417   ;
                param_nmd   <= 'd5208    ;
            end
            4'd1:   
            begin //14400
                para_nm     <= 'd6944   ;
                param_nmd   <= 'd3472   ;
            end
            4'd2:   
            begin //19200  
                para_nm     <= 'd5208   ;
                param_nmd   <= 'd2604   ;
            end
            4'd3:   
            begin //38400
                para_nm     <= 'd2604   ;
                param_nmd   <= 'd1302   ;
            end
            4'd4:   
            begin //57600
                para_nm     <= 'd1736   ;
                param_nmd   <= 'd868    ;
            end  
            4'd5:   
            begin //115200 
                para_nm     <= 'd868    ;
                param_nmd   <= 'd434    ;
            end
            4'd6:   
            begin //230400
                para_nm     <= 'd434    ;
                param_nmd   <= 'd217    ;
            end
            4'd7:   
            begin //460800
                para_nm     <= 'd217    ;
                param_nmd   <= 'd108    ;
            end
            4'd8:   
            begin //921600
                para_nm     <= 'd108    ;
                param_nmd   <= 'd54     ;
            end 
            4'd9:
            begin //2400 
                para_nm     <= 'd41667  ;
                param_nmd   <= 'd20833  ;
            end        
            4'd10:   
            begin //4800 
                para_nm     <= 'd20833  ;
                param_nmd   <= 'd10417  ;
            end        
            4'd11:   
            begin //76800
                para_nm     <= 'd1302   ;
                param_nmd   <= 'd651    ;
            end  
            4'd12:  
            begin //1200
                para_nm     <= 'd83333  ;
                param_nmd   <= 'd41667  ;
            end            
            default:
            begin //9600
                para_nm     <= 'd10417  ;
                param_nmd   <= 'd5208   ;
            end
        endcase
    end
end
endmodule
