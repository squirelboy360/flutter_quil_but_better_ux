import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quill Editor API Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: QuillEditorPage(),
    );
  }
}

class QuillEditorPage extends StatefulWidget {
  @override
  _QuillEditorPageState createState() => _QuillEditorPageState();
}

class _QuillEditorPageState extends State<QuillEditorPage> {
  late WebViewController _controller;
  String _apiContent = '<p>Initial content from API</p>';
  final _apiUpdateController = StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'QuillChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _updateApiFromJs(message.message);
        },
      )
      ..loadHtmlString(_getHtmlContent());

    // Simulate periodic API updates
    Timer.periodic(Duration(seconds: 10), (timer) {
      _simulateApiUpdate();
    });

    // Listen to API updates and update WebView
    _apiUpdateController.stream.listen((content) {
      _controller.runJavaScript("setContent('${_escapeJsString(content)}')");
    });
  }

  void _updateApiFromJs(String content) {
    setState(() {
      _apiContent = content;
    });
    print('API updated from JS: $content');
  }

  void _simulateApiUpdate() {
    final newContent = '<p>API update at ${DateTime.now()}</p>';
    setState(() {
      _apiContent = newContent;
    });
    _apiUpdateController.add(newContent);
    print('Simulated API update: $newContent');
  }

  String _getHtmlContent() {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
        <title>Quill Editor API Demo</title>
        <script src="https://cdn.quilljs.com/1.3.6/quill.js"></script>
        <link href="https://cdn.quilljs.com/1.3.6/quill.snow.css" rel="stylesheet">
        <style>
            body, html {
                margin: 0;
                padding: 0;
                height: 100%;
            }
            #editor {
                height: 400px;
            }
        </style>
    </head>
    <body>
        <div id="editor"></div>
        <script>
            var quill = new Quill('#editor', {
                theme: 'snow'
            });

            function setContent(content) {
                quill.root.innerHTML = content;
            }

            function sendToFlutter() {
                var content = quill.root.innerHTML;
                QuillChannel.postMessage(content);
            }

            quill.on('text-change', function() {
                sendToFlutter();
            });

            // Initial content set
            setContent('$_apiContent');
        </script>
    </body>
    </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quill Editor API Demo')),
      body: Column(
        children: [
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Current API Content:', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_apiContent),
          ),
          ElevatedButton(
            child: Text('Trigger API Update'),
            onPressed: _simulateApiUpdate,
          ),
        ],
      ),
    );
  }

  String _escapeJsString(String string) {
    return string
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
  }

  @override
  void dispose() {
    _apiUpdateController.close();
    super.dispose();
  }
}