`include "defs.sv"

module top (
    input  clk,
    input  rst,
    input  ps2_clk,
    input  ps2_data,
`ifdef INDICATOR_ENABLED
    output [7:0] seg,
    output [3:0] dig,
    output [3:0] led,
    output beep,
`endif
    output [2:0] rgb,
    output hsync,
    output vsync
);

wire    main_2clk;
reg     main_clk;

wire    cpu_clk;

// -- cpu signals ---
wire            hlt;
reg             int_request;
wire            cpu_int_ask;
wire            cpu_read_mem;
wire            cpu_write_mem;
wire            cpu_read_port;
wire            cpu_write_port;
wire    [15:0]  cpu_addr;
wire    [7:0]   cpu_data;

wire    [7:0]   port_addr; assign port_addr = cpu_addr[7:0];
reg     [7:0]   port_data;

wire    [15:0]  mem_addr;
wire    [7:0]   mem_r_data;
wire    [7:0]   mem_w_data;


wire            cpu_en;
wire            cpu_op_en;
wire            display_mem_read;
wire    [15:0]  display_addr;
wire    [7:0]   rgb_8bits;
reg     [3:0]   set_color;
reg     [7:0]   colors [0:15];
reg     [7:0]   display_scroll;


assign rgb = { (rgb_8bits[2:0] > 1), (rgb_8bits[5:3] > 1), (rgb_8bits[7:6] > 0) };


reg     [7:0]   debug_line [0:63];

wire read_mem;
wire write_mem; 


assign cpu_data  =  cpu_int_ask     ?   8'hff :
                    cpu_read_port   ?   port_data :
                                        mem_r_data ;
assign cpu_clk   = cpu_en & main_clk ;
assign read_mem  = display_mem_read | cpu_read_mem ;
assign write_mem = cpu_op_en ? cpu_write_mem : 1'b0 ;
assign mem_addr  = cpu_op_en ? cpu_addr : display_addr ;


// -- keyboard --
reg     [7:0]   keyboard_key;
kk              keyboard_keys0;
kk              keyboard_keys1;
kk              keyboard_keys;
reg             key_shift;
reg             key_caps;
reg     [7:0]   keyboard_line;


pll_vga (
    .inclk0( clk ),     // 50 Mz
    .c0( main_2clk )    // 50.35 Mz
);

always @( posedge main_2clk ) main_clk <= ~main_clk;

always @( posedge main_clk or negedge rst )
begin
if( ~rst )
    begin
        colors <= '{
            8'hc0, 8'hff, 8'hff, 8'hff, 8'hff, 8'hff, 8'hff, 8'hff,
            8'hff, 8'hff, 8'hff, 8'hff, 8'hff, 8'hff, 8'hff, 8'hff
        };
        indicator_value <= 16'hfffe;
    end
else
    begin
        if( cpu_write_port )
            begin
                //indicator_value[1:0] <= mem_w_data;
                //indicator_value[3:2] <= port_addr;
                case( port_addr )
                    //8'h34:    indicator_value[1:0] <= mem_w_data;
                    8'h02:  set_color <= mem_w_data[3:0];
                    8'h03:  keyboard_line <= mem_w_data;
                            //display_scroll <= mem_w_data;
                    8'h0c:  colors[set_color] <= mem_w_data;
                endcase
            end

        if( cpu_read_port )
            case( port_addr )
                8'h01:  port_data <= {
                            1'b0,
                            1'b0,
                            1'b0,
                            1'b0,
                            1'b0,
                            ~keyboard_keys['h11],   // Alt -> СС
                        ~keyboard_keys['h14],   // Ctrl -> УС
                        ~key_caps,              // Caps -> РУС/LAT
                        };
                8'h01:
                    port_data <= ~(
                        (keyboard_line[0] ?
                            {
                                1'b0,
                                keyboard_keys['h36],
                                keyboard_keys['h2e],
                                keyboard_keys['h25],
                                keyboard_keys['h26],
                                keyboard_keys['h1e],
                                keyboard_keys['h16],
                                keyboard_keys['h45],
                            } : 8'h00 ) |
                        (keyboard_line[1] ?
                            {
                                1'b0,
                                keyboard_keys['h36],
                                keyboard_keys['h2e],
                                keyboard_keys['h25],
                                keyboard_keys['h26],
                                keyboard_keys['h1e],
                                keyboard_keys['h16],
                                keyboard_keys['h45],
                            } : 8'h00 ) |
                        (keyboard_line[2] ?
                            {
                                1'b0,
                                keyboard_keys['h36],
                                keyboard_keys['h2e],
                                keyboard_keys['h25],
                                keyboard_keys['h26],
                                keyboard_keys['h1e],
                                keyboard_keys['h16],
                                keyboard_keys['h45],
                            } : 8'h00 )
                    );
            endcase
        if( write_mem && (
            ((mem_addr > 16'h900) && (mem_addr < 16'h6a00)) ||
            ((mem_addr > 16'h7000) && (mem_addr < 16'h8000)) 
        ))
        begin
            indicator_value <= mem_addr;
        end

    end
end


i8080cpu (
`ifdef DEBUG
  `ifdef PC_TO_INDICATOR
    .debug_line         ( indicator_value   ),
  `else
    .debug_line         ( debug_line        ),
  `endif
`endif
    .clk                ( cpu_clk           ),
    .reset              ( rst               ),
    .hlt                ( hlt               ),
    .addr               ( cpu_addr          ),
    .read_mem           ( cpu_read_mem      ),
    .write_mem          ( cpu_write_mem     ),
    .read_port          ( cpu_read_port     ),
    .write_port         ( cpu_write_port    ),
    .data               ( cpu_data          ),
    .w_data             ( mem_w_data        ),
    .int_request        ( int_request       ),
    .int_ask            ( cpu_int_ask       )
);




`ifdef INDICATOR_ENABLED
reg [3:0][3:0] indicator_value;
Indicator (
    .clk                ( main_clk          ),
    .show_value         ( indicator_value   ),
    .seg                ( seg               ),
    .dig                ( dig               )
);
`endif

wire [14:0] ram_addr;
assign ram_addr =   mem_addr < 16'h1200 ? mem_addr :
                    (mem_addr > 16'h6b00) && (mem_addr <= 16'h8000) ? (mem_addr - 16'h5000) :
                    mem_addr >= 16'hc000 ? (mem_addr - 16'h9000) : 15'h1000;

ram (
    .address            ( ram_addr          ),
    .clock              ( main_clk          ),
    .data               ( mem_w_data        ),
    .rden               ( read_mem          ),
    .wren               ( write_mem         ),
    .q                  ( mem_r_data        )
);


display (
    .clk                ( main_clk          ),
    .colors             ( colors            ),
//  .scroll             ( display_scroll-1  ),
    .mem_data           ( mem_r_data        ),
    .mem_addr           ( display_addr      ),
    .mem_read           ( display_mem_read  ),
    .hsync              ( hsync             ),
    .vsync              ( vsync             ),
    .rgb                ( rgb_8bits         ),
    .cpu_en             ( cpu_en            ),
    .cpu_op_en          ( cpu_op_en         ),
    .int_request        ( int_request       )
);


keyboard (
    .clock_50           ( clk               ),
    .reset              ( rst               ),
    .ps2_clk            ( ps2_clk           ),
    .ps2_data           ( ps2_data          ),
    .keyboard_keys      ( keyboard_keys0    ),
    .key_caps           ( key_caps          )
);


endmodule
