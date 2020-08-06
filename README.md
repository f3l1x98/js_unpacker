# js_unpacker

VERSION 0.1

Dart translation of jsbeautify's unpacker for Dean Edward's p.a.c.k.e.r

Python Version can be found  [here](https://github.com/beautify-web/js-beautify/blob/master/python/jsbeautifier/unpackers/packer.py)

## Usage

```dart
if(packer.detect(some_string)) {
  String unpacked = packer.unpack(some_string);
}
```
