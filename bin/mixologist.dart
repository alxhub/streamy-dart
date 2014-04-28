import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:streamy/mixologist.dart' as mixologist;

main(List<String> args) {
  var outputFile;
  var libraryName;
  var className;
  var mixins;
  var mixinDirs;
  
  var argp = new ArgParser()
    ..addOption('output-file',
        abbr: 'o',
        help: 'Path to the generated file to output',
        callback: (value) {
          outputFile = value;
        })
    ..addOption('output-library',
        abbr: 'l',
        help: 'Name of the generated library',
        callback: (value) {
          libraryName = value;
        })
    ..addOption('output-class',
        abbr: 'c',
        help: 'Name of the final generated class',
        callback: (value) {
          className = value;
        })
    ..addOption('mixin-dirs',
        abbr: 'i',
        help: 'Path to the directories which contains the potential mixins, ' +
            'comma separated',
        defaultsTo: 'lib/mixins',
        callback: (value) {
          mixinDirs = value;
        })
    ..addOption('mixins',
        abbr: 'm',
        help: 'List of mixins with which to build the output file',
        callback: (value) {
          mixins = (value == null) ? null : value.split(',');
        });
  argp.parse(args);
  if (outputFile == null || libraryName == null || className == null || mixinDirs == null || mixins == null) {
    print(argp.getUsage());
    return;
  }
  var mixinMap = {};
  mixinDirs
    .split(',')
    .map((path) => new Directory(path))
    .expand((dir) => dir.listSync())
    .where((entry) => entry is File)
    .where((entry) => entry.path.endsWith('.dart'))
    .forEach((entry) {
      var name = entry.path.split('/').last;
      name = name.substring(0, name.length - '.dart'.length);
      mixinMap[name] = entry;
    });
  Future.wait(mixins
      .map((name) => mixinMap[name])
      .map((file) => file.openRead())
      .map((stream) => stream.pipe(new mixologist.MixinReader())))
    .then((mixins) {
      var lines = <String>[
        "// Generated by the Streamy Mixologist.",
        "",
        "library $libraryName;", ''];
      lines.addAll(mixologist.writeImports(mixologist.unifyImports(mixins)));
      lines.add('');
      lines.addAll(new mixologist.LinearizedTarget(className, '', 'Object', mixins).linearize());
      lines.add('');
      return lines;
    })
    .then((lines) => (new File(outputFile).openWrite()
        ..write(lines.join("\n")))
        .close())
    .then((_) => print("Generated $outputFile."));
}
