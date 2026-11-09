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
  String get commonErrorDesc => 'Comprueba tu conexión e inténtalo de nuevo.';

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
  String get authCaptchaWindowTitle => 'Verificación de seguridad (captcha)';

  @override
  String get authCaptchaWaitingMessage =>
      'Completa la verificación de seguridad en la ventana de captcha que acaba de abrirse.';

  @override
  String get authCaptchaOpenFailed => 'No se pudo abrir la ventana de captcha.';

  @override
  String get authOr => 'o';

  @override
  String authContinueWith(String provider) {
    return 'Continuar con $provider';
  }

  @override
  String get authSocialNoAccount =>
      'No hay ninguna cuenta disponible para iniciar sesión en este dispositivo.';

  @override
  String get authSocialUnavailable =>
      'Este dispositivo no admite este método de inicio de sesión.';

  @override
  String get authSocialNotConfigured =>
      'El inicio de sesión social no está configurado en esta compilación.';

  @override
  String get authSocialRejected =>
      'No pudimos verificar tu cuenta. Inténtalo de nuevo.';

  @override
  String get authSocialNetworkError =>
      'No se pudo conectar con el servidor. Comprueba tu conexión.';

  @override
  String get authSocialServerError =>
      'El servidor no pudo completar el inicio de sesión. Inténtalo de nuevo.';

  @override
  String get authSocialError => 'No se pudo iniciar sesión.';

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
  String get setupWelcomeTitle => 'Configuremos Hosanna';

  @override
  String get setupWelcomeSubtitle =>
      'Unas pocas opciones para que canciones y servicios se sientan bien según cómo sirves.';

  @override
  String get setupWelcomeCta => 'Empezar';

  @override
  String get setupRoleTitle => '¿Cómo usas Hosanna?';

  @override
  String get setupRoleSubtitle =>
      'Abriremos los servicios según tu rol. Puedes cambiarlo después en Ajustes.';

  @override
  String get setupRoleMusician => 'Músico';

  @override
  String get setupRoleMusicianDesc =>
      'Entra directo a las canciones con acordes, cejilla y diagramas.';

  @override
  String get setupRoleLeader => 'Líder';

  @override
  String get setupRoleLeaderDesc =>
      'Empieza por el orden del servicio y las notas del momento.';

  @override
  String get setupFocusTitle => '¿Qué tocas?';

  @override
  String get setupFocusSubtitle =>
      'Esto define el instrumento predeterminado para los diagramas de acordes.';

  @override
  String get setupFocusGuitar => 'Guitarra';

  @override
  String get setupFocusBass => 'Bajo';

  @override
  String get setupFocusUkulele => 'Ukelele';

  @override
  String get setupFocusPiano => 'Piano / teclas';

  @override
  String get setupFocusVocals => 'Voz';

  @override
  String get setupFocusVocalsDesc =>
      'Letra primero — los acordes siguen disponibles cuando los necesites.';

  @override
  String get setupLeaderFocusTitle => 'Cuando abres una canción…';

  @override
  String get setupLeaderFocusSubtitle =>
      'Opcional — elige un instrumento para las cifras al revisar canciones.';

  @override
  String get setupPrefsTitle => 'Ajustes listos para el escenario';

  @override
  String get setupPrefsSubtitle =>
      'Opciones útiles para ensayos y culto en vivo.';

  @override
  String get setupPrefDiagrams => 'Mostrar diagramas de acordes';

  @override
  String get setupPrefDiagramsDesc =>
      'Digitaciones encima de la canción cuando estén disponibles.';

  @override
  String get setupPrefAwake => 'Mantener la pantalla encendida';

  @override
  String get setupPrefAwakeDesc =>
      'No oscurecer durante una canción o servicio.';

  @override
  String get setupLanguageTitle => 'Idioma';

  @override
  String get setupLanguageSubtitle => 'Elige el idioma de menús y etiquetas.';

  @override
  String get setupLanguageSystem => 'Igual que el dispositivo';

  @override
  String get setupDoneTitle => 'Listo';

  @override
  String get setupDoneSubtitle =>
      'Hosanna está configurado para ti. Entra en tu biblioteca cuando quieras.';

  @override
  String get setupDoneCta => 'Entrar a Hosanna';

  @override
  String get setupSkip => 'Omitir por ahora';

  @override
  String setupStepOf(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get settingsRedoSetup => 'Volver a configurar';

  @override
  String get settingsRedoSetupDesc =>
      'Responder de nuevo las preguntas de rol e instrumento.';

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
  String get songsSavedOffline =>
      'Guardado en este dispositivo. Los cambios se sincronizarán cuando vuelvas a tener conexión.';

  @override
  String get syncPullToRefresh => 'Desliza para sincronizar';

  @override
  String get navSongs => 'Canciones';

  @override
  String get navServices => 'Servicios';

  @override
  String get navFolders => 'Carpetas';

  @override
  String get navCollections => 'Colecciones';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get navCircleOfFifths => 'Círculo de Quintas';

  @override
  String get navMetronome => 'Metrónomo';

  @override
  String get navAgenda => 'Agenda';

  @override
  String get navExportPdf => 'Exportar PDF';

  @override
  String get navLibrarySection => 'Biblioteca';

  @override
  String get navToolsSection => 'Herramientas';

  @override
  String get agendaEmptyTitle => 'No hay eventos próximos';

  @override
  String get agendaEmptyBody =>
      'Los eventos del calendario de tu iglesia aparecerán aquí al sincronizar.';

  @override
  String get agendaNoEventsForDay => 'Nada en este día';

  @override
  String get agendaNoEventsForDayBody =>
      'Elige otro día en la barra de arriba.';

  @override
  String get agendaEventDetails => 'Evento';

  @override
  String get agendaEventNotFound => 'Evento no encontrado';

  @override
  String get agendaEventNotFoundBody =>
      'Este evento puede haberse eliminado o aún no se ha sincronizado.';

  @override
  String get agendaFieldDate => 'Fecha';

  @override
  String get agendaFieldTime => 'Hora';

  @override
  String get agendaFieldLocation => 'Lugar';

  @override
  String get agendaFieldNotes => 'Notas';

  @override
  String get agendaFieldResponsibilities => 'Equipo';

  @override
  String get agendaLinkedService => 'Servicio vinculado';

  @override
  String get agendaUnassigned => 'Sin asignar';

  @override
  String agendaMinutes(int count) {
    return '$count min';
  }

  @override
  String agendaResponsibilityCount(int count) {
    return '$count asignados';
  }

  @override
  String agendaAssigneeCount(int count) {
    return '$count personas';
  }

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
  String get songsEmpty => 'Aún no hay canciones';

  @override
  String get songsEmptyDesc =>
      'Las canciones de tu iglesia aparecerán aquí tras sincronizar.';

  @override
  String get songsNoResults => 'Sin resultados';

  @override
  String get songsNoResultsDesc => 'Prueba otra búsqueda o limpia los filtros.';

  @override
  String get songsFavoritesEmpty => 'Aún no hay favoritos';

  @override
  String get songsFavoritesEmptyDesc =>
      'Toca el corazón en una canción para guardarla aquí.';

  @override
  String get songsRecentsEmpty => 'Aún no hay recientes';

  @override
  String get songsRecentsEmptyDesc =>
      'Las canciones que abras aparecerán aquí.';

  @override
  String get songsNotFound => 'Canción no encontrada';

  @override
  String get songsNotFoundDesc =>
      'Esta canción puede haberse eliminado o aún no se ha sincronizado.';

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
  String get songsFilterByCollection => 'Filtrar por colección';

  @override
  String get songsFilterBySongNumber => 'Número de canción';

  @override
  String get songsNumberAny => 'Cualquiera';

  @override
  String get songsNumberOnly => 'Numeradas';

  @override
  String get songsNumberNone => 'Sin número';

  @override
  String get songsSearchLyrics => 'Buscar también en la letra';

  @override
  String get songsWithChords => 'Mostrar solo canciones con acordes';

  @override
  String get songsResetFilters => 'Restablecer filtros';

  @override
  String get songsClear => 'Limpiar';

  @override
  String get songsClearFilters => 'Limpiar filtros';

  @override
  String get songsClearSearch => 'Limpiar búsqueda';

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
  String get songsCreate => 'Nueva canción';

  @override
  String get songsEdit => 'Editar canción';

  @override
  String get songsPreview => 'Vista previa';

  @override
  String get songsFieldTitle => 'Título';

  @override
  String get songsFieldSubtitle => 'Subtítulo';

  @override
  String get songsFieldArtist => 'Artista';

  @override
  String get songsFieldComposer => 'Compositor';

  @override
  String get songsFieldLyricist => 'Letrista';

  @override
  String get songsFieldTranslator => 'Traductor';

  @override
  String get songsFieldArranger => 'Arreglista';

  @override
  String get songsFieldSongNumber => 'Número de canción';

  @override
  String get songsFieldKey => 'Tonalidad';

  @override
  String get songsFieldOriginalKey => 'Tonalidad original';

  @override
  String get songsFieldKeyNone => 'Ninguna';

  @override
  String get songsFieldTempo => 'Tempo (BPM)';

  @override
  String get songsFieldTime => 'Compás';

  @override
  String get songsFieldDuration => 'Duración (m:ss)';

  @override
  String get songsFieldCapo => 'Cejilla';

  @override
  String get songsFieldKeyNote => 'Nota de tonalidad';

  @override
  String get songsFieldAlbum => 'Álbum';

  @override
  String get songsFieldYear => 'Año';

  @override
  String get songsFieldCopyright => 'Copyright';

  @override
  String get songsFieldCcli => 'CCLI';

  @override
  String get songsFieldYoutube => 'URL / ID de YouTube';

  @override
  String get songsFieldTagsHint => 'Etiquetas separadas por comas';

  @override
  String get songsTabContent => 'Letra y acordes';

  @override
  String get songsTabMetadata => 'Detalles';

  @override
  String get songsTitleRequired => 'El título es obligatorio.';

  @override
  String get songsChordProHint =>
      '[G]Escribe la letra y los [C]acordes aquí…\nUsa las opciones de arriba para estrofa, estribillo y más.';

  @override
  String get songsEditorInsertVerse => 'Estrofa';

  @override
  String get songsEditorInsertChorus => 'Estribillo';

  @override
  String get songsEditorInsertBridge => 'Puente';

  @override
  String get songsEditorInsertComment => 'Comentario';

  @override
  String get songsEditorInsertVersion => 'Versión';

  @override
  String get songsLintAllClear => 'Sin problemas en el ChordPro.';

  @override
  String songsLintSummary(int errors, int warnings, int infos) {
    return '$errors errores · $warnings avisos · $infos pistas';
  }

  @override
  String songsLintLine(int line) {
    return 'L$line';
  }

  @override
  String get songsLintDetails => 'Detalles';

  @override
  String get songsLintUnclosedBrace => 'Llaves sin cerrar o desparejadas.';

  @override
  String get songsLintUnclosedBracket =>
      'Corchetes de acorde sin cerrar o desparejados.';

  @override
  String get songsLintEmptyChord => 'Acordes vacíos.';

  @override
  String songsLintUnknownChord(String chord) {
    return 'Acorde no reconocido \"$chord\".';
  }

  @override
  String get songsLintMalformedDirective =>
      'Directiva mal formada — revisa llaves y nombre.';

  @override
  String songsLintUnknownDirective(String name) {
    return 'Directiva no reconocida \"$name\".';
  }

  @override
  String songsLintUnclosedSection(String section) {
    return 'Sección $section sin cerrar — falta end_of_$section.';
  }

  @override
  String songsLintUnexpectedEndSection(String section) {
    return 'end_of_$section inesperado sin inicio correspondiente.';
  }

  @override
  String get songsLintInvalidYoutube =>
      'El valor de YouTube no es una URL o ID válido.';

  @override
  String songsLintInvalidKey(String value) {
    return 'Tonalidad inusual \"$value\". Se espera G, Am, F#m, …';
  }

  @override
  String get songsLintInvalidTempo =>
      'El tempo debe ser un BPM entre 20 y 400.';

  @override
  String get songsLintInvalidCapo => 'La cejilla debe ser un traste de 0 a 12.';

  @override
  String get songsLintInvalidTime => 'El compás debe verse como 4/4 o 6/8.';

  @override
  String get songsLintInvalidDuration =>
      'La duración debe ser segundos o m:ss (p. ej. 3:45).';

  @override
  String get songsNewSong => 'Nueva canción';

  @override
  String get songsCreateManually => 'Crear manualmente';

  @override
  String get songsCreateManuallyDesc => 'Título, acordes y letra.';

  @override
  String get songsImportWithAi => 'Importar con IA';

  @override
  String get songsImportWithAiDesc => 'Desde PDF, imagen o foto.';

  @override
  String get songsAddSong => 'Añadir canción';

  @override
  String get songsImportSheetMusic => 'Importa tu partitura';

  @override
  String get songsImportSheetMusicBody =>
      'Usa Logos AI para convertir PDFs, imágenes o fotos en canciones con letra, acordes y metadatos.';

  @override
  String get songsTakePhoto => 'Tomar foto';

  @override
  String get songsChooseGallery => 'Elegir de la galería';

  @override
  String get songsImportPdf => 'Importar PDF';

  @override
  String get songsHowItWorks => '¿Cómo funciona?';

  @override
  String get songsAiAnalyzing => 'Analizando la partitura…';

  @override
  String get songsAiAnalyzingBody =>
      'Logos está extrayendo letra, acordes e información.';

  @override
  String get songsAiStepProcess => 'Procesar el archivo';

  @override
  String get songsAiStepExtract => 'Extraer letra y acordes';

  @override
  String get songsAiStepMetadata => 'Identificar metadatos (título, tono, …)';

  @override
  String get songsAiStepVerify => 'Verificar en línea y completar metadatos';

  @override
  String get songsAiStepDraft => 'Preparar el borrador';

  @override
  String get songsAiPleaseWait => 'Esto puede tardar unos segundos…';

  @override
  String get songsAiResultTitle => 'Resultado de la importación';

  @override
  String get songsAiCreatedBanner =>
      'Canción creada con IA. Confirma y ajusta antes de guardar.';

  @override
  String get songsAiSave => 'Guardar';

  @override
  String get songsAiEditContent => 'Editar';

  @override
  String get songsAiImportFailed => 'No se pudo importar esta partitura';

  @override
  String get songsAiImportFailedBody =>
      'Prueba otra foto o PDF, o crea la canción manualmente.';

  @override
  String get songsAiCancelledTitle => 'No es una partitura';

  @override
  String get songsAiCancelledBody =>
      'Logos canceló esta importación. Prueba una foto más nítida de una cifra, o crea la canción manualmente.';

  @override
  String get songsAiCancelledGeneric =>
      'Esta imagen no parece una canción importable.';

  @override
  String get songsAiCancelledNotASong =>
      'Esto no parece una partitura o cifra.';

  @override
  String get songsAiCancelledUnreadable =>
      'La imagen está demasiado borrosa o oscura.';

  @override
  String get songsAiCancelledBlank => 'La página parece en blanco o vacía.';

  @override
  String get songsAiCancelledWrongContent =>
      'Hay texto, pero no es una canción / cifra.';

  @override
  String get songsAiCancelledMultiple =>
      'Parecen varias canciones mezcladas sin una principal clara.';

  @override
  String get songsAiCancelImport => 'Cancelar';

  @override
  String get songsAiDiscardDraft => 'Descartar borrador';

  @override
  String songsAiConfidence(String percent) {
    return 'Confianza de la IA: $percent%';
  }

  @override
  String get songsAiLowConfidence =>
      'Baja confianza — revisa bien la letra y los acordes antes de guardar.';

  @override
  String get songsAiSuccessTitle => 'Importación completada';

  @override
  String get songsAiSuccessBody => 'Se capturaron letra, acordes y metadatos.';

  @override
  String get songsAiViewSong => 'Ver canción';

  @override
  String get songsAiImportAnother => 'Importar otra';

  @override
  String get songsAiPossibleDuplicates =>
      'Posibles coincidencias en tu biblioteca';

  @override
  String get songsAiPossibleDuplicatesHint =>
      'Ábrela para comparar — volverás a este borrador. Guardar sigue creando una canción nueva.';

  @override
  String get songsAiOpenExisting => 'Abrir';

  @override
  String get songsAiLintIssues => 'Problemas de ChordPro';

  @override
  String get songsAiFieldComposer => 'Compositor';

  @override
  String get songsAiFieldCcli => 'CCLI';

  @override
  String get songsAiFieldDuration => 'Duración';

  @override
  String get songsAiFieldYoutube => 'YouTube';

  @override
  String get songsAiOpenYoutube => 'Abrir YouTube';

  @override
  String get songsAiCaptureTip =>
      'Usa luz uniforme y evita brillos o desenfoque para mejores resultados.';

  @override
  String get songsAiCaptureQualityHint =>
      'Esta imagen parece pequeña o de baja calidad — prueba una foto más nítida y bien iluminada.';

  @override
  String get songsAiPdfMultiPageHint =>
      'Se envían hasta 5 páginas en PDFs de varias páginas.';

  @override
  String get songsEmptyAddHint =>
      'Añade una canción manualmente o impórtala con Logos AI.';

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
  String get songBass => 'Bajo';

  @override
  String get songUkulele => 'Ukelele';

  @override
  String get songPiano => 'Piano';

  @override
  String get instrumentFamilyFretted => 'Con trastes';

  @override
  String get instrumentFamilyKeyboard => 'Teclado';

  @override
  String get settingsInstrumentConfig => 'Ajustes del instrumento';

  @override
  String get settingsInstrumentConfigDesc =>
      'Opciones del instrumento seleccionado — usadas al dibujar los diagramas de acordes.';

  @override
  String get settingsTuning => 'Afinación';

  @override
  String get settingsTuningDesc =>
      'Configuración de las cuerdas al aire para los diagramas.';

  @override
  String get settingsShowFingerNumbers => 'Mostrar números de dedos';

  @override
  String get settingsShowFingerNumbersDesc =>
      'Dibuja 1–4 dentro de los puntos del diagrama.';

  @override
  String get settingsShowCapoMarker => 'Mostrar capo en los diagramas';

  @override
  String get settingsShowCapoMarkerDesc =>
      'Dibuja el capo en la cejilla cuando está activo (estilo CifraClub).';

  @override
  String get settingsShowStringLabels => 'Mostrar nombres de cuerdas';

  @override
  String get settingsShowStringLabelsDesc =>
      'Etiqueta cada cuerda bajo el diagrama (E A D G B e, etc.).';

  @override
  String get settingsBassRootNotes => 'Solo notas fundamentales';

  @override
  String get settingsBassRootNotesDesc =>
      'Muestra una sola nota (tónica o bajo del acorde con barra) en lugar de formas completas.';

  @override
  String get settingsPianoCompactVoicing => 'Voicings compactos';

  @override
  String get settingsPianoCompactVoicingDesc =>
      'En acordes de 7ª y extensiones, omite la tónica en la mano derecha (ej.: C7 → Bb-E-G).';

  @override
  String get settingsPianoSlashSplit =>
      'Acordes con bajo: bajo en la mano izquierda';

  @override
  String get settingsPianoSlashSplitDesc =>
      'Toca el bajo del acorde con barra en la mano izquierda y el acorde en la derecha (ej.: A/C#).';

  @override
  String get tuningGuitarStandard => 'Estándar';

  @override
  String get tuningGuitarDropD => 'Drop D';

  @override
  String get tuningGuitarSevenString => '7 cuerdas';

  @override
  String get tuningBassFiveString => '5 cuerdas';

  @override
  String get tuningUkuleleHighG => 'Sol agudo';

  @override
  String get tuningUkuleleLowG => 'Sol grave';

  @override
  String get tuningUkuleleBaritone => 'Barítono';

  @override
  String get songAutoScrollStart => 'Iniciar desplazamiento automático';

  @override
  String get songAutoScrollPause => 'Pausar desplazamiento';

  @override
  String get songAutoScrollSpeed => 'Velocidad de desplazamiento';

  @override
  String get songYoutubeOpenPlayer => 'Escuchar en YouTube';

  @override
  String get songYoutubeClosePlayer => 'Cerrar reproductor';

  @override
  String get songYoutubePlay => 'Reproducir';

  @override
  String get songYoutubePause => 'Pausar';

  @override
  String get songYoutubeRewind => 'Retroceder 10 segundos';

  @override
  String get songYoutubeForward => 'Avanzar 30 segundos';

  @override
  String get songYoutubeError => 'No se pudo reproducir este video';

  @override
  String get songSectionChorus => 'Estribillo';

  @override
  String get songSectionBridge => 'Puente';

  @override
  String get songSectionTab => 'Tablatura';

  @override
  String get songSectionInstrumental => 'Instrumental';

  @override
  String get songRepeatChorus => '(Repetir estribillo)';

  @override
  String songKeyPill(Object key) {
    return 'Tono: $key';
  }

  @override
  String songCapoPill(Object fret) {
    return 'Capo: traste $fret';
  }

  @override
  String songShapePill(Object key) {
    return 'Formas: $key';
  }

  @override
  String songOriginalKeyPill(Object key) {
    return 'Tono original: $key';
  }

  @override
  String songTranslatorCredit(String name) {
    return 'Traducción: $name';
  }

  @override
  String songLyricistCredit(String name) {
    return 'Letra: $name';
  }

  @override
  String songArrangerCredit(String name) {
    return 'Arreglo: $name';
  }

  @override
  String songNumberPill(Object number) {
    return 'Nº $number';
  }

  @override
  String songCapoOnFret(Object fret) {
    return 'Capo en el traste $fret';
  }

  @override
  String get songChangeKey => 'Cambiar tono';

  @override
  String songChordTitle(Object chord) {
    return 'Acorde: $chord';
  }

  @override
  String songChordNotFound(Object chord) {
    return 'Acorde \"$chord\" no registrado';
  }

  @override
  String songChordNotes(Object notes) {
    return 'Notas: $notes';
  }

  @override
  String songChordSemantics(Object chord) {
    return 'Acorde $chord';
  }

  @override
  String get songPreviousChord => 'Acorde anterior';

  @override
  String get songNextChord => 'Acorde siguiente';

  @override
  String get songPrevious => 'Anterior';

  @override
  String get songNext => 'Siguiente';

  @override
  String get foldersTitle => 'Carpetas';

  @override
  String get foldersEmpty => 'Aún no hay carpetas';

  @override
  String get foldersEmptyDesc =>
      'Las carpetas organizan la biblioteca de canciones de tu iglesia.';

  @override
  String get folderContentsEmpty => 'Esta carpeta está vacía';

  @override
  String get folderContentsEmptyDesc =>
      'Aún no hay canciones ni subcarpetas aquí. Añade una canción, impórtala con Logos AI, o muévelas a esta carpeta desde Studio.';

  @override
  String get folderContentsEmptyReadonlyDesc =>
      'Aún no hay canciones ni subcarpetas aquí. Pide a un líder que las añada en Studio, o vuelve tras la próxima sincronización.';

  @override
  String get foldersNoResultsDesc =>
      'Prueba otra búsqueda o limpia los filtros.';

  @override
  String get collectionsEmpty => 'Aún no hay colecciones';

  @override
  String get collectionsEmptyDesc =>
      'Las colecciones aparecen aquí cuando tu iglesia las cree.';

  @override
  String get collectionsSearchHint => 'Buscar colecciones…';

  @override
  String get collectionContentsEmpty => 'Esta colección está vacía';

  @override
  String get collectionContentsEmptyDesc =>
      'Aún no hay canciones en esta colección. Añádelas desde Studio — una canción puede pertenecer a varias colecciones a la vez.';

  @override
  String get collectionContentsEmptyReadonlyDesc =>
      'Aún no hay canciones en esta colección. Pide a un líder que las añada en Studio, o vuelve tras la próxima sincronización.';

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
  String get foldersViewGrid => 'Vista de cuadrícula';

  @override
  String get foldersViewList => 'Vista de lista';

  @override
  String get servicesTitle => 'Servicios';

  @override
  String get servicesEmpty => 'Aún no hay servicios';

  @override
  String get servicesEmptyDesc =>
      'Los servicios y planes de adoración de tu iglesia aparecerán aquí.';

  @override
  String get servicesSearchHint => 'Buscar servicios…';

  @override
  String get servicesNoResults => 'Sin servicios coincidentes';

  @override
  String get servicesNoResultsDesc => 'Prueba otra búsqueda.';

  @override
  String get servicesNoResultsFiltersDesc =>
      'Nada coincide con estos filtros. Prueba a limpiarlos.';

  @override
  String get servicesFilter => 'Filtrar servicios';

  @override
  String get servicesSortDate => 'Fecha';

  @override
  String get servicesSortName => 'Nombre';

  @override
  String get servicesFilterWhen => 'Cuándo';

  @override
  String get servicesFilterDateAll => 'Todas las fechas';

  @override
  String get servicesFilterUpcoming => 'Próximos';

  @override
  String get servicesFilterPast => 'Pasados';

  @override
  String get servicesFilterToday => 'Hoy';

  @override
  String get servicesFilterThisWeek => 'Esta semana';

  @override
  String get servicesFilterThisMonth => 'Este mes';

  @override
  String get servicesFilterStatus => 'Estado';

  @override
  String get servicesFilterActive => 'Activos';

  @override
  String get servicesFilterArchivedOnly => 'Archivados';

  @override
  String get servicesFilterIncludeArchived => 'Activos + archivados';

  @override
  String get servicesFilterContent => 'Plan';

  @override
  String get servicesFilterContentAny => 'Cualquiera';

  @override
  String get servicesFilterWithSongs => 'Con canciones';

  @override
  String get servicesFilterWithNotes => 'Con notas';

  @override
  String get servicesFilterEmptyPlan => 'Plan vacío';

  @override
  String get servicesNextService => 'Próximo servicio';

  @override
  String get servicesNoUpcoming => 'Sin servicios próximos';

  @override
  String get servicesNoUpcomingDesc =>
      'No hay servicios programados en este momento.';

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
  String get servicesNoItems => 'Servicio sin elementos';

  @override
  String get servicesNoItemsDesc =>
      'Este servicio aún no tiene momentos ni canciones.';

  @override
  String get servicesNotFound => 'Servicio no encontrado';

  @override
  String get servicesNotFoundDesc =>
      'Este servicio puede haberse eliminado o aún no se ha sincronizado.';

  @override
  String get servicesOrderTitle => 'Orden del Servicio';

  @override
  String get servicesArchived => 'Archivado';

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
  String get servicesMore => 'Más';

  @override
  String get servicesInProgress => 'En curso';

  @override
  String get servicesItemDetail => 'Detalle del elemento';

  @override
  String get servicesEstimatedDuration => 'Duración estimada';

  @override
  String get servicesPassage => 'Pasaje';

  @override
  String get servicesMarkCompleted => 'Marcar como completado';

  @override
  String get servicesLeaderNotes => 'Notas del líder';

  @override
  String get servicesLeaderNotesHint => 'Añadir notas sobre este momento…';

  @override
  String get servicesTeamNotes => 'Notas del equipo';

  @override
  String get servicesNotesEmpty => 'Aún no hay notas';

  @override
  String get servicesNotesEmptyDesc =>
      'Comparte actualizaciones con el equipo durante el servicio.';

  @override
  String get servicesNotesAdd => 'Añadir nota';

  @override
  String get servicesNotesEdit => 'Editar nota';

  @override
  String get servicesNotesDelete => 'Eliminar';

  @override
  String get servicesNotesDeleteTitle => '¿Eliminar nota?';

  @override
  String get servicesNotesDeleteDesc =>
      'Esta nota se eliminará para todos los que puedan verla.';

  @override
  String get servicesNotesHint => 'Escribe una nota para el equipo…';

  @override
  String get servicesNotesPrivate => 'Nota privada';

  @override
  String get servicesNotesPrivateDesc => 'Solo tú puedes ver esta nota.';

  @override
  String get servicesNotesSubscriptionRequired =>
      'Se requiere una suscripción activa para añadir o editar notas.';

  @override
  String get servicesNotesForbidden =>
      'No tienes permiso para cambiar esta nota.';

  @override
  String get servicesNotesUnauthorized =>
      'Inicia sesión de nuevo para gestionar notas.';

  @override
  String get servicesNotesNotFound => 'Esta nota ya no existe.';

  @override
  String get servicesNotesElementNotFound =>
      'Ese elemento del servicio no se encontró.';

  @override
  String get servicesNotesSomeone => 'Alguien';

  @override
  String get servicesNotesQuickSend => 'Envío rápido';

  @override
  String get servicesNotesStale => 'Las notas pueden estar desactualizadas';

  @override
  String get servicesNotesStaleRetry => 'Toca para actualizar';

  @override
  String get servicesNotesServiceSection => 'Servicio completo';

  @override
  String get servicesNotesServiceSectionDesc =>
      'Notas visibles para todo el servicio, no ligadas a este elemento.';

  @override
  String get servicesNotesAddService => 'Añadir nota del servicio';

  @override
  String get servicesNotesAddItem => 'Añadir nota del elemento';

  @override
  String get servicesStartService => 'Iniciar servicio';

  @override
  String get servicesStartServiceDesc =>
      'Inicia el temporizador cuando comience el servicio.';

  @override
  String servicesScheduledWindow(String window) {
    return 'Programado $window';
  }

  @override
  String servicesItemRunning(String elapsed) {
    return 'Este elemento · $elapsed';
  }

  @override
  String get servicesNotStarted => 'No iniciado';

  @override
  String get noteSugReadyToStart => 'Listos para empezar';

  @override
  String get noteSugStandbyNext => 'Standby para el siguiente';

  @override
  String get noteSugGoNextItem => 'Pasamos al siguiente';

  @override
  String get noteSugHoldWait => 'Esperad';

  @override
  String get noteSugWrapUp => 'Cerrar este momento';

  @override
  String get noteSugBehindSchedule => 'Vamos atrasados';

  @override
  String get noteSugAheadSchedule => 'Vamos adelantados';

  @override
  String get noteSugSkipItem => 'Saltar este elemento';

  @override
  String get noteSugExtendMoment => 'Prolongar este momento';

  @override
  String get noteSugChangeOfPlan => 'Cambio de plan';

  @override
  String get noteSugLookingGood => 'Va muy bien';

  @override
  String get noteSugNeedHelp => 'Necesito ayuda en el escenario';

  @override
  String get noteSugQuietMoment => 'Momento de silencio';

  @override
  String get noteSugPrayTogether => 'Oremos juntos';

  @override
  String get noteSugDoorsClosing => 'Cerrando puertas';

  @override
  String get noteSugGuestsReady => 'Recepción / invitados listos';

  @override
  String get noteSugMicLive => 'Micrófono en vivo';

  @override
  String get noteSugMicMute => 'Silenciar ese micrófono';

  @override
  String get noteSugMicCheck => 'Hace falta prueba de micrófono';

  @override
  String get noteSugFeedbackMute => 'Acoplamiento — silenciar ya';

  @override
  String get noteSugSpareMic => 'Traer micrófono de reserva';

  @override
  String get noteSugSlidesReady => 'Diapositivas listas';

  @override
  String get noteSugNextSlide => 'Siguiente diapositiva';

  @override
  String get noteSugWrongSlide => 'Diapositiva incorrecta';

  @override
  String get noteSugBlankScreen => 'Pantalla en negro';

  @override
  String get noteSugLyricsReady => 'Letras listas';

  @override
  String get noteSugAdvanceLyrics => 'Avanzar letras';

  @override
  String get noteSugRepeatChorusSlide => 'Repetir coro en pantalla';

  @override
  String get noteSugLightsUp => 'Luces más altas';

  @override
  String get noteSugLightsDown => 'Luces más bajas';

  @override
  String get noteSugLightsAdjust => 'Ajustar luces';

  @override
  String get noteSugVideoPlay => 'Reproducir vídeo';

  @override
  String get noteSugVideoIssue => 'Problema con el vídeo';

  @override
  String get noteSugStreamIssue => 'Problema con el stream';

  @override
  String get noteSugHouseVolumeDown => 'Bajar volumen de sala';

  @override
  String get noteSugHouseVolumeUp => 'Subir volumen de sala';

  @override
  String get noteSugVocalsUp => 'Subir voces';

  @override
  String get noteSugBandDown => 'Bajar banda en la mezcla';

  @override
  String get noteSugVerse1 => 'Estrofa 1';

  @override
  String get noteSugVerse2 => 'Estrofa 2';

  @override
  String get noteSugVerse3 => 'Estrofa 3';

  @override
  String get noteSugChorus => 'Coro';

  @override
  String get noteSugBridge => 'Puente';

  @override
  String get noteSugPreChorus => 'Precoro';

  @override
  String get noteSugTag => 'Tag';

  @override
  String get noteSugInstrumental => 'Instrumental';

  @override
  String get noteSugRepeatSection => 'Repetir esta sección';

  @override
  String get noteSugEndSong => 'Terminar canción';

  @override
  String get noteSugBuildUp => 'Subir la intensidad';

  @override
  String get noteSugBringDown => 'Bajar la intensidad';

  @override
  String get noteSugDrumsVocals => 'Solo batería + voces';

  @override
  String get noteSugSoftPads => 'Solo pads suaves';

  @override
  String get noteSugCutVocals => 'Cortar voces';

  @override
  String get noteSugBandTakeIt => 'Banda asume';

  @override
  String get noteSugSpontaneousStay => 'Quedarnos aquí — espontáneo';

  @override
  String get noteSugTempoUp => 'Subir el tempo';

  @override
  String get noteSugTempoDown => 'Bajar el tempo';

  @override
  String get noteSugKeyChange => 'Cambio de tono próximo';

  @override
  String get noteSugMoreMonitor => 'Más de mí en monitores';

  @override
  String get noteSugLessMonitor => 'Menos de mí en monitores';

  @override
  String get noteSugClickLouder => 'Click / guía más alto';

  @override
  String get noteSugLostClick => 'Perdí el click';

  @override
  String get noteSugWrongChart => 'Cifrado / arreglo incorrecto';

  @override
  String get noteSugReadyNextSong => 'Listos para la siguiente canción';

  @override
  String get noteSugStartSong => 'Empezar la canción';

  @override
  String get noteSugStartWelcome => 'Empezar bienvenida';

  @override
  String get noteSugWrapWelcome => 'Cerrar bienvenida';

  @override
  String get noteSugOpenDoors => 'Abrir puertas';

  @override
  String get noteSugHospitalityReady => 'Equipo de hospitalidad listo';

  @override
  String get noteSugReaderReady => 'Lector listo';

  @override
  String get noteSugPassageOnScreen => 'Pasaje en pantalla';

  @override
  String get noteSugAdvanceVerse => 'Avanzar versículo';

  @override
  String get noteSugSoftUnderscore => 'Fondo musical suave';

  @override
  String get noteSugAfterReading => 'Después de la lectura — siguiente';

  @override
  String get noteSugPastorWalkingUp => 'Pastor subiendo';

  @override
  String get noteSugPastorMicLive => 'Micrófono del pastor en vivo';

  @override
  String get noteSugSermonSlidesReady => 'Diapositivas del mensaje listas';

  @override
  String get noteSugNextSermonSlide => 'Siguiente diapositiva del mensaje';

  @override
  String get noteSugTimerCheck => 'Revisar el tiempo';

  @override
  String get noteSugAltarCallComing => 'Llamado al altar próximo';

  @override
  String get noteSugClosingPrayer => 'Oración final';

  @override
  String get noteSugSoftMusicUnder => 'Música suave debajo';

  @override
  String get noteSugMessageLights => 'Iluminación del mensaje';

  @override
  String get noteSugAnnouncementsStart => 'Anuncios empezando';

  @override
  String get noteSugNextAnnouncement => 'Siguiente anuncio';

  @override
  String get noteSugWrapAnnouncements => 'Cerrar anuncios';

  @override
  String get noteSugGivingMoment => 'Ofrenda / dádivas';

  @override
  String get noteSugConnectionReminder => 'Recordatorio de conexión';

  @override
  String get servicesElementEmpty => 'Nada preparado para este momento';

  @override
  String get servicesElementEmptyDesc =>
      'Aún no hay pasaje, contenido ni notas en este elemento.';

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
  String get settingsTabService => 'Servicio';

  @override
  String get settingsTabAppearance => 'Apariencia';

  @override
  String get settingsSubscriptionInactive => 'Sin suscripción activa';

  @override
  String get settingsSubscriptionInactiveDesc =>
      'Esta organización es de solo lectura hasta que haya una suscripción o prueba activa. Aún puedes consultar el contenido sincronizado.';

  @override
  String get settingsOrgSwitching => 'Cambiando de organización…';

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
  String get settingsMusicianMode => 'Modo músico';

  @override
  String get settingsMusicianModeDesc =>
      'Abre los servicios en la primera canción con acordes y anotaciones. Desactívalo para la vista de orden del servicio con letras y tiempos.';

  @override
  String get settingsServiceOrderSidePanel =>
      'Panel lateral del orden del servicio';

  @override
  String get settingsServiceOrderSidePanelDesc =>
      'En tablets, mantiene el orden del servicio visible junto al elemento actual en los modos músico y no músico.';

  @override
  String get servicesCollapseOrderPanel => 'Contraer panel del orden';

  @override
  String get servicesExpandOrderPanel => 'Expandir panel del orden';

  @override
  String get settingsKeepAwake => 'Mantener Pantalla Encendida';

  @override
  String get settingsKeepAwakeDesc =>
      'Evita que la pantalla se suspenda al ver canciones.';

  @override
  String get settingsSyncAnnotations => 'Sincronizar anotaciones';

  @override
  String get settingsSyncAnnotationsDesc =>
      'Permite que las anotaciones se compartan en vivo entre todos los usuarios';

  @override
  String get settingsNotifications =>
      'Permitir notificaciones en este dispositivo';

  @override
  String get settingsNotificationsDesc =>
      'Permite que el servidor envíe notificaciones a esta sesión. Es independiente del permiso de notificaciones del sistema.';

  @override
  String get notificationConsentTitle =>
      '¿Permitir notificaciones en este dispositivo?';

  @override
  String get notificationConsentMessage =>
      'Si lo permites, el servidor podrá enviarte avisos de servicios y novedades de la biblioteca en este dispositivo. Puedes cambiarlo en Ajustes.';

  @override
  String get notificationConsentAllow => 'Permitir';

  @override
  String get notificationConsentNotNow => 'Ahora no';

  @override
  String get notificationOpenAction => 'Abrir';

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
  String get metronomePlay => 'Reproducir';

  @override
  String get metronomePause => 'Pausar';

  @override
  String get metronomeAudioUnavailable =>
      'El sonido del metrónomo no está disponible en este dispositivo.';

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

  @override
  String get annotationModeTitle => 'Anotaciones';

  @override
  String get annotationPen => 'Pluma';

  @override
  String get annotationEraser => 'Borrador de Trazo';

  @override
  String get annotationPixelEraser => 'Borrador Parcial';

  @override
  String get annotationLine => 'Línea';

  @override
  String get annotationRectangle => 'Rectángulo';

  @override
  String get annotationEllipse => 'Círculo';

  @override
  String get annotationSelect => 'Seleccionar';

  @override
  String get annotationLasso => 'Lazo';

  @override
  String get annotationText => 'Texto';

  @override
  String get annotationLayers => 'Capas';

  @override
  String get annotationUndo => 'Deshacer';

  @override
  String get annotationRedo => 'Rehacer';

  @override
  String get annotationClear => 'Borrar Todo';

  @override
  String get annotationClearConfirm =>
      '¿Borrar todas las anotaciones de esta canción?';

  @override
  String get annotationColorPicker => 'Color Personalizado';

  @override
  String get annotationClose => 'Listo';

  @override
  String get annotationRemoteChanges => 'Nuevos cambios de otro dispositivo';

  @override
  String get annotationKeepMine => 'Mantener los míos';

  @override
  String get annotationReload => 'Recargar';

  @override
  String get songVariant => 'Versión';

  @override
  String songVariantTooltip(String name) {
    return 'Versión: $name';
  }

  @override
  String get settingsLanguageSystem => 'Sistema';

  @override
  String get settingsFontPreview => 'Ejemplo';
}
