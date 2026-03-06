`timescale 1 ns / 1 ps
/////////////////////////////////////////////////////////////
//Description : 
//
//
//writer :  lzp 
//
//Create Date： 
//
//Revision:  
//    v1.1     
//    v1.2：增加从部分寄存器位置重新配置的功能接口
/////////////////////////////////////////////////////////////

module chip_cfg_bk #
(
    parameter   DATA_WIDTH     = 16              ,
    parameter   RDATA_WIDTH    = 8               ,
    parameter   CFG_WIDTH      = 9               ,  
    parameter   WDLY_PAR       = 32'hff          ,
    parameter   RDLY_PAR       = 32'hffff        ,
    parameter   DLY_PAR        = 32'h1E8480
)
(
    input                               sys_clk             ,
    input                               rst_n               ,
    output [DATA_WIDTH-1:0]             o_cmd_data          , //配置数据输出
    output                              o_opt_start         , //配置开始信号
    input                               i_opt_done          , //单次配置完成标志
    output [CFG_WIDTH-1:0]              o_cfg_addr          , //寄存器配置地址 
    input  [(DATA_WIDTH+2)-1:0]         i_cfg_data          , //寄存器配置数据，[cmd + cfg_data]
    output                              o_cfg_over          , //所有配置完成标志
    input                               i_rd_done           , //读操作外部判断有效标志，用于跳出读循环状态
    input                               i_wait_done         ,
    output                              o_cfg_rd_flag       , //通过CMD，解析读写操作
    input  [RDATA_WIDTH-1:0]            i_rd_data           ,
    input                               i_rd_val            ,
    input  [CFG_WIDTH-1:0]              i_cfg_end_num       , //寄存器最后一个数索引值
    input                               i_re_cfg_en         , //重新配置使能
    input  [CFG_WIDTH-1:0]              i_re_cfg_addr       , //重新配置地址起始
    output                              o_re_cfg_done       ,
    //debug 预留用户配置接口
    input  [(DATA_WIDTH+2)-1:0]         i_usr_cfg_data      , 
    input                               i_usr_cfg_en        , //用户配置使能
    input                               i_usr_cfg_val       ,  
    output                              o_usr_cfg_done      ,
    output [RDATA_WIDTH-1:0]            o_usr_rd_data       ,
    output                              o_usr_rd_val   
    
);

localparam      IDLE_STA    = 10'h000,
                RROM_STA    = 10'h001,
                JROM_STA    = 10'h002,
                WPRO_STA    = 10'h004,
                RPRO_STA    = 10'h008,
                WAIT_STA    = 10'h010,
                JRDT_STA    = 10'h020,
                WDLY_STA    = 10'h040,
                RDLY_STA    = 10'h080,
                DLY_STA     = 10'h100,
                OVER_STA    = 10'h200;

//regs
reg                            opt_start           ;
reg                            cfg_over            ;
reg                            dly_en              ;
reg    [31:0]                  dly_cnt             ;
reg    [CFG_WIDTH-1:0]         cfg_addr            ;
reg                            cfg_rden            ;
reg    [(DATA_WIDTH+2)-1:0]    cfg_data_reg        ;
reg    [9:0]                   cur_sta             ;
reg                            cfg_rd_flag         ;
reg    [RDATA_WIDTH-1:0]       usr_rd_data         ;
reg                            cfg_done            ;
reg                            usr_rd_val          ;
reg                            usr_cfg_val_f       ;
reg                            usr_cfg_val_ff      ;
reg                            re_cfg_en_f         ;
reg                            re_cfg_en_ff        ;
reg                            cfg_done_r          ;

reg  [31:0]                    pwr_dly_cnt         ;
reg                            pwr_dly_en          ;

reg                            re_cfg_busy         ;
reg                            re_cfg_done         ;

//wires


//assigns
assign  o_cmd_data     = cfg_data_reg[(DATA_WIDTH+2)-1 -2:0]  ; //去掉CMD部分
assign  o_opt_start    = opt_start                            ;
assign  o_cfg_over     = cfg_over                             ; 
assign  o_cfg_addr     = cfg_addr                             ;
assign  o_cfg_rd_flag  = cfg_rd_flag                          ;
assign  o_usr_cfg_done = cfg_done_r                           ;
assign  o_usr_rd_data  = usr_rd_data                          ;
assign  o_usr_rd_val   = usr_rd_val                           ;
assign  o_re_cfg_done  = re_cfg_done                          ;

//上电延时
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        pwr_dly_cnt <= 'd0; 
        pwr_dly_en  <= 1'b0;
    end
    else 
    begin
        if(pwr_dly_cnt == 'd200_0000)
        begin
            pwr_dly_cnt <= 'd200_0000; 
            pwr_dly_en  <= 1'b1;
        end
        else 
        begin
            pwr_dly_cnt <= pwr_dly_cnt + 1'b1;
            pwr_dly_en  <= 1'b0;
        end
    end
end

//外部操作时，读出寄存器值
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        usr_rd_data <= 'd0;
        usr_rd_val  <= 1'b0;
    end
    else 
    begin
        if(i_usr_cfg_en == 1'b1)
        begin
            if(i_rd_val == 1'b1)
            begin
                usr_rd_data <= i_rd_data;
                usr_rd_val  <= 1'b1;
            end
            else 
            begin
                usr_rd_data <= usr_rd_data;
                usr_rd_val  <= 1'b0;
            end
        end
        else
        begin
            usr_rd_data <= usr_rd_data;
            usr_rd_val  <= 1'b0;
        end
    end
end

//cfg_done打拍
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            cfg_done_r <= 1'b0;
        end
    else 
        begin
            cfg_done_r <= cfg_done;
        end
end


//延时计数，当单次读写后，需延时等待的时间
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        dly_cnt <= 'b0;
    end
    else
    begin
        if(dly_en)
            dly_cnt <= dly_cnt + 1'b1;
        else
            dly_cnt <= 'b0;
    end
end

//用户配置产生上升沿
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        usr_cfg_val_f  <= 1'b0;
        usr_cfg_val_ff <= 1'b0;
    end
    else 
    begin
        usr_cfg_val_f <= i_usr_cfg_val;
        usr_cfg_val_ff <= usr_cfg_val_f;
    end
end

//重新配置上升沿
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        re_cfg_en_f  <= 1'b0;
        re_cfg_en_ff <= 1'b0;
    end
    else 
    begin
        re_cfg_en_f  <= i_re_cfg_en;
        re_cfg_en_ff <= re_cfg_en_f;
    end
end

//配置寄存器寄存，配置地址递增
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        cfg_addr          <= 'b0;
        cfg_data_reg      <= 'b0;
    end
    else
    begin
        if(i_usr_cfg_en)
        begin
            if((~usr_cfg_val_ff && usr_cfg_val_f) == 1'b1)
                cfg_data_reg <= i_usr_cfg_data;
            else 
                cfg_data_reg <= cfg_data_reg   ;
        end
        else if((~re_cfg_en_ff && re_cfg_en_f) == 1'b1)
        begin
            cfg_addr <= i_re_cfg_addr;
        end
        else 
        begin
            cfg_data_reg <= i_cfg_data             ;
            if(cfg_rden)
            begin
                if(cfg_addr == i_cfg_end_num)
                    cfg_addr <= cfg_addr       ;
                else
                    cfg_addr <= cfg_addr + 1'b1;
            end
        end
    end
end

//状态机：判断读写操作，控制单次的配置开始及结束，延时设置
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        cfg_done    <= 1'b0 ;
        cfg_rden    <= 'b0  ; //单次完成配置后，1clk拉高
        opt_start   <= 'b0  ;
        dly_en      <= 'b0  ;
        cfg_over    <= 'b0  ;
        cfg_rd_flag <= 1'b0 ; //1'b0为写操作，1'b1为读操作
        re_cfg_busy <= 1'b0 ;
        re_cfg_done <= 1'b0 ;
        cur_sta     <= IDLE_STA;
    end
    else
    begin
        case(cur_sta)
            IDLE_STA:   
            begin
                cfg_done <= 1'b0;
                cfg_rden <= 1'b0;
                dly_en   <= 1'b0;
                if(cfg_addr == i_cfg_end_num) //配置计数与预设值判断 
                begin
                    cur_sta <= OVER_STA;
                    if(re_cfg_busy == 1'b1)
                    begin
                        re_cfg_done <= 1'b1;
                        re_cfg_busy <= 1'b0;
                    end
                    if(i_usr_cfg_en == 1'b1)
                    begin
                        cfg_done <= 1'b1;
                    end
                    else 
                    begin
                        cfg_done <= 1'b0;
                    end
                end
                else if(pwr_dly_en) 
                    cur_sta <= RROM_STA;
            end
            RROM_STA:   
            begin
                cfg_done<= 1'b0 ;
                dly_en  <= 'b0  ;
                cur_sta <= JROM_STA;
            end
            JROM_STA:   
            begin
                if(cfg_data_reg[(DATA_WIDTH+2)-1:(DATA_WIDTH+2)-2] == 2'b10) //判断当前是否为读操作
                begin
                    cfg_rd_flag <= 1'b1    ;
                    opt_start   <= 'b1     ;
                    cur_sta     <= RPRO_STA;
                end
                else if(cfg_data_reg[(DATA_WIDTH+2)-1:(DATA_WIDTH+2)-2] == 2'b00) //判断当前是否为写操作
                begin
                    cfg_rd_flag <= 1'b0    ;
                    opt_start   <= 'b1     ;
                    cur_sta     <= WPRO_STA;
                end
                else if(cfg_data_reg[(DATA_WIDTH+2)-1:(DATA_WIDTH+2)-2] == 2'b11) //判断当前是否为等待状态
                begin
                    cfg_rd_flag <= 1'b0    ;
                    cur_sta     <= WAIT_STA;
                end
                else //其它CMD为延时操作
                begin
                    cur_sta <= DLY_STA;
                end 
            end
            WPRO_STA:   
            begin 
                opt_start <= 'b0;
                if(i_opt_done)
                    cur_sta <= WDLY_STA; 
            end
            RPRO_STA:   
            begin
                opt_start <= 'b0;
                if(i_opt_done)
                    cur_sta <= JRDT_STA; 
            end
            WAIT_STA:   
            begin
                if(i_wait_done)
                begin
                    cfg_rden <= 1'b1;
                    cur_sta  <= IDLE_STA;
                end
                else
                begin
                    cur_sta  <= WAIT_STA;
                end
            end
            JRDT_STA:   
            begin //读操作判断状态，若读判断失败则循环读 
                if(i_rd_done)
                begin
//                  cfg_rden <= 1'b1    ;
                    cur_sta  <= WDLY_STA;
                end
                else
                begin
                    cur_sta <= RDLY_STA;
                end
            end
            WDLY_STA:   
            begin //读/写操作后延时
                dly_en <= 'b1;
                if(dly_cnt == WDLY_PAR) 
                begin
                    cfg_rden <= 1'b1     ;
                    cur_sta  <= IDLE_STA ; 
                end
            end 
            RDLY_STA:   
            begin //读操作判断失败延时重读
                dly_en <= 'b1;
                if(dly_cnt == RDLY_PAR)
                    cur_sta <= RROM_STA; 
            end
            DLY_STA:    
            begin //延时操作
                dly_en <= 'b1;
                if(dly_cnt == DLY_PAR)  
                begin
                    cfg_rden <= 1'b1    ;
                    cur_sta <= IDLE_STA ;
                end
            end
            OVER_STA:   
            begin
                if((~usr_cfg_val_ff && usr_cfg_val_f) == 1'b1) //用户配置有效信号
                    cur_sta <= RROM_STA;
                if((~re_cfg_en_ff && re_cfg_en_f) == 1'b1)
                begin
                    re_cfg_busy <= 1'b1;
                    cur_sta <= RROM_STA;
                end
                re_cfg_done <= 1'b0;
                cfg_over <= 'b1;
                cfg_done <= 1'b0;
            end
            default:    
            begin
                cfg_done    <= 1'b0 ;
                cfg_rden    <= 'b0  ;
                opt_start   <= 'b0  ;
                dly_en      <= 'b0  ;
                cfg_over    <= 'b0  ;
                cfg_rd_flag <= 1'b0 ;
                re_cfg_busy <= 1'b0 ;
                re_cfg_done <= 1'b0 ;
                cur_sta     <= IDLE_STA;
            end     
        endcase
    end      
end                     

endmodule                       
                            