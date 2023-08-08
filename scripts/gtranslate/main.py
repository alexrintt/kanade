import os

CONFIG_FILE_NAME = 'l10n.yaml'

def find_config_file_path(top: str = os.path.dirname(__file__)) -> str | None:
    for dirpath, dirnames, filenames in os.walk(topdown=True, top=top):
        for filename in filenames:
            if filename == CONFIG_FILE_NAME:
                return os.path.join(dirpath, filename)

    parent = os.path.dirname(top)

    if os.path.exists(parent):
        return find_config_file_path(parent)

    return None

config_file_path = find_config_file_path()

import yaml

with open(config_file_path, 'r', encoding='utf8') as config_file:
    config = yaml.safe_load(config_file)
    template_arb_file_name = config['template-arb-file']
    arb_dir_path = os.path.realpath(os.path.join(os.path.dirname(config_file_path), config['arb-dir']))
    arb_template_file_path = os.path.join(arb_dir_path, template_arb_file_name)

import json
from typing import Any
from gtranslate import translate
from hashlib import md5

def read_file_as_json(file_path: str) -> dict[str, Any]:
    with open(file_path, 'r', encoding='utf8') as file:
        return json.loads(file.read())

def write_file_as_json(file_path: str, data: dict[str, Any]) -> None:
    with open(file_path, 'w', encoding='utf8') as file:
        json.dump(data, file, indent=2, ensure_ascii=False)

base_i18n_data = read_file_as_json(arb_template_file_path)

def get_nested_value(nested_dict: dict[str, Any], *keys) -> Any:
    if len(keys) == 1:
        return nested_dict.get(keys[0])
    else:
        key = keys[0]
        if key in nested_dict:
            return get_nested_value(nested_dict[key], *keys[1:])
        else:
            return None

def set_nested_value(nested_dict, value, *keys):
    key = keys[0]
    if len(keys) == 1:
        nested_dict[key] = value
    else:
        if key not in nested_dict:
            nested_dict[key] = {}
        set_nested_value(nested_dict[key], value, *keys[1:])

for dirpath, dirnames, filenames in os.walk(arb_dir_path):
    cached = 0
    noncached = 0
    removed = 0

    for filename in filenames:
        if filename == template_arb_file_name: 
            continue

        target_lang_file_path = os.path.join(dirpath, filename)

        target_lang_file_data = read_file_as_json(target_lang_file_path)

        target_locale = target_lang_file_data['@@locale']

        def is_reserved_key(k: str) -> bool:
            RESERVED_PREFIXES = '_', '@'
            for prefix in RESERVED_PREFIXES:
                if k.startswith(prefix):
                    # Not a translation key
                    # pass
                    return True
            return False

        unused_keys = list(filter(lambda k: k not in base_i18n_data, target_lang_file_data.keys()))

        for unused_key in unused_keys:
            if is_reserved_key(unused_key):
                continue
            removed += 1
            print(f'removing key {unused_key}')
            del target_lang_file_data[unused_key]

        write_file_as_json(target_lang_file_path, target_lang_file_data)

        for base_lang_key, base_lang_source_value in base_i18n_data.items():
            if is_reserved_key(base_lang_key):
                continue

            print(f'Key: {base_lang_key}')
            print(f'Lang: {target_locale}')
            print(f'Original: {base_lang_source_value}')

            def get_cached_translation():
                has_translation = base_lang_key in target_lang_file_data and target_lang_file_data[base_lang_key] is not None

                base_lang_cached_source_value = get_nested_value(target_lang_file_data, f'@{base_lang_key}', 'info', 'source')
                same_source_value = has_translation and base_lang_source_value == base_lang_cached_source_value

                if same_source_value:
                    # return None
                    cached_translated = target_lang_file_data[base_lang_key]
                    return cached_translated
                else:
                    return None

            def startlower(s: str) -> bool:
                if len(s) <= 0:
                    return False
                return s[0] == s[0].lower()

            def firstupper(s: str) -> str:
                if len(s) <= 0:
                    return s
                return s[0].upper() + s[1:]

            def firstlower(s: str) -> str:
                if len(s) <= 0:
                    return s
                return s[0].lower() + s[1:]

            cached_translated = get_cached_translation()
            from_cache = cached_translated is not None
            translated = None

            if from_cache:
                cached += 1
                translated = cached_translated
            else:
                try:
                    noncached += 1
                    translated = translate(base_lang_source_value, translate_to=target_locale)
                except:
                    translated = None
                    print('Translated: [Translation not available, skipping...]')

            def normalize_case(translated: str, source: str) -> str:
                if startlower(source) != startlower(translated):
                    if startlower(source):
                        return firstlower(translated)
                    else:
                        return firstupper(translated)

                return translated

            transform_functions = [
                normalize_case
            ]

            if translated is not None:
                for transform in transform_functions:
                    translated = transform(translated, base_lang_source_value)

            if translated is None:
                print('Translated: [Translation not available, skipping...]')
            else:
                if from_cache:
                    print(f'Translated (cached): {translated}')
                else:
                    print(f'Translated: {translated}')

            target_lang_file_data[base_lang_key] = translated
            set_nested_value(target_lang_file_data, base_lang_source_value, f'@{base_lang_key}', 'info', 'source')

            # Even from cache, the transform functions were updated in this script and we need to update
            cache_changed = from_cache and cached_translated != translated

            # Translation loaded from network (third-party lib)
            from_network = not from_cache
            
            if cache_changed or from_network:
                write_file_as_json(target_lang_file_path, target_lang_file_data)

            print('-' * 30)

        write_file_as_json(target_lang_file_path, target_lang_file_data)

        print('*' * 30)
        print(f'Finished translating to {target_locale}')
        print('*' * 30)

    print('=' * 30)
    print(f'Loaded {noncached} non-cached results')
    print(f'Loaded {cached} cached results')
    print(f'Removed {removed} unused translation keys')
    print('=' * 30)
