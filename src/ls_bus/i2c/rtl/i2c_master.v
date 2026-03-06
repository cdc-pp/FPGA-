module i2c_master#
(
    parameter CLK_FR        =  100_000_000 , //时钟频率
    parameter I2C_CLK_FR    =  100_000     , //输出I2C时钟频率
    parameter REG_ADDR_NUM  =  2           , //REG_ADDR_NUM 为1时字地址为8位，REG_ADDR_NUM 为2时字地址为16位
    parameter WR_LEN        =  2           , //需要写入的字节长度，字节长度等于WR_LEN,最多支持256个字节长度
    parameter RD_LEN        =  2             //需要读取的字节长度，字节长度等于RD_LEN,最多支持256个字节长度
)
(

    input                           sys_clk             ,
    input                           rst_n               ,
            
    input                           i_opt_start         ,
    input                           i_rd_flag           ,
    
    input  [6:0]                    i_slave_addr        , //器件地址
    input  [REG_ADDR_NUM*8-1:0]     i_reg_addr          , //寄存器地址地址
    input  [WR_LEN*8-1:0]           i_wr_data           ,
    output [RD_LEN*8-1:0]           o_rd_data           ,
    output                          o_rd_val            ,
            
    output                          o_done              ,
    output                          o_busy              ,
    input                           i_mode              , //i2c_mode为1时进行随机读操作，i2c_mode为0时进行页读操作
    output                          o_err               ,
    //iic接口     
    inout                           io_sda              ,
    output                          o_scl                 

);

//I2C读写控制状态机
localparam IDLE_STA       = 7'd1  ; 
localparam START_STA      = 7'd2  ; //产生起始位
localparam SALVE_ADDR_STA = 7'd4  ; //写入器件地址状态
localparam REG_ADDR_STA   = 7'd8  ; //写入字节地址状态
localparam WR_DATA_STA    = 7'd16 ; //数据写入状态
localparam RD_DATA_STA    = 7'd32 ; //数据读取状态
localparam STOP_STA       = 7'd64 ; //产生结束位

