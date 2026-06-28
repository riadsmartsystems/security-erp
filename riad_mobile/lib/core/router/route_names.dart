abstract class Routes {
  static const login             = '/login';
  static const mfaEnrollment     = '/mfa-enrollment';
  static const mfaVerify         = '/mfa-verify';
  static const home              = '/home';
  static const tasks             = '/home/tasks';
  static const objects           = '/home/objects';
  static const vault             = '/home/vault';
  static const sync              = '/home/sync';
  static const visitDetail       = '/visit/:id';
  static const checklist         = '/checklist/:visitId';
  static const objectDetail      = '/object/:id';
  static const installationMap   = '/map/:objectId';
  static const scan              = '/scan';
  static const voiceNote         = '/voice/:visitId';
  static const remoteInspection  = '/remote-inspection/:id';
  static const serviceRequest    = '/service/:id';
  static const conflictResolution= '/conflict/:id';
  static const profile           = '/profile';
  static const sessions          = '/profile/sessions';
  static const mfaManagement     = '/profile/mfa';
  static const notifications     = '/profile/notifications';
}
