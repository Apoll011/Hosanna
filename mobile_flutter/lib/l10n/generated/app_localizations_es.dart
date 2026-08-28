// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Hosanna';

  @override
  String get appTagline =>
      'Tu biblioteca de canciones y planes de adoración, siempre sincronizados.';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonBack => 'Atrás';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonLoading => 'Cargando…';

  @override
  String get commonOk => 'Aceptar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonSearch => 'Buscar';

  @override
  String get commonError => 'Algo salió mal';

  @override
  String get commonOffline => 'Sin conexión a internet';

  @override
  String get commonDone => 'Listo';

  @override
  String get commonNext => 'Siguiente';

  @override
  String get commonUnknown => 'Desconocido';

  @override
  String get authSignIn => 'Iniciar Sesión';

  @override
  String get authSignUp => 'Crear Cuenta';

  @override
  String get authSignOut => 'Cerrar Sesión';

  @override
  String get authEmail => 'Correo Electrónico';

  @override
  String get authPassword => 'Contraseña';

  @override
  String get authName => 'Nombre Completo';

  @override
  String get authConfirmPassword => 'Confirmar Contraseña';

  @override
  String get authForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get authSignInTitle => 'Bienvenido de nuevo';

  @override
  String get authSignUpTitle => 'Crear una cuenta de Hosanna';

  @override
  String get authSignInSubtitle =>
      'Inicia sesión para acceder a tu biblioteca.';

  @override
  String get authSignUpSubtitle =>
      'Regístrate para empezar a organizar tus canciones.';

  @override
  String get authSignInButton => 'Iniciar Sesión';

  @override
  String get authSignUpButton => 'Crear Cuenta';

  @override
  String get authCreateAccount => 'Crear cuenta';

  @override
  String get authNoAccount => '¿No tienes cuenta?';

  @override
  String get authHaveAccount => '¿Ya tienes cuenta?';

  @override
  String get authSignInError =>
      'No se pudo iniciar sesión. Verifica tus credenciales.';

  @override
  String get authSignUpError => 'No se pudo crear tu cuenta.';

  @override
  String get authPasswordMinLength =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get authPasswordsDontMatch => 'Las contraseñas no coinciden.';

  @override
  String get authRequiredFields => 'Introduce tu correo y contraseña.';

  @override
  String get authNameRequired => 'Introduce tu nombre.';

  @override
  String get authEmailInvalid => 'Introduce un correo válido.';

  @override
  String get authVerifyEmail => 'Verificar Correo';

  @override
  String get authVerifyEmailTitle => 'Verifica tu correo';

  @override
  String get authVerifyEmailMessage =>
      'Enviamos un enlace de verificación a tu correo. Ábrelo para confirmar tu cuenta.';

  @override
  String get authCheckEmail => 'Revisar bandeja';

  @override
  String get authResendEmail => 'Reenviar correo de verificación';

  @override
  String get authEmailVerificationSent => '¡Correo de verificación enviado!';

  @override
  String get authResetPassword => 'Restablecer Contraseña';

  @override
  String get authResetPasswordTitle => 'Restablecer contraseña';

  @override
  String get authResetPasswordMessage =>
      'Introduce tu correo y te enviaremos un enlace para restablecer la contraseña.';

  @override
  String get authSendResetLink => 'Enviar Enlace';

  @override
  String get authResetLinkSent =>
      'Si ese correo existe, enviamos un enlace de restablecimiento.';

  @override
  String get authNewPassword => 'Nueva Contraseña';

  @override
  String get authCurrentPassword => 'Contraseña Actual';

  @override
  String get authChangePassword => 'Cambiar Contraseña';

  @override
  String get authAccount => 'Cuenta';

  @override
  String get authProfile => 'Perfil';

  @override
  String get authEditProfile => 'Editar Perfil';

  @override
  String get authNameSaved => '¡Nombre guardado correctamente!';

  @override
  String get authPasswordChanged => '¡Contraseña cambiada correctamente!';

  @override
  String get authPasswordChangeError =>
      'No se pudo cambiar la contraseña. Verifica la contraseña actual.';

  @override
  String get authEmailVerified => 'Correo verificado';

  @override
  String get authEmailNotVerified => 'Correo sin verificar';

  @override
  String get authCaptchaNotConfigured =>
      'La verificación de seguridad (captcha) no está configurada.';

  @override
  String get syncSyncing => 'Sincronizando…';

  @override
  String get syncSynced => 'Sincronizado';

  @override
  String get syncError => 'Error de sincronización';

  @override
  String get syncOffline => 'Sin conexión';

  @override
  String syncLastSynced(Object time) {
    return 'Última sincronización: $time';
  }

  @override
  String get syncNever => 'Nunca sincronizado';

  @override
  String get syncNow => 'Sincronizar ahora';

  @override
  String get syncPullToRefresh => 'Desliza para sincronizar';

  @override
  String get navSongs => 'Canciones';

  @override
  String get navServices => 'Servicios';

  @override
  String get navFolders => 'Carpetas';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get navCircleOfFifths => 'Círculo de Quintas';

  @override
  String get navMetronome => 'Metrónomo';

  @override
  String get navExportPdf => 'Exportar PDF';

  @override
  String get songsTitle => 'Canciones';

  @override
  String get songsSearchHint => 'Buscar canciones…';

  @override
  String get songsEmpty => 'Sin canciones';

  @override
  String get songsNoResults => 'Sin resultados';

  @override
  String get songsAllSongs => 'Todas las canciones';

  @override
  String get songsFilterByFolder => 'Filtrar por carpeta';

  @override
  String get songsFilterByTag => 'Filtrar por etiqueta';

  @override
  String get songsSortBy => 'Ordenar por';

  @override
  String get songsSortTitle => 'Título';

  @override
  String get songsSortArtist => 'Artista';

  @override
  String get songsSortUpdated => 'Actualización';

  @override
  String get songsTitleLabel => 'Título';

  @override
  String get songsArtistLabel => 'Artista';

  @override
  String get songsFolderLabel => 'Carpeta';

  @override
  String get songsTagsLabel => 'Etiquetas';

  @override
  String get songsChordPro => 'ChordPro';

  @override
  String get songsRawContent => 'Contenido sin procesar (ChordPro)';

  @override
  String get songsNoContent => 'Sin contenido disponible.';

  @override
  String get foldersTitle => 'Carpetas';

  @override
  String get foldersEmpty => 'Sin carpetas';

  @override
  String get foldersSubfolders => 'Subcarpetas';

  @override
  String foldersSongsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones',
      one: '1 canción',
    );
    return '$_temp0';
  }

  @override
  String get foldersRoot => 'Raíz';

  @override
  String get servicesTitle => 'Servicios';

  @override
  String get servicesEmpty => 'Sin servicios';

  @override
  String get servicesItems => 'Elementos';

  @override
  String get servicesNotes => 'Notas';

  @override
  String get servicesGeneralNotes => 'Notas generales';

  @override
  String get servicesItemNotes => 'Notas del elemento';

  @override
  String get servicesOrderedItems => 'Elementos ordenados';

  @override
  String get servicesNoItems => 'Sin elementos en este servicio.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsHighContrast => 'Alto contraste';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageLabel => 'Idioma de la app';

  @override
  String get settingsAccount => 'Cuenta';

  @override
  String get settingsOffline => 'Modo sin conexión';

  @override
  String get metronomeTitle => 'Metrónomo';

  @override
  String get metronomeDescription => 'Tempo y compás para ensayos.';

  @override
  String get circleOfFifthsTitle => 'Círculo de Quintas';

  @override
  String get circleOfFifthsDescription =>
      'Referencia de tonalidades y relativas.';

  @override
  String get exportPdfTitle => 'Exportar PDF';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get comingSoonDescription =>
      'Esta función estará disponible en una próxima versión.';
}
