import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:patrol_cli/src/base/extensions/platform.dart';
import 'package:patrol_cli/src/pubspec_reader.dart';
import 'package:platform/platform.dart';
import 'package:test/test.dart';

import '../src/common.dart';

const _pubspecBase = '''
name: example
description: A new Flutter project.
publish_to: none
version: 1.0.0+1
''';

void main() {
  _test(initFakePlatform(Platform.macOS));
  _test(initFakePlatform(Platform.windows));
}

void _test(Platform platform) {
  group('PubspecReader', () {
    late PubspecReader reader;
    late FileSystem fs;

    setUp(() {
      fs = MemoryFileSystem.test(style: platform.fileSystemStyle);
      final wd = fs.directory(fs.path.join('projects', 'awesome_app'))
        ..createSync(recursive: true);
      fs.currentDirectory = wd;

      reader = PubspecReader(projectRoot: fs.currentDirectory);
    });

    group('read()', () {
      test('returns empty config when `patrol` block does not exist', () async {
        fs.file('pubspec.yaml').writeAsStringSync(_pubspecBase);

        expect(
          await reader.read(),
          equals(PatrolPubspecConfig.empty(flutterPackageName: 'example')),
        );
      });

      test('reads top-level arguments', () async {
        fs.file('pubspec.yaml').writeAsStringSync('''
$_pubspecBase
patrol:
  app_name: Example
  flavor: dev
''');

        final config = await reader.read();
        expect(config.android.appName, equals('Example'));
        expect(config.ios.appName, equals('Example'));
        expect(config.android.flavor, equals('dev'));
        expect(config.ios.flavor, equals('dev'));
      });

      test('reads `android` block', () async {
        fs.file('pubspec.yaml').writeAsStringSync('''
$_pubspecBase
patrol:
  android:
    app_name: Example
    package_name: com.example.app
''');

        final config = await reader.read();
        expect(config.android.appName, equals('Example'));
        expect(config.android.packageName, equals('com.example.app'));
      });

      test('reads `ios` block', () async {
        fs.file('pubspec.yaml').writeAsStringSync('''
$_pubspecBase
patrol:
  ios:
    app_name: The Example
    bundle_id: com.example.ExampleApp
''');

        final config = await reader.read();
        expect(config.ios.appName, equals('The Example'));
        expect(config.ios.bundleId, equals('com.example.ExampleApp'));
      });

      test('overrides global values with platform-specific ones', () async {
        fs.file('pubspec.yaml').writeAsStringSync('''
$_pubspecBase
patrol:
  app_name: Example
  flavor: dev
  android:
    package_name: com.example.app
    flavor: devAndroid
  ios:
    app_name: The Example
    bundle_id: com.example.ExampleApp
    flavor: devApple
''');

        final config = await reader.read();
        expect(config.android.appName, equals('Example'));
        expect(config.android.packageName, equals('com.example.app'));
        expect(config.android.flavor, equals('devAndroid'));
        expect(config.ios.appName, equals('The Example'));
        expect(config.ios.bundleId, equals('com.example.ExampleApp'));
        expect(config.ios.flavor, equals('devApple'));
      });
    });
  });
}
