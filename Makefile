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

love2d :
	@echo " ---> deleting previous release love2d folder"
	rm -rf -f $(RELEASE_DIR)/love2d
	mkdir -p $(RELEASE_DIR)/love2d

	@echo " ---> Copying assets and fils to love2d release folder"
	cp -r -u lua $(RELEASE_DIR)/love2d
	cp -r -u $(GAME_FOLDER) $(RELEASE_DIR)/love2d/game
	cp -r -u game* $(RELEASE_DIR)/love2d/
	cp -r -u default $(RELEASE_DIR)/love2d
	cp -u config.lua $(RELEASE_DIR)/love2d

	mv $(RELEASE_DIR)/love2d/lua/main.lua $(RELEASE_DIR)/love2d/ 
	
	@echo " ---> Launching game (Love2d)"
	cd $(RELEASE_DIR)/love2d && love .

build-love2d:
	echo 	"Make sure you run make love2d before packaging."
	cd 		$(RELEASE_DIR)/love2d && zip -9 -r $(PROJECT_NAME).love .
	love 	$(RELEASE_DIR)/love2d/$(PROJECT_NAME).love

run-serial :
	cd $(DC_ENGINE) && $(MAKE) console-serial

profile : 
	cd $(DC_ENGINE) && $(MAKE) generate-profile

dreamcast :
	cd $(DC_ENGINE) && $(MAKE) release

cdi :
	cd $(DC_ENGINE) && $(MAKE) cdi-new
	# sudo lxdream-nitro $(RELEASE_DIR)/$(PROJECT_NAME).cdi

engine :
	cd $(DC_ENGINE) && $(MAKE) engine
	@echo "Antiruins Built"

dependecy :
	./tools/install_deps.sh