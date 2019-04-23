import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// ### 记录项目日志、捕获项目错误、缓存所有记录、写入文件、上传服务器
/// * 初始化：
/// ```dart
/// ErrorLog.log = new ErrorLog(
///     reportZone: () async {
///         runApp(new MyApp());
///     },
///     debugMode: true,
///     uploadFile: (file) async {},
///     minutesWait: 30,
///     [fileName: 'error_log.txt']
/// );
/// ```
/// 
/// ### 项目日志
/// 默认标记的项目日志可以使用相应的方法；自定义标记的项目日志可以使用基础方法。
/// * 使用方式：
/// ```dart
/// ErrorLog.log.debug('msg'*8);
/// ErrorLog.log.info('msg'*8);
/// ErrorLog.log.warn('msg'*8);
/// ErrorLog.log.error('msg'*8);
/// ErrorLog.log.fatal('msg'*8);
/// ErrorLog.log.collectLog('msg'*8, 'error');  // 都是调用这个基础方法
/// ```
/// * 输出格式：
/// #### [2019-04-18 11:50:29.844858][error] msgmsgmsgmsgmsgmsgmsgmsg
/// 
/// ### 错误报告
/// 错误报告的信息比较多，标记为`report`。
/// * 使用方式：
/// 自动捕获错误，不包含 `try/catch`，不包含 `print`。
/// * 输出格式：
/// #### [2019-04-18 14:05:03.578755][report]
/// #### 所有错误信息
/// 
/// ### 写入文件
/// 所有记录都缓存在一个数组里，如果`debugMode`为真，打印到控制台；
/// 否则根据数组索引异步写入文件`error_log.txt`，在初始化时可传参`fileName`。
/// * 使用方式：
/// ```dart
/// ErrorLog.log.printBuffer();  // 打印记录缓存
/// ErrorLog.log.clearFile();    // 清空记录文件
/// ErrorLog.log.printFile();    // 打印文件内容
/// ```
/// 
/// ### 上传服务器
/// 打开应用时上传一次，然后设置计时器，建议30分钟上传一次。
/// * 使用方式：
/// 初始化时传参`uploadFile`和`minutesWait`，获取记录的文件`ErrorLog.log.logFile`。
/// 
class ErrorLog {

  /// 实例，静态属性
  static ErrorLog log;

  /// 捕获错误的区域
  Function _reportZone;

  /// 是否调试模式
  bool _debugMode;

  /// 缓存记录的数组
  List<String> _logBuffer;

  /// 文件记录
  File _logFile;
  File get logFile => _logFile;

  /// 文件记录的起点
  int _startIndex;

  /// 文件记录的终点
  int _endIndex;

  /// 上传记录文件
  Function _uploadFile;

  /// 上传时间间隔
  int _minutesWait;

  /// 记录文件是否变化
  bool _fileChange;

  /// 记录文件的名称
  String fileName;

  ErrorLog({
    @required Function reportZone, 
    @required bool debugMode,
    @required Function uploadFile,
    @required int minutesWait,
    this.fileName = 'error_log.txt'
  }) {
    
    _reportZone = reportZone;
    _debugMode = debugMode;
    _uploadFile = uploadFile;
    _minutesWait = minutesWait;
    
    init();

  }

  /// 初始化
  void init() async {

    _logBuffer = [];
    _startIndex = 0;
    _endIndex = 0;
    _fileChange = false;

    FlutterError.onError = (FlutterErrorDetails details) {
      reportError(details);
    };

    runZoned(
      _reportZone, 
      onError: (Object obj, StackTrace stack) {
        var details = makeDetails(obj, stack);
        reportError(details);
      }
    );

    _logFile = await _getLocalFile();
    info('应用启动成功。');

    if( !_debugMode ) _uploadFile(_logFile);
    Timer.periodic(Duration(minutes: _minutesWait), (timer) async {

      if ( _fileChange && !_debugMode ) {
        await _uploadFile(_logFile);
        _fileChange = false;
      }
      
    });

  }


  /// 错误报告
  void reportError(FlutterErrorDetails details) {

    String errorMeta = '[' + (new DateTime.now().toString()) + '][report]';
    _logBuffer.add(errorMeta + '\n' + details.toString());

    if (_debugMode) {
      print(errorMeta);
      print(details.toString());
    } else {
      _writeFile();
    }
    
  }

  /// 项目日志
  collectLog(String line, String label) {

    String contents = '[' + (new DateTime.now().toString()) + '][' + label + '] ' + line;
    _logBuffer.add(contents + '\n');

    if (_debugMode) {
      print(contents);
    } else {
      _writeFile();
    }
    
  }


  /// 打印文件
  Future<Null> printFile() async {
    _readLocalFile().then((contents) {
      print(contents);
    });
  }

  /// 打印缓存
  Future<Null> printBuffer() async {
    print( _logBuffer.toString() );
  }

  /// 清空文件
  Future<Null> clearFile() async {
    await _logFile.writeAsString('', mode: FileMode.write);
  }

  /// 实时写入文件，防止意外
  Future<Null> _writeFile() async {

    int len = _logBuffer.length;
    if (len > _endIndex) {
      _startIndex = _endIndex;
      _endIndex = len;
      Iterable<String> range = _logBuffer.getRange(_startIndex, _endIndex);
      await _writeLocalFile( range.join('\n') );
      _fileChange = true;
    } 

  }

  /// 获取文件
  Future<File> _getLocalFile() async {
    String dir = (await getApplicationDocumentsDirectory()).path;
    return new File('$dir/' + fileName);
  }

  /// 读取文件
  Future<String> _readLocalFile() async {
    String contents = await _logFile.readAsString();
    return contents;
  }

  /// 写入文件
  Future<Null> _writeLocalFile(String contents) async {
    await _logFile.writeAsString(contents, mode: FileMode.append, flush: false);
  }


  /// 构建错误信息
  FlutterErrorDetails makeDetails(Object obj, StackTrace stack) {
    return FlutterErrorDetails(exception: obj, stack: stack);
  }

  /// 调试
  void debug(String msg) {
    collectLog(msg, 'debug');
  }

  /// 信息
  void info(String msg) {
    collectLog(msg, 'info');
  }

  /// 警告
  void warn(String msg) {
    collectLog(msg, 'warn');
  }

  /// 错误
  void error(String msg) {
    collectLog(msg, 'error');
  }

  /// 致命错误
  void fatal(String msg) {
    collectLog(msg, 'fatal');
  }

}

