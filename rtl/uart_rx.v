module uart_rx #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD = 115_200
)(
    input wire clk,
    input wire rst_n,
    input wire rx,
    output reg [7:0] rx_data,
    output wire rx_valid,
    output wire rx_frame_err
);

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD;
    localparam IDLE = 3'b000, START = 3'b001, FRAME = 3'b010, STOP = 3'b011, ERROR = 3'b100, WAIT = 3'b101;
    reg [2:0] state;

    reg [$clog2(CLKS_PER_BIT)-1:0] cyc_cnt;
    reg [3:0] bit_cnt;
    reg [7:0] frame;
    reg rx_meta, rx_sync;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_meta <= 1;
            rx_sync <= 1;
        end
        else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            cyc_cnt <= 0;
            bit_cnt <= 0;
            frame <= 0;
            rx_data <= 0;
        end
        else if (state == IDLE) begin
            cyc_cnt <= 1;
            bit_cnt <= 0;
            state <= rx_sync ? IDLE : START;
        end 
        else if (state == START) begin
            if (cyc_cnt == CLKS_PER_BIT/2) begin
                state <= rx_sync ? IDLE : FRAME;
                cyc_cnt <= 0;
            end
            else
                cyc_cnt <= cyc_cnt + 1;
        end 
        else if (state == FRAME)
            if (cyc_cnt == CLKS_PER_BIT -1) begin
                bit_cnt <= bit_cnt + 1;
                cyc_cnt <= 0;
                if (bit_cnt < 8)
                    frame <= {rx_sync, frame[7:1]};
                else if (bit_cnt == 8) begin
                    if (rx_sync) begin
                        rx_data <= frame;
                        state <= STOP;
                    end
                    else
                        state <= ERROR;
                end
            end
            else
                cyc_cnt <= cyc_cnt + 1;
        else if (state == STOP) begin
            state <= IDLE;
        end
        else if (state == ERROR)
            state <= WAIT;
        else if (state == WAIT)
            state <= rx_sync ? IDLE : WAIT;


    end

    assign rx_valid = (state == STOP);
    assign rx_frame_err = (state == ERROR);

endmodule