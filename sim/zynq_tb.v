`timescale 1ns / 1ps

module tb;
    reg tb_ACLK;
    reg tb_ARESETn;

    reg i_sync_reset;
    
    wire temp_clk;
    wire temp_rstn; 
    
    wire temp_i_sync_reset;
    
    reg resp;
    

    initial 
    begin       
        tb_ACLK = 1'b0;
    end

    //------------------------------------------------------------------------
    // Simple Clock Generator
    //------------------------------------------------------------------------
    
    always #2 tb_ACLK = !tb_ACLK;
    initial
    begin
    
        $display ("running the tb");
               
        tb_ARESETn = 1'b0; #2 
        tb_ARESETn = 1'b1; #2

        i_sync_reset = 1'b1; #2
        i_sync_reset = 1'b0; #2

//        repeat(1) @(posedge tb_ACLK);
        
        
        //Reset the PL
        tb.zynq_sys.design_1_i.processing_system7_0.inst.fpga_soft_reset(32'h1);
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.fpga_soft_reset(32'h0);
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h40400030,4, 32'h00000001, resp); // something about dma idk
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h40400058,4, 32'h00000010, resp);

        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00000,4, 32'h00000001, resp); // tick en up 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00000,4, 32'h00000001, resp);
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00000,4, 32'h00000003, resp); // weight enable          
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h8000A261, resp); // D0 D1  1 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h0000A4B5, resp); // D2 D3   
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h8001A7B6, resp); // D0 D1  2 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h0001A908, resp); // D2 D3  
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h8002AB0A, resp); // D0 D1  3 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h0002ADBC, resp); // D2 D3   
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h8003AFBE, resp); // D0 D1  4 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h0003A1B3, resp); // D2 D3 
        
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h8004A261, resp); // D0 D1  1 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h0004A4B5, resp); // D2 D3   
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h8005A7B6, resp); // D0 D1  2 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h0005A908, resp); // D2 D3  
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h8006AB0A, resp); // D0 D1  3 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h0006ADBC, resp); // D2 D3   
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h8007AFBE, resp); // D0 D1  4 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h0007A1B3, resp); // D2 D3 
        
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h8008A261, resp); // D0 D1  1 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h0008A4B5, resp); // D2 D3   
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h8009A7B6, resp); // D0 D1  2 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h0009A908, resp); // D2 D3  
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h800AAB0A, resp); // D0 D1  3 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h000AADBC, resp); // D2 D3   
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h800BAFBE, resp); // D0 D1  4 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h000BA1B3, resp); // D2 D3 
        
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h800CA261, resp); // D0 D1  1 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h000CA4B5, resp); // D2 D3   
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h800DA7B6, resp); // D0 D1  2 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h000DA908, resp); // D2 D3  
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h800EAB0A, resp); // D0 D1  3 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h000EADBC, resp); // D2 D3   
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h800FAFBE, resp); // D0 D1  4 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00004,4, 32'h000FA1B3, resp); // D2 D3 
        
        
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00000,4, 32'h00000001, resp); // ticl weight enable down 
     
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00000,4, 32'h00000005, resp); // unified buffer enable          
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h80000F0F, resp); // D0 D1  1 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h00000E0E, resp); // D2 D3   
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h80010C0C, resp); // D0 D1  2 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h00010D08, resp); // D2 D3  
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h80020B0A, resp); // D0 D1  3 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h00020D0F, resp); // D2 D3   
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h8003010E, resp); // D0 D1  4 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h00030F03, resp); // D2 D3 
        
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h80040F0F, resp); // D0 D1  1 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h00040E0E, resp); // D2 D3   
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h80050C0C, resp); // D0 D1  2 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h00050D08, resp); // D2 D3  
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h80060B0A, resp); // D0 D1  3 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h00060D0F, resp); // D2 D3   
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h8007010E, resp); // D0 D1  4 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h00070F03, resp); // D2 D3 
        
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h80080F0F, resp); // D0 D1  1 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h00080E0E, resp); // D2 D3   
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h80090C0C, resp); // D0 D1  2 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h00090D08, resp); // D2 D3  
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h800A0B0A, resp); // D0 D1  3 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h000A0D0F, resp); // D2 D3   
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h800B010E, resp); // D0 D1  4 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h000B0F03, resp); // D2 D3 
        
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h800C0F0F, resp); // D0 D1  1 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h000C0E0E, resp); // D2 D3   
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h800D0C0C, resp); // D0 D1  2 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h000D0D08, resp); // D2 D3  
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h800E0B0A, resp); // D0 D1  3 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h000E0D0F, resp); // D2 D3   
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h800F010E, resp); // D0 D1  4 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00008,4, 32'h000F0F03, resp); // D2 D3 
        
        
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00000,4, 32'h00000001, resp); // ticl weight enable down 
        
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C0000C,4, 32'h04040404, resp); //  
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00000,4, 32'h00000009, resp); // matrxi start enable    
       
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00000,4, 32'h00000001, resp);
        
        #2500 
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h40400030,4, 32'h00000004, resp);
        #10
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h40400030,4, 32'h00000001, resp); // something about dma idk
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h40400058,4, 32'h00000010, resp);
        
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00000,8, 64'h00000009, resp);
        #2 tb.zynq_sys.design_1_i.processing_system7_0.inst.write_data(32'h43C00000,8, 64'h00000001, resp);
        $display ("Simulation completed");
        // $stop;
    end

    assign temp_clk = tb_ACLK;
    assign temp_rstn = tb_ARESETn;
    assign temp_i_sync_reset = i_sync_reset;

    
   
design_1_wrapper zynq_sys
   (.DDR_addr(),
        .DDR_ba(),
        .DDR_cas_n(),
        .DDR_ck_n(),
        .DDR_ck_p(),
        .DDR_cke(),
        .DDR_cs_n(),
        .DDR_dm(),
        .DDR_dq(),
        .DDR_dqs_n(),
        .DDR_dqs_p(),
        .DDR_odt(),
        .DDR_ras_n(),
        .DDR_reset_n(),
        .DDR_we_n(),
        .FIXED_IO_ddr_vrn(),
        .FIXED_IO_ddr_vrp(),
        .FIXED_IO_mio(),
        .FIXED_IO_ps_clk(temp_clk),
        .FIXED_IO_ps_porb(temp_rstn),
        .FIXED_IO_ps_srstb(temp_rstn)
        );
endmodule