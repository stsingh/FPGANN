module multiplier24(
    // 8 bit fixed point with least 5 bits fractional
    input logic [7:0] in1, // 3, 5
    input logic [23:0] in2, // 9, 15

    output logic [7:0] out // 12, 20
);
    logic [31:0] temp;
    assign temp = in1 * in2;
    assign out = temp[22:15];

endmodule