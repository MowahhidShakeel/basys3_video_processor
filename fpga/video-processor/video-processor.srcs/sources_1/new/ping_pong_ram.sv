module ping_pong_ram (
    // Write Port (100 MHz)
    input wire clk_wr,               
    input wire rst,
    input wire frame_start_pulse,
    input wire wr_pixel_valid,
    input wire [7:0] wr_pixel_data,
    input wire frame_done_pulse,

    // Read Port (25 MHz)
    input wire clk_rd,               // <--- Added this port
    input wire [16:0] rd_addr,
    output reg [7:0] rd_pixel
);

    localparam FRAME_SIZE = 320 * 240; // 76800

    // Infer Block RAM
    (* ram_style = "block" *)
    reg [7:0] ram [0:2*FRAME_SIZE-1];

    // Synchronization: We need to pass the "buffer select" signal 
    // from the Write Domain (100MHz) to the Read Domain (25MHz).
    reg buf_sel_wr = 0; 
    reg buf_sel_rd_sync1 = 0;
    reg buf_sel_rd_sync2 = 0;

    reg [16:0] wr_ptr = 0;
    
    // Address calc
    wire [17:0] wr_addr_final = (buf_sel_wr ? 0 : FRAME_SIZE) + wr_ptr;
    
    // For read, we use the synced selector
    wire [17:0] rd_addr_final = (buf_sel_rd_sync2 ? FRAME_SIZE : 0) + rd_addr;

    // --- WRITE LOGIC (100 MHz) ---
    always @(posedge clk_wr) begin
        if (rst) begin
            buf_sel_wr <= 0;
            wr_ptr <= 0;
        end else begin
            if (frame_start_pulse) wr_ptr <= 0;
            
            if (wr_pixel_valid) begin
                ram[wr_addr_final] <= wr_pixel_data;
                if (wr_ptr < FRAME_SIZE - 1) wr_ptr <= wr_ptr + 1;
            end

            if (frame_done_pulse) begin
                 // Toggle buffer when frame is done
                buf_sel_wr <= ~buf_sel_wr;
                wr_ptr <= 0;
            end
        end
    end

    // --- CLOCK DOMAIN CROSSING ---
    // Safely move the swap signal from 100MHz to 25MHz
    always @(posedge clk_rd) begin
        buf_sel_rd_sync1 <= buf_sel_wr;
        buf_sel_rd_sync2 <= buf_sel_rd_sync1; 
    end

    // --- READ LOGIC (25 MHz) ---
    // Now this runs on the correct VGA clock
    always @(posedge clk_rd) begin
        rd_pixel <= ram[rd_addr_final];
    end

endmodule