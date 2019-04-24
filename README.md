# flutter_error_log

 ### 记录项目日志、捕获项目错误、缓存所有记录、写入文件、上传服务器
 * 初始化：
 ```dart
 ErrorLog.log = new ErrorLog(
     reportZone: () async {
         runApp(new MyApp());
     },
     debugMode: true,
     uploadFile: (file) async {},
     minutesWait: 30,
     [fileName: 'error_log.txt']
 );
 ```
 
 ### 项目日志
 默认标记的项目日志可以使用相应的方法；自定义标记的项目日志可以使用基础方法。
 * 使用方式：
 ```dart
 ErrorLog.log.debug('msg'*8);
 ErrorLog.log.info('msg'*8);
 ErrorLog.log.warn('msg'*8);
 ErrorLog.log.error('msg'*8);
 ErrorLog.log.fatal('msg'*8);
 ErrorLog.log.collectLog('msg'*8, 'error');  // 都是调用这个基础方法
 ```
 * 输出格式：
 #### [2019-04-18 11:50:29.844858][error] msgmsgmsgmsgmsgmsgmsgmsg
 
 ### 错误报告
 错误报告的信息比较多，标记为`report`。
 * 使用方式：
 自动捕获错误，不包含 `try/catch`，不包含 `print`。
 * 输出格式：
 #### [2019-04-18 14:05:03.578755][report]
 #### 所有错误信息
 
 ### 写入文件
 所有记录都缓存在一个数组里，如果`debugMode`为真，打印到控制台；
 否则根据数组索引异步写入文件`error_log.txt`，在初始化时可传参`fileName`。
 * 使用方式：
 ```dart
 ErrorLog.log.printBuffer();  // 打印记录缓存
 ErrorLog.log.clearFile();    // 清空记录文件
 ErrorLog.log.printFile();    // 打印文件内容
 ```
 
 ### 上传服务器
 打开应用时上传一次，然后设置计时器，建议30分钟上传一次。
 * 使用方式：
 初始化时传参`uploadFile`和`minutesWait`，获取记录的文件`ErrorLog.log.logFile`。

 ### 设备信息
 使用 [device_info](https://pub.dartlang.org/packages/device_info)，应用启动时会获取和记录。
 * 使用方式：
 ```dart
 await ErrorLog.log.getDeviceInfo();   // 异步返回设备信息
 ```
 * 输出格式：
 字符串，Future<String>
 #### [2019-04-24 10:05:11.413469][info] 设备信息 [device_info](https://pub.dartlang.org/packages/device_info)
 #### [androidInfo] androidId: 1a08f53b320ccfef, ...
 
