export DESIGN_NAME = fft_8point_top
export DESIGN_NICKNAME = fft8
export PLATFORM = sky130hd

export VERILOG_FILES = $(DESIGN_HOME)/src/$(DESIGN_NICKNAME)/DITFFT_8_point.v
export SDC_FILE = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/constraint.sdc

export DIE_AREA = 0 0 310 310
export CORE_AREA = 10 10 300 300
