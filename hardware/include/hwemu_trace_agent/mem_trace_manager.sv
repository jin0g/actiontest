// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.

`ifndef REPLACE_WITH_MODULE_MEM_TRACE_MANAGER__SV
`define REPLACE_WITH_MODULE_MEM_TRACE_MANAGER__SV

class REPLACE_WITH_MODULE_byte_mem_data extends REPLACE_WITH_MODULE_data_base_object;
    logic[7:0] Mem[*];
endclass
    
class REPLACE_WITH_MODULE_mempage_trace extends REPLACE_WITH_MODULE_trace_base_component;
    logic[7:0] Mem[*];
    bit IsWr[*];
    logic[7:0] InitMem[*];
    logic[7:0] RefMem[*];
    int page_idx;
    string FileResultPath;
    string FileInitPath;
    integer FpRes;
    integer FpInit;
    string mode;

    function new (string inst_name, string hier_name);
        super.new(inst_name, hier_name);
    endfunction

    function void init(int page_idx, string mode);
        string filename;
        Mem.delete();
        IsWr.delete();
        InitMem.delete();
        this.page_idx = page_idx;
        filename = this.full_name();
        for(int i=0; i<filename.len; i++) 
            if(filename[i]==".") filename[i] = "_";
        //this.FileResultPath = $sformatf("%s/Trace_maxigmem_result_trans%0d.dat", this.TVDir, this.page_idx);;
        //this.FileInitPath   = $sformatf("%s/Trace_maxigmem_init_trans%0d.dat", this.TVDir, this.page_idx);
        this.FileResultPath = {this.TVDir, "/", filename, "_result.dat"};
        this.FileInitPath   = {this.TVDir, "/", filename, "_init.dat"};
        this.mode = mode;
        if(mode=="tvread") begin
            longint addr;
            logic[7:0] data;
            FpRes  = $fopen(this.FileResultPath, "r");
            if(FpRes) begin
                while(!$feof(FpRes)) begin
                    void'($fscanf(FpRes, "%d %h", addr, data)); 
                    RefMem[addr] = data;
                end
            end
            $fclose(FpRes);

            FpInit = $fopen(this.FileInitPath, "r");
            if(FpInit) begin
                while(!$feof(FpInit)) begin
                    void'($fscanf(FpInit, "%d %h", addr, data)); 
                    InitMem[addr] = data;
                end
            end
            $fclose(FpInit);
        end
    endfunction

    function void dump_chk(bit[1:0] dump_mode); //1: dump initial file. 2: dump result file
        if(mode=="tvdump") begin
            longint addr;
            if(dump_mode[1] && Mem.num()>0) begin
                FpRes  = $fopen(this.FileResultPath, "w");
                if(Mem.first(addr) && FpRes)
                    do begin
                        $fdisplay(FpRes, "%0d %h", addr, Mem[addr]);
                        Mem.delete(addr);
                    end while( Mem.next(addr) );
                $fclose(FpRes);
            end
            if(dump_mode[0] && InitMem.num()>0) begin
                FpInit = $fopen(this.FileInitPath, "w");
                if(InitMem.first(addr) && FpInit)
                    do begin
                        $fdisplay(FpInit, "%0d %h", addr, InitMem[addr]);
                        InitMem.delete(addr);
                    end while( InitMem.next(addr) );
                $fclose(FpInit);
            end
        end
        if(mode=="tvread"&&dump_mode[1]) begin
            longint addr;
            int cnt=0;
            REPLACE_WITH_MODULE_byte_mem_data chkdata = new;
            chkdata.Mem = Mem;
            hook_data(chkdata, "maxigmem_ouput");
            if(Mem.first(addr))
                do begin
                    if(!RefMem.exists(addr))
                        $display("COSIM_TRACE_DRV CHECK WITH HWEMU MAXI OUTPUT ERROR, %s can't find ref item at addr:%0h", this.full_name(), addr);
                    else if(RefMem[addr]!=Mem[addr]) 
                        $display("COSIM_TRACE_DRV CHECK WITH HWEMU MAXI OUTPUT ERROR, %s check item failed at addr:%0h, ref:%0h, dut:%0h", 
                                this.full_name(), addr, RefMem[addr], Mem[addr]);
                    RefMem.delete(addr);
                    Mem.delete(addr);
                    cnt++;
                end while( Mem.next(addr) );

            if(RefMem.first(addr)) begin
                do begin
                    $display("COSIM_TRACE_DRV CHECK WITH HWEMU MAXI OUTPUT ERROR, %s can't find dut item at addr:%0h", this.full_name(), addr);
                    RefMem.delete(addr);
                end while( RefMem.next(addr) );
            end
            $display("For %0dth transaction, %d maxi memory data are checked wth HW_EMU in %s", page_idx, cnt, this.full_name());
        end
    endfunction

    function bit read_one_elem(ref logic[7:0] data, input longint addr);
        if(IsWr.exists(addr) || InitMem.exists(addr)) begin
            if(IsWr[addr]) data = Mem[addr];
            else           data = InitMem[addr];
            return 1;
        end else begin
            data = 8'hxx;
            $display("Error mem read violation (no data is available) in %s at %t. TB file:%s line:%d", 
                                     this.full_name(), $time, `__FILE__, `__LINE__);
            return 0;
        end
    endfunction

    function bit write_one_elem(logic[7:0] data, longint addr);
        if(addr>=0) begin
            //$display("lineww addr:%0h, data:%0h", addr, data);
            Mem[addr]=data;
            IsWr[addr]=1;
            return 1;
        end else begin
            $display("Error mem write violation (not allocated space ) in %s at %t. TB file:%s line:%d", 
                                     this.full_name(), $time, `__FILE__, `__LINE__);
            return 0;
        end
    endfunction

    function void read_one_elem_deduce(input logic[7:0] data, input longint addr);
        //$display("lineww addr read:%0h, data:%0h", addr, data);
        if(IsWr.exists(addr) && IsWr[addr]) return;
        InitMem[addr] = data;
    endfunction
