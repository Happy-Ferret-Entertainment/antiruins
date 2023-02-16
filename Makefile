project_name		= antiruins
project_name_linux	= antiruins
PROJECT_NAME 		= antiruins

DATE 			= $(shell date +"%m-%d-%y")
VERSION 		= V01
TYPE 			= alpha

RELEASE_NAME 	= $(project_name)_$(VERSION)_$(DATE)
RELEASE_DIR 	= release

DC_ENGINE 		= dc/
project_folder 	= $(shell pwd)

EXCLUDE_TYPE 		= *.git* *.pio* *.cdi* *.iso* *.blend*
EXCLUDE_DIR			= "release/*" "dreamcast/*" "dreamcast_build/*" "dc/*"
message?="No git message :("

.PHONY: dreamcast clean-dreamcast

clean:
	cd $(DC_ENGINE) && $(MAKE) clean
	cd $(RELEASE_DIR) && rm -rf dreamcast
	@echo "Cleaned .o and release/dreamcast"

$(project_name) :
	@echo Building antiruin $(TYPE) $(VERSION)


push-git : clean-dreamcast
	git add .
	git commit -m "$(message)"
	git push origin v2

pull-git : clean-dreamcast
	git pull origin v2

engine :
	cd $(DC_ENGINE) && $(MAKE) build-engine 
	cd $(RELEASE_DIR) && lxdream $(PROJECT_NAME).cdi
	#$(MAKE) clean-dreamcast
	@echo "Antiruins Built"

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
	#rm -rf -f $(RELEASE_DIR)/love2d
	#mkdir $(RELEASE_DIR)/love2d
	rsync -r -u lua $(RELEASE_DIR)/love2d
	rsync -r -u game $(RELEASE_DIR)/love2d
	rsync -r -u default $(RELEASE_DIR)/love2d
	mv $(RELEASE_DIR)/love2d/lua/main.lua $(RELEASE_DIR)/love2d/ 
	love $(RELEASE_DIR)/love2d

build-love2d:
	echo "Make sure you run make love2d before packaging."
	cd $(RELEASE_DIR)/love2d && zip -9 -r $(project_name).love .

cdi :
	cd $(DC_ENGINE) && $(MAKE) build-cdi-new
	cd $(RELEASE_DIR) && lxdream $(PROJECT_NAME).cdi

dependecy :
	./tools/install_deps.sh