import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'about.dart';
import 'country_details.dart';

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
      home: MyHomePage(title: 'DeLong Mobile App - Countries List'),
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
  Future<List<dynamic>?>? _countriesFuture;
  bool _isLoading = false;
  bool _isLoggedIn = false; // Flag to track user login status
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _loadData(); // Load data on initialization
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    // Simulate authentication with hardcoded credentials
    if (username == 'admin' && password == 'Password1') {
      await widget.localDataService.saveCredentials(username, password);
      setState(() {
        _isLoggedIn = true;
      });
      _loadData(); // Load country data only if logged in
    } else {
      // Show a snackbar indicating login failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed. Please check your credentials.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final countries = await widget.countryClient.getAllCountries();
      setState(() {
        _isLoading = false;
        _countriesFuture = Future.value(countries);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _countriesFuture = null; // Set countriesFuture to null on error
      });
    }
  }

  void _logout() async {
    await widget.localDataService.clearCredentials();
    setState(() {
      _isLoggedIn = false;
      _countriesFuture = null; // Clear country data on logout
    });
  }

  void _navigateToAboutPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AboutPage()),
    );
  }

  void _reloadData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reloading data...'),
        duration: Duration(seconds: 2),
      ),
    );

    await _loadData();
  }

  void _navigateToCountryDetails(
    Map<String, dynamic> countryData,
    String flagUrl,
    String countryName,
    String unMembership,
    String currency,
    String? coatOfArmsUrl,
    String googleMapsInfo,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CountryDetailsPage(
          countryData: countryData,
          flagUrl: flagUrl,
          countryName: countryName,
          unMembership: unMembership.toString(),
          currency: currency,
          coatOfArmsUrl: coatOfArmsUrl ?? 'Coat of Arms info not available',
          googleMapsInfo: googleMapsInfo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 80, 170, 245),
              const Color.fromARGB(255, 0, 6, 10)
            ],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: _isLoading
                  ? CircularProgressIndicator()
                  : _isLoggedIn
                      ? FutureBuilder<List<dynamic>?>(
                          future: _countriesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            }

                            final countries = snapshot.data as List<dynamic>?;
                            if (countries!.isEmpty) {
                              return Text('No data available');
                            }

                            if (snapshot.hasError || snapshot.data == null) {
                              return Text('Error: Failed to load countries');
                            }

                            return ListView.builder(
                              itemCount: countries.length,
                              itemBuilder: (context, index) {
                                final country = countries[index];
                                final officialName = country['name']
                                        ['official'] ??
                                    'No official name';
                                final languages = country['languages'] as Map?;
                                final language =
                                    languages != null && languages.isNotEmpty
                                        ? languages.values.first ??
                                            'Language not available'
                                        : 'Language not available';
                                final timezones = country['timezones'] as List?;
                                final timezone =
                                    timezones != null && timezones.isNotEmpty
                                        ? timezones.first ??
                                            'Timezone not available'
                                        : 'Timezone not available';
                                final capital = country['capital'] != null &&
                                        country['capital'].isNotEmpty
                                    ? country['capital'].first ??
                                        'Capital not available'
                                    : 'Capital not available';
                                final unMember = country['unMember'] != null
                                    ? country['unMember'].toString()
                                    : 'Not specified';
                                final flagUrl = country['flags']?['png'];

                                final currencies =
                                    country['currencies'] as Map?;
                                final currency =
                                    currencies != null && currencies.isNotEmpty
                                        ? currencies.values.first['name'] ??
                                            'Currency not available'
                                        : 'Currency not available';
                                final coatOfArmsUrl =
                                    country['coatOfArms']?['png'];
                                final googleMapsInfo = country['maps']
                                        ['googleMaps'] ??
                                    'Google Maps info not available';

                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ListTile(
                                        contentPadding: EdgeInsets.all(0),
                                        title: Text(
                                          officialName,
                                          style: TextStyle(
                                              color: Colors
                                                  .white), // Set text color to white
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Language: $language',
                                              style: TextStyle(
                                                  color: Colors
                                                      .white), // Set text color to white
                                            ),
                                            Text(
                                              'Timezone: $timezone',
                                              style: TextStyle(
                                                  color: Colors
                                                      .white), // Set text color to white
                                            ),
                                            Text(
                                              'Capital City: $capital',
                                              style: TextStyle(
                                                  color: Colors
                                                      .white), // Set text color to white
                                            ),
                                            Text(
                                              'UN Member: $unMember',
                                              style: TextStyle(
                                                  color: Colors
                                                      .white), // Set text color to white
                                            ),
                                          ],
                                        ),
                                        leading: flagUrl != null
                                            ? CircleAvatar(
                                                backgroundImage:
                                                    NetworkImage(flagUrl),
                                              )
                                            : null,
                                        onTap: () {
                                          _navigateToCountryDetails(
                                            {
                                              'languages': language,
                                              'timezones': timezone,
                                              'capital': capital,
                                              'unMember': unMember,
                                            },
                                            flagUrl,
                                            officialName,
                                            unMember,
                                            currency,
                                            coatOfArmsUrl,
                                            googleMapsInfo,
                                          );
                                        },
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              const Color.fromARGB(
                                                  255, 0, 6, 10),
                                              Color.fromARGB(255, 80, 170, 245)
                                            ],
                                          ),
                                        ),
                                        height: 3,
                                      )
                                    ],
                                  ),
                                );
                              },
                            );
                          })
                      : Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  labelStyle: TextStyle(color: Colors.white),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                                style: TextStyle(color: Colors.white),
                              ),
                              SizedBox(height: 20),
                              TextField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: TextStyle(color: Colors.white),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                                style: TextStyle(color: Colors.white),
                                obscureText: true,
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _login,
                                child: Text('Login'),
                              ),
                            ],
                          ),
                        ),
            ),
            if (!_isLoggedIn)
              Positioned(
                bottom: 8.0,
                left: 8.0,
                child: ElevatedButton(
                  onPressed: _navigateToAboutPage,
                  child: Text('About'),
                ),
              ),
            Positioned(
              bottom: 8.0,
              right: 8.0,
              child: _isLoggedIn
                  ? ElevatedButton(
                      onPressed: _reloadData,
                      child: Text('Reload'),
                    )
                  : Text(
                      'Version 1.1.6',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ],
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
