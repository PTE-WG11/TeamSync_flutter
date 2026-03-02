使用远程接口命令：
在运行命令时直接通过 --dart-define 传入环境变量，这会拥有最高优先级：

```
flutter run -d chrome --web-port=8080 --web-hostname=10.0.0.61 
--dart-define=API_BASE_URL=http://ag.changfanai.com:8801/api
```
这样 api_client.dart 会直接使用你传入的 URL。



