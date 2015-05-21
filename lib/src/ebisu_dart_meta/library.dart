part of ebisu.ebisu_dart_meta;

/// Defines a dart library - a collection of parts
class Library extends Object with CustomCodeBlock, Entity {

  /// Id for this library
  Id get id => _id;
  /// List of imports to be included by this library
  List<String> imports = [];
  /// List of parts in this library
  List<Part> parts = [];
  /// List of global variables for this library
  List<Variable> variables = [];
  /// Classes defined in this library
  List<Class> classes = [];
  /// Named benchmarks associated with this library
  List<Benchmark> benchmarks = [];
  /// Enums defined in this library
  List<Enum> enums = [];
  /// Name of the library file
  String get name => _name;
  /// Qualified name of the library used inside library and library parts - qualified to reduce collisions
  String get qualifiedName => _qualifiedName;
  /// If true includes logging support and a _logger
  bool includesLogger = false;
  /// If true this library is a test library to appear in test folder
  bool get isTest => _isTest;
  /// Code block inside main for custom code
  set mainCustomBlock(CodeBlock mainCustomBlock) =>
      _mainCustomBlock = mainCustomBlock;
  /// Set desired if generating just a lib and not a package
  String path;
  /// If set the main function
  String libMain;
  /// Default access for members
  Access defaultMemberAccess = Access.RW;
  /// If true classes will get library functions to construct forwarding to ctors
  bool hasCtorSansNew = false;

  // custom <class Library>

  Library(this._id) {
    _name = _id.snake;
    includesProtectBlock = true;
  }

  Iterable<Entity> get children =>
      concat([parts, variables, classes, benchmarks, enums]);

  List<Class> get allClasses {
    List<Class> result = new List.from(classes);
    parts.forEach((part) => result.addAll(part.classes));
    return result;
  }

  set isTest(bool t) {
    if (t) {
      _isTest = true;
      includesMain = true;
      includesLogger = true;
      imports.addAll([
        'package:logging/logging.dart',
        'package:test/test.dart',
        'package:args/args.dart',
      ]);
    }
  }

  String get _additionalPathParts {
    String rootPath = root.rootPath;
    List relPath = split(relative(dirname(libStubPath), from: rootPath));
    if (relPath.length > 0 &&
        (relPath.first == '.' || relPath.first == 'lib')) {
      relPath.removeAt(0);
    }
    return relPath.join('.');
  }

  String get _packageName => root.id.snake;

  String _makeQualifiedName() {
    var pathParts = _additionalPathParts;
    var pkgName = _packageName;
    String result = _id.snake;
    if (pathParts.length > 0) result = '$pathParts.$result';
    if (pkgName.length > 0) result = '$pkgName.$result';
    return result;
  }

  onOwnershipEstablished() {
    _qualifiedName =
        _qualifiedName == null ? _makeQualifiedName() : _qualifiedName;

    if (allClasses.any((c) => c.hasOpEquals)) {
      imports.add('package:quiver/core.dart');
    }
    if (allClasses.any((c) => c.hasJsonSupport)) {
      imports.add('"package:ebisu/ebisu.dart" as ebisu');
      imports.add('"dart:convert" as convert');
    }
    if (allClasses.any((c) => c.requiresEqualityHelpers == true)) {
      imports.add('package:collection/equality.dart');
    }
    if (includesLogger) {
      imports.add("package:logging/logging.dart");
    }
  }

  _ensureOwner() {
    if (owner == null) {
      owner = system('ignored');
    }
  }

  String get libStubPath => path != null
      ? "${path}/${id.snake}.dart"
      : (isTest
          ? "$rootPath/test/${id.snake}.dart"
          : "$rootPath/lib/${id.snake}.dart");

  void generate() {
    _ensureOwner();
    mergeWithDartFile('${_content}\n', libStubPath);
    parts.forEach((part) => part.generate());
    benchmarks.forEach((benchmark) => benchmark.generate());
  }

  /// Returns a string with all contents concatenated together
  get tar {
    _ensureOwner();
    return combine([_content, parts.map((p) => p._content)]);
  }

  get _content => br([
    brCompact([this.docComment, _libraryStatement]),
    brCompact(_clensedImports),
    _additionalImports,
    brCompact(_parts),
    _loggerInit,
    _enums,
    _classes,
    _variables,
    _libraryCustom,
    _libraryMain,
  ]);

  get _clensedImports =>
      cleanImports(imports.map((i) => importStatement(i)).toList());
  get _libraryStatement => 'library $qualifiedName;\n';
  get _additionalImports => customBlock('additional imports');
  get _parts => parts.length > 0
      ? ([]
    ..addAll(parts.map((p) => "part 'src/$name/${p.name}.dart';\n"))
    ..sort())
      : '';
  get _loggerInit =>
      includesLogger ? "final _logger = new Logger('$name');\n" : '';
  get _enums => enums.map((e) => '${chomp(e.define())}\n').join('\n');
  get _classes => classes.map((c) => '${chomp(c.define())}\n').join('\n');
  get _variables => variables.map((v) => chomp(v.define())).join('\n');

  set includesProtectBlock(bool value) =>
      customCodeBlock.tag = value ? 'library $name' : null;

  get _libraryCustom => indentBlock(blockText);

  get _initLogger => isTest
      ? r"""
  Logger.root.onRecord.listen((LogRecord r) =>
      print("${r.loggerName} [${r.level}]:\t${r.message}"));
  Logger.root.level = Level.OFF;
"""
      : '';

  get mainCustomBlock => _mainCustomBlock =
      _mainCustomBlock == null ? new CodeBlock(null) : _mainCustomBlock;

  withMainCustomBlock(f(CodeBlock cb)) => f(mainCustomBlock);

  get includesMain => _mainCustomBlock != null;

  set includesMain(bool im) =>
      _mainCustomBlock = (im && _mainCustomBlock == null)
          ? new CodeBlock(null)
          : im ? _mainCustomBlock : null;

  get _mainCustomText => _mainCustomBlock != null
      ? (_mainCustomBlock..tag = 'main').toString()
      : '';

  get _libraryMain => includesMain
      ? '''
main([List<String> args]) {
$_initLogger${_mainCustomText}
}'''
      : (libMain != null) ? libMain : '';

  static final _standardImports = new Set.from([
    'async',
    'chrome',
    'collection',
    'core',
    'crypto',
    'html',
    'indexed_db',
    'io',
    'isolate',
    'json',
    'math',
    'mirrors',
    'scalarlist',
    'svg',
    'uri',
    'utf',
    'web_audio',
    'web_sql',
    'convert',
    'typed_data',
  ]);

  static final _standardPackageImports = new Set.from([
    'args',
    'fixnum',
    'intl',
    'logging',
    'matcher',
    'meta',
    'mock',
    'scheduled_test',
    'serialization',
    'unittest',
    'test',
  ]);

  static final RegExp _hasQuotes = new RegExp(r'''[\'"]''');

  static String importUri(String uri) {
    if (null == _hasQuotes.firstMatch(uri)) {
      return '"${uri}"';
    } else {
      return '${uri}';
    }
  }

  static String importStatement(String i) {
    if (_standardImports.contains(i)) {
      return 'import "dart:$i";';
    } else if (_standardPackageImports.contains(i)) {
      return 'import "package:$i";';
    } else {
      return 'import ${importUri(i)};';
    }
  }

  String get rootPath => owner.rootPath;

  get _defaultAccess => defaultMemberAccess;

  // end <class Library>

  final Id _id;
  String _name;
  String _qualifiedName;
  bool _isTest = false;
  CodeBlock _mainCustomBlock;
}

// custom <part library>
// end <part library>
