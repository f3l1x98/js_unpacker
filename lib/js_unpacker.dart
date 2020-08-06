library js_unpacker;

//
// Dart translation of the python version
//
// Unpacker for Dean Edward's p.a.c.k.e.r, a part of javascript beautifier
//
// Coincidentally, it can defeat a couple of other eval-based compressors.
//
// usage:
//
// import 'package:js_unpacker/js_unpacker.dart' as packer;
//
// if(packer.detect(some_string)) {
//    String unpacked = packer.unpack(some_string);
// }
//
// REQUIRES sprintf: https://pub.dev/packages/sprintf Currently used Version: sprintf: ^4.1.0
//
//

import 'dart:math';
import 'package:sprintf/sprintf.dart';


String beginStr;
String endStr;

bool detect(String source){
  beginStr = '';
  endStr = '';
  int begin_offset = -1;
  //Detects whether `source` is P.A.C.K.E.R. coded.
  RegExp regExp = new RegExp(r"eval[ ]*\([ ]*function[ ]*\([ ]*p[ ]*,[ ]*a[ ]*,[ ]*c[ ]*,[ ]*k[ ]*,[ ]*e[ ]*,[ ]*");
  RegExpMatch match = regExp.firstMatch(source);
  if(match != null){
    begin_offset = match.start;
    beginStr = source.substring(0, begin_offset);
  }
  if(begin_offset != -1){
    // Find endstr
    String source_end = source.substring(begin_offset);
    List<String> parts = source_end.split("')))");
    if(parts[0].compareTo(source_end) == 0){
      if(parts.length > 1)
        endStr = source_end.split("}))")[1];
    } else {
      endStr = source_end.split("')))")[1];
    }
  }
  return (match != null);
}

unpack(String source){
  List<Object> argsList = _filterArgs(source);

  String payload = argsList[0].toString();
  List<String> symtab = argsList[1];
  int radix;
  int count;
  try{
    radix = int.parse(argsList[2]);
    count = int.parse(argsList[3]);
  } on FormatException catch(e) {
    throw UnpackingError('Corrupted p.a.c.k.e.r. data.');
  }

  if(count != symtab.length)
    throw UnpackingError('Malformed p.a.c.k.e.r. symtab.');

  JsUnpacker unpase = new JsUnpacker(radix);

  lookup(Match match){
    String word = match.group(0);
    String ret = symtab[unpase.unbase(word)];
    if(ret == null || ret.isEmpty)
      return word;
    else
      return ret;
  }

  RegExp regExp = new RegExp(r'\b\w+\b');
  source = payload.replaceAllMapped(regExp, lookup);

  var test = _replaceStrings(source);

  return test;
}

_filterArgs(String source){
  var juicers = [
    (r"}\('(.*)', *(\d+|\[\]), *(\d+), *'(.*)'\.split\('\|'\), *(\d+), *(.*)\)\)"),
    (r"}\('(.*)', *(\d+|\[\]), *(\d+), *'(.*)'\.split\('\|'\)"),
  ];

  for(var juicer in juicers){
    RegExp regExp = new RegExp(juicer, dotAll: true);
    RegExpMatch args = regExp.firstMatch(source);
    if(args != null){
      List<String> a = args.groups(List.generate(args.groupCount, (i) => i + 1));
      if(a[1].compareTo("[]") == 0)
        a[1] = '62';

      return [a[0], a[3].split('|'), a[1], a[2]];
    }
  }

  throw UnpackingError('Could not make sense of p.a.c.k.e.r data (unexpected code structure)');
}

_replaceStrings(String source){
  RegExp regExp = new RegExp(r'var *(_\w+)\=\["(.*?)"\];', dotAll: true);
  RegExpMatch match = regExp.firstMatch(source);

  if(match != null){
    List<String> varname, lookup = match.groups(List.generate(match.groupCount, (i) => i + 1));
    int startpoint = match.group(0).length;
    String variable = sprintf('%s[%%d]', varname);
    for(int i = 0; i < lookup.length; i++){
      source = source.replaceAll(sprintf(variable, [i]), '"${lookup[i]}"');
    }
    return source.substring(startpoint);
  }
  return beginStr + source + endStr;
}

class JsUnpacker{
  int base;
  Map dictionary;

  //Functor for a given base. Will efficiently convert strings to natural numbers.
  var ALPHABET = {
    62: '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
    95: (' !"#\$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~')
  };

  JsUnpacker(int base) {
    this.base = base;

    if(36 < base && base < 62){
      ALPHABET.putIfAbsent(base, () => ALPHABET[62].substring(0, base));
    }
    if(2 > base || base > 37){
      // create Dictionary conversion Map/dictionary
      dictionary = {};
      for(int i = 0; i < ALPHABET[base].length; i++){
        dictionary.putIfAbsent(ALPHABET[base][i], () => i);
      }
    }
  }

  unbase(String str){
    if(2 <= base && base <= 36)
      return int.parse(str, radix: base);
    else{
      return _dictunbaser;
    }
  }

  _dictunbaser(String str){
    //Decodes a  value to an integer.
    int ret = 0;
    for(int i = str.length - 1; i >= 0; i--){
      ret += (pow(base, i)) * dictionary[str[i]];
    }
    return ret;
  }

}

class UnpackingError implements Exception{
  String cause;

  UnpackingError(this.cause);
}