endclass

class REPLACE_WITH_MODULE_mem_trace_manager extends REPLACE_WITH_MODULE_trace_base_component;
    
    virtual REPLACE_WITH_MODULE_blk_ctrl_interface BlkCtrlIf;
    REPLACE_WITH_MODULE_mempage_trace pages[*];
    int rd_page_idx;
    int wr_page_idx;
    string mode;

    function new (string name, string hier_name);
        super.new(name, hier_name);
    endfunction

    virtual function void init();
        rd_page_idx = 0;
        wr_page_idx = 0;
        pages.delete();
        add_one_mempage();
    endfunction

    virtual function void cfg(string mode);
        this.mode = mode;
    endfunction

    virtual function void connect(virtual REPLACE_WITH_MODULE_blk_ctrl_interface BlkCtrlIf);
        this.BlkCtrlIf = BlkCtrlIf;
        this.BlkCtrlIf.mem_man_q.push_back(this);
        //this.init();
    endfunction

    virtual function void add_one_mempage(bit is_final=0);
        REPLACE_WITH_MODULE_mempage_trace onepage;
        if(is_final==0&&(mode=="tvdump"||mode=="tvread"&&rd_page_idx<this.BlkCtrlIf.ref_trans_cnt)) begin
            onepage = new($sformatf("%0dth_mempage",rd_page_idx), this.full_name());
            onepage.init(rd_page_idx, this.mode);
            pages[rd_page_idx] = onepage;
        end
        if(is_final && pages[rd_page_idx-1].InitMem.num()>0 && mode=="tvdump")
            $display("WARNNING: last trans' ap_ready is not received! This is weird design");
        if(rd_page_idx>0) pages[rd_page_idx-1].dump_chk(1);
        rd_page_idx++;
    endfunction

    virtual function void dump_one_mempage(bit is_final=0);
        if(is_final && pages[wr_page_idx].Mem.num()>0)
            $display("WARNNING: last trans' ap_done is not received! This is weird design");
        pages[wr_page_idx].dump_chk(2);
        wr_page_idx++;
        if(rd_page_idx==wr_page_idx && is_final==0)
            $display("WARNING: ap_ready i not asserted before ap_done! This is weird design");
    endfunction

    virtual function void put_data_called(REPLACE_WITH_MODULE_data_base_object data, string flag);
        REPLACE_WITH_MODULE_axi_trace_data d_cast;
        if( !$cast(d_cast, data) ) $display("Error, REPLACE_WITH_MODULE_data_base_object data can't be casted into REPLACE_WITH_MODULE_axi_trace_data in %s at %t. TB file:%s line:%d", this.full_name(), $time, `__FILE__, `__LINE__ );
        case(flag)
            "axi_brx_end"    : update_one_wr_transfer(d_cast);
            "feedback_rdata" : feedback_rdata_postproc(d_cast);
            "axi_rrx_end"    : update_one_rd_transfer(d_cast);
            "aww_both_rx"    : aww_both_rx_postproc(d_cast);
            default : $display("Error, undefined put_data_called flag in %s at %t. TB file:%s line:%d", this.full_name(), $time, `__FILE__, `__LINE__ );
        endcase
    endfunction

    virtual function void update_one_wr_transfer(REPLACE_WITH_MODULE_axi_trace_data tr);
        //$display( {"lineww_onewrtrans", tr.sprint()} );
        foreach(tr.addr[i]) void'(pages[wr_page_idx].write_one_elem(tr.data[i], tr.addr[i]));
    endfunction

    virtual function void update_one_rd_transfer(REPLACE_WITH_MODULE_axi_trace_data tr);
        //$display( {"lineww_onerdtrans", tr.sprint()} );
        //$display("rd_page_idx:%0d, pages.num:%0d", rd_page_idx, pages.num() );
        foreach(tr.addr[i]) void'(pages[rd_page_idx-1].read_one_elem_deduce(tr.data[i], tr.addr[i]));
    endfunction

    //feedback_rdata is usually used for physical driver to get the feedback rdata
    //So it is usually useless for mem manager or maybe can tell mem manager that
    //the data is now received by phy driver
    virtual function void feedback_rdata_postproc(REPLACE_WITH_MODULE_axi_trace_data tr);
    endfunction

    virtual function void aww_both_rx_postproc(REPLACE_WITH_MODULE_axi_trace_data tr);
    endfunction

    virtual function void get_data_called(REPLACE_WITH_MODULE_data_base_object data, string flag);
        REPLACE_WITH_MODULE_axi_trace_data d_cast;
        if( !$cast(d_cast, data) ) $display("Error, REPLACE_WITH_MODULE_data_base_object data can't be casted into REPLACE_WITH_MODULE_axi_trace_data in %s at %t. TB file:%s line:%d", this.full_name(), $time, `__FILE__, `__LINE__ );
        case(flag)
            "fetch_rdata" : fetch_one_rd_transfer(d_cast);
            default : $display("Error, undefined put_data_called flag in %s at %t. TB file:%s line:%d", this.full_name(), $time, `__FILE__, `__LINE__ );
        endcase
    endfunction

    virtual function void fetch_one_rd_transfer(REPLACE_WITH_MODULE_axi_trace_data tr);
        int bytenum = 1<<tr.size;
        longint addr = tr.addr[0];
        logic[7:0] data;
        tr.addr.delete();
        if(this.mode == "tvread") begin
            for(int i=0; i<tr.len; i++) begin
                for(int j = (i==0) ? (tr.addr[0] % bytenum) : 0; j<bytenum; j++) begin
                    void'(pages[rd_page_idx-1].read_one_elem(data, addr));
                    tr.addr.push_back(addr++);
                    tr.data.push_back(data);
                end
            end
        end
    endfunction

    virtual task run();
        fork
            forever begin
                wait(BlkCtrlIf.clkrst_if.rst===1);
                this.init();
                fork
                    forever begin
                        @(posedge BlkCtrlIf.clkrst_if.clk);
                        #1ps;
                        if(BlkCtrlIf.ap_ready===1&&BlkCtrlIf.ap_start===1) begin
                            $display("monitored ap_ready, add memory page%0d in %s at %t. TB file:%s line:%d", 
                                this.rd_page_idx-1, this.full_name(), $time, `__FILE__, `__LINE__ );
                            fork
                                begin
                                    @(posedge BlkCtrlIf.clkrst_if.clk);
                                    #0;
                                    add_one_mempage();
                                end
                                forever begin
                                    @(posedge BlkCtrlIf.clkrst_if.clk); //next or later cycle after ap_ready/ap_start, if sample ap_start
                                                                        //then we get a new start
                                    #1ps;
                                    if(BlkCtrlIf.ap_start===1) break;
                                end
                            join
                            if(mode=="tvread" && rd_page_idx==BlkCtrlIf.ref_trans_cnt) wait(0);
                        end
                    end
                    forever begin
                        @(posedge BlkCtrlIf.clkrst_if.clk);
                        #1ps;
                        if(BlkCtrlIf.ap_done===1) begin
                            $display("monitored ap_done, dump/chk memory page%0d in %s at %t. TB file:%s line:%d", 
                                this.wr_page_idx-1, this.full_name(), $time, `__FILE__, `__LINE__ );
                            fork
                                begin
                                    @(posedge BlkCtrlIf.clkrst_if.clk);
                                    #1ps; //ensure dump_one_mempage is called later than add_one_mempage if ap_ready/ap_done is asserted at the same time
                                    if(wr_page_idx<rd_page_idx) dump_one_mempage();
                                    else $display("FATAL ERROR: too many ap_dones are received before ap_ready");
                                end
                                forever begin
                                    @(posedge BlkCtrlIf.clkrst_if.clk);
                                    #1ps;
                                    if(BlkCtrlIf.ap_done===1 && BlkCtrlIf.ap_continue===1) break;
                                end
                            join
                            if(mode=="tvread" && wr_page_idx==BlkCtrlIf.ref_trans_cnt) wait(0);
                        end
                    end
                    begin
                        wait(BlkCtrlIf.clkrst_if.rst===0);
                    end
                join_any
                disable fork;
            end
        join
    endtask
endclass
`endif
