#ADC
set_property PACKAGE_PIN N22 [get_ports {dZmodADC_Data[0]}]
set_property PACKAGE_PIN L21 [get_ports {dZmodADC_Data[1]}]
set_property PACKAGE_PIN R16 [get_ports {dZmodADC_Data[2]}]
set_property PACKAGE_PIN J18 [get_ports {dZmodADC_Data[3]}]
set_property PACKAGE_PIN K18 [get_ports {dZmodADC_Data[4]}]
set_property PACKAGE_PIN L19 [get_ports {dZmodADC_Data[5]}]
set_property PACKAGE_PIN L18 [get_ports {dZmodADC_Data[6]}]
set_property PACKAGE_PIN L22 [get_ports {dZmodADC_Data[7]}]
set_property PACKAGE_PIN K20 [get_ports {dZmodADC_Data[8]}]
set_property PACKAGE_PIN P16 [get_ports {dZmodADC_Data[9]}]
set_property PACKAGE_PIN K19 [get_ports {dZmodADC_Data[10]}]
set_property PACKAGE_PIN J22 [get_ports {dZmodADC_Data[11]}]
set_property PACKAGE_PIN J21 [get_ports {dZmodADC_Data[12]}]
set_property PACKAGE_PIN P22 [get_ports {dZmodADC_Data[13]}]
set_property IOSTANDARD LVCMOS18 [get_ports -filter { name =~ dZmodADC_Data*}]


set_property PACKAGE_PIN N19 [get_ports ZmodAdcClkIn_p]
set_property IOSTANDARD DIFF_SSTL18_I [get_ports ZmodAdcClkIn_p]

set_property PACKAGE_PIN M21 [get_ports sZmodADC_CS]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodADC_CS]

set_property PACKAGE_PIN N20 [get_ports ZmodAdcClkIn_n]
set_property IOSTANDARD DIFF_SSTL18_I [get_ports ZmodAdcClkIn_n]

set_property PACKAGE_PIN R18 [get_ports sZmodADC_SDIO]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodADC_SDIO]

set_property PACKAGE_PIN M22 [get_ports iZmodSync]
set_property IOSTANDARD LVCMOS18 [get_ports iZmodSync]

set_property PACKAGE_PIN T18 [get_ports sZmodADC_Sclk]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodADC_Sclk]

set_property PACKAGE_PIN T16 [get_ports sZmodCh1CouplingH]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodCh1CouplingH]

set_property PACKAGE_PIN T17 [get_ports sZmodCh1CouplingL]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodCh1CouplingL]

set_property PACKAGE_PIN R19 [get_ports sZmodCh2CouplingH]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodCh2CouplingH]

set_property PACKAGE_PIN T19 [get_ports sZmodCh2CouplingL]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodCh2CouplingL]

set_property PACKAGE_PIN N15 [get_ports sZmodCh1GainH]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodCh1GainH]

set_property PACKAGE_PIN P15 [get_ports sZmodCh1GainL]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodCh1GainL]

set_property PACKAGE_PIN P17 [get_ports sZmodCh2GainH]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodCh2GainH]

set_property PACKAGE_PIN P18 [get_ports sZmodCh2GainL]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodCh2GainL]

set_property PACKAGE_PIN J20 [get_ports sZmodRelayComH]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodRelayComH]

set_property PACKAGE_PIN K21 [get_ports sZmodRelayComL]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodRelayComL]

set_property PACKAGE_PIN M19 [get_ports ZmodDcoClk]
set_property IOSTANDARD LVCMOS18 [get_ports ZmodDcoClk]

#create_generated_clock -name ZmodAdcClkIn_p -source [get_pins design_1_i/ZmodScopeController_0/U0/InstADC_ClkODDR/C] -divide_by 1 [get_ports ZmodAdcClkIn_p]