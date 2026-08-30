import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Hosanna'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In pt, this message translates to:
  /// **'A sua biblioteca e planos de louvor, sempre sincronizados.'**
  String get appTagline;

  /// No description provided for @commonCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In pt, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In pt, this message translates to:
  /// **'Eliminar'**
  String get commonDelete;

  /// No description provided for @commonBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get commonBack;

  /// No description provided for @commonRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get commonRetry;

  /// No description provided for @commonLoading.
  ///
  /// In pt, this message translates to:
  /// **'A carregar…'**
  String get commonLoading;

  /// No description provided for @commonOk.
  ///
  /// In pt, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get commonClose;

  /// No description provided for @commonConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get commonConfirm;

  /// No description provided for @commonSearch.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar'**
  String get commonSearch;

  /// No description provided for @commonError.
  ///
  /// In pt, this message translates to:
  /// **'Ocorreu um erro'**
  String get commonError;

  /// No description provided for @commonOffline.
  ///
  /// In pt, this message translates to:
  /// **'Sem ligação à internet'**
  String get commonOffline;

  /// No description provided for @commonDone.
  ///
  /// In pt, this message translates to:
  /// **'Concluir'**
  String get commonDone;

  /// No description provided for @commonNext.
  ///
  /// In pt, this message translates to:
  /// **'Seguinte'**
  String get commonNext;

  /// No description provided for @commonUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Desconhecido'**
  String get commonUnknown;

  /// No description provided for @commonOpenDrawer.
  ///
  /// In pt, this message translates to:
  /// **'Abrir menu'**
  String get commonOpenDrawer;

  /// No description provided for @commonCloseDrawer.
  ///
  /// In pt, this message translates to:
  /// **'Fechar o Menu'**
  String get commonCloseDrawer;

  /// No description provided for @authSignIn.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar Sessão'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In pt, this message translates to:
  /// **'Criar Conta'**
  String get authSignUp;

  /// No description provided for @authSignOut.
  ///
  /// In pt, this message translates to:
  /// **'Terminar Sessão'**
  String get authSignOut;

  /// No description provided for @authEmail.
  ///
  /// In pt, this message translates to:
  /// **'Endereço de E-mail'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In pt, this message translates to:
  /// **'Palavra-passe'**
  String get authPassword;

  /// No description provided for @authName.
  ///
  /// In pt, this message translates to:
  /// **'Nome Completo'**
  String get authName;

  /// No description provided for @authConfirmPassword.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Palavra-passe'**
  String get authConfirmPassword;

  /// No description provided for @authForgotPassword.
  ///
  /// In pt, this message translates to:
  /// **'Esqueceu-se da palavra-passe?'**
  String get authForgotPassword;

  /// No description provided for @authSignInTitle.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo de volta'**
  String get authSignInTitle;

  /// No description provided for @authSignUpTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar Conta no Hosanna'**
  String get authSignUpTitle;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Inicie sessão para aceder à sua biblioteca.'**
  String get authSignInSubtitle;

  /// No description provided for @authSignUpSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Registe-se para começar a organizar os seus cânticos.'**
  String get authSignUpSubtitle;

  /// No description provided for @authSignInButton.
  ///
  /// In pt, this message translates to:
  /// **'Entrar na Conta'**
  String get authSignInButton;

  /// No description provided for @authSignUpButton.
  ///
  /// In pt, this message translates to:
  /// **'Registar Nova Conta'**
  String get authSignUpButton;

  /// No description provided for @authCreateAccount.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get authCreateAccount;

  /// No description provided for @authNoAccount.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não tem conta?'**
  String get authNoAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In pt, this message translates to:
  /// **'Já tem uma conta?'**
  String get authHaveAccount;

  /// No description provided for @authSignInError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao iniciar sessão. Verifique as credenciais.'**
  String get authSignInError;

  /// No description provided for @authSignUpError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao criar conta.'**
  String get authSignUpError;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In pt, this message translates to:
  /// **'A palavra-passe deve ter pelo menos 6 caracteres.'**
  String get authPasswordMinLength;

  /// No description provided for @authPasswordsDontMatch.
  ///
  /// In pt, this message translates to:
  /// **'As palavras-passe não coincidem.'**
  String get authPasswordsDontMatch;

  /// No description provided for @authRequiredFields.
  ///
  /// In pt, this message translates to:
  /// **'Por favor preencha o e-mail e a palavra-passe.'**
  String get authRequiredFields;

  /// No description provided for @authNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Por favor introduza o seu nome.'**
  String get authNameRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Por favor introduza um e-mail válido.'**
  String get authEmailInvalid;

  /// No description provided for @authVerifyEmail.
  ///
  /// In pt, this message translates to:
  /// **'Verificar E-mail'**
  String get authVerifyEmail;

  /// No description provided for @authVerifyEmailTitle.
  ///
  /// In pt, this message translates to:
  /// **'Verifique o seu e-mail'**
  String get authVerifyEmailTitle;

  /// No description provided for @authVerifyEmailMessage.
  ///
  /// In pt, this message translates to:
  /// **'Enviámos uma ligação de verificação para o seu e-mail. Abra-a para confirmar a sua conta.'**
  String get authVerifyEmailMessage;

  /// No description provided for @authCheckEmail.
  ///
  /// In pt, this message translates to:
  /// **'Verificar caixa de entrada'**
  String get authCheckEmail;

  /// No description provided for @authResendEmail.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar e-mail de verificação'**
  String get authResendEmail;

  /// No description provided for @authEmailVerificationSent.
  ///
  /// In pt, this message translates to:
  /// **'E-mail de verificação enviado!'**
  String get authEmailVerificationSent;

  /// No description provided for @authResetPassword.
  ///
  /// In pt, this message translates to:
  /// **'Repor Palavra-passe'**
  String get authResetPassword;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In pt, this message translates to:
  /// **'Repor palavra-passe'**
  String get authResetPasswordTitle;

  /// No description provided for @authResetPasswordMessage.
  ///
  /// In pt, this message translates to:
  /// **'Introduza o seu e-mail e enviaremos uma ligação para repor a palavra-passe.'**
  String get authResetPasswordMessage;

  /// No description provided for @authSendResetLink.
  ///
  /// In pt, this message translates to:
  /// **'Enviar Ligação de Reposição'**
  String get authSendResetLink;

  /// No description provided for @authResetLinkSent.
  ///
  /// In pt, this message translates to:
  /// **'Se o e-mail existir, enviámos uma ligação de reposição.'**
  String get authResetLinkSent;

  /// No description provided for @authNewPassword.
  ///
  /// In pt, this message translates to:
  /// **'Nova Palavra-passe'**
  String get authNewPassword;

  /// No description provided for @authCurrentPassword.
  ///
  /// In pt, this message translates to:
  /// **'Palavra-passe Atual'**
  String get authCurrentPassword;

  /// No description provided for @authChangePassword.
  ///
  /// In pt, this message translates to:
  /// **'Alterar Palavra-passe'**
  String get authChangePassword;

  /// No description provided for @authAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get authAccount;

  /// No description provided for @authProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get authProfile;

  /// No description provided for @authEditProfile.
  ///
  /// In pt, this message translates to:
  /// **'Editar Perfil'**
  String get authEditProfile;

  /// No description provided for @authNameSaved.
  ///
  /// In pt, this message translates to:
  /// **'Nome guardado com sucesso!'**
  String get authNameSaved;

  /// No description provided for @authPasswordChanged.
  ///
  /// In pt, this message translates to:
  /// **'Palavra-passe alterada com sucesso!'**
  String get authPasswordChanged;

  /// No description provided for @authPasswordChangeError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao alterar palavra-passe. Verifique a palavra-passe atual.'**
  String get authPasswordChangeError;

  /// No description provided for @authEmailVerified.
  ///
  /// In pt, this message translates to:
  /// **'E-mail verificado'**
  String get authEmailVerified;

  /// No description provided for @authEmailNotVerified.
  ///
  /// In pt, this message translates to:
  /// **'E-mail por verificar'**
  String get authEmailNotVerified;

  /// No description provided for @authCaptchaNotConfigured.
  ///
  /// In pt, this message translates to:
  /// **'A verificação de segurança (captcha) não está configurada.'**
  String get authCaptchaNotConfigured;

  /// No description provided for @onboardingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo ao Hosanna'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Aceite um convite para entrar na organização da sua igreja.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingPendingInvites.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 convite pendente} other{{count} convites pendentes}}'**
  String onboardingPendingInvites(num count);

  /// No description provided for @onboardingNoInvites.
  ///
  /// In pt, this message translates to:
  /// **'Sem convites pendentes'**
  String get onboardingNoInvites;

  /// No description provided for @onboardingNoInvitesDesc.
  ///
  /// In pt, this message translates to:
  /// **'Peça a um administrador da sua igreja para o convidar.'**
  String get onboardingNoInvitesDesc;

  /// No description provided for @onboardingAccept.
  ///
  /// In pt, this message translates to:
  /// **'Aceitar'**
  String get onboardingAccept;

  /// No description provided for @onboardingReject.
  ///
  /// In pt, this message translates to:
  /// **'Recusar'**
  String get onboardingReject;

  /// No description provided for @onboardingRole.
  ///
  /// In pt, this message translates to:
  /// **'Função'**
  String get onboardingRole;

  /// No description provided for @onboardingLoadingInvites.
  ///
  /// In pt, this message translates to:
  /// **'A carregar convites…'**
  String get onboardingLoadingInvites;

  /// No description provided for @onboardingSignOut.
  ///
  /// In pt, this message translates to:
  /// **'Terminar Sessão'**
  String get onboardingSignOut;

  /// No description provided for @syncSyncing.
  ///
  /// In pt, this message translates to:
  /// **'A sincronizar…'**
  String get syncSyncing;

  /// No description provided for @syncSynced.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizado'**
  String get syncSynced;

  /// No description provided for @syncError.
  ///
  /// In pt, this message translates to:
  /// **'Erro de sincronização'**
  String get syncError;

  /// No description provided for @syncOffline.
  ///
  /// In pt, this message translates to:
  /// **'Sem ligação'**
  String get syncOffline;

  /// No description provided for @syncLastSynced.
  ///
  /// In pt, this message translates to:
  /// **'Última sincronização: {time}'**
  String syncLastSynced(Object time);

  /// No description provided for @syncNever.
  ///
  /// In pt, this message translates to:
  /// **'Nunca sincronizado'**
  String get syncNever;

  /// No description provided for @syncNow.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizar agora'**
  String get syncNow;

  /// No description provided for @syncPullToRefresh.
  ///
  /// In pt, this message translates to:
  /// **'Puxe para sincronizar'**
  String get syncPullToRefresh;

  /// No description provided for @navSongs.
  ///
  /// In pt, this message translates to:
  /// **'Cânticos'**
  String get navSongs;

  /// No description provided for @navServices.
  ///
  /// In pt, this message translates to:
  /// **'Cultos'**
  String get navServices;

  /// No description provided for @navFolders.
  ///
  /// In pt, this message translates to:
  /// **'Pastas'**
  String get navFolders;

  /// No description provided for @navSettings.
  ///
  /// In pt, this message translates to:
  /// **'Definições'**
  String get navSettings;

  /// No description provided for @navCircleOfFifths.
  ///
  /// In pt, this message translates to:
  /// **'Círculo de Quintas'**
  String get navCircleOfFifths;

  /// No description provided for @navMetronome.
  ///
  /// In pt, this message translates to:
  /// **'Metrónomo'**
  String get navMetronome;

  /// No description provided for @navExportPdf.
  ///
  /// In pt, this message translates to:
  /// **'Exportar PDF'**
  String get navExportPdf;

  /// No description provided for @navLibrarySection.
  ///
  /// In pt, this message translates to:
  /// **'Biblioteca'**
  String get navLibrarySection;

  /// No description provided for @navToolsSection.
  ///
  /// In pt, this message translates to:
  /// **'Ferramentas'**
  String get navToolsSection;

  /// No description provided for @navAllSongs.
  ///
  /// In pt, this message translates to:
  /// **'Todos os cânticos'**
  String get navAllSongs;

  /// No description provided for @navFavorites.
  ///
  /// In pt, this message translates to:
  /// **'Favoritos'**
  String get navFavorites;

  /// No description provided for @navRecents.
  ///
  /// In pt, this message translates to:
  /// **'Recentes'**
  String get navRecents;

  /// No description provided for @songsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cânticos'**
  String get songsTitle;

  /// No description provided for @songsSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar cânticos…'**
  String get songsSearchHint;

  /// No description provided for @songsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Sem cânticos'**
  String get songsEmpty;

  /// No description provided for @songsNoResults.
  ///
  /// In pt, this message translates to:
  /// **'Sem resultados'**
  String get songsNoResults;

  /// No description provided for @songsAllSongs.
  ///
  /// In pt, this message translates to:
  /// **'Todos os cânticos'**
  String get songsAllSongs;

  /// No description provided for @songsFilterByFolder.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar por pasta'**
  String get songsFilterByFolder;

  /// No description provided for @songsFilterByTag.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar por etiqueta'**
  String get songsFilterByTag;

  /// No description provided for @songsFilter.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar'**
  String get songsFilter;

  /// No description provided for @songsSortBy.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar por'**
  String get songsSortBy;

  /// No description provided for @songsSortTitle.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get songsSortTitle;

  /// No description provided for @songsSortArtist.
  ///
  /// In pt, this message translates to:
  /// **'Artista'**
  String get songsSortArtist;

  /// No description provided for @songsSortNumber.
  ///
  /// In pt, this message translates to:
  /// **'Número'**
  String get songsSortNumber;

  /// No description provided for @songsSortUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Atualização'**
  String get songsSortUpdated;

  /// No description provided for @songsSortAdded.
  ///
  /// In pt, this message translates to:
  /// **'Adicionado recentemente'**
  String get songsSortAdded;

  /// No description provided for @songsSortAscending.
  ///
  /// In pt, this message translates to:
  /// **'Ascendente'**
  String get songsSortAscending;

  /// No description provided for @songsSortDescending.
  ///
  /// In pt, this message translates to:
  /// **'Descendente'**
  String get songsSortDescending;

  /// No description provided for @songsMatchAll.
  ///
  /// In pt, this message translates to:
  /// **'Coincidir todas'**
  String get songsMatchAll;

  /// No description provided for @songsMatchAny.
  ///
  /// In pt, this message translates to:
  /// **'Coincidir alguma'**
  String get songsMatchAny;

  /// No description provided for @songsFilterByKey.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar por tom'**
  String get songsFilterByKey;

  /// No description provided for @songsFilterBySongNumber.
  ///
  /// In pt, this message translates to:
  /// **'Número do cântico'**
  String get songsFilterBySongNumber;

  /// No description provided for @songsNumberAny.
  ///
  /// In pt, this message translates to:
  /// **'Qualquer'**
  String get songsNumberAny;

  /// No description provided for @songsNumberOnly.
  ///
  /// In pt, this message translates to:
  /// **'Numerados'**
  String get songsNumberOnly;

  /// No description provided for @songsNumberNone.
  ///
  /// In pt, this message translates to:
  /// **'Sem número'**
  String get songsNumberNone;

  /// No description provided for @songsSearchLyrics.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar na letra'**
  String get songsSearchLyrics;

  /// No description provided for @songsWithChords.
  ///
  /// In pt, this message translates to:
  /// **'Apenas com acordes'**
  String get songsWithChords;

  /// No description provided for @songsResetFilters.
  ///
  /// In pt, this message translates to:
  /// **'Repor filtros'**
  String get songsResetFilters;

  /// No description provided for @songsClear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar'**
  String get songsClear;

  /// No description provided for @songsClearFilters.
  ///
  /// In pt, this message translates to:
  /// **'Limpar filtros'**
  String get songsClearFilters;

  /// No description provided for @songsTitleLabel.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get songsTitleLabel;

  /// No description provided for @songsArtistLabel.
  ///
  /// In pt, this message translates to:
  /// **'Artista'**
  String get songsArtistLabel;

  /// No description provided for @songsFolderLabel.
  ///
  /// In pt, this message translates to:
  /// **'Pasta'**
  String get songsFolderLabel;

  /// No description provided for @songsTagsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Etiquetas'**
  String get songsTagsLabel;

  /// No description provided for @songsChordPro.
  ///
  /// In pt, this message translates to:
  /// **'ChordPro'**
  String get songsChordPro;

  /// No description provided for @songsRawContent.
  ///
  /// In pt, this message translates to:
  /// **'Conteúdo em bruto (ChordPro)'**
  String get songsRawContent;

  /// No description provided for @songsNoContent.
  ///
  /// In pt, this message translates to:
  /// **'Sem conteúdo disponível.'**
  String get songsNoContent;

  /// No description provided for @songKey.
  ///
  /// In pt, this message translates to:
  /// **'Tom'**
  String get songKey;

  /// No description provided for @songCapo.
  ///
  /// In pt, this message translates to:
  /// **'Capo'**
  String get songCapo;

  /// No description provided for @songChords.
  ///
  /// In pt, this message translates to:
  /// **'Acordes'**
  String get songChords;

  /// No description provided for @songInstrument.
  ///
  /// In pt, this message translates to:
  /// **'Instrumento'**
  String get songInstrument;

  /// No description provided for @songDiagrams.
  ///
  /// In pt, this message translates to:
  /// **'Diagramas'**
  String get songDiagrams;

  /// No description provided for @songControlsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajustes de Leitura'**
  String get songControlsTitle;

  /// No description provided for @songTranspose.
  ///
  /// In pt, this message translates to:
  /// **'Transposição'**
  String get songTranspose;

  /// No description provided for @songSemitones.
  ///
  /// In pt, this message translates to:
  /// **'semitons'**
  String get songSemitones;

  /// No description provided for @songOriginal.
  ///
  /// In pt, this message translates to:
  /// **'Original'**
  String get songOriginal;

  /// No description provided for @songCapoNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum'**
  String get songCapoNone;

  /// No description provided for @songCapoFret.
  ///
  /// In pt, this message translates to:
  /// **'Traste {fret}'**
  String songCapoFret(Object fret);

  /// No description provided for @songFontSize.
  ///
  /// In pt, this message translates to:
  /// **'Tamanho da Letra'**
  String get songFontSize;

  /// No description provided for @songShowChords.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar Acordes'**
  String get songShowChords;

  /// No description provided for @songTwoColumn.
  ///
  /// In pt, this message translates to:
  /// **'Layout em 2 Colunas'**
  String get songTwoColumn;

  /// No description provided for @songShowDiagrams.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar Diagramas'**
  String get songShowDiagrams;

  /// No description provided for @songSectionBackground.
  ///
  /// In pt, this message translates to:
  /// **'Destacar Seções com Cor'**
  String get songSectionBackground;

  /// No description provided for @songGuitar.
  ///
  /// In pt, this message translates to:
  /// **'Guitarra'**
  String get songGuitar;

  /// No description provided for @songPiano.
  ///
  /// In pt, this message translates to:
  /// **'Piano'**
  String get songPiano;

  /// No description provided for @songAutoScrollStart.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar scroll automático'**
  String get songAutoScrollStart;

  /// No description provided for @songAutoScrollPause.
  ///
  /// In pt, this message translates to:
  /// **'Pausar scroll'**
  String get songAutoScrollPause;

  /// No description provided for @songAutoScrollSpeed.
  ///
  /// In pt, this message translates to:
  /// **'Velocidade do scroll'**
  String get songAutoScrollSpeed;

  /// No description provided for @songPrevious.
  ///
  /// In pt, this message translates to:
  /// **'Anterior'**
  String get songPrevious;

  /// No description provided for @songNext.
  ///
  /// In pt, this message translates to:
  /// **'Seguinte'**
  String get songNext;

  /// No description provided for @foldersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pastas'**
  String get foldersTitle;

  /// No description provided for @foldersEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Sem pastas'**
  String get foldersEmpty;

  /// No description provided for @foldersSubfolders.
  ///
  /// In pt, this message translates to:
  /// **'Subpastas'**
  String get foldersSubfolders;

  /// No description provided for @foldersSongsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 cântico} other{{count} cânticos}}'**
  String foldersSongsCount(num count);

  /// No description provided for @foldersRoot.
  ///
  /// In pt, this message translates to:
  /// **'Raiz'**
  String get foldersRoot;

  /// No description provided for @servicesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cultos'**
  String get servicesTitle;

  /// No description provided for @servicesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Sem cultos'**
  String get servicesEmpty;

  /// No description provided for @servicesSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar cultos…'**
  String get servicesSearchHint;

  /// No description provided for @servicesItems.
  ///
  /// In pt, this message translates to:
  /// **'Itens'**
  String get servicesItems;

  /// No description provided for @servicesNotes.
  ///
  /// In pt, this message translates to:
  /// **'Notas'**
  String get servicesNotes;

  /// No description provided for @servicesGeneralNotes.
  ///
  /// In pt, this message translates to:
  /// **'Notas gerais'**
  String get servicesGeneralNotes;

  /// No description provided for @servicesItemNotes.
  ///
  /// In pt, this message translates to:
  /// **'Notas do item'**
  String get servicesItemNotes;

  /// No description provided for @servicesOrderedItems.
  ///
  /// In pt, this message translates to:
  /// **'Itens ordenados'**
  String get servicesOrderedItems;

  /// No description provided for @servicesNoItems.
  ///
  /// In pt, this message translates to:
  /// **'Sem itens neste culto.'**
  String get servicesNoItems;

  /// No description provided for @servicesOrderTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ordem do Culto'**
  String get servicesOrderTitle;

  /// No description provided for @servicesArchived.
  ///
  /// In pt, this message translates to:
  /// **'Arquivado'**
  String get servicesArchived;

  /// No description provided for @servicesLeave.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get servicesLeave;

  /// No description provided for @servicesLeaveMode.
  ///
  /// In pt, this message translates to:
  /// **'Sair do Modo Culto'**
  String get servicesLeaveMode;

  /// No description provided for @servicesMoments.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 momento} other{{count} momentos}}'**
  String servicesMoments(num count);

  /// No description provided for @servicesItemOf.
  ///
  /// In pt, this message translates to:
  /// **'Item {current} de {total}'**
  String servicesItemOf(Object current, Object total);

  /// No description provided for @servicesAddNotes.
  ///
  /// In pt, this message translates to:
  /// **'Toque para adicionar anotações…'**
  String get servicesAddNotes;

  /// No description provided for @servicesElementSong.
  ///
  /// In pt, this message translates to:
  /// **'Cântico'**
  String get servicesElementSong;

  /// No description provided for @servicesElementWelcome.
  ///
  /// In pt, this message translates to:
  /// **'Boas-vindas'**
  String get servicesElementWelcome;

  /// No description provided for @servicesElementScripture.
  ///
  /// In pt, this message translates to:
  /// **'Escritura'**
  String get servicesElementScripture;

  /// No description provided for @servicesElementMessage.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem'**
  String get servicesElementMessage;

  /// No description provided for @servicesElementAnnouncement.
  ///
  /// In pt, this message translates to:
  /// **'Avisos'**
  String get servicesElementAnnouncement;

  /// No description provided for @servicesElementDefault.
  ///
  /// In pt, this message translates to:
  /// **'Elemento'**
  String get servicesElementDefault;

  /// No description provided for @settingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Definições'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In pt, this message translates to:
  /// **'Aspeto'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In pt, this message translates to:
  /// **'Sistema'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get settingsThemeDark;

  /// No description provided for @settingsHighContrast.
  ///
  /// In pt, this message translates to:
  /// **'Alto contraste'**
  String get settingsHighContrast;

  /// No description provided for @settingsLanguage.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In pt, this message translates to:
  /// **'Idioma da aplicação'**
  String get settingsLanguageLabel;

  /// No description provided for @settingsAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get settingsAccount;

  /// No description provided for @settingsOffline.
  ///
  /// In pt, this message translates to:
  /// **'Modo offline'**
  String get settingsOffline;

  /// No description provided for @settingsTabAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get settingsTabAccount;

  /// No description provided for @settingsTabWorkspace.
  ///
  /// In pt, this message translates to:
  /// **'Organização'**
  String get settingsTabWorkspace;

  /// No description provided for @settingsTabPreferences.
  ///
  /// In pt, this message translates to:
  /// **'Preferências'**
  String get settingsTabPreferences;

  /// No description provided for @settingsActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativa'**
  String get settingsActive;

  /// No description provided for @settingsSwitchOrg.
  ///
  /// In pt, this message translates to:
  /// **'Alternar Organização'**
  String get settingsSwitchOrg;

  /// No description provided for @settingsOrganization.
  ///
  /// In pt, this message translates to:
  /// **'Organização'**
  String get settingsOrganization;

  /// No description provided for @settingsSyncLibrary.
  ///
  /// In pt, this message translates to:
  /// **'Sincronização da Biblioteca'**
  String get settingsSyncLibrary;

  /// No description provided for @settingsSyncLibraryDesc.
  ///
  /// In pt, this message translates to:
  /// **'Sincroniza cânticos, pastas e cultos da sua organização.'**
  String get settingsSyncLibraryDesc;

  /// No description provided for @settingsSyncNow.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizar'**
  String get settingsSyncNow;

  /// No description provided for @settingsLastSync.
  ///
  /// In pt, this message translates to:
  /// **'Última Sincronização'**
  String get settingsLastSync;

  /// No description provided for @settingsSyncState.
  ///
  /// In pt, this message translates to:
  /// **'Estado do Sync'**
  String get settingsSyncState;

  /// No description provided for @settingsLocalSongs.
  ///
  /// In pt, this message translates to:
  /// **'Cânticos Locais'**
  String get settingsLocalSongs;

  /// No description provided for @settingsSavedServices.
  ///
  /// In pt, this message translates to:
  /// **'Cultos Guardados'**
  String get settingsSavedServices;

  /// No description provided for @settingsUserId.
  ///
  /// In pt, this message translates to:
  /// **'ID do Utilizador'**
  String get settingsUserId;

  /// No description provided for @settingsRole.
  ///
  /// In pt, this message translates to:
  /// **'Função'**
  String get settingsRole;

  /// No description provided for @settingsActiveOrg.
  ///
  /// In pt, this message translates to:
  /// **'Organização Ativa'**
  String get settingsActiveOrg;

  /// No description provided for @settingsNoActiveOrg.
  ///
  /// In pt, this message translates to:
  /// **'Sem organização ativa'**
  String get settingsNoActiveOrg;

  /// No description provided for @settingsChangeEmail.
  ///
  /// In pt, this message translates to:
  /// **'Alterar E-mail'**
  String get settingsChangeEmail;

  /// No description provided for @settingsNewEmail.
  ///
  /// In pt, this message translates to:
  /// **'Novo E-mail'**
  String get settingsNewEmail;

  /// No description provided for @settingsSaveEmail.
  ///
  /// In pt, this message translates to:
  /// **'Guardar E-mail'**
  String get settingsSaveEmail;

  /// No description provided for @settingsEmailChangeSent.
  ///
  /// In pt, this message translates to:
  /// **'Pedido de alteração de e-mail enviado!'**
  String get settingsEmailChangeSent;

  /// No description provided for @settingsEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get settingsEdit;

  /// No description provided for @settingsCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get settingsCancel;

  /// No description provided for @settingsSave.
  ///
  /// In pt, this message translates to:
  /// **'Guardar'**
  String get settingsSave;

  /// No description provided for @settingsSaving.
  ///
  /// In pt, this message translates to:
  /// **'A guardar…'**
  String get settingsSaving;

  /// No description provided for @settingsNameEmpty.
  ///
  /// In pt, this message translates to:
  /// **'O nome não pode estar vazio.'**
  String get settingsNameEmpty;

  /// No description provided for @settingsEmailInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Introduza um e-mail válido.'**
  String get settingsEmailInvalid;

  /// No description provided for @settingsMusicianMode.
  ///
  /// In pt, this message translates to:
  /// **'Modo Músico nos Cultos'**
  String get settingsMusicianMode;

  /// No description provided for @settingsMusicianModeDesc.
  ///
  /// In pt, this message translates to:
  /// **'Abre o culto diretamente no primeiro cântico com navegação lateral contínua.'**
  String get settingsMusicianModeDesc;

  /// No description provided for @settingsKeepAwake.
  ///
  /// In pt, this message translates to:
  /// **'Manter Ecrã Ligado'**
  String get settingsKeepAwake;

  /// No description provided for @settingsKeepAwakeDesc.
  ///
  /// In pt, this message translates to:
  /// **'Impede o ecrã de suspender durante a visualização de cânticos.'**
  String get settingsKeepAwakeDesc;

  /// No description provided for @settingsSyncAnnotations.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizar anotações'**
  String get settingsSyncAnnotations;

  /// No description provided for @settingsSyncAnnotationsDesc.
  ///
  /// In pt, this message translates to:
  /// **'Faz com que as anotações sejam partilhadas ao vivo entre todos os utilizadores'**
  String get settingsSyncAnnotationsDesc;

  /// No description provided for @settingsSessionsOnly.
  ///
  /// In pt, this message translates to:
  /// **'Apenas a sessão atual deste dispositivo está ativa.'**
  String get settingsSessionsOnly;

  /// No description provided for @metronomeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Metrónomo'**
  String get metronomeTitle;

  /// No description provided for @metronomeDescription.
  ///
  /// In pt, this message translates to:
  /// **'Tempo e compasso para ensaios.'**
  String get metronomeDescription;

  /// No description provided for @metronomeTapTempo.
  ///
  /// In pt, this message translates to:
  /// **'Toque o Tempo'**
  String get metronomeTapTempo;

  /// No description provided for @metronomeTimeSignature.
  ///
  /// In pt, this message translates to:
  /// **'COMPASSO'**
  String get metronomeTimeSignature;

  /// No description provided for @metronomeAccent.
  ///
  /// In pt, this message translates to:
  /// **'Acentuar'**
  String get metronomeAccent;

  /// No description provided for @circleOfFifthsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Círculo de Quintas'**
  String get circleOfFifthsTitle;

  /// No description provided for @circleOfFifthsDescription.
  ///
  /// In pt, this message translates to:
  /// **'Referência de tons e relativas.'**
  String get circleOfFifthsDescription;

  /// Section header above the chord grid on the Circle of Fifths page
  ///
  /// In pt, this message translates to:
  /// **'Campo Harmónico'**
  String get circleOfFifthsHarmonicField;

  /// Label for the I degree (tonic) chord card
  ///
  /// In pt, this message translates to:
  /// **'Tónica'**
  String get circleOfFifthsTonic;

  /// Label for the vi degree (relative minor) chord card
  ///
  /// In pt, this message translates to:
  /// **'Relativa Menor'**
  String get circleOfFifthsRelativeMinor;

  /// No description provided for @exportPdfTitle.
  ///
  /// In pt, this message translates to:
  /// **'Exportar PDF'**
  String get exportPdfTitle;

  /// No description provided for @comingSoon.
  ///
  /// In pt, this message translates to:
  /// **'Em breve'**
  String get comingSoon;

  /// No description provided for @comingSoonDescription.
  ///
  /// In pt, this message translates to:
  /// **'Esta funcionalidade estará disponível numa próxima versão.'**
  String get comingSoonDescription;

  /// No description provided for @annotationModeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Anotações'**
  String get annotationModeTitle;

  /// No description provided for @annotationPen.
  ///
  /// In pt, this message translates to:
  /// **'Caneta'**
  String get annotationPen;

  /// No description provided for @annotationEraser.
  ///
  /// In pt, this message translates to:
  /// **'Borracha de Traço'**
  String get annotationEraser;

  /// No description provided for @annotationPixelEraser.
  ///
  /// In pt, this message translates to:
  /// **'Borracha Parcial'**
  String get annotationPixelEraser;

  /// No description provided for @annotationLine.
  ///
  /// In pt, this message translates to:
  /// **'Linha'**
  String get annotationLine;

  /// No description provided for @annotationRectangle.
  ///
  /// In pt, this message translates to:
  /// **'Retângulo'**
  String get annotationRectangle;

  /// No description provided for @annotationEllipse.
  ///
  /// In pt, this message translates to:
  /// **'Círculo'**
  String get annotationEllipse;

  /// No description provided for @annotationSelect.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar'**
  String get annotationSelect;

  /// No description provided for @annotationLasso.
  ///
  /// In pt, this message translates to:
  /// **'Laço'**
  String get annotationLasso;

  /// No description provided for @annotationText.
  ///
  /// In pt, this message translates to:
  /// **'Texto'**
  String get annotationText;

  /// No description provided for @annotationLayers.
  ///
  /// In pt, this message translates to:
  /// **'Camadas'**
  String get annotationLayers;

  /// No description provided for @annotationUndo.
  ///
  /// In pt, this message translates to:
  /// **'Desfazer'**
  String get annotationUndo;

  /// No description provided for @annotationRedo.
  ///
  /// In pt, this message translates to:
  /// **'Refazer'**
  String get annotationRedo;

  /// No description provided for @annotationClear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar Tudo'**
  String get annotationClear;

  /// No description provided for @annotationClearConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Limpar todas as anotações deste cântico?'**
  String get annotationClearConfirm;

  /// No description provided for @annotationColorPicker.
  ///
  /// In pt, this message translates to:
  /// **'Cor Personalizada'**
  String get annotationColorPicker;

  /// No description provided for @annotationClose.
  ///
  /// In pt, this message translates to:
  /// **'Concluir'**
  String get annotationClose;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
