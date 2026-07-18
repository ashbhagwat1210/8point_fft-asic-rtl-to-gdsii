
// complex number multiplication
module complex_mult (
    input  signed [15:0] a_re, a_im,
    input  signed [15:0] w_re, w_im,
    output signed [15:0] p_re, p_im
);
    wire signed [31:0] mult_rr = a_re * w_re;
    wire signed [31:0] mult_ii = a_im * w_im;
    wire signed [31:0] mult_ri = a_re * w_im;
    wire signed [31:0] mult_ir = a_im * w_re;

    assign p_re = (mult_rr - mult_ii) >>> 15;
    assign p_im = (mult_ri + mult_ir) >>> 15;
endmodule
 

// First butterfly where W = 1
module butterfly_w0 (
    input  signed [15:0] a_re, a_im,
    input  signed [15:0] b_re, b_im,
    output signed [15:0] out_top_re, out_top_im,
    output signed [15:0] out_bot_re, out_bot_im
);
  
    wire signed [16:0] sum_re = {a_re[15],a_re} + {b_re[15],b_re};
    wire signed [16:0] sum_im = {a_im[15],a_im} + {b_im[15],b_im};
    wire signed [16:0] dif_re = {a_re[15],a_re} - {b_re[15],b_re};
    wire signed [16:0] dif_im = {a_im[15],a_im} - {b_im[15],b_im};

    assign out_top_re = sum_re[16:1];
    assign out_top_im = sum_im[16:1];
    assign out_bot_re = dif_re[16:1];
    assign out_bot_im = dif_im[16:1];
endmodule


// Second butterfly where W = -j
// (-j)*(re + j*im) = im - j*re
module butterfly_wneg_j (
    input  signed [15:0] a_re, a_im,
    input  signed [15:0] b_re, b_im,
    output signed [15:0] out_top_re, out_top_im,
    output signed [15:0] out_bot_re, out_bot_im
);
    wire signed [15:0] b_rot_re = b_im;
    wire signed [15:0] b_rot_im = -b_re;

    wire signed [16:0] sum_re = {a_re[15],a_re} + {b_rot_re[15],b_rot_re};
    wire signed [16:0] sum_im = {a_im[15],a_im} + {b_rot_im[15],b_rot_im};
    wire signed [16:0] dif_re = {a_re[15],a_re} - {b_rot_re[15],b_rot_re};
    wire signed [16:0] dif_im = {a_im[15],a_im} - {b_rot_im[15],b_rot_im};

    assign out_top_re = sum_re[16:1];
    assign out_top_im = sum_im[16:1];
    assign out_bot_re = dif_re[16:1];
    assign out_bot_im = dif_im[16:1];
endmodule


// Butterfly for W1,W3
module butterfly_general (
    input  signed [15:0] a_re, a_im,
    input  signed [15:0] b_re, b_im,
    input  signed [15:0] w_re, w_im,
    output signed [15:0] out_top_re, out_top_im,
    output signed [15:0] out_bot_re, out_bot_im
);
    wire signed [15:0] b_rot_re, b_rot_im;

    complex_mult u_cmult (
        .a_re(b_re), .a_im(b_im),
        .w_re(w_re), .w_im(w_im),
        .p_re(b_rot_re), .p_im(b_rot_im)
    );

    wire signed [16:0] sum_re = {a_re[15],a_re} + {b_rot_re[15],b_rot_re};
    wire signed [16:0] sum_im = {a_im[15],a_im} + {b_rot_im[15],b_rot_im};
    wire signed [16:0] dif_re = {a_re[15],a_re} - {b_rot_re[15],b_rot_re};
    wire signed [16:0] dif_im = {a_im[15],a_im} - {b_rot_im[15],b_rot_im};

    assign out_top_re = sum_re[16:1];
    assign out_top_im = sum_im[16:1];
    assign out_bot_re = dif_re[16:1];
    assign out_bot_im = dif_im[16:1];
endmodule


