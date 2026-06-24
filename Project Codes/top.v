module top(
    input  clk_50mhz,        // Board clock
    input  rst_n,            // KEY0 (active-low reset)
    input  [1:0] arduino_in, // 2-bit input from Arduino
    output [1:0] led,        // LEDR[1:0] to show gesture code
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output tx_dfplayer       // UART TX to DFPlayer RX
);

    wire [1:0] gesture_code;
    wire [31:0] latency_value;

    //---------------------------------------------------------
    // Gesture FSM (runs at full 50 MHz for low latency)
    //---------------------------------------------------------
    gesture_fsm_2bit u_fsm (
        .clk(clk_50mhz),
        .rst(~rst_n),          // active-high reset
        .sensor_in(arduino_in),
        .gesture(gesture_code)
    );

    //---------------------------------------------------------
    // LEDs show gesture_code
    //---------------------------------------------------------
    assign led = gesture_code;

    //---------------------------------------------------------
    // Display gesture as text on HEX displays
    //---------------------------------------------------------
    gesture_display u_disp (
        .gesture_code(gesture_code),
        .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2),
        .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5)
    );

    //---------------------------------------------------------
    // DFPlayer controller with latency measurement
    //---------------------------------------------------------
    dfplayer_ctrl u_dfp (
        .clk(clk_50mhz),
        .rst(~rst_n),
        .gesture_code(gesture_code),
        .tx(tx_dfplayer),      // goes to DFPlayer RX pin
        .latency_value(latency_value)
    );

endmodule
