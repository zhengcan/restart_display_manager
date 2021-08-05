import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ssh2/ssh2.dart';

class Homepage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late SSHClient _client;
  String? _output;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _client = SSHClient(
      host: dotenv.env['HOST'] ?? '',
      port: int.tryParse(dotenv.env['PORT'] ?? '') ?? 22,
      username: dotenv.env['USERNAME'] ?? 'root',
      passwordOrKey: dotenv.env['PASSWORD'] ?? 'password',
    );
    _client.connect().whenComplete(() {
      setState(() {});
    });
  }

  void execute(String command) {
    _client.isConnected().then<bool>((connected) {
      if (!connected) {
        return _client.connect().then(
              (_) => _client.isConnected(),
            );
      } else {
        return true;
      }
    }).then((connected) {
      if (connected) {
        _client.execute(command).then((output) {
          setState(() {
            _output = (output?.isEmpty ?? true) ? '(empty)' : output;
            _errorMsg = null;
          });
        }, onError: (error) {
          setState(() {
            _output = null;
            _errorMsg = error.toString();
          });
        });
      } else {
        setState(() {
          _output = null;
          _errorMsg = 'Not connected';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Restart DisplayManager'),
      ),
      body: SafeArea(
        child: buildBody(context),
      ),
    );
  }

  Widget buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildServerInfo(context),
          Divider(),
          buildCheckKodiButton(context),
          buildCheckDisplayManagerButton(context),
          buildRestartDisplayManagerButton(context),
          Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_output != null)
                    Text(
                      _output!,
                      style: TextStyle(
                        color: Colors.green.shade800,
                      ),
                    ),
                  if (_errorMsg != null)
                    Text(
                      _errorMsg!,
                      style: TextStyle(
                        color: Colors.red.shade800,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCheckKodiButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        execute('ps aux | grep kodi');
      },
      child: Text('Check Kodi status'),
    );
  }

  Widget buildCheckDisplayManagerButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        execute('systemctl status display-manager.service --no-pager');
      },
      child: Text('Check DisplayManager status'),
    );
  }

  Widget buildRestartDisplayManagerButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        execute('systemctl restart display-manager.service');
      },
      child: Text('Restart DisplayManager'),
    );
  }

  Widget buildServerInfo(BuildContext context) {
    const style = TextStyle(height: 1.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'HOST: ${_client.host}',
          style: style,
        ),
        Text(
          'PORT: ${_client.port}',
          style: style,
        ),
        Text(
          'USER: ${_client.username}',
          style: style,
        ),
        FutureBuilder<bool>(
          future: _client.isConnected(),
          builder: (context, snapshot) {
            if (snapshot.data != null) {
              if (snapshot.data == true) {
                return Text(
                  'STATUS: Connected',
                  style: style,
                );
              } else {
                return Text(
                  'STATUS: Disconnected',
                  style: style,
                );
              }
            } else {
              return Text(
                'STATUS: Connecting',
                style: style,
              );
            }
          },
        ),
      ],
    );
  }
}
