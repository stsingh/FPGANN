`define FIXED_5 (5<<5)
`define FIXED_1 (1<<5)
`define FIXED_2_375 8'h4C//32'h26000
`define FIXED_0_84375 8'h1B//32'h0D800
`define FIXED_0_03125 8'h01//32'h00800
`define FIXED_0_125 8'h04//32'h02000
`define FIXED_0_625 8'h14//32'h0A000
`define FIXED_0_25 8'h08//32'h04000
`define FIXED_0_5 8'h10//32'h08000 

module sigmoid_func(input logic clk,
    input logic reset,
    input logic en,
    input logic [7:0] in,
    output logic [7:0] out
);

    function logic [7:0] piecewise_sig_stage1(logic [7:0] in);
        if(in>=`FIXED_5)
            piecewise_sig_stage1 = `FIXED_1;
        else if ((in >= `FIXED_2_375) && (in < `FIXED_5))
            piecewise_sig_stage1 = (in>>5);
        else if ((in >= `FIXED_1) && (in < `FIXED_2_375))
            piecewise_sig_stage1 = (in>>3);
        else
            piecewise_sig_stage1 = (in>>2);
    endfunction

    function logic [7:0] piecewise_sig_stage2(logic [7:0] in, logic [7:0] temp);
        if(in>=`FIXED_5)
            piecewise_sig_stage2 = `FIXED_1;
        else if ((in >= `FIXED_2_375) && (in < `FIXED_5))
            piecewise_sig_stage2 = temp + `FIXED_0_84375;
        else if ((in >= `FIXED_1) && (in < `FIXED_2_375))
            piecewise_sig_stage2 = temp + `FIXED_0_625;
        else
            piecewise_sig_stage2 = temp + `FIXED_0_5;
    endfunction

    logic [7:0] temp1, temp2, result;
    logic sign;
    always_ff @(posedge clk) begin
        if (reset) begin
            temp1 <= 8'b0;
            temp2 <= 8'b0;
            result <= 8'b0;
            sign <= 1'b0;
        end else if (en) begin
            temp1 <= in[7] ? piecewise_sig_stage1(~in+1) : piecewise_sig_stage1(in);
            temp2 <= in[7] ? ~in+1 : in;
            sign <= in[7];
            result <= sign ? `FIXED_1 - piecewise_sig_stage2(temp2, temp1) : piecewise_sig_stage2(temp2, temp1);
        end
    end
    assign out = result;
endmodule