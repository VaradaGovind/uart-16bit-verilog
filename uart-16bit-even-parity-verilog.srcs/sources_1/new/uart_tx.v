module uart_tx (
    input clk,
    input rst,
    input tx_start,
    input [15:0]tx_data,
    output reg tx,
    output reg tx_busy
);

    parameter CLK_FREQ = 50_000_000;
    parameter BAUD_RATE = 115200;

    localparam BAUD_DIV = CLK_FREQ / BAUD_RATE;

    integer baud_cnt;
    integer bit_cnt;

    reg [18:0]frame;
    reg parity;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx <= 1'b1;
            tx_busy <= 0;
            baud_cnt <= 0;
            bit_cnt <= 0;
            frame <= 0;
        end 
        else begin
            if (tx_start && !tx_busy) begin
                parity = ^tx_data;
                frame <= {1'b1, parity, tx_data, 1'b0};
                tx_busy <= 1;
                baud_cnt <= 0;
                bit_cnt <= 0;
            end 
            else if (tx_busy) begin
                if (baud_cnt == BAUD_DIV - 1) begin
                    baud_cnt <= 0;
                    tx <= frame[0];
                    frame <= frame >> 1;
                    bit_cnt <= bit_cnt + 1;
                    
                    if (bit_cnt == 19) begin
                        tx_busy <= 0;
                        tx <= 1'b1;
                    end
                    
                end 
                else begin
                    baud_cnt <= baud_cnt + 1;
                end
            end
        end
    end
endmodule