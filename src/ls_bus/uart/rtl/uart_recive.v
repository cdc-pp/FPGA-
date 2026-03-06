module uart_recive#(
    parameter BAUD_RATE = 'd9600       ,//波特率不得低于9600bps
    parameter USER_CLK  = 'd100_000_000,//用户时钟频率不得高于300M
    parameter UART_TYPE = 'd0           //0无校验位，1奇校验，2偶校验
)
(
input            sysclk       ,
input            rst_n        ,

input            i_uart_rev   ,
output reg [7:0] o_rdata      ,
output           o_rdata_valid
    );

localparam IDLE_STATE  = 6'b000001,
           START_STATE = 6'b000010,//起始位
           DATA_STATE  = 6'b000100,//数据位
           STOP_STATE  = 6'b001000,//停止位
           CHECK_STATE = 6'b010000,//校验位
           ERR_STATE   = 6'b100000;
 
reg        i_uart_rev_d1    ;
reg        i_uart_rev_d2    ;
reg [14:0] cnt0            ;
reg [3:0]  cnt1            ;
reg        ptr             ;
reg        odds_check      ;
reg [4:0]  state           ;
reg [4:0]  nextstate       ;
       
//去除亚稳态
always@(posedge sysclk)
begin
    i_uart_rev_d1 <= i_uart_rev  ;
    i_uart_rev_d2 <= i_uart_rev_d1;
end

//波特率
always@(posedge sysclk or negedge rst_n)
begin
    if(!rst_n | state == IDLE_STATE)
        cnt0 <= USER_CLK/(2*BAUD_RATE) + 4;
    else if(cnt0 == USER_CLK/BAUD_RATE)
        cnt0 <= 'd0;
    else
        cnt0 <= cnt0 + 1'b1;
end

//对采集到的DATA位数进行计数
always@(posedge sysclk or negedge rst_n)
begin
    if(!rst_n | state == IDLE_STATE)
        cnt1 <= 4'd0;
    else if((state == DATA_STATE | CHECK_STATE) & ptr)
        cnt1 <= cnt1 + 1'b1;
    else
        cnt1 <= cnt1;
end

//状态跳变指示信号ptr，以保证采集到稳定的信号
always@(posedge sysclk)
begin
    if(cnt0 == USER_CLK/BAUD_RATE)
        ptr <= 1'b1;
    else
        ptr <= 1'b0;
end

//状态机控制
always@(posedge sysclk or negedge rst_n)
begin
    if(!rst_n)
        state <= IDLE_STATE;
    else
        state <= nextstate;
end
always@(*)
begin
    if(!rst_n)
        nextstate<=IDLE_STATE;
    else begin
        case(state)
            IDLE_STATE:begin
                if(!i_uart_rev_d2)
                    nextstate <= START_STATE;
                else
                    nextstate <= IDLE_STATE;
                end
            START_STATE:begin
                if(ptr & i_uart_rev_d2)
                    nextstate <= IDLE_STATE;
                else if(ptr & !i_uart_rev_d2)
                    nextstate <= DATA_STATE;
                else
                    nextstate <= START_STATE;
            end
            DATA_STATE:begin
                if(cnt1 == 3'd7 & ptr & UART_TYPE == 1'b0)
                    nextstate <= STOP_STATE;
                else if(cnt1 == 3'd7 & ptr & UART_TYPE !== 1'b0)
                    nextstate <= CHECK_STATE;
                else
                    nextstate <= DATA_STATE;
            end
            CHECK_STATE:begin
                if(cnt1 == 4'd8 && ptr && (i_uart_rev_d2 == odds_check))
                    nextstate <= STOP_STATE;
                else if(cnt1 == 4'd8 && ptr && (i_uart_rev_d2 !== odds_check))
                    nextstate <= ERR_STATE;
                else
                    nextstate <= CHECK_STATE;
            end
            STOP_STATE:begin
                if(ptr & i_uart_rev_d2)
                    nextstate <= IDLE_STATE;
                else if(ptr & !i_uart_rev_d2)
                    nextstate <= ERR_STATE;
                else
                    nextstate <= STOP_STATE;
            end

            ERR_STATE :begin
                if(ptr)
                    nextstate <= IDLE_STATE;
                else
                    nextstate <= ERR_STATE;
            end
            default:nextstate <= IDLE_STATE;
        endcase
    end
end


//移位寄存读取的数据
always@(posedge sysclk or negedge rst_n)
begin
    if(!rst_n)
        o_rdata <= 3'd0;
    else if(state == DATA_STATE & ptr)
        o_rdata <= {i_uart_rev_d2,o_rdata[7:1]};
    else
        o_rdata <= o_rdata;
end
//校验位

always @(posedge sysclk or negedge rst_n) begin
    if (!rst_n) begin
        odds_check <= 1'b0;
    end
    else if(state == CHECK_STATE)begin
        odds_check <= {UART_TYPE[0]^o_rdata[0]^o_rdata[1]^o_rdata[2]^o_rdata[3]^o_rdata[4]^o_rdata[5]^o_rdata[6]^o_rdata[7]};
    end
end

//数据有效指示o_rdata_valid
assign o_rdata_valid=(state == STOP_STATE & nextstate == IDLE_STATE)?1'b1:1'b0;

endmodule
