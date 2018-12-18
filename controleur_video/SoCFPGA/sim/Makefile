# Squelette de Makefile pour le projet Video
#
.PHONY: clean all simu_batch compile simu_gui info

# WORKDIR est le répertoire de simulation
WORKDIR = $(shell pwd)/work
# TOPDIR est le répertoire principal (le dépot git de vos travaux)
TOPDIR = $(realpath $(shell pwd)/../..)

# Le module top a simuler
TB_TOP = tb_Top

VLOG     := vlog
VLOG_OPT ?= +acc -l comp.log -timescale "1ns/1ps"  

VSIM     := vsim
VSIM_OPT := -lib work -L altera_lnsim_ver
VLOG_DEFINE := +define+IMAGE_FILE=\"$(PROJECT_DIR)/tb_src/image.hex\"

# Sources
VPATH := $(TOPDIR)/ips/interfaces:$(TOPDIR)/SoCFPGA/tb_src:$(TOPDIR)/SoCFPGA/src:$(TOPDIR)/ips/hws:$(TOPDIR)/ips/sys_pll:$(TOPDIR)/ips/sys_pll/sys_pll:$(TOPDIR)/ips/fifos

SRC       = $(wildcard $(TOPDIR)/ips/interfaces/*.sv)
SRC      += $(wildcard $(TOPDIR)/ips/sys_pll/*.v)
SRC      += $(wildcard $(TOPDIR)/ips/sys_pll/*/*.v)
SRC      += $(TOPDIR)/ips/hws/hw_support.sv
SRC      += $(wildcard $(TOPDIR)/ips/fifos/*.sv)
SRC      += $(wildcard $(TOPDIR)/SoCFPGA/tb_src/*.sv)
SRC      += $(wildcard $(TOPDIR)/SoCFPGA/src/*.sv)

DEP       = $(patsubst %.sv,$(WORKDIR)/.%.compiled,$(notdir ${SRC}))
DEP      += $(patsubst %.v,$(WORKDIR)/.%.compiled,$(notdir ${SRC}))

info:
	@echo "Les commandes possibles sont:"
	@echo "make compile    : compilation des codes (module à tester et testbenchs)"
	@echo "make simu_batch : simulation en mode terminal, avec simple affichage des résultats des tests"
	@echo "make simu_gui   : simulation en mode graphique pour faire un debug de votre code."
	@echo "make all        : équivalent à simu_gui"
	@echo "make info       : ce message"
	@echo "make clean      : nettoyage des fichiers inutiles"

all: simu_batch

simu_batch: compile
	cd $(WORKDIR) ; $(VSIM) $(VSIM_OPT)  -batch $(TB_TOP) -do "run -all ; quit"

simu_gui: compile
	cd $(WORKDIR); $(VSIM) $(VSIM_OPT)  $(TB_TOP)

compile: $(DEP)

$(WORKDIR)/.%.compiled: %.sv | $(WORKDIR)
	cd $(WORKDIR) ; vlog  +acc +define+SIMULATION $< 
	touch $@

$(WORKDIR)/.%.compiled: %.v | $(WORKDIR)
	cd $(WORKDIR) ; vlog  +acc +define+SIMULATION $< 
	touch $@

$(WORKDIR):
	mkdir -p $(WORKDIR) 

clean:
	rm -rf $(WORKDIR)

