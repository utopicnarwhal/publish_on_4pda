import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart' as crypto;

Dio _dio;
Map<String, String> _defaultHeaders;

Future<bool> publishOn4pda({
  String topicId,
  String passHash,
  String memberId,
  List<File> fileList,
  String version,
  String shortDescription,
  String description,
  String packageName,
}) async {
  try {
    _initHttpClient(passHash, memberId, topicId);

    List<String> uploadedFilesId;
    uploadedFilesId = [];

    for (var file in fileList) {
      var fileId = await _attachFile(file, topicId, packageName, version);
      if (fileId == null) {
        print('Can\'t upload file');
        return false;
      }
      uploadedFilesId.add(fileId);
    }

    return await _submitNewPost(
      topicId,
      uploadedFilesId,
      version,
      shortDescription,
      description,
    );
  } catch (e) {
    print(e);
  }
  return false;
}

void _initHttpClient(String passHash, String memberId, String topicId) {
  _dio = Dio(
    BaseOptions(
      connectTimeout: 30000,
      receiveTimeout: 30000,
      sendTimeout: 30000,
      responseType: ResponseType.plain,
    ),
  );

  var cookieJar = CookieJar();
  cookieJar.saveFromResponse(
    Uri.https('4pda.ru', '/'),
    [
      Cookie('pass_hash', passHash),
      Cookie('member_id', memberId),
    ],
  );
  var cookieManager = CookieManager(cookieJar);
  _dio.interceptors.add(cookieManager);

  _defaultHeaders = {
    'accept': 'text/plain, */*; q=0.01',
    'accept-encoding': 'gzip, deflate, br',
    'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8',
    'origin': 'https://4pda.ru',
    'referer': 'https://4pda.ru/forum/index.php?showtopic=$topicId',
    'sec-fetch-site': 'same-origin',
    'user-agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36',
  };
}

Future<String> _attachFile(
  File fileToAttach,
  String topicId, [
  String packageName,
  String version,
]) async {
  var uri = Uri.https('4pda.ru', '/forum/index.php', {'act': 'attach'});
  var fileBytes = await fileToAttach.readAsBytes();
  var md5 = crypto.md5.convert(fileBytes);

  var newFileName = _genNewFileName(fileToAttach.path, packageName, version);

  var checkResponse = await _dio.postUri(
    uri,
    data: {
      'topic_id': topicId,
      'index': '1',
      'relId': '0',
      'maxSize': '201326592',
      'allowExt': 'apk,apks,exe,zip,rar,obb,7z,r00,r01',
      'md5': md5,
      'size': fileToAttach.lengthSync(),
      'name': newFileName,
      'code': 'check',
    },
    options: Options(
      method: 'POST',
      headers: _defaultHeaders,
      contentType: Headers.formUrlEncodedContentType,
      responseType: ResponseType.plain,
    ),
  );

  if (checkResponse.data is String) {
    String checkResponseString = checkResponse.data;
    if (checkResponseString != '0') {
      checkResponseString = checkResponseString.replaceAll('', '');
      checkResponseString = checkResponseString.replaceAll('', '');
      var result = checkResponseString.split('');

      if (result.length < 6) {
        print('UNACCEPTABLE FILE: ${fileToAttach.path}');
        return null;
      }

      print('File ${fileToAttach.path} exist on server');
      return result.first;
    }

    print('File ${fileToAttach.path} accepted');
  }

  var multipartFile = MultipartFile.fromBytes(
    fileBytes,
    filename: newFileName,
  );

  var uploadResponse = await _dio.postUri(
    uri,
    data: FormData.fromMap({
      'topic_id': '964348',
      'index': '1',
      'relId': '0',
      'maxSize': '201326592',
      'allowExt': 'apk,apks,exe,zip,rar,obb,7z,r00,r01',
      'code': 'upload',
      'FILE_UPLOAD[]': multipartFile,
    }),
    options: Options(
      method: 'POST',
      headers: _defaultHeaders,
      contentType: 'multipart/form-data',
      responseType: ResponseType.plain,
    ),
  );

  if (uploadResponse.data is String) {
    String uploadResponseString = uploadResponse.data;
    uploadResponseString = uploadResponseString.replaceAll('', '');
    uploadResponseString = uploadResponseString.replaceAll('', '');
    var result = uploadResponseString.split('');

    if (result.length < 6) {
      print('UNACCEPTABLE FILE: ${fileToAttach.path}');
      return null;
    }

    print('File ${fileToAttach.path} uploaded');
    return result.first;
  }

  return null;
}

String _genNewFileName(String filePath, String packageName, String version) {
  String newFileName;
  if (packageName != null && version != null) {
    newFileName = '$packageName.$version';

    if (path.extension(filePath).toLowerCase() == '.apk') {
      var filenameWithoutExt = path.basenameWithoutExtension(filePath);

      if (filenameWithoutExt.contains('x86_64')) {
        newFileName = newFileName + '_x86_64';
      } else if (filenameWithoutExt.contains('arm64-v8a')) {
        newFileName = newFileName + '_arm8';
      } else {
        newFileName = newFileName + '_arm7';
      }
    }

    newFileName = newFileName + path.extension(filePath);
  } else {
    newFileName = path.basename(filePath);
  }
  return newFileName;
}

Future<bool> _submitNewPost(
  String topicId,
  List<String> fileIdList,
  String version,
  String shortDescription,
  String description,
) async {
  var uri = Uri.https('4pda.ru', '/forum/index.php', {});

  var filesString = fileIdList.join(',');

  try {
    await _dio.postUri(
      uri,
      data: {
        'st': '0',
        'act': 'post',
        's': '',
        'removeattachid': '0',
        'MAX_FILE_SIZE': '0',
        'CODE': '3',
        'f': '318',
        't': topicId,
        'p': '0',
        'topic_id': topicId,
        'use-template-data': '1',
        'forum-template-field[0] id=': '1',
        'forum-template-field[1]': version ?? 'Не указана',
        'forum-template-field[2]': shortDescription ?? 'Не указано',
        'editor_ids[]': 'ed-1',
        'forum-template-field[3]': description ?? 'Нет описания',
        'file-list[1]': filesString,
        'forum-attach-files': filesString,
        '1_attach_box_index': '1',
        'enable-emo-sig-flag': '1',
        'enableemo': 'yes',
        'enablesig': 'yes',
      },
      options: Options(
        method: 'POST',
        headers: _defaultHeaders,
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
      ),
    );
  } on DioError catch (dioError) {
    if (dioError.response.statusCode == 302) {
      return true;
    }
  }

  return false;
}
