class Config {
  // Use 10.0.2.2 for Android emulator to connect to host machine's localhost
  // For physical devices, use your machine's actual IP address
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api';

  // Add other configuration constants as needed
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // Helper method to get the appropriate base URL
  static String getBaseUrl() {
    // You can add platform-specific logic here if needed
    return apiBaseUrl;
  }
}
