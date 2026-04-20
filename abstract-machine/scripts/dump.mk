OBJCOPY_BIN ?= $(CROSS_COMPILE)objcopy
FPGA_PACK   ?= $(AM_HOME)/scripts/fpga_pack.sh
DMEM_WORD_PACK ?= $(AM_HOME)/scripts/dmem_byte_to_word.awk

FPGA_DIR  ?= $(abspath $(AM_HOME)/../fpga)
FPGA_IMEM ?= $(FPGA_DIR)/Test_8_Instr.dat
FPGA_DMEM ?= $(FPGA_DIR)/prog1.hex
FPGA_DMEM_WORD ?= $(FPGA_DIR)/prog1_word.hex

FPGA_IMAGE_IMEM := $(IMAGE).imem.hex
FPGA_IMAGE_DMEM := $(IMAGE).dmem.hex

$(FPGA_IMAGE_IMEM) $(FPGA_IMAGE_DMEM): $(IMAGE).elf $(FPGA_PACK)
	@echo + PACK "->" $(shell realpath $(IMAGE).elf --relative-to .)
	@OBJCOPY=$(OBJCOPY_BIN) bash $(FPGA_PACK) $(IMAGE).elf $(FPGA_IMAGE_IMEM) $(FPGA_IMAGE_DMEM)

.PHONY: dump_hex dump fpga_image update_fpga update show_fpga_paths program_fpga

dump_hex dump fpga_image: $(FPGA_IMAGE_IMEM) $(FPGA_IMAGE_DMEM)

update_fpga update: dump_hex
	@mkdir -p $(FPGA_DIR)
	@cp $(FPGA_IMAGE_IMEM) $(FPGA_IMEM)
	@cp $(FPGA_IMAGE_DMEM) $(FPGA_DMEM)
	@awk -f $(DMEM_WORD_PACK) $(FPGA_DMEM) > $(FPGA_DMEM_WORD)
	@echo UPDATE $(shell realpath $(FPGA_IMEM) --relative-to .) $(shell realpath $(FPGA_DMEM) --relative-to .) $(shell realpath $(FPGA_DMEM_WORD) --relative-to .)

show_fpga_paths:
	@echo ELF:  $(IMAGE).elf
	@echo IMEM: $(FPGA_IMAGE_IMEM)
	@echo DMEM: $(FPGA_IMAGE_DMEM)
	@echo COPY_IMEM: $(FPGA_IMEM)
	@echo COPY_DMEM: $(FPGA_DMEM)
	@echo COPY_DMEM_WORD: $(FPGA_DMEM_WORD)

QUARTUS_PGM ?= quartus_pgm
CABLE       ?= USB-Blaster
SOF         ?=

program_fpga:
	@test -n "$(SOF)" || (echo "Usage: make program_fpga SOF=/abs/path/top.sof [CABLE=USB-Blaster]" && exit 1)
	@$(QUARTUS_PGM) -m jtag -c "$(CABLE)" -o "p;$(SOF)"
