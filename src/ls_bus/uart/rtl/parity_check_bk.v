`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:      
// Design Name: 
// Module Name:    eecm 
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
//     20250109：eecm -> parity_check_bk，修改模块接口和代码内部命名，将不属于该
//               模块的内容移出
//
//////////////////////////////////////////////////////////////////////////////////

module parity_check_bk
(

    rst_n        ,
    sys_clk      ,
    i_check_mode ,
    i_data_num   , 
    o_check_data ,
    i_data
    
);
    input               rst_n         ;
    input               sys_clk       ;
    input     [ 1:0]    i_check_mode  ; //x0 不校验，11奇校验，01偶校验
    input     [ 3:0]    i_data_num    ; //需要奇偶校验的数据个数 
    output              o_check_data  ; //奇偶校验数据
    input     [ 7:0]    i_data        ; //输入的需要校验的数据  
                                      
    reg                 par_flag_en   ; //取par的0位  0不校验，1校验
    reg                 par_flag      ; //取par的1位 1奇校验，0偶校验
    reg                 par_num       ; //1表示有奇数个1，0表示有偶数个1
    reg                 par_data      ; //加入的校验码 
    reg       [ 7:0]    data_reg      ; //设置传输的字符个数，根据是否有奇偶校验，给不同的值
 
assign o_check_data = par_data ;

always@(posedge sys_clk or negedge rst_n) //奇偶校验
begin
    if(!rst_n)
        data_reg <= 8'b0;
    else
        data_reg <= i_data;
end

always@(posedge sys_clk or negedge rst_n) //par_num 1的个数是奇数个还是偶数个
begin
    if(!rst_n)
        par_num <= 1'b0;
    else
    begin
        case(i_data_num)
            4'd5:
            begin
                par_num <= data_reg[4] ^data_reg[3] ^data_reg[2] ^data_reg[1] ^data_reg[0];
            end
            4'd6:
            begin
                par_num <= data_reg[5] ^data_reg[4] ^data_reg[3] ^data_reg[2] ^data_reg[1] ^data_reg[0];
            end
            4'd7:
            begin
                par_num <= data_reg[6] ^data_reg[5] ^data_reg[4] ^data_reg[3] ^data_reg[2] ^data_reg[1] ^data_reg[0];
            end
            4'd8:
            begin
                par_num <= data_reg[7] ^data_reg[6] ^data_reg[5] ^data_reg[4] ^data_reg[3] ^data_reg[2] ^data_reg[1] ^data_reg[0];
            end
            default:
            begin
                par_num <= data_reg[7] ^data_reg[6] ^data_reg[5] ^data_reg[4] ^data_reg[3] ^data_reg[2] ^data_reg[1] ^data_reg[0];
            end
        endcase
    end
end
        
always@(posedge sys_clk or negedge rst_n)  //奇偶校验
begin
    if(!rst_n)
        begin
            par_flag_en <= 1'b0;
            par_flag    <= 1'b0;
        end
    else
        begin
            par_flag_en <= i_check_mode[0];
            par_flag    <= i_check_mode[1];
        end 
end     
        
always@(posedge sys_clk or negedge rst_n) //par_data 奇偶校验中需要加入的校验码
begin
    if(!rst_n)
        par_data <= 1'b1;
    else if (par_flag_en) //需要校验  
    begin
        if(par_flag) //奇校验
            par_data <= ~par_num;
        else
            par_data <=  par_num;                           
    end
    else
        par_data <= 1'b1;
end

endmodule
