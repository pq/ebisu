part of ebisu.ebisu_dart_meta;

/// Defines a dart *web* application. For non-web console app, use Script
class App extends Object with CustomCodeBlock, Entity {
  App(this._id);

  /// Id for this app
  Id get id => _id;

  /// Classes defined in this app
  List<Class> classes = [];

  /// List of libraries of this app
  List<Library> libraries = [];

  /// List of global variables for this library
  List<Variable> variables = [];

  /// If true this is a web ui app
  bool isWebUi = false;

  // custom <class App>

  /// Returns the children, including contained _classes_, _libraries_,
  /// _variables_ and any of their children recursively
  Iterable<Entity> get children => concat([classes, libraries, variables]);

  /// Returns the root path corresponding to the folder with the _pubspec.yaml_
  /// file
  String get rootPath => (rootEntity as System).rootPath;

  /// Generates the dart application
  void generate() {
    libraries.forEach((lib) => lib.generate());
    String appPath = "${rootPath}/web/${_id.snake}.dart";
    String appHtmlPath = "${rootPath}/web/${_id.snake}.html";
    String appCssPath = "${rootPath}/web/${_id.snake}.css";
    String appBuildPath = "${rootPath}/build.dart";
    mergeWithDartFile(_content, appPath);
    htmlMergeWithFile(
        '''<!DOCTYPE html>

<html>
  <head>
    <meta charset="utf-8">
    <title>${_id.title}</title>
    <link rel="stylesheet" href="${_id.snake}.css">
${htmlCustomBlock(id.toString() + ' head')}
  </head>
  <body>
${htmlCustomBlock(id.toString() + ' body')}
    <script type="application/dart" src="${_id.snake}.dart"></script>
    <script src="packages/browser/dart.js"></script>
  </body>
</html>
''',
        appHtmlPath);

    cssMergeWithFile(
        '''
body {
  background-color: #F8F8F8;
  font-family: 'Open Sans', sans-serif;
  font-size: 14px;
  font-weight: normal;
  line-height: 1.2em;
  margin: 15px;
}

h1, p {
  color: #333;
}

${cssCustomBlock(id.toString())}
''',
        appCssPath);

    mergeWithDartFile(
        '''
import 'dart:io';
import 'package:polymer/component_build.dart';

main() {
  build(Platform.arguments, ['web/${_id.snake}.html']);
}
''',
        appBuildPath);
  }

  get _content => brCompact([
        "import 'package:mdv/mdv.dart' as mdv;",
        brCompact(classes.forEach((c) => c.definition())),
        '''
void main() {
  mdv.initialize();
}
'''
      ]);

  // end <class App>

  final Id _id;
}

// custom <part app>
// end <part app>
