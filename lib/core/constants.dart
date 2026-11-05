abstract final class AppConstants {
  static const appName = 'Campus Reporter';

  static const maxPhotos = 3;
  static const titleMinLength = 5;
  static const titleMaxLength = 80;
  static const descriptionMinLength = 15;
  static const passwordMinLength = 6;

  /// Only ALU accounts can sign up. Staff emails get the staff role.
  static const staffEmailDomain = 'alueducation.com';
  static const allowedEmailDomains = ['alustudent.com', staffEmailDomain];

  static const locations = [
    'Block A',
    'Block B — Room 204',
    'Block C',
    'Library',
    'Cafeteria',
    'Student Residence',
    'Computer Lab',
    'Science Lab',
    'Lecture Hall 1',
    'Sports Complex',
    'Admin Block',
    'Parking Lot',
    'Main Gate',
    'Other',
  ];
}