reg [6:0]                       state         ;
reg [6:0]                       nextstate     ;
reg                             i2c_clk       ;
reg                             i2c_clk_d     ;
reg [10:0]                      clkdiv_cnt    ;
reg [11:0]                      cnt           ;
reg                             ptr           ;
reg [3:0]                       bit_cnt       ;
reg                             en            ;
reg                             i2c_mode_d    ;
reg [7:0]                       reg_addr_num  ;
reg [7:0]                       wr_cnt        ;
reg [7:0]                       rd_cnt        ;
reg [7:0]                       slave_addr_d  ;
reg [REG_ADDR_NUM*8-1'b1:0]     reg_addr_d    ;
reg [WR_LEN*8-1'b1:0]           i2c_wr_data_d ;
reg [RD_LEN*8-1'b1:0]           i2c_rd_data_d ;
reg                             icc_drv       ;
reg                             sda_do        ;
reg                             err           ;
wire                            wr_en_d       ;
reg                             wr_en_dd      ;
wire                            rd_en_d       ;
reg                             rd_en_dd      ;
wire                            sda_di        ;
wire                            wr_en_pe      ;
wire                            rd_en_pe      ;
wire                            i2c_clk_pe    ;

//三态门，由信号icc_drv控制，icc_drv为1时，控制总线，icc_drv为0时，释放总线
assign io_sda = icc_drv ? sda_do : 1'bz;
assign sda_di = io_sda;

always@(posedge sys_clk)
begin
    wr_en_dd <= wr_en_d;
    rd_en_dd <= rd_en_d;
end



assign wr_en_d = (i_opt_start & !i_rd_flag);
assign rd_en_d = (i_opt_start &  i_rd_flag);


assign wr_en_pe = wr_en_d & !wr_en_dd;
assign rd_en_pe = rd_en_d & !rd_en_dd;

always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
       state <= IDLE_STA ;
    else
       state <= nextstate ;
end

always@(*)
begin
    case(state)
        IDLE_STA:
        begin//0
            nextstate = (wr_en_pe|rd_en_pe)?START_STA:IDLE_STA;
        end
        START_STA:
        begin//1
            if(ptr)
                nextstate = SALVE_ADDR_STA;
            else
                nextstate = START_STA     ;
            end
        SALVE_ADDR_STA:
        begin//2
            if(err)
                nextstate <= STOP_STA;
            else if(bit_cnt == 4'd8 & ptr &(!i2c_mode_d) & en)  
                nextstate = RD_DATA_STA; 
            else if(bit_cnt == 4'd8 & ptr & i2c_mode_d & en)
                nextstate = REG_ADDR_STA;     
            else if(bit_cnt == 4'd8 & ptr & (!en))
                nextstate = REG_ADDR_STA; 
            else
                nextstate = SALVE_ADDR_STA;   
        end 
        REG_ADDR_STA:
        begin//3
            if(err)
                nextstate <= STOP_STA;
            else if(bit_cnt == 4'd8 & ptr & (!reg_addr_num) & en)
                nextstate = START_STA;
            else if(bit_cnt == 4'd8 & ptr & (!reg_addr_num) & (!en))
                nextstate = WR_DATA_STA;  
            else
                nextstate = REG_ADDR_STA;  
        end
        WR_DATA_STA:
        begin
            if(err)
                nextstate = STOP_STA;
            else
                nextstate =(bit_cnt == 4'd8 & ptr & wr_cnt == 8'd0)?STOP_STA:WR_DATA_STA;  
        end
        RD_DATA_STA:
        begin
            nextstate=(bit_cnt == 4'd8 & ptr & rd_cnt == 8'd  0)?STOP_STA:RD_DATA_STA;  
        end
        STOP_STA:
        begin
            nextstate=(bit_cnt == 4'd1 & ptr)?IDLE_STA:STOP_STA;
        end
        default:nextstate = IDLE_STA;
    endcase
end

//I2C总线时钟
always@(posedge sys_clk)
begin
    if(!rst_n | state == IDLE_STA | (state == STOP_STA & i2c_clk)|(nextstate == START_STA & state == REG_ADDR_STA))
    begin
        clkdiv_cnt <= 10'd0;
        i2c_clk <= 1'b1;
    end
    else if(clkdiv_cnt == (CLK_FR/(2*I2C_CLK_FR))-1)
    begin
        clkdiv_cnt <= 10'd0;
        i2c_clk <= ~i2c_clk;
    end
    else 
    begin
        clkdiv_cnt <= clkdiv_cnt + 10'b1;
        i2c_clk <= i2c_clk;
    end    
end

//I2C总线时钟上升沿
always@(posedge sys_clk)
begin
     i2c_clk_d <= i2c_clk; 
end

assign i2c_clk_pe = i2c_clk & !i2c_clk_d;
assign o_scl = i2c_clk;

//状态机跳变指示信号ptr
always@(posedge sys_clk)
begin
    if(!rst_n | state == IDLE_STA | (nextstate == START_STA & state == REG_ADDR_STA))
    begin
        cnt <= (CLK_FR/(4*I2C_CLK_FR))+2'd2;
        ptr <= 1'b0;
    end
    else if(cnt == CLK_FR/I2C_CLK_FR-1)
    begin
        cnt <= 11'd0;
        ptr <= 1'b1;
    end
    else 
    begin
        cnt <= cnt + 11'b1;
        ptr <= 1'b0;
    end    
end

//bit_cnt，每9个bit_cnt为一个状态周期
always@(posedge sys_clk)
begin
    if(!rst_n | state == IDLE_STA | state == START_STA)
        bit_cnt <= 4'd0;
    else if(ptr)
        if(bit_cnt == 4'd8)
            bit_cnt <= 4'd0;
        else
            bit_cnt <= bit_cnt + 1'b1;
end

//en为1时表示为读操作，en为零时表示为写操作
always@(posedge sys_clk)
begin
    if(state == IDLE_STA & wr_en_pe)
        en <= 1'b0;
    else if(state == IDLE_STA & rd_en_pe)
        en <= 1'b1;
    else
        en <= en;
end

//i2c_mode_d为1时进行随机读操作，i2c_mode_i为0时进行读当前寄存器或页读操作
always@(posedge sys_clk)
begin
    if(state == IDLE_STA & rd_en_pe)
        i2c_mode_d <= i_mode;
    else if(state == REG_ADDR_STA)//完成虚写操作后，下一步转化为读当前寄存器或页读操作，此时将i2c_mode_i信号拉低
        i2c_mode_d <= 1'b0;
    else
        i2c_mode_d <= i2c_mode_d;
end

//reg_addr_num 为1时字地址为16位，reg_addr_num 为0时字地址为8位
always@(posedge sys_clk)
begin
    if(state == IDLE_STA)
        reg_addr_num <= REG_ADDR_NUM - 'd1;
    else if(state == REG_ADDR_STA & bit_cnt == 4'd8 & ptr)
    begin
        if(reg_addr_num == 'd0)
            reg_addr_num <= reg_addr_num;
        else
            reg_addr_num <= reg_addr_num - 1'b1;
    end
    else
        reg_addr_num <= reg_addr_num;
end

//wr_cnt计算剩余待写字节
always@(posedge sys_clk)
begin
    if(!rst_n)
        wr_cnt <= 8'd0;
    else if((state == IDLE_STA ) & wr_en_pe)
        wr_cnt <= WR_LEN - 'd1;
    else if(state == WR_DATA_STA & bit_cnt == 4'd8 & ptr)
        wr_cnt <= wr_cnt - 1'b1;
    else
        wr_cnt <= wr_cnt;
end

//rd_cnt计算剩余待读字节
always@(posedge sys_clk)
begin
    if(!rst_n)
        rd_cnt <= 8'd  0;
    else if((state == IDLE_STA ) & rd_en_pe)
        rd_cnt <= RD_LEN - 'd1;
    else if(state == RD_DATA_STA & bit_cnt==4'd8 & ptr)
        rd_cnt <= rd_cnt - 1'b1;
    else
        rd_cnt <= rd_cnt;
end

//对icc_drv信号进行控制
always @ (posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
        icc_drv <= 1'b1;
    else if(state == IDLE_STA)
        icc_drv <= 1'b1;
    else if(state == START_STA)
        icc_drv <= 1'b1;
    else if(bit_cnt == 4'd8)
        begin
            if(state == SALVE_ADDR_STA|state == REG_ADDR_STA|state == WR_DATA_STA)
                icc_drv <= 1'b0;
            else if (state == RD_DATA_STA & rd_cnt > 8'd0  )
                icc_drv <= 1'b1;
            else if (state == RD_DATA_STA & rd_cnt == 8'd  0)
                icc_drv <= 1'b0;
            else
                ;
        end
    else if(bit_cnt<4'd8)
        begin
            if(state == SALVE_ADDR_STA|state == REG_ADDR_STA|state == WR_DATA_STA|(state == STOP_STA & bit_cnt == 4'd0))
                icc_drv <= 1'b1;
            else if (state == RD_DATA_STA)
                icc_drv <= 1'b0;
            else
                icc_drv <= icc_drv;
        end
    else
        icc_drv <= icc_drv;
end

//从机未应答时，err拉高，直接产生停止位
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
        err <= 1'b0;
    else if(state == IDLE_STA | state == START_STA )
        err <= 1'b0;
    else if(bit_cnt == 4'd8 & i2c_clk_pe & (state == SALVE_ADDR_STA |state == REG_ADDR_STA|state == WR_DATA_STA))
    begin
        if (sda_di)
            err <= 1'b1;
        else
            err <= err;   
    end
    else
        err <= err;
end

//slave_addr_d移位输出器件地址slave_addr
always@(posedge sys_clk)
begin
    if(!rst_n)
        slave_addr_d <= 8'd0;
    else if((state == IDLE_STA ) & (wr_en_pe | (rd_en_pe & i_mode) ))
        slave_addr_d <= {i_slave_addr[6:0], 1'b0};   
    else if((state == IDLE_STA ) & (rd_en_pe & !i_mode))
        slave_addr_d <= {i_slave_addr[6:0], 1'b1};
    else if( (state == SALVE_ADDR_STA)  & (bit_cnt<8) & ptr)
        slave_addr_d <= {slave_addr_d[6:0],slave_addr_d[7]};     
    else if(state == REG_ADDR_STA)
        slave_addr_d <= {i_slave_addr[6:0], 1'b1};     
    else
        slave_addr_d <= slave_addr_d;
end
//reg_addr_d移位输出字节地址reg_addr
always@(posedge sys_clk)
begin
    if(!rst_n)
        reg_addr_d <= 'd0;
    else if((state== IDLE_STA) & (wr_en_pe|rd_en_pe))
        reg_addr_d <= i_reg_addr;
    else if( state== REG_ADDR_STA  & bit_cnt < 'd8 & ptr)
        reg_addr_d <= {reg_addr_d[REG_ADDR_NUM*8-2:0],reg_addr_d[REG_ADDR_NUM*8-1]};
    else
        reg_addr_d <= reg_addr_d;
end

//i2c_wr_data_d移位处理需要写入的数据i2c_wr_data
always@(posedge sys_clk)
begin
    if(!rst_n  )
        i2c_wr_data_d <= 'd0;
    else if((state == IDLE_STA) & wr_en_pe)
        i2c_wr_data_d <= i_wr_data;
    else if( state == WR_DATA_STA  & bit_cnt<8 & ptr)
        i2c_wr_data_d <= {i2c_wr_data_d[WR_LEN*8-2:0],i2c_wr_data_d[WR_LEN*8-1]};
    else
        i2c_wr_data_d <= i2c_wr_data_d;
end

//i2c_rd_data_d移位读取数据
always@(posedge sys_clk)
begin
    if(!rst_n )
        i2c_rd_data_d <= 'd0;
    else if( state == RD_DATA_STA  & bit_cnt<8 & i2c_clk_pe)
        i2c_rd_data_d <= {i2c_rd_data_d[RD_LEN*8-2:0],sda_di};
    else
        i2c_rd_data_d <= i2c_rd_data_d;
end

assign o_rd_data = i2c_rd_data_d;

//I2C总线数据
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
        sda_do <= 1'b1;
    else if(state == IDLE_STA | state == START_STA & cnt < (CLK_FR/(2*I2C_CLK_FR)+2))
        sda_do <= 1'b1;
    else if(state == START_STA & cnt>=(CLK_FR/(2*I2C_CLK_FR)+2))
        sda_do <= 1'b0;
    else if(state == SALVE_ADDR_STA)
        sda_do <= slave_addr_d[7];
    else if(state == REG_ADDR_STA)
        sda_do <= reg_addr_d[REG_ADDR_NUM*8-1];
    else if(state == WR_DATA_STA)
        sda_do <= i2c_wr_data_d[WR_LEN*8-1];
    else if(state == RD_DATA_STA & bit_cnt == 4'd8 & rd_cnt == 8'd0)
        sda_do <= 1;
    else if(state == RD_DATA_STA & bit_cnt == 4'd8 & rd_cnt > 8'd0  )
        sda_do <= 0;
    else if(state == STOP_STA & bit_cnt == 4'd0)
        sda_do <= 0;
    else if(state == STOP_STA & bit_cnt == 4'd1)
        sda_do <= 1;   
    else
        sda_do <= sda_do;
end

//busy为0时表示状态机空闲
assign o_busy = (state == IDLE_STA) ? 1'b0 : 1'b1;

//输出读数据有效指示rd_val ，写数据有效指示
assign o_rd_val = (nextstate == IDLE_STA & state == STOP_STA & en  ) ? 1'b1 : 1'b0;
assign o_done = (nextstate == IDLE_STA & state == STOP_STA ) && (err == 1'b0) ? 1'b1 : 1'b0;
assign o_err = err;


//ila_0 u_ila_0 (
//    .clk        (sys_clk), // input wire clk
//    
//    
//    .probe0     ({sda_do, sda_di, i2c_clk, state, bit_cnt, icc_drv}) // input wire [127:0] probe0
//);

endmodule
