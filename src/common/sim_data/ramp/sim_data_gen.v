`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/04/10 20:31:26
// Design Name: 
// Module Name: sim_dat_gen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//                      20250122：修改测试模式，参数化
// 
//////////////////////////////////////////////////////////////////////////////////


module sim_data_gen#
(
    parameter DATA_WIDTH = 128
)
(

    input                         sys_clk             ,
    input                         rst_n               ,
    input   [ 7:0]                i_speed             , 
    input   [ 3:0]                i_sim_mode          , //4'd0：ramp
                                                        //4'd1：8位递增数
                                                        //4'd2: 16位递增数
                                                        //4'd3: 32位递增数
                                                        //4'd4: 64位递增数
                                                        //4'd5: 0、1翻转
    
    output  [DATA_WIDTH - 1:0]    o_sim_data          ,
    output                        o_sim_vl            
    
);

reg     [DATA_WIDTH - 1:0]    sim_data       ;
reg                           sim_vl         ;
reg     [ 7:0]                cnt            ;

reg     [ 3:0]                sim_mode_r     ;
reg     [ 3:0]                sim_mode_rr    ;
reg                           mode_rst_n     ;

assign  o_sim_data =  sim_data     ;
assign  o_sim_vl   =  sim_vl       ;


//检测当前测试模式是否发生变化
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        sim_mode_r    <= 4'd0;
        sim_mode_rr   <= 4'd0;
        mode_rst_n    <= 1'b0;
    end
    else 
    begin 
        sim_mode_r  <= i_sim_mode;
        sim_mode_rr <= sim_mode_r;
        if(sim_mode_rr != i_sim_mode)
            mode_rst_n <= 1'b0;
        else
            mode_rst_n <= 1'b1;
    end
end 

//通过i_speed使内部计数来变换数据和产生数据有效的频率，用于控制速度
always@(posedge sys_clk or negedge mode_rst_n)
begin
    if(!mode_rst_n)
    begin
        cnt     <= 'b0;
    end
    else
    begin
        if((i_speed == cnt + 1'b1) || i_speed == 'd0)
            cnt <= 'd0;
        else
            cnt <= cnt + 1'b1 ;
    end
end


//根据不同测试模式，有不同的初值和测试数据生成
integer i;

always@(posedge sys_clk or negedge mode_rst_n)
begin
    if(!mode_rst_n)
    begin
        if(i_sim_mode == 'd0)
        begin 
            sim_data <= {DATA_WIDTH{1'b0}};
        end
        else if(i_sim_mode == 'd1)
        begin
            //8位递增数
            for (i = 0; i < DATA_WIDTH/8; i = i + 1) 
            begin
                //设置每个8位块的值
                sim_data[(i+1)*8-1 -: 8] <= i;
            end 
        end
        else if(i_sim_mode == 'd2)
        begin
            //16位递增数
            for (i = 0; i < DATA_WIDTH/16; i = i + 1) 
            begin
                //设置每个16位块的值
                sim_data[(i+1)*16-1 -: 16] <= i;
            end 
        end
        else if(i_sim_mode == 'd3)
        begin
            //32位递增数
            for (i = 0; i < DATA_WIDTH/32; i = i + 1) 
            begin
                //设置每个32位块的值
                sim_data[(i+1)*32-1 -: 32] <= i;
            end 
        end
        else if(i_sim_mode == 'd4)
        begin
            //64位递增数
            for (i = 0; i < DATA_WIDTH/64; i = i + 1) 
            begin
                //设置每个64位块的值
                sim_data[(i+1)*64-1 -: 64] <= i;
            end 
        end
        else if(i_sim_mode == 'd5)
        begin
            sim_data <= {DATA_WIDTH{1'b0}};
        end
        sim_vl  <= 'b0; 
    end
    else
    begin
        if(cnt == 'd0)
        begin 
            if(i_sim_mode == 'd0)
            begin
                sim_data <= sim_data + 1'b1;
            end
            else if(i_sim_mode == 'd1)
            begin
                for (i = 0; i < DATA_WIDTH/8; i = i + 1) 
                begin
                    //设置每个8位块的值
                    sim_data[(i+1)*8-1 -: 8] <= sim_data[(i+1)*8-1 -: 8] + DATA_WIDTH/8;
                end
            end
            else if(i_sim_mode == 'd2)
            begin
                for (i = 0; i < DATA_WIDTH/16; i = i + 1) 
                begin
                    //设置每个16位块的值
                    sim_data[(i+1)*16-1 -: 16] <= sim_data[(i+1)*16-1 -: 16] + DATA_WIDTH/16;
                end
            end
            else if(i_sim_mode == 'd3)
            begin
                for (i = 0; i < DATA_WIDTH/32; i = i + 1) 
                begin
                    //设置每个32位块的值
                    sim_data[(i+1)*32-1 -: 32] <= sim_data[(i+1)*32-1 -: 32] + DATA_WIDTH/32;
                end
            end
            else if(i_sim_mode == 'd4)
            begin
                for (i = 0; i < DATA_WIDTH/64; i = i + 1) 
                begin
                    //设置每个64位块的值
                    sim_data[(i+1)*64-1 -: 64] <= sim_data[(i+1)*64-1 -: 64] + DATA_WIDTH/64;
                end
            end
            else if(i_sim_mode == 'd5)
            begin
                sim_data <= ~sim_data;
            end
            sim_vl          <= 'b1;
        end
        else
        begin
            sim_data <= sim_data;
            sim_vl  <= 'b0;
        end
    end
end




//ila_320b u_ila_320b (
//    .clk        (sys_clk), // input wire clk
//    
//    
//    .probe0     ({sim_data, sim_vl, cnt}) // input wire [319:0] probe0
//);

endmodule
