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
  String get commonOpenDrawer => 'Abrir menú';

  @override
  String get commonCloseDrawer => 'Cerrar el menú';

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
  String get onboardingTitle => 'Bienvenido a Hosanna';

  @override
  String get onboardingSubtitle =>
      'Acepta una invitación para unirte a la organización de tu iglesia.';

  @override
  String onboardingPendingInvites(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invitaciones pendientes',
      one: '1 invitación pendiente',
    );
    return '$_temp0';
  }

  @override
  String get onboardingNoInvites => 'Sin invitaciones pendientes';

  @override
  String get onboardingNoInvitesDesc =>
      'Pide a un administrador de tu iglesia que te invite.';

  @override
  String get onboardingAccept => 'Aceptar';

  @override
  String get onboardingReject => 'Rechazar';

  @override
  String get onboardingRole => 'Rol';

  @override
  String get onboardingLoadingInvites => 'Cargando invitaciones…';

  @override
  String get onboardingSignOut => 'Cerrar Sesión';

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
  String get navLibrarySection => 'Biblioteca';

  @override
  String get navToolsSection => 'Herramientas';

  @override
  String get navAllSongs => 'Todas las canciones';

  @override
  String get navFavorites => 'Favoritos';

  @override
  String get navRecents => 'Recientes';

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
  String get songsFilter => 'Filtrar';

  @override
  String get songsSortBy => 'Ordenar por';

  @override
  String get songsSortTitle => 'Título';

  @override
  String get songsSortArtist => 'Artista';

  @override
  String get songsSortNumber => 'Número';

  @override
  String get songsSortUpdated => 'Actualización';

  @override
  String get songsSortAdded => 'Añadida recientemente';

  @override
  String get songsSortAscending => 'Ascendente';

  @override
  String get songsSortDescending => 'Descendente';

  @override
  String get songsMatchAll => 'Coincidir todas';

  @override
  String get songsMatchAny => 'Coincidir alguna';

  @override
  String get songsFilterByKey => 'Filtrar por tonalidad';

  @override
  String get songsFilterBySongNumber => 'Número de canción';

  @override
  String get songsNumberAny => 'Cualquiera';

  @override
  String get songsNumberOnly => 'Numeradas';

  @override
  String get songsNumberNone => 'Sin número';

  @override
  String get songsSearchLyrics => 'Buscar en la letra';

  @override
  String get songsWithChords => 'Solo con acordes';

  @override
  String get songsResetFilters => 'Restablecer filtros';

  @override
  String get songsClear => 'Limpiar';

  @override
  String get songsClearFilters => 'Limpiar filtros';

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
  String get songKey => 'Tonalidad';

  @override
  String get songCapo => 'Cejilla';

  @override
  String get songChords => 'Acordes';

  @override
  String get songInstrument => 'Instrumento';

  @override
  String get songDiagrams => 'Diagramas';

  @override
  String get songControlsTitle => 'Ajustes de Lectura';

  @override
  String get songTranspose => 'Transposición';

  @override
  String get songSemitones => 'semitonos';

  @override
  String get songOriginal => 'Original';

  @override
  String get songCapoNone => 'Ninguna';

  @override
  String songCapoFret(Object fret) {
    return 'Traste $fret';
  }

  @override
  String get songFontSize => 'Tamaño de la Letra';

  @override
  String get songShowChords => 'Mostrar Acordes';

  @override
  String get songTwoColumn => 'Diseño en 2 Columnas';

  @override
  String get songShowDiagrams => 'Mostrar Diagramas';

  @override
  String get songSectionBackground => 'Fondo de Color en Secciones';

  @override
  String get songGuitar => 'Guitarra';

  @override
  String get songPiano => 'Piano';

  @override
  String get songAutoScrollStart => 'Iniciar desplazamiento automático';

  @override
  String get songAutoScrollPause => 'Pausar desplazamiento';

  @override
  String get songAutoScrollSpeed => 'Velocidad de desplazamiento';

  @override
  String get songPrevious => 'Anterior';

  @override
  String get songNext => 'Siguiente';

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
  String get servicesSearchHint => 'Buscar servicios…';

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
  String get servicesOrderTitle => 'Orden del Servicio';

  @override
  String get servicesArchived => 'Sair';

  @override
  String get servicesLeave => 'Salir';

  @override
  String get servicesLeaveMode => 'Salir del Modo Servicio';

  @override
  String servicesMoments(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count momentos',
      one: '1 momento',
    );
    return '$_temp0';
  }

  @override
  String servicesItemOf(Object current, Object total) {
    return 'Elemento $current de $total';
  }

  @override
  String get servicesAddNotes => 'Toca para añadir notas…';

  @override
  String get servicesElementSong => 'Canción';

  @override
  String get servicesElementWelcome => 'Bienvenida';

  @override
  String get servicesElementScripture => 'Escritura';

  @override
  String get servicesElementMessage => 'Mensaje';

  @override
  String get servicesElementAnnouncement => 'Anuncios';

  @override
  String get servicesElementDefault => 'Elemento';

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
  String get settingsTabAccount => 'Cuenta';

  @override
  String get settingsTabWorkspace => 'Organización';

  @override
  String get settingsTabPreferences => 'Preferencias';

  @override
  String get settingsActive => 'Activa';

  @override
  String get settingsSwitchOrg => 'Cambiar Organización';

  @override
  String get settingsOrganization => 'Organización';

  @override
  String get settingsSyncLibrary => 'Sincronización de la Biblioteca';

  @override
  String get settingsSyncLibraryDesc =>
      'Sincroniza las canciones, carpetas y servicios de tu organización.';

  @override
  String get settingsSyncNow => 'Sincronizar';

  @override
  String get settingsLastSync => 'Última Sincronización';

  @override
  String get settingsSyncState => 'Estado de Sincronización';

  @override
  String get settingsLocalSongs => 'Canciones Locales';

  @override
  String get settingsSavedServices => 'Servicios Guardados';

  @override
  String get settingsUserId => 'ID de Usuario';

  @override
  String get settingsRole => 'Rol';

  @override
  String get settingsActiveOrg => 'Organización Activa';

  @override
  String get settingsNoActiveOrg => 'Sin organización activa';

  @override
  String get settingsChangeEmail => 'Cambiar Correo';

  @override
  String get settingsNewEmail => 'Nuevo Correo';

  @override
  String get settingsSaveEmail => 'Guardar Correo';

  @override
  String get settingsEmailChangeSent =>
      '¡Solicitud de cambio de correo enviada!';

  @override
  String get settingsEdit => 'Editar';

  @override
  String get settingsCancel => 'Cancelar';

  @override
  String get settingsSave => 'Guardar';

  @override
  String get settingsSaving => 'Guardando…';

  @override
  String get settingsNameEmpty => 'El nombre no puede estar vacío.';

  @override
  String get settingsEmailInvalid => 'Introduce un correo válido.';

  @override
  String get settingsMusicianMode => 'Modo Músico en los Servicios';

  @override
  String get settingsMusicianModeDesc =>
      'Abre el servicio directamente en la primera canción con navegación lateral continua.';

  @override
  String get settingsKeepAwake => 'Mantener Pantalla Encendida';

  @override
  String get settingsKeepAwakeDesc =>
      'Evita que la pantalla se suspenda al ver canciones.';

  @override
  String get settingsSessionsOnly =>
      'Solo está activa la sesión actual de este dispositivo.';

  @override
  String get metronomeTitle => 'Metrónomo';

  @override
  String get metronomeDescription => 'Tempo y compás para ensayos.';

  @override
  String get metronomeTapTempo => 'Marcar Tempo';

  @override
  String get metronomeTimeSignature => 'COMPÁS';

  @override
  String get metronomeAccent => 'Acento';

  @override
  String get circleOfFifthsTitle => 'Círculo de Quintas';

  @override
  String get circleOfFifthsDescription =>
      'Referencia de tonalidades y relativas.';

  @override
  String get circleOfFifthsHarmonicField => 'Campo Armónico';

  @override
  String get circleOfFifthsTonic => 'Tónica';

  @override
  String get circleOfFifthsRelativeMinor => 'Relativa Menor';

  @override
  String get exportPdfTitle => 'Exportar PDF';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get comingSoonDescription =>
      'Esta función estará disponible en una próxima versión.';
}
