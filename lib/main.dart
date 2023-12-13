import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Countries API Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Countries API Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final CountryClient countryClient = CountryClient();
  final LocalDataService localDataService =
      LocalDataService(); // Added LocalDataService

  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<dynamic>?> _countriesFuture;
  bool _isLoading = true;
  bool _isLoggedIn = false; // Flag to track user login status

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkLoginStatus();
    _initCredentials(); // Call method to set initial credentials
  }

  Future<void> _initCredentials() async {
    // Initialize with default credentials if not already present
    final credentials = await widget.localDataService.getCredentials();
    if (credentials == null) {
      await widget.localDataService.saveCredentials('admin', 'Password1');
    }
  }

  void _checkLoginStatus() async {
    final credentials = await widget.localDataService.getCredentials();
    if (credentials != null) {
      // Check if credentials exist and set login status accordingly
      setState(() {
        _isLoggedIn = true;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      final countries = await widget.countryClient.getAllCountries();
      setState(() {
        _isLoading = false;
        _countriesFuture = Future.value(countries);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _countriesFuture = Future.error(e.toString());
      });
    }
  }

  void _login() {
    setState(() {
      _isLoading = true;
    });

    // Simulating a login after 2 seconds
    Future.delayed(Duration(seconds: 2), () async {
      await widget.localDataService.saveCredentials('admin', 'Password1');
      setState(() {
        _isLoggedIn = true;
        _isLoading = false;
      });
    });
  }

  void _logout() {
    setState(() {
      _isLoading = true;
    });

    // Simulating a logout after 1 second
    Future.delayed(Duration(seconds: 1), () async {
      await widget.localDataService.clearCredentials();
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Show different actions based on login status
          _isLoggedIn
              ? IconButton(
                  icon: Icon(Icons.exit_to_app),
                  onPressed: _logout,
                )
              : IconButton(
                  icon: Icon(Icons.login),
                  onPressed: _login,
                ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              )
            : FutureBuilder<List<dynamic>?>(
                future: _countriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  final countries = snapshot.data as List<dynamic>?;
                  if (countries == null || countries.isEmpty) {
                    return Text('No data available');
                  }

                  return ListView.builder(
                    itemCount: countries.length,
                    itemBuilder: (context, index) {
                      final country = countries[index];
                      return ListTile(
                        title: Text(country['name']['common']),
                        // Add more details or customize the ListTile as needed
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class CountryClient {
  Future<List<dynamic>?> getAllCountries() async {
    try {
      final uri = Uri.parse('https://restcountries.com/v3.1/all');
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == HttpStatus.ok) {
        final responseBody = await response.transform(utf8.decoder).join();
        return json.decode(responseBody);
      } else {
        throw Exception('Failed to load countries');
      }
    } catch (e) {
      throw Exception('Failed to connect to the API');
    }
  }
}

class LocalDataService {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> saveCredentials(String username, String password) async {
    await _secureStorage.write(key: 'username', value: username);
    await _secureStorage.write(key: 'password', value: password);
  }

  Future<Map<String, String>?> getCredentials() async {
    final username = await _secureStorage.read(key: 'username');
    final password = await _secureStorage.read(key: 'password');
    if (username != null && password != null) {
      return {'username': username, 'password': password};
    }
    return null;
  }

  Future<void> clearCredentials() async {
    await _secureStorage.deleteAll();
  }
}
