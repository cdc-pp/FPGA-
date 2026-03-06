`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/31 17:22:22
// Design Name: 
// Module Name: i2c_slave
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
// 
//////////////////////////////////////////////////////////////////////////////////


module i2c_slave#
(

    parameter REG_ADDR_NUM  = 2         //REG_ADDR_NUM为1时，字节地址为8位，REG_ADDR_NUM为2时，字节地址为16位

)
(
    input                                       sys_clk       ,
    input                                       rst_n         ,
    input     [ 6:0]                            i_slave_addr  ,
    //写数据解析
    output                                      o_wr_val      ,
    output    [ 7:0]                            o_wr_data     ,
    output    [REG_ADDR_NUM * 8 - 1 : 0]        o_wr_addr     ,
    //读数据解析                                              
    input     [ 7:0]                            i_rd_data     ,
    output    [REG_ADDR_NUM * 8 - 1 : 0]        o_rd_addr     ,
    //I2C接口
    inout                                       io_sda        ,
    input                                       i_scl  
    
);

localparam IDLE_STATE       = 'd1   ,
           S0_STATE         = 'd2   ,
           S1_STATE         = 'd4   ,
           S2_STATE         = 'd8   ,
           S3_STATE         = 'd16  ,
           S4_STATE         = 'd32  ,
           S5_STATE         = 'd64  ,
           S6_STATE         = 'd128 ,//S1_STATE——S6_STATE通过序列检测机，检测主机通信的对象
           S7_STATE         = 'd256 ,//读写判断
           ACK_STATE        = 'd512 ,//从机应答
           REG_ADDR_STATE   = 'd1024,//字节地址
           WR_DATA_STATE    = 'd2048,//主机写数据
           RD_DATA_STATE    = 'd4096;//主机读数据

reg     [ 6:0]                      slave_addr      ;
wire                                scl_pe          ;
wire                                scl_ne          ;
wire                                sda_in_pe       ;
wire                                sda_in_ne       ;
//wire    [ 7:0]                      rd_data         ;
//wire                                ena             ;
wire                                sda_in          ;
                        
reg                                 sda_do          ;
reg     [15:0]                      reg_addr        ; //解析主设备传输的地址

reg     [REG_ADDR_NUM * 8 - 1 : 0]  wr_addr         ;
reg     [REG_ADDR_NUM * 8 - 1 : 0]  rd_addr         ;

reg     [ 7:0]                      wr_data         ;
reg                                 wr_val          ;
reg                                 wr_val_r        ;
reg                                 rd_val          ;
reg                                 rd_val_r        ;
reg     [ 7:0]                      wr_data_r       ;
reg                                 i2c_drv         ;
reg     [12:0]                      state           ;
reg     [12:0]                      nextstate       ;
reg                                 scl_d0          ;
reg                                 scl_d1          ;
reg                                 scl_d2          ;
reg                                 sda_in_d0       ;
reg                                 sda_in_d1       ;
reg                                 sda_in_d2       ;
reg                                 en              ;
reg     [3:0]                       cnt             ;
reg     [3:0]                       cnt_d           ;
reg                                 reg_addr_num    ;


//输出信号解析
assign o_wr_val   = wr_val_r  ;
assign o_wr_data  = wr_data_r ;
assign o_wr_addr  = wr_addr[(REG_ADDR_NUM * 8 - 1) : 0];
assign o_rd_addr  = rd_addr[(REG_ADDR_NUM * 8 - 1) : 0];
                  
//assign ena        = wr_val | rd_val             ;
assign io_sda     = i2c_drv ? sda_do : 1'bz ;
assign sda_in     = io_sda                  ;
assign scl_pe     = !scl_d2 & scl_d1        ;
assign scl_ne     = !scl_d1 & scl_d2        ; 
assign sda_in_pe  = !sda_in_d2 & sda_in_d1  ;
assign sda_in_ne  = !sda_in_d1 & sda_in_d2  ; 

//器件地址
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        slave_addr <= 7'd0;
    end
    else
    begin
        slave_addr <= i_slave_addr;
    end
end

//有效信号打拍
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        wr_val_r <= 1'b0;
        rd_val_r <= 1'b0;
    end
    else
    begin
        wr_val_r <= wr_val;
        rd_val_r <= rd_val;
    end
end

//写数据打拍
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        wr_data_r  <= 'd0;
    end
    else 
    begin
        if(wr_val == 1'b1)
        begin
            wr_data_r <= wr_data;
        end
        else 
        begin
            wr_data_r <= wr_data_r;
        end
    end
end

//写地址打拍
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        wr_addr  <= 'd0;
    end
    else 
    begin
        if(wr_val == 1'b1)
        begin
            wr_addr <= reg_addr[(REG_ADDR_NUM * 8 - 1) : 0];
        end
        else 
        begin
            wr_addr <= wr_addr;
        end
    end
end

always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        rd_addr  <= 'd0;
    end
    else 
    begin
        if(scl_ne & cnt == 'd0 & en)
        begin
            rd_addr <= reg_addr[(REG_ADDR_NUM * 8 - 1) : 0];
        end
        else 
        begin
            rd_addr <= rd_addr;
        end
    end
end

//处理跨时钟信号
always@(posedge sys_clk)
begin
    sda_in_d0 <= sda_in   ;
    sda_in_d1 <= sda_in_d0;
    sda_in_d2 <= sda_in_d1;
end

always@(posedge sys_clk)
begin
    scl_d0 <= i_scl   ;
    scl_d1 <= scl_d0;
    scl_d2 <= scl_d1;
end


//记录主机的读写请求方便状态机跳转
always@(posedge sys_clk)
begin
    if(state == S7_STATE & scl_pe)begin
        en <= sda_in;
    end
    else begin
        en <= en    ; 
    end
end


//以9个I2C时钟周期为一个周期
always@(posedge sys_clk) 
begin
    if (state == IDLE_STATE | (cnt == 4'd0 & scl_ne) | state == S0_STATE ) begin
        cnt <= 4'd8;
    end
    else if (scl_ne) begin
        cnt <= cnt + 4'hf;
    end
    else begin
        cnt <= cnt ;
    end
end

always @(posedge sys_clk) 
begin
    cnt_d <= cnt ;
end

//reg_addr_num为1时，写入字节地址高8位1，reg_addr_num为时，写入字节地址低8位
always@(posedge sys_clk) 
begin
    if (state == IDLE_STATE) begin
        reg_addr_num <= REG_ADDR_NUM - 1;
    end
    else if (state == REG_ADDR_STATE & cnt =='d0 & scl_ne) begin
        reg_addr_num <= 1'b0;
    end
    else begin
        reg_addr_num <= reg_addr_num;
    end
end


//状态机
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)begin
        state <= IDLE_STATE;
    end
    else begin
        state <= nextstate;
    end
end

always@(*)
begin
    case(state)
        IDLE_STATE : 
        begin
            if(scl_d1 & sda_in_ne)begin
                nextstate  = S0_STATE;
            end
            else begin
                nextstate  = IDLE_STATE;
            end
        end
        S0_STATE: 
        begin  
            if(scl_d1 & sda_in_pe)begin
                nextstate  = IDLE_STATE;
            end
            else if(scl_pe & sda_in_d1 == slave_addr[6]) begin
                nextstate  = S1_STATE;
            end
            else if(scl_pe & sda_in_d1 !== slave_addr[6]) begin
                nextstate  = IDLE_STATE;
            end
            else begin
                nextstate  = S0_STATE;
            end
        end
        S1_STATE   : 
        begin  
            if(scl_d1 & sda_in_pe)begin
                nextstate  = IDLE_STATE;
            end
            else if(scl_pe & sda_in_d1 == slave_addr[5]) begin
                nextstate  = S2_STATE;
            end
            else if(scl_pe & sda_in_d1 !== slave_addr[5]) begin
                nextstate  = IDLE_STATE;
            end
            else begin
                nextstate  = S1_STATE;
            end
        end
        S2_STATE   : 
        begin  
            if(scl_d1 & sda_in_pe)begin
                nextstate  = IDLE_STATE;
            end
            else if(scl_pe & sda_in_d1 == slave_addr[4]) begin
                nextstate  = S3_STATE;
            end
            else if(scl_pe & sda_in_d1 !== slave_addr[4]) begin
                nextstate  = IDLE_STATE;
            end
            else begin
                nextstate  = S2_STATE;
            end
        end
        S3_STATE   : 
        begin  
            if(scl_d1 & sda_in_pe)begin
                nextstate  = IDLE_STATE;
            end
            else if(scl_pe & sda_in_d1 == slave_addr[3]) begin
                nextstate  = S4_STATE;
            end
            else if(scl_pe & sda_in_d1 !== slave_addr[3]) begin
                nextstate  = IDLE_STATE;
            end
            else begin
                nextstate  = S3_STATE;
            end
        end
        S4_STATE   : 
        begin  
            if(scl_d1 & sda_in_pe)begin
                nextstate  = IDLE_STATE;
            end
            else if(scl_pe & sda_in_d1 == slave_addr[2]) begin
                nextstate  = S5_STATE;
            end
            else if(scl_pe & sda_in_d1 !== slave_addr[2]) begin
                nextstate  = IDLE_STATE;
            end
            else begin
                nextstate  = S4_STATE;
            end
        end
        S5_STATE   : 
        begin  
            if(scl_d1 & sda_in_pe)begin
                nextstate  = IDLE_STATE;
            end
            else if(scl_pe & sda_in_d1 == slave_addr[1]) begin
                nextstate  = S6_STATE;
            end
            else if(scl_pe & sda_in_d1 !== slave_addr[1]) begin
                nextstate  = IDLE_STATE;
            end
            else begin
                nextstate  = S5_STATE;
            end
        end
        S6_STATE   : 
        begin  
            if(scl_d1 & sda_in_pe)begin
                nextstate  = IDLE_STATE;
            end
            else if(scl_pe & sda_in_d1 == slave_addr[0]) begin
                nextstate  = S7_STATE;
            end
            else if(scl_pe & sda_in_d1 !== slave_addr[0]) begin
                nextstate  = IDLE_STATE;
            end
            else begin
                nextstate  = S6_STATE;
            end
        end
        S7_STATE   : 
        begin  
            if(scl_d1 & sda_in_pe)begin
                nextstate  = IDLE_STATE;
            end
            else if(scl_pe) begin
                nextstate  = ACK_STATE;
            end
            else begin
                nextstate  = S7_STATE;
            end
        end
        ACK_STATE : 
        begin  
            if(scl_d1 & sda_in_pe)begin
                nextstate  = IDLE_STATE;
            end
            else if(scl_ne & cnt == 'd0 & !en) begin
                nextstate  = REG_ADDR_STATE;
            end
            else if(scl_ne & cnt == 'd0 & en) begin
                nextstate  = RD_DATA_STATE;
            end
            else begin
                nextstate  = ACK_STATE;
            end
        end
        REG_ADDR_STATE:
        begin  
            if(scl_d1 & sda_in_pe)begin
                nextstate  = IDLE_STATE;
            end
            else if(scl_ne & cnt == 'd0 & reg_addr_num == 1'd0) begin
                nextstate  = WR_DATA_STATE;
            end
            else begin
                nextstate  = REG_ADDR_STATE;
            end
        end
        WR_DATA_STATE:
        begin  
            if(scl_d1 & sda_in_pe)begin
                nextstate  = IDLE_STATE;
            end
            else if(scl_d1 & sda_in_ne)begin
                nextstate  = S0_STATE;
            end
            else begin
                nextstate  = WR_DATA_STATE;
            end
        end
        RD_DATA_STATE:
        begin  
            if(scl_d1 & sda_in_pe | (cnt == 'd0 & sda_in !=='d0 & scl_pe))begin
                nextstate  = IDLE_STATE;
            end
            else begin
                nextstate  = RD_DATA_STATE;
            end
        end
        default: begin nextstate = IDLE_STATE; end
    endcase
end


//三态门控制信号i2c_drv，i2c_drv为1时，从机获得总线控制权，i2c_drv为0时，释放总线控制权
always @(posedge sys_clk) 
begin
    if (state == IDLE_STATE) 
        i2c_drv <= 1'b0;
    else if(cnt == 'd0)
    begin
        if(state == ACK_STATE | state == REG_ADDR_STATE | state == WR_DATA_STATE)begin
            i2c_drv <= 1'b1;
        end
        else if (state == RD_DATA_STATE)begin
            i2c_drv <= 1'b0;
        end
        else begin
            i2c_drv <= i2c_drv;
        end
    end
    else if(cnt > 'd0)
    begin
        if(state == ACK_STATE | state == REG_ADDR_STATE | state == WR_DATA_STATE)
            i2c_drv <= 1'b0;
        else if (state == RD_DATA_STATE)
            i2c_drv <= 1'b1;
        else begin
            i2c_drv <= i2c_drv;
        end
    end
    else begin
        i2c_drv <= i2c_drv;
    end
end

//从机获得总线控制权，发送回复信号，或者发送主机需要读取的数据
always @(posedge sys_clk) 
begin
    if (state == IDLE_STATE) 
        sda_do <= 1'b0;
    else if(state == ACK_STATE & scl_ne | (state == REG_ADDR_STATE & cnt == 'd0)| (state == WR_DATA_STATE & cnt == 'd0) )
        sda_do <= 1'b0;
    else if(state == RD_DATA_STATE )
        sda_do <= i_rd_data[cnt - 1];
    else 
        sda_do <= sda_do;
end

//每次通信需要读写的地址
always @(posedge sys_clk or negedge rst_n) 
begin
    if(!rst_n)
        reg_addr <= 16'd0;
    else if(state == REG_ADDR_STATE & reg_addr_num & cnt !== 'd0 & scl_pe)begin
        reg_addr[(cnt + 8) - 1] <= sda_in;
    end
    else if(state == REG_ADDR_STATE & !reg_addr_num & cnt !== 'd0 & scl_pe)begin
        reg_addr[cnt - 1] <= sda_in;
    end
    else if((state == WR_DATA_STATE | state == RD_DATA_STATE) &  cnt_d =='d0 & scl_pe)begin
        reg_addr <= reg_addr + 'b1;
    end
    else begin
        reg_addr <= reg_addr;
    end
end

//通过写使能将主机写入的数据存入RAM
always @(posedge sys_clk) 
begin
    if (state == IDLE_STATE) begin
        wr_val <= 1'b0;
    end
    else if(state == WR_DATA_STATE & cnt == 'd0 & cnt_d =='d1)begin
        wr_val <= 1'b1;
    end
    else begin
        wr_val <= 1'b0;
    end
end

//通过写使能将主机想要读取的数据从RAM中读取
always @(posedge sys_clk) 
begin
    if (state == IDLE_STATE) begin
        rd_val <= 1'b0;
    end
    else if(state == RD_DATA_STATE & cnt == 'd0 & cnt_d =='d1)begin
        rd_val <= 1'b1;
    end
    else begin
        rd_val <= 1'b0;
    end
end

//wr_data将主机写入的数据存入RAM
always @(posedge sys_clk) 
begin
    if (state == IDLE_STATE) begin
        wr_data <= 'd0;
    end
    else if(state == WR_DATA_STATE & cnt !== 'd0 & scl_pe)begin
        wr_data[cnt - 'd1] <= sda_in;
    end
    else begin
        wr_data <= wr_data;
    end
end

//blk_8bit_16depth u_blk_8bit_16depth (
//  .clka(sys_clk),    // input wire clka
//  .ena(ena),      // input wire ena
//  .wea(wr_val),      // input wire [0 : 0] wea
//  .addra(reg_addr),  // input wire [15 : 0] addra
//  .dina(wr_data),    // input wire [7 : 0] dina
//  .clkb(sys_clk),    // input wire clkb
//  .enb(1'b1),      // input wire enb
//  .addrb(reg_addr),  // input wire [15 : 0] addrb
//  .doutb(rd_data)  // output wire [7 : 0] doutb
//);

//i2c_reg #(
//    .REG_ADDR_NUM(2)
//) u_i2c_reg (
//    .sysclk   (sys_clk  ),
//    .rst_n     (rst_n    ),
//    .i_wr_val  (o_wr_val ),
//    .i_wr_data (o_wr_data),
//    .i_wr_addr (o_wr_addr),
//    .o_rd_data (i_rd_data),
//    .i_rd_addr (o_rd_addr)
//);

ila_128b u_ila_128b (
    .clk        (sys_clk), // input wire clk
            
            
    .probe0     ({cnt, reg_addr, reg_addr_num, sda_in, state, reg_addr}) // input wire [127:0] probe0
);

endmodule
