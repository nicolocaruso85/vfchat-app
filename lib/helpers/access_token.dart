import 'package:googleapis_auth/auth_io.dart';

class AccessToken {

  final String firebaseMessagingScope =
      "https://www.googleapis.com/auth/firebase.messaging";

  Future<String> getAccessToken() async {

    // In the Firebase console, open Settings > Service Accounts.
    // Click Generate New Private Key, then confirm by clicking Generate Key.
    // set data from downloaded file here
    final accountCredentials = ServiceAccountCredentials.fromJson({
      "private_key_id": "f009f6065a4c9d78c46f8d1074b7a873418bcbb4",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDGJ1xOvkzhxHTu\nOlm2oLL4gBaoQwvnEvUrA5RtrH7PBWf2f91DYHmg50u9iqPDcCLerMkfUGFghMju\nWR5kVLocCy6rPyEGHCztXXoWK0LHjQdVIX1HPG5kwtSZse0IFfbN0VEqgImSmGmS\n8Og2CNCQ8f2lydfRiQjkkH/cPfycO5Y0y+hQMDRVUs7DvYM23yslNs13PjmIZKsu\nmyR1wF71NhRQyyyisYZlW4EI8wIq8OUuscFb25VMcWab4IKhMXxeNoom6iV2ROvb\nKIZbrbYgrYGXge3zhYqC8ahcFLkzcq4Rrt1j1ISJKb5A3/y4m4DJ3DVAemUtj3lp\nZ0/CyGTZAgMBAAECggEAT3GKZZuQMVfVVYmZXEnzVwPrkYxH4l3MY3Fs+ceVk6Rk\nOQSsjg3I1cTFrfk+jOWRZVs6y04rrEmwUTbzo2AAuauWC1wk/lEfhg7bGrY/cMfO\n78ecdYn57HXcTL5z/LDpoTzRYMvl3Bs1AI+LWdaQ3/vVKLnSyBQ7t39jc8Z6V5wr\ncR/I60Vj9evWEA12Glu6kDFqynWGAqlD6qPWllnuyY9VxgfRdtdGcXrG7YRFY4TP\nnDjvkh7jTGhWyWXdyfOeoihrUzFqa57B+/L468QF41dAnOK1mYTleswyZzAjJHOG\nGVlPi5aFMoshl5QHi8DsA6bKSyc2BoScLBffnVV0LQKBgQDqMBTMfHetgVGhjjrh\nJUamUWzCO0qKJFHdLZ98jwRnOvg7AZk4maEvumSmMWkn7j+ShoC6Gk7uI0u5iXdd\n29DbkIWkwPkuzrCduJEe1lNABepXVts7MrPrQ/Oifv8vzhv9SQkQOiBWezzKCbQ3\nFAdJAnu/pfQL+aB5ZzmF8sm6MwKBgQDYnBd1MzDBGT217OFOJzUmVGh6A7OwFzKc\nPKvyAWfiJEjJgKK3EP9LiykgEtVD2DhIdyOxKls7XDRd5G05Y6Fz+kZhOiEKK3DT\nHx+QxBl37sVZE5iOaMF/SqrsCmddpMJ+HHQuSvnTX+4aMmuHmdZnsJbvANKMKXQd\nAcJsFPIwwwKBgBo3wcxWzussxB/LFYppKuypxvxDuQeYI1YYqnc+Z6bK8klg129/\nu4zlWClG9NfUk2drCXRMR7PfXbXqzuNCHbLHDj8wn3T/DMTLieui4PUU9HRMtAR/\nm6bmF5uEjjsi3v1PNOWNLFuiNl8EERntcxdYYNRG1viUPMP6q3T0hmMDAoGBAKrt\nCWm3WlqV02dypBuqvrsfUk4uC6YBuDMngTt3toTxwuoW8s9ovzvadTpVAisGPOuZ\n7/VGijVePgh1T2dA4k+Fh/IDD71ZqC9A2QTAaaSFKv9ugiymJ0KOJjAayZRQhhVD\n2L4K9fbBNT9A2C9pypGJ/KBe0sY9k92r3MKzCKZHAoGBAKmfSgjaivqaRNtOKBkk\nMgHy3AOykfIQIaynNXaiFMM9dxw9ODDyGRzCbQgSTMdu2Ovc34nyPzf3g3M7F2LN\nIc9ng/PtVxEYgkyBLh775DWlUZXaVJzP7iLVOM+tPyZimAB1/aWAWjbTXNLSSeJK\np6cs8pIxADVhys7hTAoqibPy\n-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk-v7d04@vfchat-cba48.iam.gserviceaccount.com",
      "client_id": "104499401266644214274",
      "type": "service_account"
    });

    final client = await clientViaServiceAccount(
      accountCredentials,
      [firebaseMessagingScope],
    );

    return client.credentials.accessToken.data;
  }
}
