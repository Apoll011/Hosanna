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
  String get commonErrorDesc => 'Verifique a ligação e tente novamente.';

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
  String get commonCloseDrawer => 'Fechar o Menu';

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
  String get authCaptchaWindowTitle => 'Verificação de segurança (captcha)';

  @override
  String get authCaptchaWaitingMessage =>
      'Conclua a verificação de segurança na janela de captcha que acabou de abrir.';

  @override
  String get authCaptchaOpenFailed =>
      'Não foi possível abrir a janela de captcha.';

  @override
  String get authOr => 'ou';

  @override
  String authContinueWith(String provider) {
    return 'Continuar com $provider';
  }

  @override
  String get authSocialNoAccount =>
      'Nenhuma conta disponível para iniciar sessão neste dispositivo.';

  @override
  String get authSocialUnavailable =>
      'Este dispositivo não suporta este método de início de sessão.';

  @override
  String get authSocialNotConfigured =>
      'O início de sessão social não está configurado nesta versão.';

  @override
  String get authSocialRejected =>
      'Não foi possível verificar a sua conta. Tente novamente.';

  @override
  String get authSocialNetworkError =>
      'Sem ligação ao servidor. Verifique a sua Internet.';

  @override
  String get authSocialServerError =>
      'O servidor não conseguiu concluir o início de sessão. Tente novamente.';

  @override
  String get authSocialError => 'Não foi possível iniciar sessão.';

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
  String get setupWelcomeTitle => 'Vamos configurar o Hosanna';

  @override
  String get setupWelcomeSubtitle =>
      'Algumas escolhas rápidas para que canções e cultos fiquem certos para a forma como serve.';

  @override
  String get setupWelcomeCta => 'Começar';

  @override
  String get setupRoleTitle => 'Como usa o Hosanna?';

  @override
  String get setupRoleSubtitle =>
      'Abrimos os cultos da forma que melhor se adequa ao seu papel. Pode mudar isto depois nas Definições.';

  @override
  String get setupRoleMusician => 'Músico';

  @override
  String get setupRoleMusicianDesc =>
      'Entre direto nas canções com acordes, capo e diagramas.';

  @override
  String get setupRoleLeader => 'Líder';

  @override
  String get setupRoleLeaderDesc =>
      'Comece pela ordem do culto e pelas notas do momento.';

  @override
  String get setupFocusTitle => 'O que toca?';

  @override
  String get setupFocusSubtitle =>
      'Isto define o instrumento predefinido para os diagramas de acordes.';

  @override
  String get setupFocusGuitar => 'Guitarra';

  @override
  String get setupFocusBass => 'Baixo';

  @override
  String get setupFocusUkulele => 'Ukulele';

  @override
  String get setupFocusPiano => 'Piano / teclas';

  @override
  String get setupFocusVocals => 'Voz';

  @override
  String get setupFocusVocalsDesc =>
      'Letra em primeiro — os acordes ficam disponíveis quando precisar.';

  @override
  String get setupLeaderFocusTitle => 'Quando abre uma canção…';

  @override
  String get setupLeaderFocusSubtitle =>
      'Opcional — escolha um instrumento para as cifras ao rever canções.';

  @override
  String get setupPrefsTitle => 'Predefinições para o palco';

  @override
  String get setupPrefsSubtitle => 'Opções úteis para ensaios e culto ao vivo.';

  @override
  String get setupPrefDiagrams => 'Mostrar diagramas de acordes';

  @override
  String get setupPrefDiagramsDesc =>
      'Digitação acima da canção quando disponível.';

  @override
  String get setupPrefAwake => 'Manter o ecrã ligado';

  @override
  String get setupPrefAwakeDesc => 'Não escurecer durante uma canção ou culto.';

  @override
  String get setupLanguageTitle => 'Idioma';

  @override
  String get setupLanguageSubtitle => 'Escolha o idioma dos menus e etiquetas.';

  @override
  String get setupLanguageSystem => 'Seguir o dispositivo';

  @override
  String get setupDoneTitle => 'Está pronto';

  @override
  String get setupDoneSubtitle =>
      'O Hosanna está configurado para si. Entre na biblioteca quando quiser.';

  @override
  String get setupDoneCta => 'Entrar no Hosanna';

  @override
  String get setupSkip => 'Saltar por agora';

  @override
  String setupStepOf(int current, int total) {
    return 'Passo $current de $total';
  }

  @override
  String get settingsRedoSetup => 'Repetir configuração';

  @override
  String get settingsRedoSetupDesc =>
      'Voltar a responder às perguntas de função e instrumento.';

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
  String get songsSavedOffline =>
      'Guardado neste dispositivo. As alterações sincronizam quando voltares a ter ligação.';

  @override
  String get syncPullToRefresh => 'Puxe para sincronizar';

  @override
  String get navSongs => 'Cânticos';

  @override
  String get navServices => 'Cultos';

  @override
  String get navFolders => 'Pastas';

  @override
  String get navCollections => 'Coleções';

  @override
  String get navSettings => 'Definições';

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
  String get navToolsSection => 'Ferramentas';

  @override
  String get agendaEmptyTitle => 'Sem eventos próximos';

  @override
  String get agendaEmptyBody =>
      'Os eventos do calendário da igreja aparecem aqui depois de sincronizar.';

  @override
  String get agendaNoEventsForDay => 'Nada neste dia';

  @override
  String get agendaNoEventsForDayBody => 'Escolha outro dia na barra acima.';

  @override
  String get agendaEventDetails => 'Evento';

  @override
  String get agendaEventNotFound => 'Evento não encontrado';

  @override
  String get agendaEventNotFoundBody =>
      'Este evento pode ter sido removido ou ainda não sincronizou.';

  @override
  String get agendaFieldDate => 'Data';

  @override
  String get agendaFieldTime => 'Hora';

  @override
  String get agendaFieldLocation => 'Local';

  @override
  String get agendaFieldNotes => 'Notas';

  @override
  String get agendaFieldResponsibilities => 'Equipa';

  @override
  String get agendaLinkedService => 'Culto associado';

  @override
  String get agendaUnassigned => 'Sem atribuição';

  @override
  String agendaMinutes(int count) {
    return '$count min';
  }

  @override
  String agendaResponsibilityCount(int count) {
    return '$count atribuídos';
  }

  @override
  String agendaAssigneeCount(int count) {
    return '$count pessoas';
  }

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
  String get songsEmpty => 'Ainda sem cânticos';

  @override
  String get songsEmptyDesc =>
      'Os cânticos da sua igreja aparecem aqui após a sincronização.';

  @override
  String get songsNoResults => 'Nenhum resultado';

  @override
  String get songsNoResultsDesc =>
      'Experimente outra pesquisa ou limpe os filtros.';

  @override
  String get songsFavoritesEmpty => 'Ainda sem favoritos';

  @override
  String get songsFavoritesEmptyDesc =>
      'Toque no coração num cântico para o guardar aqui.';

  @override
  String get songsRecentsEmpty => 'Ainda sem recentes';

  @override
  String get songsRecentsEmptyDesc => 'Os cânticos que abrir aparecem aqui.';

  @override
  String get songsNotFound => 'Cântico não encontrado';

  @override
  String get songsNotFoundDesc =>
      'Este cântico pode ter sido removido ou ainda não sincronizou.';

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
  String get songsSortNumber => 'Número';

  @override
  String get songsSortUpdated => 'Atualização';

  @override
  String get songsSortAdded => 'Adicionado recentemente';

  @override
  String get songsSortAscending => 'Ascendente';

  @override
  String get songsSortDescending => 'Descendente';

  @override
  String get songsMatchAll => 'Coincidir todas';

  @override
  String get songsMatchAny => 'Coincidir alguma';

  @override
  String get songsFilterByKey => 'Filtrar por tom';

  @override
  String get songsFilterByCollection => 'Filtrar por coleção';

  @override
  String get songsFilterBySongNumber => 'Número do cântico';

  @override
  String get songsNumberAny => 'Qualquer';

  @override
  String get songsNumberOnly => 'Numerados';

  @override
  String get songsNumberNone => 'Sem número';

  @override
  String get songsSearchLyrics => 'Pesquisar também na letra';

  @override
  String get songsWithChords => 'Mostrar apenas cânticos com acordes';

  @override
  String get songsResetFilters => 'Repor filtros';

  @override
  String get songsClear => 'Limpar';

  @override
  String get songsClearFilters => 'Limpar filtros';

  @override
  String get songsClearSearch => 'Limpar pesquisa';

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
  String get songsCreate => 'Nova canção';

  @override
  String get songsEdit => 'Editar canção';

  @override
  String get songsPreview => 'Pré-visualizar';

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
  String get songsFieldTranslator => 'Tradutor';

  @override
  String get songsFieldArranger => 'Arranjador';

  @override
  String get songsFieldSongNumber => 'Número da canção';

  @override
  String get songsFieldKey => 'Tom';

  @override
  String get songsFieldOriginalKey => 'Tom original';

  @override
  String get songsFieldKeyNone => 'Nenhum';

  @override
  String get songsFieldTempo => 'Tempo (BPM)';

  @override
  String get songsFieldTime => 'Compasso';

  @override
  String get songsFieldDuration => 'Duração (m:ss)';

  @override
  String get songsFieldCapo => 'Capo';

  @override
  String get songsFieldKeyNote => 'Nota de tom';

  @override
  String get songsFieldAlbum => 'Álbum';

  @override
  String get songsFieldYear => 'Ano';

  @override
  String get songsFieldCopyright => 'Copyright';

  @override
  String get songsFieldCcli => 'CCLI';

  @override
  String get songsFieldYoutube => 'URL / ID do YouTube';

  @override
  String get songsFieldTagsHint => 'Etiquetas separadas por vírgula';

  @override
  String get songsTabContent => 'Letra e acordes';

  @override
  String get songsTabMetadata => 'Detalhes';

  @override
  String get songsTitleRequired => 'O título é obrigatório.';

  @override
  String get songsChordProHint =>
      '[G]Escreva a letra e os [C]acordes aqui…\nUse as opções acima para verso, refrão e mais.';

  @override
  String get songsEditorInsertVerse => 'Verso';

  @override
  String get songsEditorInsertChorus => 'Refrão';

  @override
  String get songsEditorInsertBridge => 'Ponte';

  @override
  String get songsEditorInsertComment => 'Comentário';

  @override
  String get songsEditorInsertVersion => 'Versão';

  @override
  String get songsLintAllClear => 'Nenhum problema no ChordPro.';

  @override
  String songsLintSummary(int errors, int warnings, int infos) {
    return '$errors erros · $warnings avisos · $infos dicas';
  }

  @override
  String songsLintLine(int line) {
    return 'L$line';
  }

  @override
  String get songsLintDetails => 'Detalhes';

  @override
  String get songsLintUnclosedBrace => 'Chavetas por fechar ou desalinhadas.';

  @override
  String get songsLintUnclosedBracket =>
      'Parênteses de acorde por fechar ou desalinhados.';

  @override
  String get songsLintEmptyChord => 'Acordes vazios.';

  @override
  String songsLintUnknownChord(String chord) {
    return 'Acorde não reconhecido \"$chord\".';
  }

  @override
  String get songsLintMalformedDirective =>
      'Diretiva malformada — verifique chavetas e nome.';

  @override
  String songsLintUnknownDirective(String name) {
    return 'Diretiva não reconhecida \"$name\".';
  }

  @override
  String songsLintUnclosedSection(String section) {
    return 'Secção $section por fechar — falta end_of_$section.';
  }

  @override
  String songsLintUnexpectedEndSection(String section) {
    return 'end_of_$section inesperado sem início correspondente.';
  }

  @override
  String get songsLintInvalidYoutube =>
      'O valor do YouTube não é um URL ou ID válido.';

  @override
  String songsLintInvalidKey(String value) {
    return 'Tom invulgar \"$value\". Esperado G, Am, F#m, …';
  }

  @override
  String get songsLintInvalidTempo => 'O tempo deve ser um BPM entre 20 e 400.';

  @override
  String get songsLintInvalidCapo => 'O capo deve ser um traste de 0 a 12.';

  @override
  String get songsLintInvalidTime => 'O compasso deve parecer 4/4 ou 6/8.';

  @override
  String get songsLintInvalidDuration =>
      'A duração deve ser segundos ou m:ss (ex. 3:45).';

  @override
  String get songsNewSong => 'Nova canção';

  @override
  String get songsCreateManually => 'Criar manualmente';

  @override
  String get songsCreateManuallyDesc => 'Título, acordes e letra.';

  @override
  String get songsImportWithAi => 'Importar com IA';

  @override
  String get songsImportWithAiDesc => 'De PDF, imagem ou fotografia.';

  @override
  String get songsAddSong => 'Adicionar canção';

  @override
  String get songsImportSheetMusic => 'Importe a sua folha de música';

  @override
  String get songsImportSheetMusicBody =>
      'Use a Logos AI para converter PDFs, imagens ou fotos em canções com letra, acordes e metadados.';

  @override
  String get songsTakePhoto => 'Tirar fotografia';

  @override
  String get songsChooseGallery => 'Escolher da galeria';

  @override
  String get songsImportPdf => 'Importar PDF';

  @override
  String get songsHowItWorks => 'Como funciona?';

  @override
  String get songsAiAnalyzing => 'A analisar a folha de música…';

  @override
  String get songsAiAnalyzingBody =>
      'A Logos está a extrair letra, acordes e informação.';

  @override
  String get songsAiStepProcess => 'Processar o ficheiro';

  @override
  String get songsAiStepExtract => 'Extrair letra e acordes';

  @override
  String get songsAiStepMetadata => 'Identificar metadados (título, tom, …)';

  @override
  String get songsAiStepVerify => 'Verificar online e completar metadados';

  @override
  String get songsAiStepDraft => 'Preparar o rascunho';

  @override
  String get songsAiPleaseWait => 'Isto pode demorar alguns segundos…';

  @override
  String get songsAiResultTitle => 'Resultado da importação';

  @override
  String get songsAiCreatedBanner =>
      'Canção criada com IA. Confirme e ajuste as informações antes de guardar.';

  @override
  String get songsAiSave => 'Guardar';

  @override
  String get songsAiEditContent => 'Editar';

  @override
  String get songsAiImportFailed => 'Não foi possível importar esta folha';

  @override
  String get songsAiImportFailedBody =>
      'Tente outra foto ou PDF, ou crie a canção manualmente.';

  @override
  String get songsAiCancelledTitle => 'Não é uma partitura';

  @override
  String get songsAiCancelledBody =>
      'O Logos cancelou esta importação. Tente uma foto mais nítida de uma cifra, ou crie a canção manualmente.';

  @override
  String get songsAiCancelledGeneric =>
      'Esta imagem não parece uma canção importável.';

  @override
  String get songsAiCancelledNotASong =>
      'Isto não parece uma partitura ou cifra.';

  @override
  String get songsAiCancelledUnreadable =>
      'A imagem está demasiado desfocada ou escura.';

  @override
  String get songsAiCancelledBlank => 'A página parece em branco ou vazia.';

  @override
  String get songsAiCancelledWrongContent =>
      'Há texto, mas não é uma canção / cifra.';

  @override
  String get songsAiCancelledMultiple =>
      'Parecem várias canções misturadas sem uma principal clara.';

  @override
  String get songsAiCancelImport => 'Cancelar';

  @override
  String get songsAiDiscardDraft => 'Descartar rascunho';

  @override
  String songsAiConfidence(String percent) {
    return 'Confiança da IA: $percent%';
  }

  @override
  String get songsAiLowConfidence =>
      'Baixa confiança — reveja bem a letra e os acordes antes de guardar.';

  @override
  String get songsAiSuccessTitle => 'Importação concluída';

  @override
  String get songsAiSuccessBody =>
      'Letra, acordes e metadados foram capturados.';

  @override
  String get songsAiViewSong => 'Ver canção';

  @override
  String get songsAiImportAnother => 'Importar outra';

  @override
  String get songsAiPossibleDuplicates =>
      'Possíveis correspondências na biblioteca';

  @override
  String get songsAiPossibleDuplicatesHint =>
      'Abra para comparar — volta a este rascunho depois. Guardar cria sempre uma canção nova.';

  @override
  String get songsAiOpenExisting => 'Abrir';

  @override
  String get songsAiLintIssues => 'Problemas ChordPro';

  @override
  String get songsAiFieldComposer => 'Compositor';

  @override
  String get songsAiFieldCcli => 'CCLI';

  @override
  String get songsAiFieldDuration => 'Duração';

  @override
  String get songsAiFieldYoutube => 'YouTube';

  @override
  String get songsAiOpenYoutube => 'Abrir YouTube';

  @override
  String get songsAiCaptureTip =>
      'Use luz uniforme e evite reflexos ou desfoque para melhores resultados.';

  @override
  String get songsAiCaptureQualityHint =>
      'Esta imagem parece pequena ou de baixa qualidade — tente uma foto mais nítida e bem iluminada.';

  @override
  String get songsAiPdfMultiPageHint =>
      'Até 5 páginas são enviadas em PDFs com várias páginas.';

  @override
  String get songsEmptyAddHint =>
      'Adicione uma canção manualmente ou importe com a Logos AI.';

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
  String get songSectionBackground => 'Destacar Seções com Cor';

  @override
  String get songGuitar => 'Guitarra';

  @override
  String get songBass => 'Baixo';

  @override
  String get songUkulele => 'Ukelele';

  @override
  String get songPiano => 'Piano';

  @override
  String get instrumentFamilyFretted => 'Com trastes';

  @override
  String get instrumentFamilyKeyboard => 'Teclado';

  @override
  String get settingsInstrumentConfig => 'Definições do instrumento';

  @override
  String get settingsInstrumentConfigDesc =>
      'Opções do instrumento selecionado — usadas ao desenhar os diagramas de acordes.';

  @override
  String get settingsTuning => 'Afinação';

  @override
  String get settingsTuningDesc =>
      'Configuração das cordas abertas para os diagramas.';

  @override
  String get settingsShowFingerNumbers => 'Mostrar números dos dedos';

  @override
  String get settingsShowFingerNumbersDesc =>
      'Desenha 1–4 dentro dos pontos no diagrama.';

  @override
  String get settingsShowCapoMarker => 'Mostrar capo nos diagramas';

  @override
  String get settingsShowCapoMarkerDesc =>
      'Desenha o capo no pestana quando está ativo (estilo CifraClub).';

  @override
  String get settingsShowStringLabels => 'Mostrar nomes das cordas';

  @override
  String get settingsShowStringLabelsDesc =>
      'Etiqueta cada corda por baixo do diagrama (E A D G B e, etc.).';

  @override
  String get settingsBassRootNotes => 'Só notas fundamentais';

  @override
  String get settingsBassRootNotesDesc =>
      'Mostra uma única nota (tónica ou baixo do acorde com barra) em vez de formas completas.';

  @override
  String get settingsPianoCompactVoicing => 'Voicings compactos';

  @override
  String get settingsPianoCompactVoicingDesc =>
      'Em acordes de 7ª e extensões, omite a tónica na mão direita (ex.: C7 → Bb-E-G).';

  @override
  String get settingsPianoSlashSplit =>
      'Acordes com baixo: baixo na mão esquerda';

  @override
  String get settingsPianoSlashSplitDesc =>
      'Toca o baixo do acorde com barra na mão esquerda e o acorde na direita (ex.: A/C#).';

  @override
  String get tuningGuitarStandard => 'Padrão';

  @override
  String get tuningGuitarDropD => 'Drop D';

  @override
  String get tuningGuitarSevenString => '7 cordas';

  @override
  String get tuningBassFiveString => '5 cordas';

  @override
  String get tuningUkuleleHighG => 'Sol agudo';

  @override
  String get tuningUkuleleLowG => 'Sol grave';

  @override
  String get tuningUkuleleBaritone => 'Barítono';

  @override
  String get songAutoScrollStart => 'Iniciar scroll automático';

  @override
  String get songAutoScrollPause => 'Pausar scroll';

  @override
  String get songAutoScrollSpeed => 'Velocidade do scroll';

  @override
  String get songYoutubeOpenPlayer => 'Ouvir no YouTube';

  @override
  String get songYoutubeClosePlayer => 'Fechar leitor';

  @override
  String get songYoutubePlay => 'Reproduzir';

  @override
  String get songYoutubePause => 'Pausar';

  @override
  String get songYoutubeRewind => 'Recuar 10 segundos';

  @override
  String get songYoutubeForward => 'Avançar 30 segundos';

  @override
  String get songYoutubeError => 'Não foi possível reproduzir este vídeo';

  @override
  String get songSectionChorus => 'Refrão';

  @override
  String get songSectionBridge => 'Ponte';

  @override
  String get songSectionTab => 'Tablatura';

  @override
  String get songSectionInstrumental => 'Instrumental';

  @override
  String get songRepeatChorus => '(Repete o refrão)';

  @override
  String songKeyPill(Object key) {
    return 'Tom: $key';
  }

  @override
  String songCapoPill(Object fret) {
    return 'Capo: $fretª casa';
  }

  @override
  String songShapePill(Object key) {
    return 'Formato: $key';
  }

  @override
  String songOriginalKeyPill(Object key) {
    return 'Tom Orig: $key';
  }

  @override
  String songTranslatorCredit(String name) {
    return 'Tradução: $name';
  }

  @override
  String songLyricistCredit(String name) {
    return 'Letra: $name';
  }

  @override
  String songArrangerCredit(String name) {
    return 'Arranjo: $name';
  }

  @override
  String songNumberPill(Object number) {
    return 'Nº $number';
  }

  @override
  String songCapoOnFret(Object fret) {
    return 'Capo na $fretª casa';
  }

  @override
  String get songChangeKey => 'Mudar tom';

  @override
  String songChordTitle(Object chord) {
    return 'Dicionário: $chord';
  }

  @override
  String songChordNotFound(Object chord) {
    return 'Acorde \"$chord\" não registado';
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
  String get songNextChord => 'Acorde seguinte';

  @override
  String get songPrevious => 'Anterior';

  @override
  String get songNext => 'Seguinte';

  @override
  String get foldersTitle => 'Pastas';

  @override
  String get foldersEmpty => 'Ainda sem pastas';

  @override
  String get foldersEmptyDesc =>
      'As pastas organizam a biblioteca de cânticos da sua igreja.';

  @override
  String get folderContentsEmpty => 'Esta pasta está vazia';

  @override
  String get folderContentsEmptyDesc =>
      'Ainda não há cânticos nem subpastas aqui. Adicione um cântico, importe com a Logos AI, ou mova cânticos para esta pasta no Studio.';

  @override
  String get folderContentsEmptyReadonlyDesc =>
      'Ainda não há cânticos nem subpastas aqui. Peça a um líder para os adicionar no Studio, ou volte após a próxima sincronização.';

  @override
  String get foldersNoResultsDesc =>
      'Experimente outra pesquisa ou limpe os filtros.';

  @override
  String get collectionsEmpty => 'Ainda sem coleções';

  @override
  String get collectionsEmptyDesc =>
      'As coleções aparecem aqui quando a sua igreja as criar.';

  @override
  String get collectionsSearchHint => 'Pesquisar coleções…';

  @override
  String get collectionContentsEmpty => 'Esta coleção está vazia';

  @override
  String get collectionContentsEmptyDesc =>
      'Ainda não há cânticos nesta coleção. Adicione-os no Studio — um cântico pode pertencer a várias coleções ao mesmo tempo.';

  @override
  String get collectionContentsEmptyReadonlyDesc =>
      'Ainda não há cânticos nesta coleção. Peça a um líder para os adicionar no Studio, ou volte após a próxima sincronização.';

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
  String get foldersViewGrid => 'Ver em grelha';

  @override
  String get foldersViewList => 'Ver em lista';

  @override
  String get servicesTitle => 'Cultos';

  @override
  String get servicesEmpty => 'Ainda sem cultos';

  @override
  String get servicesEmptyDesc =>
      'Os cultos e planos de louvor da sua igreja aparecem aqui.';

  @override
  String get servicesSearchHint => 'Pesquisar cultos…';

  @override
  String get servicesNoResults => 'Nenhum culto correspondente';

  @override
  String get servicesNoResultsDesc => 'Experimente outra pesquisa.';

  @override
  String get servicesNoResultsFiltersDesc =>
      'Nada corresponde a estes filtros. Experimenta limpá-los.';

  @override
  String get servicesFilter => 'Filtrar cultos';

  @override
  String get servicesSortDate => 'Data';

  @override
  String get servicesSortName => 'Nome';

  @override
  String get servicesFilterWhen => 'Quando';

  @override
  String get servicesFilterDateAll => 'Todas as datas';

  @override
  String get servicesFilterUpcoming => 'Próximos';

  @override
  String get servicesFilterPast => 'Passados';

  @override
  String get servicesFilterToday => 'Hoje';

  @override
  String get servicesFilterThisWeek => 'Esta semana';

  @override
  String get servicesFilterThisMonth => 'Este mês';

  @override
  String get servicesFilterStatus => 'Estado';

  @override
  String get servicesFilterActive => 'Ativos';

  @override
  String get servicesFilterArchivedOnly => 'Arquivados';

  @override
  String get servicesFilterIncludeArchived => 'Ativos + arquivados';

  @override
  String get servicesFilterContent => 'Plano';

  @override
  String get servicesFilterContentAny => 'Qualquer';

  @override
  String get servicesFilterWithSongs => 'Com músicas';

  @override
  String get servicesFilterWithNotes => 'Com notas';

  @override
  String get servicesFilterEmptyPlan => 'Plano vazio';

  @override
  String get servicesNextService => 'Próximo culto';

  @override
  String get servicesNoUpcoming => 'Sem cultos futuros';

  @override
  String get servicesNoUpcomingDesc => 'Não há cultos agendados de momento.';

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
  String get servicesNoItems => 'Culto sem itens';

  @override
  String get servicesNoItemsDesc =>
      'Este culto ainda não tem momentos ou cânticos.';

  @override
  String get servicesNotFound => 'Culto não encontrado';

  @override
  String get servicesNotFoundDesc =>
      'Este culto pode ter sido removido ou ainda não sincronizou.';

  @override
  String get servicesOrderTitle => 'Ordem do Culto';

  @override
  String get servicesArchived => 'Arquivado';

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
  String get servicesMore => 'Mais';

  @override
  String get servicesInProgress => 'Em andamento';

  @override
  String get servicesItemDetail => 'Detalhe do Item';

  @override
  String get servicesEstimatedDuration => 'Duração estimada';

  @override
  String get servicesPassage => 'Passagem';

  @override
  String get servicesMarkCompleted => 'Marcar como concluído';

  @override
  String get servicesLeaderNotes => 'Notas do Líder';

  @override
  String get servicesLeaderNotesHint => 'Adicionar notas sobre este momento…';

  @override
  String get servicesTeamNotes => 'Notas da Equipa';

  @override
  String get servicesNotesEmpty => 'Ainda sem notas';

  @override
  String get servicesNotesEmptyDesc =>
      'Partilhe atualizações com a equipa durante o culto.';

  @override
  String get servicesNotesAdd => 'Adicionar nota';

  @override
  String get servicesNotesEdit => 'Editar nota';

  @override
  String get servicesNotesDelete => 'Eliminar';

  @override
  String get servicesNotesDeleteTitle => 'Eliminar nota?';

  @override
  String get servicesNotesDeleteDesc =>
      'Esta nota será removida para todos os que a podem ver.';

  @override
  String get servicesNotesHint => 'Escreva uma nota para a equipa…';

  @override
  String get servicesNotesPrivate => 'Nota privada';

  @override
  String get servicesNotesPrivateDesc => 'Só você pode ver esta nota.';

  @override
  String get servicesNotesSubscriptionRequired =>
      'É necessária uma subscrição ativa para adicionar ou editar notas.';

  @override
  String get servicesNotesForbidden =>
      'Não tem permissão para alterar esta nota.';

  @override
  String get servicesNotesUnauthorized =>
      'Inicie sessão novamente para gerir notas.';

  @override
  String get servicesNotesNotFound => 'Esta nota já não existe.';

  @override
  String get servicesNotesElementNotFound =>
      'Esse item do culto não foi encontrado.';

  @override
  String get servicesNotesSomeone => 'Alguém';

  @override
  String get servicesNotesQuickSend => 'Envio rápido';

  @override
  String get servicesNotesStale => 'As notas podem estar desatualizadas';

  @override
  String get servicesNotesStaleRetry => 'Toque para atualizar';

  @override
  String get servicesNotesServiceSection => 'Culto inteiro';

  @override
  String get servicesNotesServiceSectionDesc =>
      'Notas visíveis para todo o culto, não ligadas a este item.';

  @override
  String get servicesNotesAddService => 'Adicionar nota do culto';

  @override
  String get servicesNotesAddItem => 'Adicionar nota do item';

  @override
  String get servicesStartService => 'Iniciar culto';

  @override
  String get servicesStartServiceDesc =>
      'Inicie o temporizador quando o culto começar.';

  @override
  String servicesScheduledWindow(String window) {
    return 'Agendado $window';
  }

  @override
  String servicesItemRunning(String elapsed) {
    return 'Este item · $elapsed';
  }

  @override
  String get servicesNotStarted => 'Não iniciado';

  @override
  String get noteSugReadyToStart => 'Prontos para começar';

  @override
  String get noteSugStandbyNext => 'Standby para o próximo';

  @override
  String get noteSugGoNextItem => 'A passar para o próximo';

  @override
  String get noteSugHoldWait => 'Aguardar';

  @override
  String get noteSugWrapUp => 'Encerrar este momento';

  @override
  String get noteSugBehindSchedule => 'Estamos atrasados';

  @override
  String get noteSugAheadSchedule => 'Estamos adiantados';

  @override
  String get noteSugSkipItem => 'Saltar este item';

  @override
  String get noteSugExtendMoment => 'Prolongar este momento';

  @override
  String get noteSugChangeOfPlan => 'Mudança de plano';

  @override
  String get noteSugLookingGood => 'Está a correr bem';

  @override
  String get noteSugNeedHelp => 'Preciso de ajuda no palco';

  @override
  String get noteSugQuietMoment => 'Momento de silêncio';

  @override
  String get noteSugPrayTogether => 'Vamos orar';

  @override
  String get noteSugDoorsClosing => 'A fechar portas';

  @override
  String get noteSugGuestsReady => 'Recepção / convidados prontos';

  @override
  String get noteSugMicLive => 'Microfone ao vivo';

  @override
  String get noteSugMicMute => 'Silenciar esse microfone';

  @override
  String get noteSugMicCheck => 'Precisa de teste de microfone';

  @override
  String get noteSugFeedbackMute => 'Feedback — silenciar já';

  @override
  String get noteSugSpareMic => 'Trazer microfone de reserva';

  @override
  String get noteSugSlidesReady => 'Slides prontos';

  @override
  String get noteSugNextSlide => 'Próximo slide';

  @override
  String get noteSugWrongSlide => 'Slide errado';

  @override
  String get noteSugBlankScreen => 'Ecrã em preto';

  @override
  String get noteSugLyricsReady => 'Letras prontas';

  @override
  String get noteSugAdvanceLyrics => 'Avançar letras';

  @override
  String get noteSugRepeatChorusSlide => 'Repetir refrão no ecrã';

  @override
  String get noteSugLightsUp => 'Luzes mais altas';

  @override
  String get noteSugLightsDown => 'Luzes mais baixas';

  @override
  String get noteSugLightsAdjust => 'Ajustar luzes';

  @override
  String get noteSugVideoPlay => 'Reproduzir vídeo';

  @override
  String get noteSugVideoIssue => 'Problema com o vídeo';

  @override
  String get noteSugStreamIssue => 'Problema com a transmissão';

  @override
  String get noteSugHouseVolumeDown => 'Baixar volume da sala';

  @override
  String get noteSugHouseVolumeUp => 'Subir volume da sala';

  @override
  String get noteSugVocalsUp => 'Subir vozes';

  @override
  String get noteSugBandDown => 'Baixar banda na mistura';

  @override
  String get noteSugVerse1 => 'Estrofe 1';

  @override
  String get noteSugVerse2 => 'Estrofe 2';

  @override
  String get noteSugVerse3 => 'Estrofe 3';

  @override
  String get noteSugChorus => 'Refrão';

  @override
  String get noteSugBridge => 'Ponte';

  @override
  String get noteSugPreChorus => 'Pré-refrão';

  @override
  String get noteSugTag => 'Tag';

  @override
  String get noteSugInstrumental => 'Instrumental';

  @override
  String get noteSugRepeatSection => 'Repetir esta secção';

  @override
  String get noteSugEndSong => 'Terminar música';

  @override
  String get noteSugBuildUp => 'Subir a intensidade';

  @override
  String get noteSugBringDown => 'Baixar a intensidade';

  @override
  String get noteSugDrumsVocals => 'Só bateria + vozes';

  @override
  String get noteSugSoftPads => 'Só pads suaves';

  @override
  String get noteSugCutVocals => 'Cortar vozes';

  @override
  String get noteSugBandTakeIt => 'Banda assume';

  @override
  String get noteSugSpontaneousStay => 'Ficar aqui — espontâneo';

  @override
  String get noteSugTempoUp => 'Acelerar o tempo';

  @override
  String get noteSugTempoDown => 'Abrir o tempo';

  @override
  String get noteSugKeyChange => 'Mudança de tom a chegar';

  @override
  String get noteSugMoreMonitor => 'Mais de mim nos monitores';

  @override
  String get noteSugLessMonitor => 'Menos de mim nos monitores';

  @override
  String get noteSugClickLouder => 'Click / guia mais alto';

  @override
  String get noteSugLostClick => 'Perdi o click';

  @override
  String get noteSugWrongChart => 'Cifra / arranjo errado';

  @override
  String get noteSugReadyNextSong => 'Prontos para a próxima música';

  @override
  String get noteSugStartSong => 'Começar a música';

  @override
  String get noteSugStartWelcome => 'Começar boas-vindas';

  @override
  String get noteSugWrapWelcome => 'Encerrar boas-vindas';

  @override
  String get noteSugOpenDoors => 'Abrir portas';

  @override
  String get noteSugHospitalityReady => 'Equipa de hospitalidade pronta';

  @override
  String get noteSugReaderReady => 'Leitor pronto';

  @override
  String get noteSugPassageOnScreen => 'Passagem no ecrã';

  @override
  String get noteSugAdvanceVerse => 'Avançar versículo';

  @override
  String get noteSugSoftUnderscore => 'Fundo musical suave';

  @override
  String get noteSugAfterReading => 'Após a leitura — próximo';

  @override
  String get noteSugPastorWalkingUp => 'Pastor a subir';

  @override
  String get noteSugPastorMicLive => 'Microfone do pastor ao vivo';

  @override
  String get noteSugSermonSlidesReady => 'Slides da mensagem prontos';

  @override
  String get noteSugNextSermonSlide => 'Próximo slide da mensagem';

  @override
  String get noteSugTimerCheck => 'Verificar tempo';

  @override
  String get noteSugAltarCallComing => 'Apelo a chegar';

  @override
  String get noteSugClosingPrayer => 'Oração final';

  @override
  String get noteSugSoftMusicUnder => 'Música suave por baixo';

  @override
  String get noteSugMessageLights => 'Iluminação da mensagem';

  @override
  String get noteSugAnnouncementsStart => 'Anúncios a começar';

  @override
  String get noteSugNextAnnouncement => 'Próximo anúncio';

  @override
  String get noteSugWrapAnnouncements => 'Encerrar anúncios';

  @override
  String get noteSugGivingMoment => 'Oferta / dádivas';

  @override
  String get noteSugConnectionReminder => 'Lembrete de ligação';

  @override
  String get servicesElementEmpty => 'Nada preparado para este momento';

  @override
  String get servicesElementEmptyDesc =>
      'Ainda não há passagem, conteúdo ou notas neste item.';

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
  String get settingsTabAccount => 'Conta';

  @override
  String get settingsTabWorkspace => 'Organização';

  @override
  String get settingsTabPreferences => 'Preferências';

  @override
  String get settingsTabService => 'Culto';

  @override
  String get settingsTabAppearance => 'Aparência';

  @override
  String get settingsSubscriptionInactive => 'Sem subscrição ativa';

  @override
  String get settingsSubscriptionInactiveDesc =>
      'Esta organização está só de leitura até haver uma subscrição ou período de avaliação ativo. Ainda pode consultar o conteúdo sincronizado.';

  @override
  String get settingsOrgSwitching => 'A mudar de organização…';

  @override
  String get settingsActive => 'Ativa';

  @override
  String get settingsSwitchOrg => 'Alternar Organização';

  @override
  String get settingsOrganization => 'Organização';

  @override
  String get settingsSyncLibrary => 'Sincronização da Biblioteca';

  @override
  String get settingsSyncLibraryDesc =>
      'Sincroniza cânticos, pastas e cultos da sua organização.';

  @override
  String get settingsSyncNow => 'Sincronizar';

  @override
  String get settingsLastSync => 'Última Sincronização';

  @override
  String get settingsSyncState => 'Estado do Sync';

  @override
  String get settingsLocalSongs => 'Cânticos Locais';

  @override
  String get settingsSavedServices => 'Cultos Guardados';

  @override
  String get settingsUserId => 'ID do Utilizador';

  @override
  String get settingsRole => 'Função';

  @override
  String get settingsActiveOrg => 'Organização Ativa';

  @override
  String get settingsNoActiveOrg => 'Sem organização ativa';

  @override
  String get settingsChangeEmail => 'Alterar E-mail';

  @override
  String get settingsNewEmail => 'Novo E-mail';

  @override
  String get settingsSaveEmail => 'Guardar E-mail';

  @override
  String get settingsEmailChangeSent =>
      'Pedido de alteração de e-mail enviado!';

  @override
  String get settingsEdit => 'Editar';

  @override
  String get settingsCancel => 'Cancelar';

  @override
  String get settingsSave => 'Guardar';

  @override
  String get settingsSaving => 'A guardar…';

  @override
  String get settingsNameEmpty => 'O nome não pode estar vazio.';

  @override
  String get settingsEmailInvalid => 'Introduza um e-mail válido.';

  @override
  String get settingsMusicianMode => 'Modo músico';

  @override
  String get settingsMusicianModeDesc =>
      'Abre os cultos no primeiro cântico com acordes e anotações. Desative para a vista de ordem do culto com letras e tempos.';

  @override
  String get settingsServiceOrderSidePanel =>
      'Painel lateral da ordem do culto';

  @override
  String get settingsServiceOrderSidePanelDesc =>
      'Em tablets, mantém a ordem do culto visível ao lado do item atual nos modos músico e não músico.';

  @override
  String get servicesCollapseOrderPanel => 'Recolher painel da ordem';

  @override
  String get servicesExpandOrderPanel => 'Expandir painel da ordem';

  @override
  String get settingsKeepAwake => 'Manter Ecrã Ligado';

  @override
  String get settingsKeepAwakeDesc =>
      'Impede o ecrã de suspender durante a visualização de cânticos.';

  @override
  String get settingsSyncAnnotations => 'Sincronizar anotações';

  @override
  String get settingsSyncAnnotationsDesc =>
      'Faz com que as anotações sejam partilhadas ao vivo entre todos os utilizadores';

  @override
  String get settingsNotifications => 'Permitir notificações neste dispositivo';

  @override
  String get settingsNotificationsDesc =>
      'Permite que o servidor envie notificações para esta sessão. É independente da permissão de notificações do sistema.';

  @override
  String get notificationConsentTitle =>
      'Permitir notificações neste dispositivo?';

  @override
  String get notificationConsentMessage =>
      'Se permitir, o servidor poderá enviar-lhe avisos de cultos e novidades da biblioteca neste dispositivo. Pode alterar isto nas Definições.';

  @override
  String get notificationConsentAllow => 'Permitir';

  @override
  String get notificationConsentNotNow => 'Agora não';

  @override
  String get notificationOpenAction => 'Abrir';

  @override
  String get settingsSessionsOnly =>
      'Apenas a sessão atual deste dispositivo está ativa.';

  @override
  String get metronomeTitle => 'Metrónomo';

  @override
  String get metronomeDescription => 'Tempo e compasso para ensaios.';

  @override
  String get metronomeTapTempo => 'Toque o Tempo';

  @override
  String get metronomeTimeSignature => 'COMPASSO';

  @override
  String get metronomeAccent => 'Acentuar';

  @override
  String get metronomePlay => 'Reproduzir';

  @override
  String get metronomePause => 'Pausar';

  @override
  String get metronomeAudioUnavailable =>
      'O som do metrónomo não está disponível neste dispositivo.';

  @override
  String get circleOfFifthsTitle => 'Círculo de Quintas';

  @override
  String get circleOfFifthsDescription => 'Referência de tons e relativas.';

  @override
  String get circleOfFifthsHarmonicField => 'Campo Harmónico';

  @override
  String get circleOfFifthsTonic => 'Tónica';

  @override
  String get circleOfFifthsRelativeMinor => 'Relativa Menor';

  @override
  String get exportPdfTitle => 'Exportar PDF';

  @override
  String get comingSoon => 'Em breve';

  @override
  String get comingSoonDescription =>
      'Esta funcionalidade estará disponível numa próxima versão.';

  @override
  String get annotationModeTitle => 'Anotações';

  @override
  String get annotationPen => 'Caneta';

  @override
  String get annotationEraser => 'Borracha de Traço';

  @override
  String get annotationPixelEraser => 'Borracha Parcial';

  @override
  String get annotationLine => 'Linha';

  @override
  String get annotationRectangle => 'Retângulo';

  @override
  String get annotationEllipse => 'Círculo';

  @override
  String get annotationSelect => 'Selecionar';

  @override
  String get annotationLasso => 'Laço';

  @override
  String get annotationText => 'Texto';

  @override
  String get annotationLayers => 'Camadas';

  @override
  String get annotationUndo => 'Desfazer';

  @override
  String get annotationRedo => 'Refazer';

  @override
  String get annotationClear => 'Limpar Tudo';

  @override
  String get annotationClearConfirm =>
      'Limpar todas as anotações deste cântico?';

  @override
  String get annotationColorPicker => 'Cor Personalizada';

  @override
  String get annotationClose => 'Concluir';

  @override
  String get annotationRemoteChanges => 'Novas alterações de outro dispositivo';

  @override
  String get annotationKeepMine => 'Manter as minhas';

  @override
  String get annotationReload => 'Recarregar';

  @override
  String get songVariant => 'Versão';

  @override
  String songVariantTooltip(String name) {
    return 'Versão: $name';
  }

  @override
  String get settingsLanguageSystem => 'Sistema';

  @override
  String get settingsFontPreview => 'Exemplo';
}
