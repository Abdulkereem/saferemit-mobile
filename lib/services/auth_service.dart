import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static const String baseUrl = 'https://saferemit.finance';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // serverClientId tells Google to issue an id_token whose audience
    // is the web client ID — so the backend can verify it with GOOGLE_CLIENT_ID.
    serverClientId: '400743682454-44mopbbkc524e8s45ps4tik0nj7qa0mk.apps.googleusercontent.com',
  );

  // Google Sign In
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Trigger Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {'success': false, 'message': 'Sign in cancelled'};
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        return {
          'success': false,
          'message':
              'Failed to get ID token. Please check Google Sign-In configuration.'
        };
      }

      // Send token to backend
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_token': googleAuth.idToken,
          'access_token': googleAuth.accessToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'session_token': data['session_token'] ?? '',
          'user': data['user'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Authentication failed',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Error: ${error.toString()}',
      };
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  // Check if signed in
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }
}
