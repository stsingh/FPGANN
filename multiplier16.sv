module multiplier16(
    // 8 bit fixed point with least 5 bits fractional
    input logic [7:0] in1, // 3, 5
    input logic [15:0] in2, // 6, 10

    output logic [23:0] out // 24 bit fixed point with least 5 bits fractional
);
    assign out = (in1 * in2); // 9, 15

endmodule