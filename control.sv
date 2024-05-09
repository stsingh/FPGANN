// Controls NN flow (forward -> backward or display depending on if in test or train mode)

`timescale 1ns / 1ps
module control #(
    parameter integer IMG_SIZE = 256,
    parameter integer CLASSES = 10
) (
    input logic clk, 
    input logic reset,
    input logic start, 
    input logic train,
    input logic test,
    input logic backprop_done,
    input logic forprop_done,
    
    output logic train_buff,
    output logic test_buff,
    output logic start_backprop,
    output logic start_forprop,
    output logic display_val
);

    // States
    enum logic [1:0] {
        start_ctrl,  //idling 
        forprop, // forward propagation 
        backprop, // backwards propagation 
        display // display results
    } curr_state, next_state;

    logic in_prog; // is the state machine started
    logic clear; // clear start signal
    // Next state logic
    always_comb begin
        start_forprop = 0;
        display_val = 0;
        start_backprop = 0;
        clear = 0;

        case (curr_state)
            start_ctrl: begin
                if(in_prog) begin // if the nn has started, go into forward prop mode
                    next_state = forprop;
                end else begin // else stay idle
                    next_state = start_ctrl;
                end
            end

            forprop: begin
                start_forprop = ~forprop_done; // if forward prop done, don't start forprop
                if (forprop_done) begin
                    if (train | train_buff) begin // if forprop done and train signals high, go into backprop
                        next_state = backprop;
                    end else begin // else display results
                        next_state = display;
                    end
                end else begin // otherwise stay in forprop
                    next_state = forprop;
                end
                clear = test_buff & forprop_done; // if in test mode and forprop done, clear start signal
            end

            backprop: begin
                start_backprop = ~backprop_done; // don't start backprop if backprop is done
                if (backprop_done) begin // if backprop done, display else stay in backprop
                    next_state = display;
                end else begin
                    next_state = backprop;
                end
                clear = backprop_done; // clear start signal if backprop done
            end

            display: begin
                display_val = 1'b1;
                next_state = start_ctrl;
            end

            default: next_state = start_ctrl;
        endcase
    end

    // synchronously update states
    always_ff @(posedge clk) begin
        if(reset) begin
            curr_state <= start_ctrl; // idling
            in_prog <= 1'b0; // has not started yet
            train_buff <= 1'b0; // not training
            test_buff <= 1'b0; // not testing
        end else begin 
            curr_state <= next_state;

            // Given train, test, and start signals, update as needed
            // buffer train signal
            if (train) begin
                train_buff <= 1'b1;
            end else if (test) begin
                train_buff <= 1'b0;
            end else begin
                train_buff <= train_buff;
            end

            // buffer test signal
            if (test) begin
                test_buff <= 1'b1;
            end else if (train) begin
                test_buff <= 1'b0;
            end else begin
                test_buff <= test_buff;
            end

            // buffer "in progress" signal
            if (start) begin
                in_prog <= 1'b1;
            end else if (clear) begin
                in_prog <= 1'b0;
            end else begin
                in_prog <= in_prog;
            end
        end
    end

endmodule