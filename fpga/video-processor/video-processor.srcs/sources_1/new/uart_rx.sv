module uart_rx #(
    parameter CLKS_PER_BIT = 868 // 100MHz / 115200 baud
) (
    input wire clk,
    input wire rst,
    input wire rx,
    output reg [7:0] dout,
    output reg valid
);

    // State machine states
    localparam s_IDLE      = 3'd0;
    localparam s_START_BIT = 3'd1;
    localparam s_DATA_BITS = 3'd2;
    localparam s_STOP_BIT  = 3'd3;
    localparam s_CLEANUP   = 3'd4;

    reg [2:0] state = s_IDLE;
    reg [9:0] clk_count = 0;
    reg [2:0] bit_idx = 0;
    reg [7:0] rx_data = 0;

    // --- 1. DOUBLE-FLOP SYNCHRONIZER ---
    reg rx_sync_stage1 = 1'b1;
    reg rx_sync = 1'b1;

    always @(posedge clk) begin
        rx_sync_stage1 <= rx;
        rx_sync        <= rx_sync_stage1; // Use 'rx_sync' in your logic, NEVER 'rx'
    end
    // -----------------------------------

    always @(posedge clk) begin
        if (rst) begin
            state <= s_IDLE;
            valid <= 1'b0;
            clk_count <= 0;
            bit_idx <= 0;
        end else begin
            valid <= 1'b0; // Default low

            case (state)
                s_IDLE: begin
                    clk_count <= 0;
                    bit_idx   <= 0;
                    if (rx_sync == 1'b0) begin // Start bit detected
                        state <= s_START_BIT;
                    end
                end

                s_START_BIT: begin
                    // Wait for middle of start bit
                    if (clk_count == (CLKS_PER_BIT - 1) / 2) begin
                        if (rx_sync == 1'b0) begin
                            clk_count <= 0; // Reset counter for data bits
                            state     <= s_DATA_BITS;
                        end else begin
                            state <= s_IDLE; // False start glitch
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end

                s_DATA_BITS: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count          <= 0;
                        rx_data[bit_idx]   <= rx_sync; // Sample synchronized data
                        
                        if (bit_idx < 7) begin
                            bit_idx <= bit_idx + 1;
                        end else begin
                            bit_idx <= 0;
                            state   <= s_STOP_BIT;
                        end
                    end
                end

                s_STOP_BIT: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        // Check for Stop Bit (should be High)
                        if (rx_sync == 1'b1) begin
                            valid <= 1'b1;       // Valid byte received
                            dout  <= rx_data;    // Update output
                        end
                        // Even if stop bit is missing, go to cleanup to prevent lockup
                        state <= s_CLEANUP; 
                    end
                end

                s_CLEANUP: begin
                    state <= s_IDLE;
                end

                default: state <= s_IDLE;
            endcase
        end
    end
endmodule