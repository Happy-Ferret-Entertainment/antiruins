PROJECT_NAME 	= ANTIRUINS
RELEASE_DIR 	= release
MKDCDISC 			= tools/mkdcdisc
ENGINE_BINARY = antiruins.elf

NAME = "empty"

EXCLUDE_DIR = engine .git tools music Makefile README.md

# CDDA MUSIC
CDDA_FOLDER = music
CDDA_TRACKS = $(wildcard $(CDDA_FOLDER)/*) 		# Checks all the files in the music folder
CDDA 				= $(addprefix -c ,$(CDDA_TRACKS)) # Adds the -c prefix in front

# CONSOLE CONFIG
# different baudrates are 115200, 520833, 781250, 1562500
DC_TOOL_SERIAL 	= dc-tool-ser
SERIAL_PORT 		= /dev/ttyUSB0
BAUDRATE 				= 1562500

DC_TOOL_IP 			= dc-tool-ip
BBA_IP 					= 192.168.0.118

dependency:
	mkdir tools
	default/install_deps.sh

new:
	mkdir -p game_$(NAME)

	cp -r default/game.lua game_$(NAME)/game.lua
	mkdir -p game_$(NAME)/assets
	@echo "Created new project $(NAME)"

serial:
	sudo $(DC_TOOL_SERIAL) -t $(SERIAL_PORT) -b $(BAUDRATE) -c . -x $(ENGINE_BINARY) 2>err.log

bba:
	sudo $(DC_TOOL_IP) -t $(BBA_IP) -c . -x $(ENGINE_BINARY)

emulator:
	lxdream-nitro -u $(RELEASE_DIR)/$(PROJECT_NAME).cdi

cdi:
	@echo "---> Removing previous build"
	rm -f $(RELEASE_DIR)/$(PROJECT_NAME).cdi

	mkdir -p $(RELEASE_DIR)/dreamcast
	rsync $(addprefix --exclude ,$(EXCLUDE_DIR)) -r . $(RELEASE_DIR)/dreamcast
	
	rm -rf $(RELEASE_DIR)/dreamcast/release
	@echo "---> Building the .CDI"
	$(MKDCDISC) -v 3 -N -n $(PROJECT_NAME) $(CDDA) -d $(RELEASE_DIR)/dreamcast/ -e $(RELEASE_DIR)/dreamcast/$(ENGINE_BINARY) -o $(RELEASE_DIR)/$(PROJECT_NAME).cdi
