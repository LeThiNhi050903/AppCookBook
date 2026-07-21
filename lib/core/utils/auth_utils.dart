const String kAdminEmail = 'adminCookBook@gmail.com';
const String kAdminPassword = 'admin050903';

bool isAdminEmail(String email) {
  return email.trim().toLowerCase() == kAdminEmail.toLowerCase();
}

bool isAdminCredentials(String email, String password) {
  return isAdminEmail(email) && password.trim() == kAdminPassword;
}
