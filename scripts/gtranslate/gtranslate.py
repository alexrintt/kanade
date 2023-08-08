from googletranslatepy import Translator

def translate(text: str, translate_to: str, translate_from: str = 'en'):
    translator = Translator(target=translate_to, source=translate_from)
    translated = translator.translate(text)
    return translated
