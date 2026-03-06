module uart_send#(
    parameter BAUD_RATE = 'd9600,//波特率不得低于9600bps
    parameter USER_CLK  = 'd100_000_000,//用户时钟频率不得高于300M
    parameter UART_TYPE = 'd0           //0无校验位，1奇校验，2偶校验
)
(
input            sysclk        ,
input            rst_n         ,
                            
input      [7:0] i_rev         ,
input            i_rev_val     ,
output reg       o_uart_send
    );
    
wire       i_rev_val_pose;
reg        i_rev_val_d1  ;
reg        busy          ;
reg [7:0]  uart_send     ;
reg [14:0] cnt0          ;
reg [3:0]  cnt1          ;
reg        odds_check    ;
//采集i_rev_val_pose的上升沿
always@(posedge sysclk)
begin
    i_rev_val_d1<=i_rev_val;
end
assign i_rev_val_pose = i_rev_val & (!i_rev_val_d1);

//收到有效数据时进行存储
always@(posedge sysclk)
begin
    if(i_rev_val_pose & !busy)
        uart_send <= i_rev;
    else
        uart_send <= uart_send;
end

//波特率
always@(posedge sysclk or negedge rst_n)
begin
    if(!rst_n | (i_rev_val_pose & !busy))
        cnt0 <= 14'd0;
    else if(cnt0 == USER_CLK/BAUD_RATE)
        cnt0 <= 14'd0;
    else
        cnt0 <= cnt0 + 1'b1;
end

always@(posedge sysclk or negedge rst_n)
begin
    if(!rst_n | cnt1==4'd12)
        cnt1 <= 4'd0;
    else if(i_rev_val_pose & cnt1== 4'd0 & !busy)
        cnt1 <= 4'd1;
    else if(cnt0 == USER_CLK/BAUD_RATE & cnt1>4'd0)
        cnt1 <= cnt1+1'b1;
    else
        cnt1 <= cnt1;
end

//串并转换控制
generate
/*无校验位*/
    if(UART_TYPE == 1'b0)
    begin
        always@(posedge sysclk or negedge rst_n)
        begin
            if(!rst_n)
                o_uart_send <= 1'b1;
            else begin
                case(cnt1)
                    4'd0:begin o_uart_send <= 1'b1;          end
                    4'd1:begin o_uart_send <= 1'b0;          end
                    4'd2:begin o_uart_send <= uart_send[0];  end
                    4'd3:begin o_uart_send <= uart_send[1];  end
                    4'd4:begin o_uart_send <= uart_send[2];  end
                    4'd5:begin o_uart_send <= uart_send[3];  end
                    4'd6:begin o_uart_send <= uart_send[4];  end
                    4'd7:begin o_uart_send <= uart_send[5];  end
                    4'd8:begin o_uart_send <= uart_send[6];  end
                    4'd9:begin o_uart_send <= uart_send[7];  end
                    4'd10:begin o_uart_send<= 1'b1;          end
                    4'd11:begin o_uart_send<= 1'b1;          end
                    4'd12:begin o_uart_send<= 1'b1;          end
                    default:begin o_uart_send <= 1'b1;       end
                endcase
            end
        end
    end
/*有校验位*/
    else 
    begin
        always@(posedge sysclk or negedge rst_n)
        begin
            if(!rst_n)
                o_uart_send <= 1'b1;
            else begin
                case(cnt1)
                    4'd0:begin o_uart_send <= 1'b1;          end
                    4'd1:begin o_uart_send <= 1'b0;          end
                    4'd2:begin o_uart_send <= uart_send[0];  end
                    4'd3:begin o_uart_send <= uart_send[1];  end
                    4'd4:begin o_uart_send <= uart_send[2];  end
                    4'd5:begin o_uart_send <= uart_send[3];  end
                    4'd6:begin o_uart_send <= uart_send[4];  end
                    4'd7:begin o_uart_send <= uart_send[5];  end
                    4'd8:begin o_uart_send <= uart_send[6];  end
                    4'd9:begin o_uart_send <= uart_send[7];  end
                    4'd10:begin o_uart_send<= odds_check;    end
                    4'd11:begin o_uart_send<= 1'b1;          end
                    4'd12:begin o_uart_send<= 1'b1;          end
                    default:begin o_uart_send <= 1'b1;       end
                endcase
            end
        end
    end
endgenerate

always @(posedge sysclk or negedge rst_n) begin
    if (!rst_n) begin
        odds_check <= 1'b0;
    end
    else begin
        odds_check <= {UART_TYPE[0]^uart_send[0]^uart_send[1]^uart_send[2]^uart_send[3]^uart_send[4]^uart_send[5]^uart_send[6]^uart_send[7]};
    end
end

//传输状态用busy信号表示
always@(posedge sysclk or negedge rst_n)
begin
    if(!rst_n | cnt1==4'd11)
        busy <= 1'b0;
    else if(i_rev_val_pose)
        busy <= 1'b1;
    else
        busy <= busy;
end
endmodule
