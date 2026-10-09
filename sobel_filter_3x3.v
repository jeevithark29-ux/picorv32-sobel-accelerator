`timescale 1ns / 1ps

module sobel_filter_3x3 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        in_valid,
    input  wire [7:0]  threshold,
    input  wire [7:0]  p00, input wire [7:0] p01, input wire [7:0] p02,
    input  wire [7:0]  p10, input wire [7:0] p11, input wire [7:0] p12,
    input  wire [7:0]  p20, input wire [7:0] p21, input wire [7:0] p22,

    output reg         out_valid,
    output reg  [7:0]  out_edge
);

    reg signed [10:0] gx, gy;
    reg [10:0] abs_gx, abs_gy;
    reg [11:0] grad;
    reg        v1, v2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gx        <= 0;
            gy        <= 0;
            abs_gx    <= 0;
            abs_gy    <= 0;
            grad      <= 0;
            out_edge  <= 0;
            v1        <= 0;
            v2        <= 0;
            out_valid <= 0;
        end else begin
            v1 <= in_valid;
            v2 <= v1;
            out_valid <= v2;

            // Stage 1: Gradient kernels
            if (in_valid) begin
                // Gx = (p02 - p00) + 2*(p12 - p10) + (p22 - p20)
                gx <= ($signed({3'b0, p02}) - $signed({3'b0, p00})) +
                      (($signed({3'b0, p12}) - $signed({3'b0, p10})) <<< 1) +
                      ($signed({3'b0, p22}) - $signed({3'b0, p20}));

                // Gy = (p20 - p00) + 2*(p21 - p01) + (p22 - p02)
                gy <= ($signed({3'b0, p20}) - $signed({3'b0, p00})) +
                      (($signed({3'b0, p21}) - $signed({3'b0, p01})) <<< 1) +
                      ($signed({3'b0, p22}) - $signed({3'b0, p02}));
            end

            // Stage 2: Absolute values & Manhattan sum
            if (v1) begin
                abs_gx <= (gx < 0) ? -gx : gx;
                abs_gy <= (gy < 0) ? -gy : gy;
                grad   <= ((gx < 0) ? -gx : gx) + ((gy < 0) ? -gy : gy);
            end

            // Stage 3: Thresholding / Normalization
            if (v2) begin
                if (threshold == 8'd0) begin
                    // Continuous edge output clamped to 255
                    out_edge <= (grad > 255) ? 8'd255 : grad[7:0];
                end else begin
                    // Binary edge output (Black & White edge)
                    out_edge <= (grad >= {4'b0, threshold}) ? 8'd255 : 8'd0;
                end
            end
        end
    end
endmodule