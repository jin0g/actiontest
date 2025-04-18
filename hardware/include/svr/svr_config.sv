// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.

`ifndef SVR_CONFIG__SV
    `define SVR_CONFIG__SV
    
    class svr_config extends uvm_object;
        svr_inst_type           svr_type;
        svr_protocol_type       prt_type;
        svr_active_passive_enum is_active;
        svr_reset_level_enum    reset_level;
        svr_latency             clatency;
        svr_spec_cfg_enum       spec_cfg;

        `uvm_object_utils_begin(svr_config)
        `uvm_field_enum(svr_inst_type          , svr_type   , UVM_DEFAULT)
        `uvm_field_enum(svr_protocol_type      , prt_type   , UVM_DEFAULT)
        `uvm_field_enum(svr_active_passive_enum, is_active  , UVM_DEFAULT)
        `uvm_field_enum(svr_reset_level_enum   , reset_level, UVM_DEFAULT)
        `uvm_field_enum(svr_spec_cfg_enum      , spec_cfg   , UVM_DEFAULT)
        `uvm_field_object(clatency             , UVM_DEFAULT)
        `uvm_object_utils_end
        
        function new (string name = "svr_config");
            super.new(name);
            set_default();
        endfunction
        function void set_default();
            clatency    = svr_pkg::svr_latency::type_id::create( "clatency" );
        endfunction
    endclass
    
`endif
