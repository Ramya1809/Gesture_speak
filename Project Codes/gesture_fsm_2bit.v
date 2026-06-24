module gesture_fsm_2bit (
    input clk,               // Clock input
    input rst,               // Reset button (active high)
    input [1:0] sensor_in,   // 2-bit input for gestures
    output reg [1:0] gesture // 2-bit gesture output
);

    // State encoding
    parameter S_IDLE   = 2'b10;
    parameter S_HELP   = 2'b01;
    parameter S_OK     = 2'b00;
    parameter S_THANKS = 2'b11;

    reg [1:0] current_state, next_state;

    // Sequential block for state transition
    always @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= S_IDLE;  // default state after reset
        else
            current_state <= next_state;
    end

    // Next state logic based on 2-bit input
    always @(*) begin
        case (sensor_in)
            2'b00: next_state = S_OK;    // Idle
            2'b01: next_state = S_HELP;    // Help
            2'b10: next_state = S_IDLE;      // OK
            2'b11: next_state = S_THANKS;  // Thanks
            default: next_state = S_IDLE;
        endcase
    end

    // Output logic (gesture = state code)
    always @(*) begin
        case (current_state)
            S_OK:   gesture = 2'b00;
            S_HELP:   gesture = 2'b01;
            S_IDLE:     gesture = 2'b10;
            S_THANKS: gesture = 2'b11;
            default:  gesture = 2'b00;
        endcase
    end

endmodule

