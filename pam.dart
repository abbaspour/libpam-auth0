import 'dart:io';
import 'dart:convert';

const PAM_SUCCESS = 0;
const PAM_SERVICE_ERR = 3;
const PAM_SYSTEM_ERR = 4;
const PAM_AUTH_ERR = 7;
const PAM_AUTHINFO_UNAVAIL = 9;
const PAM_NO_MODULE_DATA = 18;

const CONFIG_FILE = '/etc/auth0.conf';

String getUser() {
  return (Platform.environment['PAM_TYPE'] != 'auth') ? null : Platform.environment['PAM_USER'];
}

String readPassword() {
  return stdin.readLineSync();
}

Map getConfig() {
  var file = new File(CONFIG_FILE);

  if(!file.existsSync())
    return null;

  var config = {
    'AUTH0_DOMAIN': '',
    'AUTH0_CLIENT_ID': '',
    'AUTH0_CLIENT_SECRET': '',
    'AUTH0_CONNECTION' : ''
  };

  var contents = file.readAsStringSync();
  final RegExp exp = new RegExp(r"^[^#](\S+)=(\S+)", multiLine: true);
  final matches = exp.allMatches(contents);

  matches.map(((m) => m.group(0).split('='))).forEach((kv) => { if(config.containsKey(kv[0])) config[kv[0]] = kv[1]});

  return config;
}

Future<bool> authenticate(config, username, password) async {
  final body = {
      'grant_type': 'http://auth0.com/oauth/grant-type/password-realm',
      'realm' : config['AUTH0_CONNECTION'],
      'client_id': config['AUTH0_CLIENT_ID'],
      'client_secret': config['AUTH0_CLIENT_SECRET'],
      'username': username,
      'password': password
  };

  var client = HttpClient();

  final token_endpoint = 'https://${config['AUTH0_DOMAIN']}/oauth/token';
  var apiUrl = Uri.parse(token_endpoint);

  HttpClientRequest request = await client.postUrl(apiUrl);

  request.headers.contentType = new ContentType("application", "json", charset: "utf-8");
  request.write(json.encode(body));

  HttpClientResponse response = await request.close();
  return response.statusCode == 200 ? true : false;
}

void main() async {
  final username = getUser();
  if(username == null) {
    exit(PAM_SYSTEM_ERR);
    return;
  }

  var config = getConfig();

  final password = readPassword();

  bool result = await authenticate(config, username, password);

  if(result) {
    print("success for user: " + username);
    exit(PAM_SUCCESS);
    return;
  }

  print("failed for user: " + username);
  exit(PAM_AUTH_ERR);

}
