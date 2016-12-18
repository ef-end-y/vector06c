`include "defs.sv"


`define SCREEN_START_X      12'd191
`define SCREEN_START_Y      12'd111

`define SCREEN_MEM_START    16'h8000


module display (
    input               clk,
    input   [7:0]       colors [0:15],
//  input   [7:0]       scroll,
    input   [7:0]       mem_data,
    output  [15:0]      mem_addr,
    output              mem_read,
    output              hsync,
    output              vsync,
    output  [7:0]       rgb,
    output  reg         cpu_en,
    output  reg         cpu_op_en,
    output              int_request
);

vga (
    .clk                ( clk           ),
    .reset_n            ( 1             ),
    .vga_hs             ( hsync         ),
    .vga_vs             ( vsync         ),
    .vga_de             ( rgb_enable    ),
    .pixel_x            ( x             ),
    .pixel_y            ( y             ),
    .future_x           ( future_x      ),
    .future_y           ( future_y      )
);

wire    rgb_enable;
wire    [11:0] x;
wire    [11:0] y;
wire    [11:0] future_x;
wire    [11:0] future_y;
wire    signed [12:0] x0; assign x0 = x - `SCREEN_START_X;
wire    signed [12:0] y0; assign y0 = y - `SCREEN_START_Y;
wire    signed [12:0] xa; assign xa = future_x - `SCREEN_START_X;
wire    signed [12:0] ya; assign ya = future_y - `SCREEN_START_Y;

wire    addr_state; assign addr_state   = (xa[12:8] || ya[12:8]) == 0;
wire    draw_state; assign draw_state   = (x0[12:8] || y0[12:8]) == 0;
assign int_request = ya[12:8] == 1;

wire [2:0] xa3; assign xa3 = xa[2:0];
assign mem_read = (xa3 < 4) ? 1'b1 : 1'b0;

wire    [15:0] bank_addr;
assign bank_addr =  xa3 == 0 ?  16'h0000 :
                    xa3 == 1 ?  16'h2000 :
                    xa3 == 2 ?  16'h4000 :
                    xa3 == 3 ?  16'h6000 :
                                16'h0000 ;

wire    [7:0] scroll_offset; assign scroll_offset = 8'hff - ya; //scroll - ya;
assign mem_addr = addr_state? ((xa[11:3] << 8) + scroll_offset + bank_addr + `SCREEN_MEM_START) : 0;

reg     [7:0] prefetch_data [0:3];
reg     [7:0] data [0:3];


wire [2:0] x_bit; assign x_bit = x0[2:0];
wire [3:0] color_index; assign color_index = {
    ((data[0] << x_bit) & 8'h80 ? 1'b1 : 1'b0),
    ((data[1] << x_bit) & 8'h80 ? 1'b1 : 1'b0),
    ((data[2] << x_bit) & 8'h80 ? 1'b1 : 1'b0),
    ((data[3] << x_bit) & 8'h80 ? 1'b1 : 1'b0),
    
};
assign rgb =    rgb_enable && draw_state ? colors[color_index] :
                (((y0 == -1) || (y0 == 256)) && (x0[12:8] == 0)) ||
                (((x0 == -1) || (x0 == 256)) && (y0[12:8] == 0)) ? 8'h07 :  8'h00;

always @( posedge clk )
begin
    case( xa3 )
        1, 2, 3, 4:
            begin
                prefetch_data[xa3-1] <= mem_data;
                if( xa3 == 4 ) cpu_op_en <= 1;
            end
        5:  begin
                data <= prefetch_data;
            end
        6:  begin
                if( cpu_op_en ) cpu_en <= 1;
            end
        7:  begin
                cpu_en <= 0;
                cpu_op_en <= 0;
            end
    endcase
end

endmodule