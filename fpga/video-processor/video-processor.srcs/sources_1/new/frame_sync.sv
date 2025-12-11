module frame_sync (
    input wire clk,
    input wire rst,
    input wire [7:0] uart_data,
    input wire uart_valid,

    output reg [7:0] pixel_data,
    output reg pixel_valid,
    output reg frame_start_pulse,
    output reg [15:0] pixel_x,
    output reg [15:0] pixel_y,
    output reg frame_done_pulse
);

    localparam WIDTH  = 320;
    localparam HEIGHT = 240;
    localparam FRAME_PIXELS = WIDTH * HEIGHT;
    localparam [31:0] MAGIC_SEQ = 32'hAA55DEAD;

    reg [31:0] magic_buffer = 0; 
    
    reg [17:0] pixel_counter = 0; 

    // State definition
    localparam s_IDLE = 1'b0;
    localparam s_RECEIVING = 1'b1;
    reg state = s_IDLE;

    always @(posedge clk) begin
        if (rst) begin
            state <= s_IDLE;
            pixel_valid <= 0;
            frame_start_pulse <= 0;
            frame_done_pulse <= 0;
            pixel_counter <= 0;
            pixel_x <= 0;
            pixel_y <= 0;
            magic_buffer <= 0;
        end else begin
            // Pulse defaults
            pixel_valid <= 0;
            frame_start_pulse <= 0;
            frame_done_pulse <= 0;

            if (uart_valid) begin
                // Shift data into the buffer continuously
                magic_buffer <= {magic_buffer[23:0], uart_data};

                case (state)
                    s_IDLE: begin
                        // FIX 2: Check the CONCATENATION, not the buffer alone.
                        // We check if "current buffer + incoming byte" equals MAGIC.
                        if ({magic_buffer[23:0], uart_data} == MAGIC_SEQ) begin
                            state <= s_RECEIVING;
                            pixel_counter <= 0;
                            pixel_x <= 0;
                            pixel_y <= 0;
                            frame_start_pulse <= 1'b1; // Signal start of frame
                        end
                    end

                    s_RECEIVING: begin
                        // Pass data through
                        pixel_data <= uart_data;
                        pixel_valid <= 1'b1;

                        // Increment X/Y counters
                        if (pixel_counter == FRAME_PIXELS - 1) begin
                            frame_done_pulse <= 1'b1;
                            state <= s_IDLE; // Frame done, look for next magic
                            pixel_counter <= 0;
                        end else begin
                            pixel_counter <= pixel_counter + 1;
                            
                            // X/Y Logic
                            if (pixel_x == WIDTH - 1) begin
                                pixel_x <= 0;
                                pixel_y <= pixel_y + 1;
                            end else begin
                                pixel_x <= pixel_x + 1;
                            end
                        end
                    end
                endcase
            end
        end
    end
endmodule