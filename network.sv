`timescale 1ns / 1ps
// Performs entire forward and backward prop
module network #(
    parameter integer IMG_SIZE = 256,
    parameter integer CLASSES = 10
) (
    input logic clk, 
    input logic reset,
    input logic start_backprop,
    input logic start_forprop,
    input logic train_buff,
    input logic test_buff,
    input logic [IMG_SIZE-1:0][7:0] img, // image buffer
    input logic [CLASSES-1:0][7:0] weights, // buffer holding weights for one neuron
    input logic [7:0] label_val,

    output logic forprop_done, // forward prop is done
    output logic backprop_done, // back prop is done
    output logic get_weights, // read weights
    output logic [CLASSES-1:0][7:0] result, // fixed point result to compare to input label
    output logic [CLASSES-1:0][7:0] delta, // change in weights
    output logic update, // enable backprop update of weights (basically wren)
    output logic [7:0] weight_addr, 
    output logic [2:0] fp_state_reg,
    output logic [2:0] bp_state_reg
);

    logic clear;
    logic start_delta;
    logic [CLASSES-1:0][7:0] accum; // accumulate dot prods for output layer
    logic[$clog2(IMG_SIZE):0] f_nidx; // neuron idx for forward prop
    logic[$clog2(IMG_SIZE):0] b_nidx; // neuron idx for backward prop
    logic forprop_en;

    logic [CLASSES-1:0][23:0] weight_change; // mult with inputs to get delta
    logic [CLASSES-1:0][15:0] slope; // partial deriv of sigmoid wrt accumulated vals

    logic [CLASSES-1:0] [7:0] error; // error for each output
    logic [CLASSES-1:0] [7:0] ideal; // 
    logic [CLASSES-1:0][7:0] label;
    
    logic [7:0] bram_raddr;
    logic [7:0] bram_waddr;
    
    integer k;
    always_comb begin
        label = {10{8'h0}};
        label[label_val] = 8'b00100000;
        for (k = 0; k < CLASSES; k++)
            error[k] = ideal[k] - result[k];
    end

    // Calculate error
    integer j;
    always_comb begin
        ideal = {CLASSES{8'h0}};
        for(j = 0; j < CLASSES; j++) begin
            if(label[j] == 1'b1) begin
                ideal[j] = 8'b00100000;
            end
        end

        for(j = 0; j < CLASSES; j++) begin
            error[j] = ideal[j] - result[j];
        end
    end

    // generate forprop neurons
    genvar i, m;
    generate 
        for(i = 0; i < CLASSES; i++) begin: forward
            forprop_neuron forprop_neuron ( // forprop neuron
                .clk(clk),
                .reset(reset),
                .clear(clear),
                .en(forprop_en),
                .weight(weights[i]),
                .data(img[IMG_SIZE-f_nidx]),
                .accum(accum[i])
            );

            sigmoid_func sigmoid (
                .clk(clk),
                .reset(reset),
                .en(forprop_en),
                .in(accum[i]),
                .out(result[i])
            );
        end
    endgenerate

    // generate multipliers to act as neurons during backprop
    generate 
        for (i = 0; i < CLASSES; i++) begin: backward
            multiplier8 mult1(
                .in1({8{start_delta}} & result[i]),  // activation
                .in2(8'h20-result[i]), // 1 - activation
                .out(slope[i]) // dS/dy
            ); 

            multiplier16 mult2(
                .in1({8{start_delta}} & error[i]), 
                .in2(slope[i]),
                .out(weight_change[i]) // weight change for each neuron
            );

            multiplier24 mult3(
                .in1({8{start_delta}} & img[IMG_SIZE-b_nidx]), 
                .in2(weight_change[i]), 
                .out(delta[i]) // calculate delta
            );
        end
    endgenerate


    // forprop enums and fsm definition
    enum logic [2:0] {
        forprop_idle, // idle state
        forprop_get_weights, // get weights
        forprop_l1, // layer 1
        forprop_delay, // 1 clock delay
        forprop_wait, // wait state
        forprop_done_s // finished state
    } forprop_curr_s, forprop_next_s;

    always_ff @(posedge clk) begin
        if (reset) begin 
            forprop_curr_s <= forprop_idle;
        end else begin
            forprop_curr_s <= forprop_next_s;
        end
    end

    always_comb begin
        forprop_done = 1'b0;
        clear = 1'b0;
        forprop_en = 1'b0;
        get_weights = 1'b0;
        bram_raddr = 8'b0;

        case(forprop_curr_s)
            default: forprop_next_s = forprop_idle;
            forprop_idle: begin
                clear = start_forprop || start_backprop; // clear all neurons if prop is occurring
                get_weights = start_forprop || start_backprop; // get weights if prop occurring
                if (start_forprop || start_backprop) begin // get weights if prop is occurring
                    forprop_next_s = forprop_get_weights;
                end else begin // else stay idle
                    forprop_next_s = forprop_idle;
                end
            end

            forprop_get_weights: begin
                forprop_next_s = forprop_delay; // proceed to layer one
            end

            forprop_l1: begin
                forprop_en = 1'b1; // enable forprop
                if (f_nidx < IMG_SIZE - 1) begin // if all neurons haven't been iterated through, stay in layer
                    forprop_next_s = forprop_delay;
                end else begin // else finish
                    forprop_next_s = forprop_done_s;
                end
            end

            forprop_delay: begin
                bram_raddr = f_nidx;
                forprop_next_s = forprop_l1;
            end

            forprop_done_s: begin
                forprop_done = 1'b1; // forprop is done
                if (~train_buff) begin // if not training, go to idle
                    forprop_next_s = forprop_idle;
                end else begin // else go to wait for backprop
                    forprop_next_s = forprop_wait;
                end
            end

            forprop_wait: begin
                if(backprop_done) begin // if backprop done, go to idle
                    forprop_next_s = forprop_idle;
                end else begin // else stay in wait
                    forprop_next_s = forprop_wait;
                end
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            f_nidx <= 0;
        end else begin
            case(forprop_curr_s)
                forprop_idle: begin
                    f_nidx <= 0;
                end

                forprop_delay: begin
                    if (f_nidx == IMG_SIZE - 1) begin
                        f_nidx <= 0;
                    end else begin
                        f_nidx <= f_nidx + 1;
                    end
                end
            endcase
        end
    end
    
    assign fp_state_reg = forprop_curr_s;

    // backprop enums and fsm definition
    enum logic [2:0] {
        backprop_idle, // idle state
        backprop_update, // update weights
        backprop_getdata, // 
        backprop_clk1,
        backprop_clk2,
        backprop_delta, 
        backprop_delay,
        backprop_done_s
    } backprop_curr_s, backprop_next_s;

    always_ff @(posedge clk) begin 
        if (reset) begin 
            backprop_curr_s <= backprop_idle;
        end else begin
            backprop_curr_s <= backprop_next_s;
        end
    end

    always_comb begin
        backprop_done = 1'b0;
        start_delta = 1'b0;
        update = 1'b0;
        bram_waddr = 8'b0;

        case (backprop_curr_s) 
            default: backprop_next_s = backprop_idle;
            backprop_idle: begin
                if (start_backprop) begin // if start_backprop high, go to update weights state
                    backprop_next_s = backprop_update;
                end else begin // else stay idle
                    backprop_next_s = backprop_idle;
                end
            end

            backprop_update: begin
                update = 1'b1; // enable updating of weights (wren for weights bram)
                backprop_next_s = backprop_getdata;
            end

            backprop_getdata: begin
                backprop_next_s = backprop_delay;
            end

            backprop_clk1: begin
                backprop_next_s = backprop_clk2;
            end

            backprop_clk2: begin
                backprop_next_s = backprop_delay;
            end

            backprop_delta: begin
                start_delta = 1'b1; // start delta calculation
                if (b_nidx < IMG_SIZE - 1) begin // while indexing through neurons, stay in delta calc mode
                    backprop_next_s = backprop_delay;
                end else begin
                    backprop_next_s = backprop_done_s;
                end
            end

            backprop_delay: begin
                bram_waddr = b_nidx;
                if(b_nidx == 0) begin 
                    backprop_next_s = backprop_clk1;
                end else begin
                    backprop_next_s = backprop_delta;
                end
            end

            backprop_done_s: begin
                backprop_done = 1'b1; // signal that backprop is done
                backprop_next_s = backprop_idle;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            b_nidx <= 0;
        end else begin
            case(backprop_curr_s)

                backprop_idle: begin
                    b_nidx <= 0;
                end

                backprop_delay: begin
                    if (b_nidx == IMG_SIZE - 1) begin
                        b_nidx <= 0;
                    end else begin
                        b_nidx <= b_nidx + 1;
                    end
                end
                
            endcase
        end
    end

    assign bp_state_reg = backprop_curr_s;

    // weight ram addr signals
    always_comb begin
        if (backprop_curr_s != 3'b0) begin
            weight_addr = bram_waddr;
        end else if (forprop_curr_s != 3'b0) begin
            weight_addr = bram_raddr;
        end else begin
            weight_addr = 8'b0;
        end
    end

endmodule