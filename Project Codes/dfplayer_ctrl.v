module dfplayer_ctrl(
    input  clk,
    input  rst,
    input  [1:0] gesture_code,
    output tx,                       // to DFPlayer RX
    output reg [31:0] latency_value, // measured latency in clock cycles
    output reg new_latency            // goes high when a new latency value is ready
);

    //---------------------------------------------------------
    // UART for DFPlayer
    //---------------------------------------------------------
    reg [7:0] tx_data;
    reg send;
    wire busy;

    uart_tx #(.CLK_FREQ(50000000), .BAUD(9600)) u_uart (
        .clk(clk),
        .rst(rst),
        .tx_start(send),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(busy)
    );

    //---------------------------------------------------------
    // Command frame storage (10 bytes)
    //---------------------------------------------------------
    reg [7:0] frame [0:9];
    reg [3:0] idx;
    reg [1:0] prev_gesture;
    reg [1:0] state;

    localparam IDLE=0, LOAD=1, WAIT=2;

    //---------------------------------------------------------
    // Latency measurement
    //---------------------------------------------------------
    reg [31:0] latency_counter;
    reg measuring;

    //---------------------------------------------------------
    // Load frame task (full DFPlayer command with checksum)
    //---------------------------------------------------------
    task load_frame(input [1:0] g);
        reg [15:0] param;
        reg [15:0] checksum;
        begin
            case (g)
                2'b00: param = 16'h0001; // 0001.mp3
                2'b01: param = 16'h0002; // 0002.mp3
                2'b10: param = 16'h0003; // 0003.mp3
                2'b11: param = 16'h0004; // 0004.mp3
            endcase

            frame[0] = 8'h7E;   // start byte
            frame[1] = 8'hFF;   // version
            frame[2] = 8'h06;   // length
            frame[3] = 8'h03;   // command = play track
            frame[4] = 8'h00;   // feedback
            frame[5] = param[15:8]; // param high
            frame[6] = param[7:0];  // param low

            // checksum = 0 - (sum of bytes 1..6)
            checksum = 16'h0000 - (frame[1] + frame[2] + frame[3] +
                                   frame[4] + frame[5] + frame[6]);

            frame[7] = checksum[15:8]; // checksum high
            frame[8] = checksum[7:0];  // checksum low
            frame[9] = 8'hEF;          // end byte
        end
    endtask

    //---------------------------------------------------------
    // FSM to send DFPlayer command + measure latency
    //---------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prev_gesture   <= 2'b00;
            state          <= IDLE;
            idx            <= 0;
            send           <= 0;
            latency_counter<= 0;
            latency_value  <= 0;
            measuring      <= 0;
            new_latency    <= 0;
        end else begin
            case (state)
                IDLE: begin
                    send <= 0;
                    new_latency <= 0;
                    if (gesture_code != prev_gesture) begin
                        prev_gesture <= gesture_code;
                        load_frame(gesture_code);
                        idx <= 0;
                        state <= LOAD;

                        // start latency measurement
                        measuring <= 1;
                        latency_counter <= 0;
                    end
                end

                LOAD: begin
                    if (!busy) begin
                        tx_data <= frame[idx];
                        send <= 1;
                        state <= WAIT;
                    end
                end

                WAIT: begin
                    send <= 0;
                    if (!busy) begin
                        if (idx < 9) begin   // send 10 bytes
                            idx <= idx + 1;
                            state <= LOAD;
                        end else begin
                            state <= IDLE;
                            if (measuring) begin
                                latency_value <= latency_counter;
                                measuring <= 0;
                                new_latency <= 1;  // flag ready
                            end
                        end
                    end
                end
            endcase

            if (measuring)
                latency_counter <= latency_counter + 1;
        end
    end
endmodule