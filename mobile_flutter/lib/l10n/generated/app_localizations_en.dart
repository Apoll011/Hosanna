// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Hosanna';

  @override
  String get appTagline =>
      'Your song library and worship plans, always in sync.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonBack => 'Back';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonOk => 'OK';

  @override
  String get commonClose => 'Close';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get commonOffline => 'No internet connection';

  @override
  String get commonDone => 'Done';

  @override
  String get commonNext => 'Next';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get commonOpenDrawer => 'Open menu';

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authSignUp => 'Sign Up';

  @override
  String get authSignOut => 'Sign Out';

  @override
  String get authEmail => 'Email Address';

  @override
  String get authPassword => 'Password';

  @override
  String get authName => 'Full Name';

  @override
  String get authConfirmPassword => 'Confirm Password';

  @override
  String get authForgotPassword => 'Forgot your password?';

  @override
  String get authSignInTitle => 'Welcome back';

  @override
  String get authSignUpTitle => 'Create a Hosanna account';

  @override
  String get authSignInSubtitle => 'Sign in to access your library.';

  @override
  String get authSignUpSubtitle => 'Register to start organizing your songs.';

  @override
  String get authSignInButton => 'Sign In';

  @override
  String get authSignUpButton => 'Create Account';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authSignInError => 'Could not sign in. Check your credentials.';

  @override
  String get authSignUpError => 'Could not create your account.';

  @override
  String get authPasswordMinLength => 'Password must be at least 6 characters.';

  @override
  String get authPasswordsDontMatch => 'Passwords do not match.';

  @override
  String get authRequiredFields => 'Please enter your email and password.';

  @override
  String get authNameRequired => 'Please enter your name.';

  @override
  String get authEmailInvalid => 'Please enter a valid email.';

  @override
  String get authVerifyEmail => 'Verify Email';

  @override
  String get authVerifyEmailTitle => 'Verify your email';

  @override
  String get authVerifyEmailMessage =>
      'We sent a verification link to your email. Open it to confirm your account.';

  @override
  String get authCheckEmail => 'Check inbox';

  @override
  String get authResendEmail => 'Resend verification email';

  @override
  String get authEmailVerificationSent => 'Verification email sent!';

  @override
  String get authResetPassword => 'Reset Password';

  @override
  String get authResetPasswordTitle => 'Reset password';

  @override
  String get authResetPasswordMessage =>
      'Enter your email and we\'ll send you a link to reset your password.';

  @override
  String get authSendResetLink => 'Send Reset Link';

  @override
  String get authResetLinkSent => 'If that email exists, we sent a reset link.';

  @override
  String get authNewPassword => 'New Password';

  @override
  String get authCurrentPassword => 'Current Password';

  @override
  String get authChangePassword => 'Change Password';

  @override
  String get authAccount => 'Account';

  @override
  String get authProfile => 'Profile';

  @override
  String get authEditProfile => 'Edit Profile';

  @override
  String get authNameSaved => 'Name saved successfully!';

  @override
  String get authPasswordChanged => 'Password changed successfully!';

  @override
  String get authPasswordChangeError =>
      'Could not change password. Check your current password.';

  @override
  String get authEmailVerified => 'Email verified';

  @override
  String get authEmailNotVerified => 'Email not verified';

  @override
  String get authCaptchaNotConfigured =>
      'Security verification (captcha) is not configured.';

  @override
  String get onboardingTitle => 'Welcome to Hosanna';

  @override
  String get onboardingSubtitle =>
      'Accept an invitation to join your church\'s organization.';

  @override
  String onboardingPendingInvites(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pending invitations',
      one: '1 pending invitation',
    );
    return '$_temp0';
  }

  @override
  String get onboardingNoInvites => 'No pending invitations';

  @override
  String get onboardingNoInvitesDesc =>
      'Ask a church administrator to invite you.';

  @override
  String get onboardingAccept => 'Accept';

  @override
  String get onboardingReject => 'Reject';

  @override
  String get onboardingRole => 'Role';

  @override
  String get onboardingLoadingInvites => 'Loading invitations…';

  @override
  String get onboardingSignOut => 'Sign Out';

  @override
  String get syncSyncing => 'Syncing…';

  @override
  String get syncSynced => 'Synced';

  @override
  String get syncError => 'Sync error';

  @override
  String get syncOffline => 'Offline';

  @override
  String syncLastSynced(Object time) {
    return 'Last synced: $time';
  }

  @override
  String get syncNever => 'Never synced';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncPullToRefresh => 'Pull to sync';

  @override
  String get navSongs => 'Songs';

  @override
  String get navServices => 'Services';

  @override
  String get navFolders => 'Folders';

  @override
  String get navSettings => 'Settings';

  @override
  String get navCircleOfFifths => 'Circle of Fifths';

  @override
  String get navMetronome => 'Metronome';

  @override
  String get navExportPdf => 'Export PDF';

  @override
  String get navLibrarySection => 'Library';

  @override
  String get navToolsSection => 'Tools';

  @override
  String get navAllSongs => 'All songs';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navRecents => 'Recent';

  @override
  String get songsTitle => 'Songs';

  @override
  String get songsSearchHint => 'Search songs…';

  @override
  String get songsEmpty => 'No songs';

  @override
  String get songsNoResults => 'No results';

  @override
  String get songsAllSongs => 'All songs';

  @override
  String get songsFilterByFolder => 'Filter by folder';

  @override
  String get songsFilterByTag => 'Filter by tag';

  @override
  String get songsFilter => 'Filter';

  @override
  String get songsSortBy => 'Sort by';

  @override
  String get songsSortTitle => 'Title';

  @override
  String get songsSortArtist => 'Artist';

  @override
  String get songsSortUpdated => 'Updated';

  @override
  String get songsTitleLabel => 'Title';

  @override
  String get songsArtistLabel => 'Artist';

  @override
  String get songsFolderLabel => 'Folder';

  @override
  String get songsTagsLabel => 'Tags';

  @override
  String get songsChordPro => 'ChordPro';

  @override
  String get songsRawContent => 'Raw content (ChordPro)';

  @override
  String get songsNoContent => 'No content available.';

  @override
  String get songKey => 'Key';

  @override
  String get songCapo => 'Capo';

  @override
  String get songChords => 'Chords';

  @override
  String get songInstrument => 'Instrument';

  @override
  String get songDiagrams => 'Diagrams';

  @override
  String get songControlsTitle => 'Reading Settings';

  @override
  String get songTranspose => 'Transpose';

  @override
  String get songSemitones => 'semitones';

  @override
  String get songOriginal => 'Original';

  @override
  String get songCapoNone => 'None';

  @override
  String songCapoFret(Object fret) {
    return 'Fret $fret';
  }

  @override
  String get songFontSize => 'Font Size';

  @override
  String get songShowChords => 'Show Chords';

  @override
  String get songTwoColumn => '2-Column Layout';

  @override
  String get songShowDiagrams => 'Show Diagrams';

  @override
  String get songGuitar => 'Guitar';

  @override
  String get songPiano => 'Piano';

  @override
  String get songAutoScrollStart => 'Start auto-scroll';

  @override
  String get songAutoScrollPause => 'Pause scroll';

  @override
  String get songAutoScrollSpeed => 'Scroll speed';

  @override
  String get songPrevious => 'Previous';

  @override
  String get songNext => 'Next';

  @override
  String get foldersTitle => 'Folders';

  @override
  String get foldersEmpty => 'No folders';

  @override
  String get foldersSubfolders => 'Subfolders';

  @override
  String foldersSongsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String get foldersRoot => 'Root';

  @override
  String get servicesTitle => 'Services';

  @override
  String get servicesEmpty => 'No services';

  @override
  String get servicesItems => 'Items';

  @override
  String get servicesNotes => 'Notes';

  @override
  String get servicesGeneralNotes => 'General notes';

  @override
  String get servicesItemNotes => 'Item notes';

  @override
  String get servicesOrderedItems => 'Ordered items';

  @override
  String get servicesNoItems => 'No items in this service.';

  @override
  String get servicesOrderTitle => 'Service Order';

  @override
  String get servicesLeave => 'Leave';

  @override
  String get servicesLeaveMode => 'Leave Service Mode';

  @override
  String servicesMoments(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moments',
      one: '1 moment',
    );
    return '$_temp0';
  }

  @override
  String servicesItemOf(Object current, Object total) {
    return 'Item $current of $total';
  }

  @override
  String get servicesAddNotes => 'Tap to add notes…';

  @override
  String get servicesElementSong => 'Song';

  @override
  String get servicesElementWelcome => 'Welcome';

  @override
  String get servicesElementScripture => 'Scripture';

  @override
  String get servicesElementMessage => 'Message';

  @override
  String get servicesElementAnnouncement => 'Announcement';

  @override
  String get servicesElementDefault => 'Element';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsHighContrast => 'High contrast';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageLabel => 'App language';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsOffline => 'Offline mode';

  @override
  String get metronomeTitle => 'Metronome';

  @override
  String get metronomeDescription => 'Tempo and time signature for rehearsals.';

  @override
  String get circleOfFifthsTitle => 'Circle of Fifths';

  @override
  String get circleOfFifthsDescription => 'Key and relative-key reference.';

  @override
  String get exportPdfTitle => 'Export PDF';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get comingSoonDescription =>
      'This feature will be available in a future release.';
}
