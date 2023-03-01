PROJECT_NAME 		= antiruins
GAME_FOLDER 		= game

DATE 			= $(shell date +"%m-%d-%y")
VERSION 		= V01
TYPE 			= alpha

RELEASE_NAME 	= $(PROJECT_NAME)_$(VERSION)_$(DATE)
RELEASE_DIR 	= release

DC_ENGINE 		= dc/
project_folder 	= $(shell pwd)

EXCLUDE_TYPE 		= *.git* *.pio* *.cdi* *.iso* *.blend*
EXCLUDE_DIR			= "release/*" "dreamcast/*" "dc/*"
message?="No git message :("

.PHONY: dreamcast clean-dreamcast

clean:
	cd $(DC_ENGINE) && $(MAKE) clean
	cd $(RELEASE_DIR) && rm -rf dreamcast
	@echo "Cleaned .o and release/dreamcast"

$(PROJECT_NAME) :
	@echo Building antiruin $(TYPE) $(VERSION)


push-git : clean-dreamcast
	git add .
	git commit -m "$(message)"
	git push origin v2

pull-git : clean-dreamcast
	git pull origin v2

dreamcast :
	cd $(DC_ENGINE) && $(MAKE) console
	#$(MAKE) clean-dreamcast
	@echo "Dreamcast test is over & cleaned"

lxdream :
	cd $(DC_ENGINE) && $(MAKE) lxdream
	#$(MAKE) clean-dreamcast
	@echo "Dreamcast test is over & cleaned"

lxdream-nitro :
	cd $(DC_ENGINE) && $(MAKE) lxdream-nitro
	#$(MAKE) clean-dreamcast
	@echo "Dreamcast test is over & cleaned"

emulator :
	cd $(DC_ENGINE) && $(MAKE) reicast
	#$(MAKE) clean-dreamcast
	@echo "Dreamcast test is over & cleaned"

redream :
	cd $(DC_ENGINE) && $(MAKE) redream
	#$(MAKE) clean-dreamcast
	echo "Dreamcast test is over & cleaned"

build-dc :
	cd $(DC_ENGINE) && $(MAKE) build-cd
	# $(MAKE) clean-dreamcast
	echo "Dreamcast test is over & cleaned"

build-cdda :
	cd $(DC_ENGINE) && $(MAKE) build-cdda
	# $(MAKE) clean-dreamcast
	echo "Dreamcast test is over & cleaned"

gdemu : build-dc
	cp -f $(RELEASE_DIR)/$(PROJECT_NAME).cdi /media/magnes/GDEMU_BB/33/disc.cdi
	umount /media/magnes/GDEMU_BB

love2d :
	@echo " ---> deleting previous release love2d folder"
	rm -rf -f $(RELEASE_DIR)/love2d
	mkdir -p $(RELEASE_DIR)/love2d

	@echo " ---> Copying assets and fils to love2d release folder"
	cp -r -u lua $(RELEASE_DIR)/love2d
	--cp -r -u $(GAME_FOLDER) $(RELEASE_DIR)/love2d/game
	cp -r -u game* $(RELEASE_DIR)/love2d/
	cp -r -u default $(RELEASE_DIR)/love2d
	cp -u config.lua $(RELEASE_DIR)/love2d

	mv $(RELEASE_DIR)/love2d/lua/main.lua $(RELEASE_DIR)/love2d/ 
	
	@echo " ---> Launching game (Love2d)"
	cd $(RELEASE_DIR)/love2d && love .

build-love2d:
	echo "Make sure you run make love2d before packaging."
	cd $(RELEASE_DIR)/love2d && zip -9 -r $(PROJECT_NAME).love .

cdi :
	cd $(DC_ENGINE) && $(MAKE) build-cdi-new
	# sudo lxdream-nitro $(RELEASE_DIR)/$(PROJECT_NAME).cdi

engine :
	cd $(DC_ENGINE) && $(MAKE) build-engine build-cdi-new
	sudo lxdream-nitro $(RELEASE_DIR)/$(PROJECT_NAME).cdi
	#$(MAKE) clean-dreamcast
	@echo "Antiruins Built"

dependecy :
	./tools/install_deps.sh