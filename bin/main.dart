import 'dart:io';

import 'package:args/args.dart';
import 'package:publish_on_4pda/publish_on_4pda.dart' as publish_on_4pda;
import 'package:path/path.dart' as path;

const String helpText = '''
A command-line utility for publishing new release on 4pda.

Options:
-P, --pass-hash             "pass_hash" cookie header.
-M, --member-id             "member_id" cookie header.
-T, --topic-id              "topic_id" of topic where to post.
-C, --directory             Directory from which to take files.
-E, --dir-files-ext         Directory files filter by extension. Example:
                            --dir-files-ext apk
                            Only works with --directory option.
-F, --files                 Another approach to --directory with --dir-files-ext.
                            Uses only if --directory option doesn't exist.
                            Relative or absolute path to file to attach.
                            For multiple files: 
                            --files a,b 
                            OR 
                            --files a --files b
                            allow ext.: apk, apks, exe, zip, rar, obb, 7z, r00, r0
                            max files size: 192Mb
-V, --version-in-post       What to paste in "version" field in the post
-S, --short-description     What to paste in "short description" field in post
-D, --description           What to paste in "description" field in post
-N, --package-name          If you want to rename your files in style:
                            package-name + "." + version-in-post + "_" + arch (if .apk) + file-extension
                            If there is no arch in original filename pastes "arm7" by default.
                            Example result: "flibusta.0.6.5_arm7.apk"

Flags:
-h, --help                 Print this usage information.
''';

void main(List<String> arguments) async {
  var parser = ArgParser()
    ..addOption('package-name', abbr: 'N')
    ..addOption('pass-hash', abbr: 'P')
    ..addOption('member-id', abbr: 'M')
    ..addOption('topic-id', abbr: 'T')
    ..addOption('directory', abbr: 'C')
    ..addOption('dir-files-ext', abbr: 'E')
    ..addMultiOption('files', abbr: 'F')
    ..addOption('version-in-post', abbr: 'V')
    ..addOption('short-description', abbr: 'S')
    ..addOption('description', abbr: 'D')
    ..addFlag('help', abbr: 'h');

  var argResults = parser.parse(arguments);

  if (argResults['help'] == true) {
    print(helpText);
    return;
  }

  if (argResults['pass-hash'] == null ||
      argResults['member-id'] == null ||
      argResults['topic-id'] == null ||
      (argResults['files'] == null && argResults['directory'] == null)) {
    print(
        'Please, pass "pass-hash", "member-id", "topic-id" and "files" or "directory" options at least.');
    return;
  }

  var fileList = _getFiles(
    argResults['files'],
    argResults['directory'],
    argResults['dir-files-ext'],
  );

  if (fileList == null) {
    return;
  }

  if (fileList.isEmpty) {
    print('Files not found!');
    return;
  }

  print('Start Publishing');
  var publishResult = await publish_on_4pda.publishOn4pda(
    passHash: argResults['pass-hash'],
    memberId: argResults['member-id'],
    topicId: argResults['topic-id'],
    fileList: fileList,
    version: argResults['version-in-post'],
    shortDescription: argResults['short-description'],
    description: argResults['description'],
    packageName: argResults['package-name'],
  );
  if (publishResult == true) {
    print('Publish successful');
  } else {
    print('Publish failed');
  }
  print('Finish');
}

List<File> _getFiles(
  List<String> argFiles,
  String argDirectory,
  String argDirFilesExt,
) {
  List<File> fileList;
  fileList = [];

  if (argDirectory != null) {
    var dir = Directory(argDirectory.trim());

    if (!dir.existsSync()) {
      print('Directory $argDirectory doesn\'t exist');
      return null;
    }

    if (argDirFilesExt?.isNotEmpty == true) {
      if (!argDirFilesExt.startsWith('.')) {
        argDirFilesExt = '.' + argDirFilesExt;
      }
    }

    for (var entity in dir.listSync()) {
      if (entity is File) {
        if (argDirFilesExt?.isNotEmpty == true &&
            path.extension(entity.path).toLowerCase() != argDirFilesExt) {
          continue;
        }
        fileList.add(entity);
      }
    }
  } else if (argFiles != null) {
    for (var filePath in argFiles) {
      var file = File(filePath.trim());

      if (!file.existsSync()) {
        print('File $filePath doesn\'t exist');
        return null;
      }
      fileList.add(file);
    }
  }
  return fileList;
}
