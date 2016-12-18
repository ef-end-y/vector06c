`include "defs.sv"

module keyboard(
    input           clock_50,
    input           reset,
    input           ps2_clk,
    input           ps2_data,
    output  kk      keyboard_keys,
    output          key_caps
);

reg             ps2_key_up_action;
logic   [7:0]   ps2_recv_data;
logic           ps2_recv_ready;


PS2_Controller ( 
  .CLOCK_50             ( clock_50          ),
  .reset                ( 0                 ),

  .PS2_CLK              ( ps2_clk           ),
  .PS2_DAT              ( ps2_data          ),

  .received_data        ( ps2_recv_data     ),
  .received_data_en     ( ps2_recv_ready    )
);


always @( posedge ps2_recv_ready or negedge reset )
if( ~reset )
    begin
        //ps2_recv_data  <= 8'h0;
        //ps2_recv_ready <= 1'b0;
    end
else
begin
    if( ps2_recv_data == 8'hF0 )
        begin
            ps2_key_up_action <= 1;
        end
    else
        begin
            ps2_key_up_action <= 0;
            if( ps2_key_up_action )
                case( ps2_recv_data )
                    //8'h59,
                    //8'h12:        key_shift <= 0;
                    default:    keyboard_keys <= keyboard_keys & ~(1'b1 << ps2_recv_data);
                endcase
            else
                case( ps2_recv_data )
                    //8'h59,
                    //8'h12:        key_shift <= 1;
                    8'h58:      key_caps <= ~key_caps;
                    default:    keyboard_keys <= keyboard_keys | (1'b1 << ps2_recv_data);
                endcase
        end
end
endmodule
