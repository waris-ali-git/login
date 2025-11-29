class Database {
  // IMPORTANT: Storing plaintext passwords is a major security risk.
  // This is for demonstration purposes only and should not be used in a production environment.
  static const Map<String, String> adminCredentials = {
    'acm@admin.com': 'acm123',
    'cls@admin.com': 'cls123',
    'css@admin.com': 'css123',
  };

  static const Map<String, String> adminSocieties = {
    'acm@admin.com': 'ACM',
    'cls@admin.com': 'CLS',
    'css@admin.com': 'CSS',
  };
}
