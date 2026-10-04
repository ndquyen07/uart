module uart_tx #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD = 115_200
)(
    input wire clk,
    input wire rst_n,
    input wire [7:0] tx_data,
    input wire tx_valid,
    output wire tx_ready,
    output wire tx
);

    localparam IDLE = 1'b0, SEND = 1'b1;
    localparam CLKS_PER_BIT = CLK_FREQ/BAUD;
    
    reg state, next_state;
    wire done;
    reg [$clog2(CLKS_PER_BIT)-1:0] cyc_cnt;
    reg [3:0] bit_cnt;
    reg [9:0] frame;

    always @(*) begin
        case (state)
            IDLE : next_state = tx_valid ? SEND : IDLE;
            SEND : next_state = done ? IDLE : SEND;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt <= 0;
            cyc_cnt <= 0;
            frame <= 10'b1111111111;
        end
        else if (state == IDLE) begin
            bit_cnt <= 0;
            cyc_cnt <= 0;
            if (tx_valid)
                frame <= {1'b1, tx_data, 1'b0};
        end
        else if (state == SEND) begin
            if (cyc_cnt == CLKS_PER_BIT - 1) begin
                cyc_cnt <= 0;
                bit_cnt <= bit_cnt + 1;
                frame <= {1'b1, frame[9:1]};
            end
            else
                cyc_cnt <= cyc_cnt + 1;
        end
    end


    assign done = (bit_cnt == 9 && cyc_cnt == CLKS_PER_BIT-1);
    assign tx_ready = (state == IDLE);
    assign tx = frame[0];

endmodule