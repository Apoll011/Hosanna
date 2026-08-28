// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Hosanna';

  @override
  String get appTagline =>
      'A sua biblioteca e planos de louvor, sempre sincronizados.';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonBack => 'Voltar';

  @override
  String get commonRetry => 'Tentar novamente';

  @override
  String get commonLoading => 'A carregar…';

  @override
  String get commonOk => 'OK';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonSearch => 'Pesquisar';

  @override
  String get commonError => 'Ocorreu um erro';

  @override
  String get commonOffline => 'Sem ligação à internet';

  @override
  String get commonDone => 'Concluir';

  @override
  String get commonNext => 'Seguinte';

  @override
  String get commonUnknown => 'Desconhecido';

  @override
  String get commonOpenDrawer => 'Abrir menu';

  @override
  String get authSignIn => 'Iniciar Sessão';

  @override
  String get authSignUp => 'Criar Conta';

  @override
  String get authSignOut => 'Terminar Sessão';

  @override
  String get authEmail => 'Endereço de E-mail';

  @override
  String get authPassword => 'Palavra-passe';

  @override
  String get authName => 'Nome Completo';

  @override
  String get authConfirmPassword => 'Confirmar Palavra-passe';

  @override
  String get authForgotPassword => 'Esqueceu-se da palavra-passe?';

  @override
  String get authSignInTitle => 'Bem-vindo de volta';

  @override
  String get authSignUpTitle => 'Criar Conta no Hosanna';

  @override
  String get authSignInSubtitle =>
      'Inicie sessão para aceder à sua biblioteca.';

  @override
  String get authSignUpSubtitle =>
      'Registe-se para começar a organizar os seus cânticos.';

  @override
  String get authSignInButton => 'Entrar na Conta';

  @override
  String get authSignUpButton => 'Registar Nova Conta';

  @override
  String get authCreateAccount => 'Criar conta';

  @override
  String get authNoAccount => 'Ainda não tem conta?';

  @override
  String get authHaveAccount => 'Já tem uma conta?';

  @override
  String get authSignInError =>
      'Erro ao iniciar sessão. Verifique as credenciais.';

  @override
  String get authSignUpError => 'Erro ao criar conta.';

  @override
  String get authPasswordMinLength =>
      'A palavra-passe deve ter pelo menos 6 caracteres.';

  @override
  String get authPasswordsDontMatch => 'As palavras-passe não coincidem.';

  @override
  String get authRequiredFields =>
      'Por favor preencha o e-mail e a palavra-passe.';

  @override
  String get authNameRequired => 'Por favor introduza o seu nome.';

  @override
  String get authEmailInvalid => 'Por favor introduza um e-mail válido.';

  @override
  String get authVerifyEmail => 'Verificar E-mail';

  @override
  String get authVerifyEmailTitle => 'Verifique o seu e-mail';

  @override
  String get authVerifyEmailMessage =>
      'Enviámos uma ligação de verificação para o seu e-mail. Abra-a para confirmar a sua conta.';

  @override
  String get authCheckEmail => 'Verificar caixa de entrada';

  @override
  String get authResendEmail => 'Reenviar e-mail de verificação';

  @override
  String get authEmailVerificationSent => 'E-mail de verificação enviado!';

  @override
  String get authResetPassword => 'Repor Palavra-passe';

  @override
  String get authResetPasswordTitle => 'Repor palavra-passe';

  @override
  String get authResetPasswordMessage =>
      'Introduza o seu e-mail e enviaremos uma ligação para repor a palavra-passe.';

  @override
  String get authSendResetLink => 'Enviar Ligação de Reposição';

  @override
  String get authResetLinkSent =>
      'Se o e-mail existir, enviámos uma ligação de reposição.';

  @override
  String get authNewPassword => 'Nova Palavra-passe';

  @override
  String get authCurrentPassword => 'Palavra-passe Atual';

  @override
  String get authChangePassword => 'Alterar Palavra-passe';

  @override
  String get authAccount => 'Conta';

  @override
  String get authProfile => 'Perfil';

  @override
  String get authEditProfile => 'Editar Perfil';

  @override
  String get authNameSaved => 'Nome guardado com sucesso!';

  @override
  String get authPasswordChanged => 'Palavra-passe alterada com sucesso!';

  @override
  String get authPasswordChangeError =>
      'Erro ao alterar palavra-passe. Verifique a palavra-passe atual.';

  @override
  String get authEmailVerified => 'E-mail verificado';

  @override
  String get authEmailNotVerified => 'E-mail por verificar';

  @override
  String get authCaptchaNotConfigured =>
      'A verificação de segurança (captcha) não está configurada.';

  @override
  String get onboardingTitle => 'Bem-vindo ao Hosanna';

  @override
  String get onboardingSubtitle =>
      'Aceite um convite para entrar na organização da sua igreja.';

  @override
  String onboardingPendingInvites(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count convites pendentes',
      one: '1 convite pendente',
    );
    return '$_temp0';
  }

  @override
  String get onboardingNoInvites => 'Sem convites pendentes';

  @override
  String get onboardingNoInvitesDesc =>
      'Peça a um administrador da sua igreja para o convidar.';

  @override
  String get onboardingAccept => 'Aceitar';

  @override
  String get onboardingReject => 'Recusar';

  @override
  String get onboardingRole => 'Função';

  @override
  String get onboardingLoadingInvites => 'A carregar convites…';

  @override
  String get onboardingSignOut => 'Terminar Sessão';

  @override
  String get syncSyncing => 'A sincronizar…';

  @override
  String get syncSynced => 'Sincronizado';

  @override
  String get syncError => 'Erro de sincronização';

  @override
  String get syncOffline => 'Sem ligação';

  @override
  String syncLastSynced(Object time) {
    return 'Última sincronização: $time';
  }

  @override
  String get syncNever => 'Nunca sincronizado';

  @override
  String get syncNow => 'Sincronizar agora';

  @override
  String get syncPullToRefresh => 'Puxe para sincronizar';

  @override
  String get navSongs => 'Cânticos';

  @override
  String get navServices => 'Cultos';

  @override
  String get navFolders => 'Pastas';

  @override
  String get navSettings => 'Definições';

  @override
  String get navCircleOfFifths => 'Círculo de Quintas';

  @override
  String get navMetronome => 'Metrónomo';

  @override
  String get navExportPdf => 'Exportar PDF';

  @override
  String get navLibrarySection => 'Biblioteca';

  @override
  String get navToolsSection => 'Ferramentas';

  @override
  String get navAllSongs => 'Todos os cânticos';

  @override
  String get navFavorites => 'Favoritos';

  @override
  String get navRecents => 'Recentes';

  @override
  String get songsTitle => 'Cânticos';

  @override
  String get songsSearchHint => 'Pesquisar cânticos…';

  @override
  String get songsEmpty => 'Sem cânticos';

  @override
  String get songsNoResults => 'Sem resultados';

  @override
  String get songsAllSongs => 'Todos os cânticos';

  @override
  String get songsFilterByFolder => 'Filtrar por pasta';

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
  String get songsSortUpdated => 'Atualização';

  @override
  String get songsTitleLabel => 'Título';

  @override
  String get songsArtistLabel => 'Artista';

  @override
  String get songsFolderLabel => 'Pasta';

  @override
  String get songsTagsLabel => 'Etiquetas';

  @override
  String get songsChordPro => 'ChordPro';

  @override
  String get songsRawContent => 'Conteúdo em bruto (ChordPro)';

  @override
  String get songsNoContent => 'Sem conteúdo disponível.';

  @override
  String get songKey => 'Tom';

  @override
  String get songCapo => 'Capo';

  @override
  String get songChords => 'Acordes';

  @override
  String get songInstrument => 'Instrumento';

  @override
  String get songDiagrams => 'Diagramas';

  @override
  String get songControlsTitle => 'Ajustes de Leitura';

  @override
  String get songTranspose => 'Transposição';

  @override
  String get songSemitones => 'semitons';

  @override
  String get songOriginal => 'Original';

  @override
  String get songCapoNone => 'Nenhum';

  @override
  String songCapoFret(Object fret) {
    return 'Traste $fret';
  }

  @override
  String get songFontSize => 'Tamanho da Letra';

  @override
  String get songShowChords => 'Mostrar Acordes';

  @override
  String get songTwoColumn => 'Layout em 2 Colunas';

  @override
  String get songShowDiagrams => 'Mostrar Diagramas';

  @override
  String get songGuitar => 'Guitarra';

  @override
  String get songPiano => 'Piano';

  @override
  String get foldersTitle => 'Pastas';

  @override
  String get foldersEmpty => 'Sem pastas';

  @override
  String get foldersSubfolders => 'Subpastas';

  @override
  String foldersSongsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cânticos',
      one: '1 cântico',
    );
    return '$_temp0';
  }

  @override
  String get foldersRoot => 'Raiz';

  @override
  String get servicesTitle => 'Cultos';

  @override
  String get servicesEmpty => 'Sem cultos';

  @override
  String get servicesItems => 'Itens';

  @override
  String get servicesNotes => 'Notas';

  @override
  String get servicesGeneralNotes => 'Notas gerais';

  @override
  String get servicesItemNotes => 'Notas do item';

  @override
  String get servicesOrderedItems => 'Itens ordenados';

  @override
  String get servicesNoItems => 'Sem itens neste culto.';

  @override
  String get servicesOrderTitle => 'Ordem do Culto';

  @override
  String get servicesLeave => 'Sair';

  @override
  String get servicesLeaveMode => 'Sair do Modo Culto';

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
    return 'Item $current de $total';
  }

  @override
  String get servicesAddNotes => 'Toque para adicionar anotações…';

  @override
  String get servicesElementSong => 'Cântico';

  @override
  String get servicesElementWelcome => 'Boas-vindas';

  @override
  String get servicesElementScripture => 'Escritura';

  @override
  String get servicesElementMessage => 'Mensagem';

  @override
  String get servicesElementAnnouncement => 'Avisos';

  @override
  String get servicesElementDefault => 'Elemento';

  @override
  String get settingsTitle => 'Definições';

  @override
  String get settingsAppearance => 'Aspeto';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Escuro';

  @override
  String get settingsHighContrast => 'Alto contraste';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageLabel => 'Idioma da aplicação';

  @override
  String get settingsAccount => 'Conta';

  @override
  String get settingsOffline => 'Modo offline';

  @override
  String get metronomeTitle => 'Metrónomo';

  @override
  String get metronomeDescription => 'Tempo e compasso para ensaios.';

  @override
  String get circleOfFifthsTitle => 'Círculo de Quintas';

  @override
  String get circleOfFifthsDescription => 'Referência de tons e relativas.';

  @override
  String get exportPdfTitle => 'Exportar PDF';

  @override
  String get comingSoon => 'Em breve';

  @override
  String get comingSoonDescription =>
      'Esta funcionalidade estará disponível numa próxima versão.';
}
