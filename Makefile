FLUTTER = flutter
DART = dart

flutter_app_module = modules/flutter_app
flutter_i18n_module = modules/flutter_i18n
flutter_i18n_auto_translate_module = modules/flutter_i18n/auto_translate

.PHONY: setup dependencies test run generate dev clean

ifeq ($(OS),Windows_NT)
    RM = RD /S /Q
    FIXPATH = $(subst /,\,$1)
else
    RM = rm -rf
    FIXPATH = $1
endif

# Default target
setup: dependencies generate

# Target to install dependencies
setup: setup-flutter-app setup-flutter-i18n setup-flutter-i18n-auto-translate

# Target to generate code
setup-flutter-app:
	cd $(flutter_app_module) && $(FLUTTER) pub get
	cd $(flutter_app_module) && $(DART) run build_runner build --delete-conflicting-outputs

# Target to generate code
setup-flutter-i18n:
	cd $(flutter_app_module) && $(FLUTTER) gen-l10n

setup-flutter-i18n-auto-translate:
	cd $(flutter_i18n_auto_translate_module) && $(RM) venv
	cd $(flutter_i18n_auto_translate_module) && ./venv/Scripts/activate
	cd $(flutter_i18n_auto_translate_module) && pip install -r requirements.txt


# Target to run code generation in watch mode
dev:
	@while true; do \
		find lib -name '*.dart' | \
		grep -v 'build/' | \
		inotifywait -e modify -e create -e delete && \
		make generate; \
	done

# Target to clean up
clean:
	@$(FLUTTER) clean


  # setup_flutter_i18n_auto_translate:
  #   runs-on: ubuntu-20.04
  #   steps:
  #     - uses: actions/checkout@v2
  #     - uses: subosito/flutter-action@v2
  #       with:
  #         channel: "stable"
  #     - name: Setup project
  #       steps:
  #         - name: "Delete venv on if it exists"
  #           working-directory: modules/flutter_i18n/auto_translate
  #           run: |-
  #             if [ -d "venv" ]; then
  #               rm -rf venv
  #             fi

  #         - name: "Create venv"
  #           shell: bash
  #           working-directory: modules/flutter_i18n/auto_translate
  #           run: |-
  #             python -m venv venv

  #         - name: "Install requirements"
  #           shell: bash
  #           working-directory: modules/flutter_i18n/auto_translate
  #           run: |-
  #             ./venv/Scripts/activate
  #             pip install -r requirements.txt
