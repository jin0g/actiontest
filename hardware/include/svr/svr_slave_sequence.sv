// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.

`ifndef SVR_SLAVE_SEQUENCE__SV
	`define SVR_SLAVE_SEQUENCE__SV
    
	class svr_slave_sequence#(int DATA_WIDTH = 32) extends svr_base_sequence#(DATA_WIDTH);
        
		svr_transfer#(DATA_WIDTH) svr_trans;
        svr_config cfg;
        
        `uvm_object_param_utils_begin (svr_slave_sequence#(DATA_WIDTH))
        `uvm_object_utils_end
      
		function new (string name = "svr_slave_sequence");
			super.new(name);
			`uvm_info(this.get_full_name(), "new is called", UVM_LOW)
		endfunction
 
		virtual task body();
            uvm_object data;
			`uvm_info(this.get_full_name(), "body is called", UVM_LOW)
            if(!uvm_config_db #(svr_config)::get(m_sequencer, "", "cfg", cfg))
                `uvm_fatal(this.get_full_name(), "svr config must be set for cfg!!!")
			fork 
                begin
                    forever begin
                        int delay;
                        `uvm_info(this.get_full_name(), "receive data", UVM_DEBUG)
                        `uvm_create(svr_trans);

                        // if(isusr_delay==NO_DELAY) svr_trans.delay = 0;
                        // else if(usr_delay.size==0) begin
                        //     void'(std::randomize(delay) with {
                        //                 delay dist {1:=4, 0:=4, ii:=1, latency:=1, [0:latency]:/5};
                        //                 delay inside {[0:latency]};
                        //                                      });
                        //     svr_trans.delay = delay;
                        // end else begin
                        //     svr_trans.delay = usr_delay.pop_front();
                        //     if(isusr_delay==LEFT_ROUND_DELAY) usr_delay.push_back(svr_trans.delay);
                        // end
                        svr_trans.delay = cfg.clatency.get_transfer_lat();
                        `uvm_info(this.get_full_name(), {"send trans:", svr_trans.sprint}, UVM_MEDIUM)
                        `uvm_send(svr_trans);
                        //if (is_event_FINAL_AP_DONE()) begin
                        //    `uvm_info (this.get_full_name(), "received final AP_DONE", UVM_LOW)
                        //    break;
                        //end
                    end
                    
			     end
            join
		endtask
	endclass
    
`endif
