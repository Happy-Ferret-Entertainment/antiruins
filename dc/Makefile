PROJECT_NAME 		= antiruins
TARGET 				= main.elf

DIR 				= $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
RELEASE_DIR			= ../release
BUILD_DIR 			= $(RELEASE_DIR)/dreamcast

#Mostly used for IP.BIN and some emulators.
TOOL_DIR 			= /home/magnes/Dreamcast
IPBIN				= ../dc/IP.BIN
MKDCDISC			= ./../tools/mkdcdisc/build/mkdcdisc

CRAYONVMU = crayonVMU/setup.o crayonVMU/savefile.o

#DC engine objects
OBJS = main.o luadc.o utils.o audio.o graphics.o input.o gameworld.o
OBJS += sh4_math.o saveload.o vmu.o profiler.o
OBJS += $(CRAYONVMU)

# Externals libraries
INCLUDE_DIR 	= -I$(KOS_PORTS)/include/lua -I$(KOS_BASE)/include -I$(KOS_BASE)/addons

# Excluded from the CD generation
EXCLUDE_DIR 	= -m .git -m RAW

KOS_CFLAGS += -std=gnu11
# SH4 MATH
SH4_FLAGS 	= -ffreestanding -mpretend-cmove -m4-single-only -Os -ffp-contract=fast -fno-unsafe-math-optimizations
IAN_FLAGS 	= -Wall -g -ml -m4-single-only -ffast-math -fno-builtin -fno-strict-aliasing -fno-optimize-sibling-calls -funroll-all-loops -funroll-loops -DFRAME_POINTERS -fno-omit-frame-pointer -falign-functions=32 -falign-labels=32 -falign-loops=32 -falign-jumps=32
KOS_EXTRA_FLAGS = $(KOS_LDFLAGS)

# Adding all the other flags
KOS_CFLAGS += $(INCLUDE_DIR) $(SH4_FLAGS)

LBASIZE = 0

include $(KOS_BASE)/Makefile.rules
all: rm-elf $(TARGET)


clean:
	@$(RM) $(TARGET) $(OBJS) romdisk.* *.cdi *.iso *.img *.gz
	@$(RM) -r $(BUILD_DIR)

rm-elf:
	@$(RM) $(TARGET) romdisk.*

$(TARGET): $(OBJS)
	$(KOS_CC) $(KOS_CFLAGS) $(KOS_LDFLAGS) $(IAN_FLAGS) $(SH4_FLAGS) -o $(TARGET) $(KOS_START) \
	$(OBJS) $(OBJEXTRA) -lpng -llua -ldreamroq -lGLdc -lmp3_new -loggvorbisplay -lvorbis -logg -lm -lz  $(KOS_LIBS)

#make a bunch of romdisk here
romdisk.img: FORCE
	$(KOS_GENROMFS) -f ../asset/romdisk.img 			-d ../asset/romdisk

	# This is for each MAP romdisk. Not useful for antiruins
	# $(foreach var, $(MAP), $(KOS_GENROMFS) -f ../asset/rd_$(var).img -d ../asset/map_$(var);)

romdisk.o: romdisk.img
	$(KOS_BASE)/utils/bin2o/bin2o ../asset/romdisk.img romdisk romdisk.o

run: $(TARGET)
	$(KOS_LOADER) $(TARGET)

build-engine: rebuildmain $(TARGET)
	# Wonderful

build-cdi-new:
	@echo "---> Make sure the directory exist"
	mkdir -p $(BUILD_DIR)
	@echo "---> Copy the dreamcast basics"
	cp -u $(TARGET) $(IPBIN) $(BUILD_DIR)
	@echo "---> Copy LUA files"
	cp -u -r ../lua "$(BUILD_DIR)"   
	@echo "---> Copy the game files"
	cp -u -r ../game "$(BUILD_DIR)" 

	@# -e .elf file 
	@echo "---> Building the .CDI"
	$(MKDCDISC) -n $(PROJECT_NAME) -d $(BUILD_DIR)/ -e $(BUILD_DIR)/$(TARGET) -o $(RELEASE_DIR)/$(PROJECT_NAME).cdi

