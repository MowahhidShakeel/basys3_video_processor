module vga_controller_640x480 (
    input wire clk_pixel,   // 25.175 MHz
    input wire rst,

    output wire hsync,
    output wire vsync,
    output wire [3:0] red,
    output wire [3:0] green,
    output wire [3:0] blue,
    output wire video_active,
    output wire [9:0] px_x,
    output wire [9:0] px_y,
    
    // Memory Interface
    output wire [16:0] frame_rd_addr,
    input wire [7:0] frame_rd_data
);

    // VESA 640x480 @ 60Hz
    localparam H_ACTIVE = 640;
    localparam H_FRONT  = 16;
    localparam H_PULSE  = 96;
    localparam H_BACK   = 48;
    localparam H_TOTAL  = 800;

    localparam V_ACTIVE = 480;
    localparam V_FRONT  = 10;
    localparam V_PULSE  = 2;
    localparam V_BACK   = 33;
    localparam V_TOTAL  = 525;

    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;

    // --- TIMING GENERATOR ---
    always @(posedge clk_pixel or posedge rst) begin
        if (rst) begin
            h_count <= 0;
            v_count <= 0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 0;
                if (v_count == V_TOTAL - 1)
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
            end else begin
                h_count <= h_count + 1;
            end
        end
    end

    assign hsync = ~(h_count >= H_ACTIVE + H_FRONT && h_count < H_ACTIVE + H_FRONT + H_PULSE);
    assign vsync = ~(v_count >= V_ACTIVE + V_FRONT && v_count < V_ACTIVE + V_FRONT + V_PULSE);
    assign video_active = (h_count < H_ACTIVE) && (v_count < V_ACTIVE);

    assign px_x = h_count;
    assign px_y = v_count;

    // --- ADDRESS GENERATION (2x SCALING) ---
    // 640x480 screen -> 320x240 image
    // Simply divide screen coordinates by 2 (drop LSB)
    wire [8:0] img_x = h_count[9:1]; // 0-319
    wire [8:0] img_y = v_count[9:1]; // 0-239
    
    // Address = y * 320 + x
    assign frame_rd_addr = (img_y * 320) + img_x;

    // --- COLOR OUTPUT ---
    // 8-bit Grayscale (RRR GGG BB) -> 12-bit VGA (RRRR GGGG BBBB)
    // We take the top 4 bits of the grayscale for all channels
    wire [3:0] gray = frame_rd_data[7:4];
    
    assign red   = video_active ? gray : 4'b0;
    assign green = video_active ? gray : 4'b0;
    assign blue  = video_active ? gray : 4'b0;

endmodule