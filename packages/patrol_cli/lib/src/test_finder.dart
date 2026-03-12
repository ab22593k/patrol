import 'package:collection/collection.dart';
import 'package:file/file.dart';
import 'package:patrol_cli/src/base/exceptions.dart';

const _kDefaultTestFileSuffix = '_test.dart';

/// Discovers integration tests.
class TestFinder {
  TestFinder({required Directory testDir})
    : _integrationTestDirectory = testDir,
      _fs = testDir.fileSystem..currentDirectory = testDir.parent;

  final Directory _integrationTestDirectory;
  final FileSystem _fs;

  Future<String> findTest(
    String target, [
    String testFileSuffix = _kDefaultTestFileSuffix,
  ]) async {
    final testFiles = await findTests([target], testFileSuffix);
    if (testFiles.length > 1) {
      throwToolExit(
        'target $target is ambiguous, '
        'it matches multiple test targets: ${testFiles.join(', ')}',
      );
    }

    return testFiles.single;
  }

  /// Checks that every element of [targets] is a valid target.
  ///
  /// A target is valid if it:
  ///
  ///  * is a path to a Dart test file, or
  ///
  ///  * is a path to a directory recursively containing at least one Dart test
  ///    file
  Future<List<String>> findTests(
    List<String> targets, [
    String testFileSuffix = _kDefaultTestFileSuffix,
  ]) async {
    final testFiles = <String>[];

    for (final target in targets) {
      if (target.endsWith(testFileSuffix)) {
        final isFile = await _fs.file(target).exists();
        if (!isFile) {
          throwToolExit('target file $target does not exist');
        }
        testFiles.add(_fs.file(target).absolute.path);
      } else if (await _fs.directory(target).exists()) {
        final foundTargets = await findAllTests(
          directory: _fs.directory(target),
          testFileSuffix: testFileSuffix,
        );
        if (foundTargets.isEmpty) {
          throwToolExit('target directory $target does not contain any tests');
        }

        testFiles.addAll(foundTargets);
      } else {
        throwToolExit(
          'target $target is invalid. Does your test file(s) end with "$testFileSuffix"?',
        );
      }
    }

    return testFiles;
  }

  /// Recursively searches the `integration_test` directory and returns files
  /// ending with defined [testFileSuffix]. If [testFileSuffix] is not defined,
  /// the default suffix `_test.dart` is used.
  Future<List<String>> findAllTests({
    Directory? directory,
    Set<String> excludes = const {},
    String testFileSuffix = _kDefaultTestFileSuffix,
  }) async {
    directory ??= _integrationTestDirectory;

    if (!await directory.exists()) {
      throwToolExit("Directory ${directory.path} doesn't exist");
    }

    final absoluteExcludes = excludes
        .map((e) => _fs.file(e).absolute.path)
        .toSet();

    final files = await directory
        .list(recursive: true, followLinks: false)
        .toList();

    return files
        .sorted((a, b) => a.path.compareTo(b.path))
        // Find only test files
        .where((fileSystemEntity) {
          final hasSuffix = fileSystemEntity.path.endsWith(testFileSuffix);
          final isFile = fileSystemEntity is File;
          return hasSuffix && isFile;
        })
        // Filter out excluded files
        .where((fileSystemEntity) {
          // TODO: Doesn't handle excluded passes as absolute paths
          final isExcluded = absoluteExcludes.contains(fileSystemEntity.path);
          return !isExcluded;
        })
        .map((entity) => entity.absolute.path)
        .toList();
  }
}
