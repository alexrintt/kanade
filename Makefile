# fvm? change it below
FLUTTER = flutter
DART = dart

flutter_app_module = modules/flutter_app
flutter_i18n_module = modules/flutter_i18n
flutter_i18n_auto_translate_module = modules/flutter_i18n/auto_translate
daemon_pkg = pkgs/daemon

.PHONY: setup dependencies test run generate dev clean

ifeq ($(OS),Windows_NT)
    RM = RD /S /Q
    FIXPATH = $(subst /,\,$1)
else
    RM = rm -rf
    FIXPATH = $1
endif

# SETUP ENVIROMENT
setup: setup-flutter-app setup-flutter-i18n setup-flutter-i18n-auto-translate setup-daemon-pkg

setup-flutter-app:
	cd $(flutter_app_module) && $(FLUTTER) pub get
	cd $(flutter_app_module) && $(DART) run build_runner build --delete-conflicting-outputs

setup-flutter-i18n:
	cd $(flutter_app_module) && $(FLUTTER) gen-l10n

setup-flutter-i18n-auto-translate:
	cd $(flutter_i18n_auto_translate_module) && $(DART) pub get

setup-daemon-pkg:
	cd $(daemon_pkg) && $(DART) pub get

# CODE GENERATION REQUIRED FOR DEVELOPMENT
gw: gen-code-watch gen-i18n-watch

gen-code-watch:
	cd $(flutter_app_module) && \
		$(DART) run build_runner watch --delete-conflicting-outputs

gen-i18n-watch:
	cd $(flutter_app_module) && \
		$(DART) run ../../pkgs/daemon/lib/daemon.dart --watch "../flutter_i18n/assets" --exec "flutter gen-l10n"

# CODE GENERATION REQUIRED AFTER DEVELOPMENT
gb: auto-translate

auto-translate:
	cd $(flutter_i18n_auto_translate_module) && dart run lib/auto_translate.dart

# Required only once or when configuring/changing resources
# gen-flutter-app-arts:
# 	cd $(flutter_app_module) && $(FLUTTER) pub get
# 	cd $(flutter_app_module) && $(DART) run flutter_launcher_icons
# 	cd $(flutter_app_module) && $(DART) run flutter_native_splash:create

# DEVELOPMENT
dev: gw