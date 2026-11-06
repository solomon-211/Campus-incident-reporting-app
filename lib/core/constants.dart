abstract final class AppConstants {
  static const appName = 'Campus Reporter';

  /// Supabase is used only to store report files (photos and PDFs). The
  /// publishable key is meant to ship inside apps; never put the secret key
  /// here.
  static const supabaseUrl = 'https://kdzmrbrsovfetvqjvjfs.supabase.co';
  static const supabaseKey = 'sb_publishable_csOG_bQBW0BMrxicQLXV9w_n8cDZ6di';
  static const storageBucket = 'incident-files';

  /// Photos and PDFs together.
  static const maxAttachments = 3;
  static const maxPdfBytes = 10 * 1024 * 1024;
  static const titleMinLength = 5;
  static const titleMaxLength = 80;
  static const descriptionMinLength = 15;
  static const passwordMinLength = 6;

  /// Only ALU accounts can sign up. Staff emails get the staff role.
  static const staffEmailDomain = 'alueducation.com';
  static const allowedEmailDomains = ['alustudent.com', staffEmailDomain];

  static const locations = [
    'Leadership Center',
    'Social Enterprise',
    'Social Common',
    'Cafeteria',
    'Computer Lab',
    'Wellness Center',
    'FabLab',
    'Other',
  ];
}
