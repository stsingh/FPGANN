module multiplier8 (
    // 8 bit fixed point with least 5 bits fractional
    input logic [7:0] in1,
    input logic [7:0] in2,

    output logic [15:0] out // 16 bit fixed point with least 5 bits fractional
);
    assign out = (in1 * in2);

endmodule