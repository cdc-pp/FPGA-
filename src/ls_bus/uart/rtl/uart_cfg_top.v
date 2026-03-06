module uart_cfg_top#(
    parameter BAUD_RATE = 9600       ,//波特率不得低于9600bps
    parameter USER_CLK  = 100_000_000,//用户时钟频率不得高于300M
    parameter UART_TYPE = 'd1         //0无校验位，1奇校验，2偶校验
)
(
input        clk_100m  ,
input        rst_n     ,

input [7:0]  i_wr_uart ,//需要发送的数据
input        i_wr_valid,//发送指令有效指示

output[7:0]  o_rd_uart ,//读取的数据
output       o_rd_valid,//读取数据有效指示

input        uart_rx   ,
output       uart_tx
); 


uart_send#(
    .BAUD_RATE      (BAUD_RATE  ),
    .USER_CLK       (USER_CLK   ),
    .UART_TYPE      (UART_TYPE  )
)
u_uart_send
(
    .sysclk         (clk_100m   ),
    .rst_n          (rst_n      ),

    .i_rev          (i_wr_uart  ),
    .i_rev_val      (i_wr_valid ),
    .o_uart_send    (uart_tx    )
    );

uart_recive#
(
    .BAUD_RATE      (BAUD_RATE  ),
    .USER_CLK       (USER_CLK   ),
    .UART_TYPE      (UART_TYPE  )
)
u_uart_recive
(
    .sysclk         (clk_100m   ),
    .rst_n          (rst_n      ),

    .i_uart_rev     (uart_rx    ),
    .o_rdata        (o_rd_uart  ),
    .o_rdata_valid  (o_rd_valid )
    );

endmodule