build-cdi:
	@echo "---> Make sure the directory exist"
	mkdir -p $(BUILD_DIR)
	@echo "---> Copy the dreamcast basics"
	cp -u $(TARGET) $(IPBIN) $(BUILD_DIR)
	@echo "---> Copy LUA files"
	cp -u -r ../lua "$(BUILD_DIR)"   
	@echo "---> Copy the game files"
	cp -u -r ../game "$(BUILD_DIR)"

	@cd $(BUILD_DIR) && \
	sh-elf-objcopy -R .stack -O binary $(TARGET) output.bin && \
	$(KOS_BASE)/utils/scramble/scramble output.bin 1ST_READ.BIN && \
	mkisofs -C 0,11702 -V $(PROJECT_NAME) -G IP.BIN -r -J -l $(EXCLUDE_DIR) -o ../$(PROJECT_NAME).iso .

	@cd $(BUILD_DIR) && \
	$(KOS_BASE)/utils/cdi4dc/cdi4dc ../$(PROJECT_NAME).iso ../$(PROJECT_NAME).cdi > null.txt && rm null.txt

build-cdda: rebuildmain $(TARGET)

	$(RM) $(OBJS)

	@# Make sure the directory exist
	@mkdir -p $(BUILD_DIR)
	# ---> Copy the dreamcast basics
	@cp -u $(BUILD_DIR) -r $(TARGET) $(IPBIN)
	# ---> Copy LUA files
	@cp -u $(BUILD_DIR) -r ../*.lua ../LANTERN_ENGINE
	# ---> Copy the assets
	@cp -u -$(BUILD_DIR) -r ../asset

	# Remove OGG files
	rm -rf $(BUILD_DIR)/asset/sounds/bgm/*.ogg

	# Build CCDA
	./tools/build-cdda.sh

reicast: build-cd
	cd $(RELEASE_DIR) && reicast $(PROJECT_NAME).cdi

redream: build-cd
	cd $(RELEASE_DIR) && sudo redream $(PROJECT_NAME).cdi

lxdream: build-cd
	cd $(RELEASE_DIR) && lxdream $(PROJECT_NAME).cdi

lxdream-nitro: build-cd
	cd $(RELEASE_DIR) && lxdream-nitro $(PROJECT_NAME).cdi

console: $(TARGET)

	# Make sure the directory exist
	mkdir -p $(BUILD_DIR)
	# Copy the dreamcast basics
	cp -u -t $(BUILD_DIR) -r $(TARGET) $(IPBIN)
	# Copy LUA files
	cp -u -t $(BUILD_DIR) -r ../*.lua ../LANTERN_ENGINE
	# Copy the assets
	cp -u -t $(BUILD_DIR) -r ../asset

	cd $(BUILD_DIR) && \
	sh-elf-objcopy -R .stack -O binary $(TARGET) output.bin

	@sudo arp -s 192.168.1.99 00:d0:f1:03:14:02
	sudo $(TOOL_DIR)/dc-tool-ip -t 192.168.1.99 -c $(BUILD_DIR) -x $(BUILD_DIR)/$(TARGET) 2>err.log

	#sudo $(TOOL_DIR)/dc-tool-ip_1nano -t 192.168.1.99 -c $(BUILD_DIR) -x $(BUILD_DIR)/$(TARGET) 2>err.log
	#@sudo umount $(BUILD_DIR)/build/asset

#foreach exemple!
assets:
	#../tools/convertToDtex.sh ../asset/map_panneau/spritesheet.png
	$(foreach var,$(MAP_FOLDER), ../tools/convertToDtex.sh $(var)/spritesheet.png;)

dist:
	rm -f $(OBJS) romdisk.o romdisk.img
	$(KOS_STRIP) $(TARGET)

rebuildmain:
	$(RM) $(OBJS)

FORCE:
