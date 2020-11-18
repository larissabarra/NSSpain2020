BUNDLE=$(if $(rbenv > /dev/null), rbenv exec bundle, bundle)
FASTLANE=$(BUNDLE) exec fastlane
FRAMEWORKS_FOLDER=Carthage/PreBuiltFrameworks
CARTHAGE_FRAMEWORKS=ls Carthage/Build/iOS/*.framework | grep "\.framework" | cut -d "/" -f 4 | cut -d "." -f 1 | xargs -I '{}'
ROME_CACHE_FOLDER=~/Library/Caches/Rome/*
CARTHAGE_CACHE_FOLDER=~/Library/Caches/org.carthage.CarthageKit/*


#===========================#
#	Environment commands	#
#===========================#

install_xcode: ## install xcode
	$(FASTLANE) install_xcode

clean: ## clean project, archives and all dependencies caches
	carthage_clean 
	rome_clean 
	$(FASTLANE) clean

wipe: ## delete all cached outputs, kill and reset all simulators
	-rm -rf ~/Library/Developer/Xcode/{DerivedData,Archives,Products}
	-osascript -e 'tell application "iOS Simulator" to quit'
	-osascript -e 'tell application "Simulator" to quit'
	-xcrun simctl shutdown all
	-xcrun simctl erase all

reset_simulator: ## reset the iPhone simulator
	-osascript -e 'tell application "Simulator" to quit'
	-xcrun simctl shutdown all
	-xcrun simctl erase all


#===========================#
#		Setup commands		#
#===========================#

setup: ## install required tools
	cd scripts && ./setup.sh all && cd ..
	make install
	@echo "\033[1;33m"
	@echo "-----------------------------------------------------------"
	@echo "Restart all your terminals to ensure the setup takes effect"
	@echo "-----------------------------------------------------------"
	@echo "\033[0m"

install_bundle: ## install gems
	$(BUNDLE) install

install_certificates: ## fetch and install certificates
	$(FASTLANE) fetch_certificates

install: ## install gems, certificates, fetch prebuilt carthage frameworks
	install_bundle 
	carthage_bootstrap 
	install_certificates


#===========================#
#	Dependency management	#
#===========================#

carthage_bootstrap: ## bootstrap carthage frameworks
	@echo "Running Carthage bootstrap with Rome..."
	make rome_download
	carthage bootstrap --platform iOS --no-use-binaries --cache-builds
	make rome_upload

carthage_update: ## update carthage packages
	carthage update --platform iOS --no-use-binaries --cache-builds


carthage_copy: ## copy carthage frameworks
	$(CARTHAGE_FRAMEWORKS) env SCRIPT_INPUT_FILE_0=Carthage/build/iOS/'{}'.framework SCRIPT_INPUT_FILE_COUNT=1 carthage copy-frameworks

carthage_clean: ## clean carthage artifacts
	-rm -rf Carthage
	-rm -rf $(CARTHAGE_CACHE_FOLDER)
	-mkdir -p $(FRAMEWORKS_FOLDER)

#-------	Cache	 -------#

rome_clean: ## Clear all dependencies from Rome Cache
	-rm -rf $(ROME_CACHE_FOLDER)

rome_upload: ## Upload what is missing to Cache
	@echo "Updloading missing dependencies to Rome local cache"
	rome list --platform iOS | awk '{print $$1}' | xargs rome upload --platform iOS
	@echo "This will be used to check Carthage dependency updates in the future."

rome_download: ## Download missing frameworks (or copy from local cache)
	@echo "Download missing frameworks (copying from local cache)"
	rome download --platform iOS


#===========================#
#		Test commands		#
#===========================#

xcode_autocorrect_files: ## reformat and autocorrect all swift files in the project
	swiftlint autocorrect --format

lint: ## run lint
	$(FASTLANE) lint

unit_test: ## run unit tests
	$(FASTLANE) unit_test

ui_test: ## run UI tests
	$(FASTLANE) ui_test

retro_compatibility_test:
	$(FASTLANE) retro_compatibility_test

integration_test: 
	reset_simulator
	$(FASTLANE) integration_test


#===========================#
#		Build commands		#
#===========================#

build_dev: ## make the App.ipa with dev settings
	$(FASTLANE) build_ipa scheme:AppDev configuration:development

build_release: ## make the App.ipa with release settings
	$(FASTLANE) build_ipa scheme:AppInternalRelease configuration:adhoc

release_alpha: ## Update the build version release the Alpha IPA to Testflight
	$(FASTLANE) release_alpha

new_swimlane_testflight: ## Update the patch version and release the IPA to Testflight.
	$(FASTLANE) new_swimlane_testflight

release_testflight: ## release the IPA to Testflight
	$(FASTLANE) release_testflight

renew_certificates_and_provisioning: ## Renew all the Certificates and Provisioning profiles - Requires manually REVOKING of Certificates and Provisioning profiles.
	$(FASTLANE) new_certificates_and_provisioning_profiles
