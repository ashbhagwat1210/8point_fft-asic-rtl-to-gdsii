// SELF CHECKING TESTBENCH (formatted neatly using AI) 
`timescale 1ns/1ps

module tb_fft_8point_top;

    reg          clk;
    reg          rst_n;
    reg          in_valid;
    reg  [127:0] in_flat;
    wire         out_valid;
    wire [255:0] out_flat;

    integer errors = 0;

    fft_8point_top dut (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_flat(in_flat),
        .out_valid(out_valid), .out_flat(out_flat)
    );

    always #5 clk = ~clk;

    // ---- Q1.15 helpers ----
    function signed [15:0] to_q15;
        input real val;
        begin
            to_q15 = $rtoi(val * 32768.0);
        end
    endfunction

    function real from_q15;
        input signed [15:0] val;
        begin
            from_q15 = val / 32768.0;
        end
    endfunction

    task pack_input;
        input real x0,x1,x2,x3,x4,x5,x6,x7;
        begin
            in_flat[127:112] = to_q15(x0);
            in_flat[111:96]  = to_q15(x1);
            in_flat[95:80]   = to_q15(x2);
            in_flat[79:64]   = to_q15(x3);
            in_flat[63:48]   = to_q15(x4);
            in_flat[47:32]   = to_q15(x5);
            in_flat[31:16]   = to_q15(x6);
            in_flat[15:0]    = to_q15(x7);
        end
    endtask

    // ---- golden model: same stage structure as the RTL, floating point ----
    task golden_fft;
        input  real x0,x1,x2,x3,x4,x5,x6,x7;
        output real Or0,Oi0,Or1,Oi1,Or2,Oi2,Or3,Oi3,Or4,Oi4,Or5,Oi5,Or6,Oi6,Or7,Oi7; 
        real r0,r1,r2,r3,r4,r5,r6,r7;
        real i0,i1,i2,i3,i4,i5,i6,i7;
        real t0r,t1r,t2r,t3r,t4r,t5r,t6r,t7r;
        real t0i,t1i,t2i,t3i,t4i,t5i,t6i,t7i;
        real s0r,s1r,s2r,s3r,s4r,s5r,s6r,s7r;
        real s0i,s1i,s2i,s3i,s4i,s5i,s6i,s7i;
        real W;
        real br,bi;

        begin
            W = 0.70710678118654752; // 1/sqrt2

            r0=x0; r1=x4; r2=x2; r3=x6; r4=x1; r5=x5; r6=x3; r7=x7;
            i0=0; i1=0; i2=0; i3=0; i4=0; i5=0; i6=0; i7=0;

            // stage 1: pairs (0,1)(2,3)(4,5)(6,7), all W0
            t0r=(r0+r1)/2; t0i=(i0+i1)/2; t1r=(r0-r1)/2; t1i=(i0-i1)/2;
            t2r=(r2+r3)/2; t2i=(i2+i3)/2; t3r=(r2-r3)/2; t3i=(i2-i3)/2;
            t4r=(r4+r5)/2; t4i=(i4+i5)/2; t5r=(r4-r5)/2; t5i=(i4-i5)/2;
            t6r=(r6+r7)/2; t6i=(i6+i7)/2; t7r=(r6-r7)/2; t7i=(i6-i7)/2;

            // stage 2: group(0-3): (0,2)=W0,(1,3)=W(-j); group(4-7) same
            s0r=(t0r+t2r)/2; s0i=(t0i+t2i)/2; s2r=(t0r-t2r)/2; s2i=(t0i-t2i)/2;
            br=t3i; bi=-t3r;
            s1r=(t1r+br)/2;  s1i=(t1i+bi)/2;  s3r=(t1r-br)/2;  s3i=(t1i-bi)/2;

            s4r=(t4r+t6r)/2; s4i=(t4i+t6i)/2; s6r=(t4r-t6r)/2; s6i=(t4i-t6i)/2;
            br=t7i; bi=-t7r;
            s5r=(t5r+br)/2;  s5i=(t5i+bi)/2;  s7r=(t5r-br)/2;  s7i=(t5i-bi)/2;

            // stage 3: (0,4)=W0, (1,5)=W1=(1-j)/sqrt2, (2,6)=W(-j), (3,7)=W3=(-1-j)/sqrt2
            Or0=(s0r+s4r)/2; Oi0=(s0i+s4i)/2; Or4=(s0r-s4r)/2; Oi4=(s0i-s4i)/2;

            br = s5r*W - s5i*(-W);
            bi = s5r*(-W) + s5i*W;
            Or1=(s1r+br)/2; Oi1=(s1i+bi)/2; Or5=(s1r-br)/2; Oi5=(s1i-bi)/2;

            br=s6i; bi=-s6r;
            Or2=(s2r+br)/2; Oi2=(s2i+bi)/2; Or6=(s2r-br)/2; Oi6=(s2i-bi)/2;

            br = s7r*(-W) - s7i*(-W);
            bi = s7r*(-W) + s7i*(-W);
            Or3=(s3r+br)/2; Oi3=(s3i+bi)/2; Or7=(s3r-br)/2; Oi7=(s3i-bi)/2;
        end
    endtask

    task check_output;
        input real x0,x1,x2,x3,x4,x5,x6,x7;
        real Or0,Oi0,Or1,Oi1,Or2,Oi2,Or3,Oi3,Or4,Oi4,Or5,Oi5,Or6,Oi6,Or7,Oi7;
        real exp_re[0:7];
        real exp_im[0:7];
        real got_re, got_im;
        real tol;
        integer k;
        integer re_bits, im_bits;
        begin
            golden_fft(x0,x1,x2,x3,x4,x5,x6,x7,
                       Or0,Oi0,Or1,Oi1,Or2,Oi2,Or3,Oi3,Or4,Oi4,Or5,Oi5,Or6,Oi6,Or7,Oi7);

            exp_re[0]=Or0; exp_im[0]=Oi0; exp_re[1]=Or1; exp_im[1]=Oi1;
            exp_re[2]=Or2; exp_im[2]=Oi2; exp_re[3]=Or3; exp_im[3]=Oi3;
            exp_re[4]=Or4; exp_im[4]=Oi4; exp_re[5]=Or5; exp_im[5]=Oi5;
            exp_re[6]=Or6; exp_im[6]=Oi6; exp_re[7]=Or7; exp_im[7]=Oi7;

            tol = 4.0/32768.0 + 0.001;

            for (k = 0; k < 8; k = k + 1) begin
                re_bits = out_flat[255-32*k -: 16];
                im_bits = out_flat[239-32*k -: 16];
                got_re  = from_q15(re_bits);
                got_im  = from_q15(im_bits);

                if ( (got_re-exp_re[k] > tol) || (exp_re[k]-got_re > tol) ||
                     (got_im-exp_im[k] > tol) || (exp_im[k]-got_im > tol) ) begin
                    errors = errors + 1;
                    $display("FAIL bin %0d: got=(%.4f,%.4f) exp=(%.4f,%.4f)",
                              k, got_re, got_im, exp_re[k], exp_im[k]);
                end else begin
                    $display("PASS bin %0d: got=(%.4f,%.4f) exp=(%.4f,%.4f)",
                              k, got_re, got_im, exp_re[k], exp_im[k]);
                end
            end
        end
    endtask

    task run_vector;
    input real x0,x1,x2,x3,x4,x5,x6,x7;
    begin
        pack_input(x0,x1,x2,x3,x4,x5,x6,x7);
        @(posedge clk);
        in_valid = 1'b1;
        @(posedge clk);
        in_valid = 1'b0;

        wait (out_valid == 1'b1);
        @(posedge clk); // let out_flat fully settle this cycle before reading
        $display("---- vector: %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f ----",
                   x0,x1,x2,x3,x4,x5,x6,x7);
        check_output(x0,x1,x2,x3,x4,x5,x6,x7);
    end
endtask

    initial begin
    clk = 0;
    rst_n = 0;
    in_valid = 0;
    in_flat = 128'sd0;

    repeat (5) @(posedge clk);   // was 3 - give more settle margin
    rst_n = 1;
    repeat (5) @(posedge clk);   // extra idle cycles before first real vector

    
    // max representable positive on every input (rail value, positive side)
run_vector(0.99997, 0.99997, 0.99997, 0.99997, 0.99997, 0.99997, 0.99997, 0.99997);

// max representable negative on every input (rail value, negative side - this one IS exactly -1.0, unlike +1.0)
run_vector(-1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0);

// alternating max positive / max negative -- worst-case magnitude swing on every single add/sub
run_vector(0.99997, -1.0, 0.99997, -1.0, 0.99997, -1.0, 0.99997, -1.0);

// impulse at a different position than before (index 4 instead of index 0)
run_vector(0.0, 0.0, 0.0, 0.0, 0.99997, 0.0, 0.0, 0.0);  // note: use 0.99997 not 1.0, same reason as before

// tiny near-zero values, checks rounding doesn't do anything weird near the LSB
run_vector(0.001, -0.001, 0.001, -0.001, 0.001, -0.001, 0.001, -0.001);

        $display("========================================");
        if (errors == 0)
            $display("ALL FFT VECTORS PASSED");
        else
            $display("%0d BIN(S) FAILED", errors);

        $finish;
    end

endmodule