// Bit reversal where 0,1,2,3,4,5,6,7 becomes 0,4,2,6,1,5,3,7
module bit_reverse (
    input  [127:0] in_flat,
    output [255:0] data_out
);
    wire [15:0] s0 = in_flat[127:112];
    wire [15:0] s1 = in_flat[111:96];
    wire [15:0] s2 = in_flat[95:80];
    wire [15:0] s3 = in_flat[79:64];
    wire [15:0] s4 = in_flat[63:48];
    wire [15:0] s5 = in_flat[47:32];
    wire [15:0] s6 = in_flat[31:16];
    wire [15:0] s7 = in_flat[15:0];

    assign data_out[255:224] = {s0, 16'sd0};
    assign data_out[223:192] = {s4, 16'sd0};
    assign data_out[191:160] = {s2, 16'sd0};
    assign data_out[159:128] = {s6, 16'sd0};
    assign data_out[127:96]  = {s1, 16'sd0};
    assign data_out[95:64]   = {s5, 16'sd0};
    assign data_out[63:32]   = {s3, 16'sd0};
    assign data_out[31:0]    = {s7, 16'sd0};
endmodule


// First stage of 8 point- DITFFT - 4 butterflies 
module fft_stage1 (
    input  [255:0] data_in,
    output [255:0] data_out
);
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : g_bfly
            wire signed [15:0] a_re = data_in[255-64*i -: 16];
            wire signed [15:0] a_im = data_in[239-64*i -: 16];
            wire signed [15:0] b_re = data_in[223-64*i -: 16];
            wire signed [15:0] b_im = data_in[207-64*i -: 16];
            wire signed [15:0] top_re, top_im, bot_re, bot_im;

            butterfly_w0 u_bf (
                a_re, a_im, b_re, b_im,
                top_re, top_im, bot_re, bot_im
            );

            assign data_out[255-64*i -: 16] = top_re;
            assign data_out[239-64*i -: 16] = top_im;
            assign data_out[223-64*i -: 16] = bot_re;
            assign data_out[207-64*i -: 16] = bot_im;
        end
    endgenerate
endmodule


// Second stage of 8 point- DITFFT - 2 butterflies 
module fft_stage2 (
    input  [255:0] data_in,
    output [255:0] data_out
);
    genvar g;
    generate
        for (g = 0; g < 2; g = g + 1) begin : g_group
            localparam BASE = 255 - 128*g;

            wire signed [15:0] s0_re = data_in[BASE      -: 16];
            wire signed [15:0] s0_im = data_in[BASE-16   -: 16];
            wire signed [15:0] s1_re = data_in[BASE-32   -: 16];
            wire signed [15:0] s1_im = data_in[BASE-48   -: 16];
            wire signed [15:0] s2_re = data_in[BASE-64   -: 16];
            wire signed [15:0] s2_im = data_in[BASE-80   -: 16];
            wire signed [15:0] s3_re = data_in[BASE-96   -: 16];
            wire signed [15:0] s3_im = data_in[BASE-112  -: 16];

            wire signed [15:0] o0_re, o0_im, o2_re, o2_im;
            wire signed [15:0] o1_re, o1_im, o3_re, o3_im;

            butterfly_w0 u_bf_evens (
                s0_re, s0_im, s2_re, s2_im,
                o0_re, o0_im, o2_re, o2_im
            );
            butterfly_wneg_j u_bf_odds (
                s1_re, s1_im, s3_re, s3_im,
                o1_re, o1_im, o3_re, o3_im
            );

            assign data_out[BASE      -: 16] = o0_re;
            assign data_out[BASE-16   -: 16] = o0_im;
            assign data_out[BASE-32   -: 16] = o1_re;
            assign data_out[BASE-48   -: 16] = o1_im;
            assign data_out[BASE-64   -: 16] = o2_re;
            assign data_out[BASE-80   -: 16] = o2_im;
            assign data_out[BASE-96   -: 16] = o3_re;
            assign data_out[BASE-112  -: 16] = o3_im;
        end
    endgenerate
endmodule


// Third stage of 8 point- DITFFT - 1 butterfly 
module fft_stage3 (
    input  [255:0] data_in,
    output [255:0] data_out
);
    localparam signed [15:0] W1_RE =  16'sd23170; // 1/sqrt2 in Q1.15
    localparam signed [15:0] W1_IM = -16'sd23170;
    localparam signed [15:0] W3_RE = -16'sd23170;
    localparam signed [15:0] W3_IM = -16'sd23170;

    wire signed [15:0] a0_re=data_in[255:240], a0_im=data_in[239:224];
    wire signed [15:0] a1_re=data_in[223:208], a1_im=data_in[207:192];
    wire signed [15:0] a2_re=data_in[191:176], a2_im=data_in[175:160];
    wire signed [15:0] a3_re=data_in[159:144], a3_im=data_in[143:128];
    wire signed [15:0] b0_re=data_in[127:112], b0_im=data_in[111:96];
    wire signed [15:0] b1_re=data_in[95:80],   b1_im=data_in[79:64];
    wire signed [15:0] b2_re=data_in[63:48],   b2_im=data_in[47:32];
    wire signed [15:0] b3_re=data_in[31:16],   b3_im=data_in[15:0];

    wire signed [15:0] o0_re,o0_im,o4_re,o4_im;
    wire signed [15:0] o1_re,o1_im,o5_re,o5_im;
    wire signed [15:0] o2_re,o2_im,o6_re,o6_im;
    wire signed [15:0] o3_re,o3_im,o7_re,o7_im;

    butterfly_w0 u_bf_04 (
        a0_re,a0_im, b0_re,b0_im,
        o0_re,o0_im, o4_re,o4_im
    );
    butterfly_general u_bf_15 (
        a1_re,a1_im, b1_re,b1_im, W1_RE,W1_IM,
        o1_re,o1_im, o5_re,o5_im
    );
    butterfly_wneg_j u_bf_26 (
        a2_re,a2_im, b2_re,b2_im,
        o2_re,o2_im, o6_re,o6_im
    );
    butterfly_general u_bf_37 (
        a3_re,a3_im, b3_re,b3_im, W3_RE,W3_IM,
        o3_re,o3_im, o7_re,o7_im
    );

    assign data_out[255:240]=o0_re; assign data_out[239:224]=o0_im;
    assign data_out[223:208]=o1_re; assign data_out[207:192]=o1_im;
    assign data_out[191:176]=o2_re; assign data_out[175:160]=o2_im;
    assign data_out[159:144]=o3_re; assign data_out[143:128]=o3_im;
    assign data_out[127:112]=o4_re; assign data_out[111:96] =o4_im;
    assign data_out[95:80]  =o5_re; assign data_out[79:64]  =o5_im;
    assign data_out[63:48]  =o6_re; assign data_out[47:32]  =o6_im;
    assign data_out[31:16]  =o7_re; assign data_out[15:0]   =o7_im;
endmodule

// TOP MODULE - INTEGRATE ALL THESE
module fft_8point_top (
    input               clk,
    input               rst_n,
    input               in_valid,
    input      [127:0]  in_flat,     // 8 x 16b real Q1.15
    output reg          out_valid,
    output reg [255:0]  out_flat     // 8 x (16b re + 16b im) Q1.15
);
    wire [255:0] rev_out;
    bit_reverse u_rev (.in_flat(in_flat), .data_out(rev_out));

    reg [255:0] stage1_in_r;
    reg         v1;
    wire [255:0] stage1_out;
    fft_stage1 u_s1 (.data_in(stage1_in_r), .data_out(stage1_out));

    reg [255:0] stage2_in_r;
    reg         v2;
    wire [255:0] stage2_out;
    fft_stage2 u_s2 (.data_in(stage2_in_r), .data_out(stage2_out));

    reg [255:0] stage3_in_r;
    reg         v3;
    wire [255:0] stage3_out;
    fft_stage3 u_s3 (.data_in(stage3_in_r), .data_out(stage3_out));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_in_r <= 256'sd0; v1 <= 1'b0;
            stage2_in_r <= 256'sd0; v2 <= 1'b0;
            stage3_in_r <= 256'sd0; v3 <= 1'b0;
            out_flat    <= 256'sd0; out_valid <= 1'b0;
        end else begin
            stage1_in_r <= rev_out;      v1 <= in_valid;
            stage2_in_r <= stage1_out;   v2 <= v1;
            stage3_in_r <= stage2_out;   v3 <= v2;
            out_flat    <= stage3_out;   out_valid <= v3;
        end
    end
endmodule
