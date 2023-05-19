import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

import 'package:url_launcher/url_launcher.dart';

import 'screens/home_screen.dart';

// These URLs are endpoints that are provided by the authorization
// server. They're usually included in the server's documentation of its
// OAuth2 API.
final authorizationEndpoint =
    Uri.parse('https://connect.smartcar.com/oauth/authorize?mode=test');
final tokenEndpoint = Uri.parse('https://auth.smartcar.com/oauth/token');
// The authorization server will issue each client a separate client
// identifier and secret, which allows the server to tell which client
// is accessing it. Some servers may also have an anonymous
// identifier/secret pair that any client may use.
//
// Note that clients whose source code or binary executable is readily
// available may not be able to make sure the client secret is kept a
// secret. This is fine; OAuth2 servers generally won't rely on knowing
// with certainty that a client is who it claims to be.
const identifier = '1ac97b37-88a7-42e6-9963-f066664649a7';
const secret = '9c429145-464f-4834-81ac-ceb3c9c124bf';

// This is a URL on your application's server. The authorization server
// will redirect the resource owner here once they've authorized the
// client. The redirection will include the authorization code in the
// query parameters.

// final redirectUrl =
//     Uri.parse('sc1ac97b37-88a7-42e6-9963-f066664649a7://callback');
final redirectUrl = Uri.parse('http://localhost:8000/exchange');

/// A file in which the users credentials are stored persistently. If the server
/// issues a refresh token allowing the client to refresh outdated credentials,
/// these may be valid indefinitely, meaning the user never has to
/// re-authenticate.
// final credentialsFile = File(path.join(
//   Directory.current.path,
//   'credentials',
//   'credentials.json',
// ));

/// Either load an OAuth2 client from saved credentials or authenticate a new
/// one.
Future<oauth2.Client> createClient() async {
  // var exists = await credentialsFile.exists();

  // // If the OAuth2 credentials have already been saved from a previous run, we
  // // just want to reload them.
  // if (exists) {
  //   var credentials =
  //       oauth2.Credentials.fromJson(await credentialsFile.readAsString());
  //   return oauth2.Client(credentials, identifier: identifier, secret: secret);
  // }

  // If we don't have OAuth2 credentials yet, we need to get the resource owner
  // to authorize us. We're assuming here that we're a command-line application.
  var grant = oauth2.AuthorizationCodeGrant(
      identifier, authorizationEndpoint, tokenEndpoint,
      secret: secret);

  // A URL on the authorization server (authorizationEndpoint with some additional
  // query parameters). Scopes and state can optionally be passed into this method.
  var authorizationUrl =
      grant.getAuthorizationUrl(redirectUrl, scopes: ['read_vehicle_info']);

  // Redirect the resource owner to the authorization URL. Once the resource
  // owner has authorized, they'll be redirected to `redirectUrl` with an
  // authorization code. The `redirect` should cause the browser to redirect to
  // another URL which should also have a listener.
  //
  // `redirect` and `listen` are not shown implemented here. See below for the
  // details.
  await redirect(authorizationUrl);
  var responseUrl =
      await listen(redirectUrl).catchError((error) => print(error));

  // Once the user is redirected to `redirectUrl`, pass the query parameters to
  // the AuthorizationCodeGrant. It will validate them and extract the
  // authorization code to create a new Client.
  var authRes =
      await grant.handleAuthorizationResponse(responseUrl.queryParameters);

  return authRes;
}

Future<void> redirect(Uri uri) async {
  if (await canLaunch(uri.toString())) {
    await launch(uri.toString());
  } else {
    throw Exception('Could not launch $uri');
  }
}

Future<Uri> listen(Uri redirectUri) async {
  // Create a Completer to handle the result of the authentication
  Completer<Uri> completer = Completer<Uri>();

  // Start listening for incoming requests
  HttpServer.bind(InternetAddress.loopbackIPv4, 8000).then((server) {
    server.listen((request) {
      // Check if the request matches the expected redirect URI
      if (request.uri.path == redirectUri.path) {
        // Close the server
        server.close();

        // Set the result of the Completer with the URI containing the
        // authorization code
        completer.complete(request.uri);
      }
    });
  });

  // Return the future that will complete when the authentication
  // is complete
  return completer.future;
}

void main() async {
  runApp(const MyApp());

  // Once you have a Client, you can use it just like any other HTTP client.
  // print(await client.read('http://example.com/protected-resources.txt'));

  // Once we're done with the client, save the credentials file. This ensures
  // that if the credentials were automatically refreshed while using the
  // client, the new credentials are available for the next run of the
  // program.
  // await credentialsFile.writeAsString(client.credentials.toJson());
  // writeAsString(client.credentials.toJson());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('data'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            createClient().then((client) {
              print(client.credentials.accessToken);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>
                    HomeScreen(client.credentials.accessToken),
              ));
            }).catchError((error) => print(error));
          },
          child: const Text('Login'),
        ),
      ),
    );
  }
}
