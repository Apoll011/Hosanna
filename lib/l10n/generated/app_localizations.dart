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

  /// No description provided for @commonErrorDesc.
  ///
  /// In pt, this message translates to:
  /// **'Verifique a ligação e tente novamente.'**
  String get commonErrorDesc;

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

  /// No description provided for @authCaptchaWindowTitle.
  ///
  /// In pt, this message translates to:
  /// **'Verificação de segurança (captcha)'**
  String get authCaptchaWindowTitle;

  /// No description provided for @authCaptchaWaitingMessage.
  ///
  /// In pt, this message translates to:
  /// **'Conclua a verificação de segurança na janela de captcha que acabou de abrir.'**
  String get authCaptchaWaitingMessage;

  /// No description provided for @authCaptchaOpenFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir a janela de captcha.'**
  String get authCaptchaOpenFailed;

  /// No description provided for @authOr.
  ///
  /// In pt, this message translates to:
  /// **'ou'**
  String get authOr;

  /// Social sign-in button label; {provider} is the provider's display name, e.g. Google
  ///
  /// In pt, this message translates to:
  /// **'Continuar com {provider}'**
  String authContinueWith(String provider);

  /// No description provided for @authSocialNoAccount.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma conta disponível para iniciar sessão neste dispositivo.'**
  String get authSocialNoAccount;

  /// No description provided for @authSocialUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Este dispositivo não suporta este método de início de sessão.'**
  String get authSocialUnavailable;

  /// No description provided for @authSocialNotConfigured.
  ///
  /// In pt, this message translates to:
  /// **'O início de sessão social não está configurado nesta versão.'**
  String get authSocialNotConfigured;

  /// No description provided for @authSocialRejected.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível verificar a sua conta. Tente novamente.'**
  String get authSocialRejected;

  /// No description provided for @authSocialNetworkError.
  ///
  /// In pt, this message translates to:
  /// **'Sem ligação ao servidor. Verifique a sua Internet.'**
  String get authSocialNetworkError;

  /// No description provided for @authSocialServerError.
  ///
  /// In pt, this message translates to:
  /// **'O servidor não conseguiu concluir o início de sessão. Tente novamente.'**
  String get authSocialServerError;

  /// No description provided for @authSocialError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível iniciar sessão.'**
  String get authSocialError;

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

  /// No description provided for @setupWelcomeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Vamos configurar o Hosanna'**
  String get setupWelcomeTitle;

  /// No description provided for @setupWelcomeSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Algumas escolhas rápidas para que canções e cultos fiquem certos para a forma como serve.'**
  String get setupWelcomeSubtitle;

  /// No description provided for @setupWelcomeCta.
  ///
  /// In pt, this message translates to:
  /// **'Começar'**
  String get setupWelcomeCta;

  /// No description provided for @setupRoleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Como usa o Hosanna?'**
  String get setupRoleTitle;

  /// No description provided for @setupRoleSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Abrimos os cultos da forma que melhor se adequa ao seu papel. Pode mudar isto depois nas Definições.'**
  String get setupRoleSubtitle;

  /// No description provided for @setupRoleMusician.
  ///
  /// In pt, this message translates to:
  /// **'Músico'**
  String get setupRoleMusician;

  /// No description provided for @setupRoleMusicianDesc.
  ///
  /// In pt, this message translates to:
  /// **'Entre direto nas canções com acordes, capo e diagramas.'**
  String get setupRoleMusicianDesc;

  /// No description provided for @setupRoleLeader.
  ///
  /// In pt, this message translates to:
  /// **'Líder'**
  String get setupRoleLeader;

  /// No description provided for @setupRoleLeaderDesc.
  ///
  /// In pt, this message translates to:
  /// **'Comece pela ordem do culto e pelas notas do momento.'**
  String get setupRoleLeaderDesc;

  /// No description provided for @setupFocusTitle.
  ///
  /// In pt, this message translates to:
  /// **'O que toca?'**
  String get setupFocusTitle;

  /// No description provided for @setupFocusSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Isto define o instrumento predefinido para os diagramas de acordes.'**
  String get setupFocusSubtitle;

  /// No description provided for @setupFocusGuitar.
  ///
  /// In pt, this message translates to:
  /// **'Guitarra'**
  String get setupFocusGuitar;

  /// No description provided for @setupFocusBass.
  ///
  /// In pt, this message translates to:
  /// **'Baixo'**
  String get setupFocusBass;

  /// No description provided for @setupFocusUkulele.
  ///
  /// In pt, this message translates to:
  /// **'Ukulele'**
  String get setupFocusUkulele;

  /// No description provided for @setupFocusPiano.
  ///
  /// In pt, this message translates to:
  /// **'Piano / teclas'**
  String get setupFocusPiano;

  /// No description provided for @setupFocusVocals.
  ///
  /// In pt, this message translates to:
  /// **'Voz'**
  String get setupFocusVocals;

  /// No description provided for @setupFocusVocalsDesc.
  ///
  /// In pt, this message translates to:
  /// **'Letra em primeiro — os acordes ficam disponíveis quando precisar.'**
  String get setupFocusVocalsDesc;

  /// No description provided for @setupLeaderFocusTitle.
  ///
  /// In pt, this message translates to:
  /// **'Quando abre uma canção…'**
  String get setupLeaderFocusTitle;

  /// No description provided for @setupLeaderFocusSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Opcional — escolha um instrumento para as cifras ao rever canções.'**
  String get setupLeaderFocusSubtitle;

  /// No description provided for @setupPrefsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Predefinições para o palco'**
  String get setupPrefsTitle;

  /// No description provided for @setupPrefsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Opções úteis para ensaios e culto ao vivo.'**
  String get setupPrefsSubtitle;

  /// No description provided for @setupPrefDiagrams.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar diagramas de acordes'**
  String get setupPrefDiagrams;

  /// No description provided for @setupPrefDiagramsDesc.
  ///
  /// In pt, this message translates to:
  /// **'Digitação acima da canção quando disponível.'**
  String get setupPrefDiagramsDesc;

  /// No description provided for @setupPrefAwake.
  ///
  /// In pt, this message translates to:
  /// **'Manter o ecrã ligado'**
  String get setupPrefAwake;

  /// No description provided for @setupPrefAwakeDesc.
  ///
  /// In pt, this message translates to:
  /// **'Não escurecer durante uma canção ou culto.'**
  String get setupPrefAwakeDesc;

  /// No description provided for @setupLanguageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get setupLanguageTitle;

  /// No description provided for @setupLanguageSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o idioma dos menus e etiquetas.'**
  String get setupLanguageSubtitle;

  /// No description provided for @setupLanguageSystem.
  ///
  /// In pt, this message translates to:
  /// **'Seguir o dispositivo'**
  String get setupLanguageSystem;

  /// No description provided for @setupDoneTitle.
  ///
  /// In pt, this message translates to:
  /// **'Está pronto'**
  String get setupDoneTitle;

  /// No description provided for @setupDoneSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'O Hosanna está configurado para si. Entre na biblioteca quando quiser.'**
  String get setupDoneSubtitle;

  /// No description provided for @setupDoneCta.
  ///
  /// In pt, this message translates to:
  /// **'Entrar no Hosanna'**
  String get setupDoneCta;

  /// No description provided for @setupSkip.
  ///
  /// In pt, this message translates to:
  /// **'Saltar por agora'**
  String get setupSkip;

  /// No description provided for @setupStepOf.
  ///
  /// In pt, this message translates to:
  /// **'Passo {current} de {total}'**
  String setupStepOf(int current, int total);

  /// No description provided for @settingsRedoSetup.
  ///
  /// In pt, this message translates to:
  /// **'Repetir configuração'**
  String get settingsRedoSetup;

  /// No description provided for @settingsRedoSetupDesc.
  ///
  /// In pt, this message translates to:
  /// **'Voltar a responder às perguntas de função e instrumento.'**
  String get settingsRedoSetupDesc;

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

  /// No description provided for @songsSavedOffline.
  ///
  /// In pt, this message translates to:
  /// **'Guardado neste dispositivo. As alterações sincronizam quando voltares a ter ligação.'**
  String get songsSavedOffline;

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

  /// No description provided for @navCollections.
  ///
  /// In pt, this message translates to:
  /// **'Coleções'**
  String get navCollections;

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

  /// No description provided for @navAgenda.
  ///
  /// In pt, this message translates to:
  /// **'Agenda'**
  String get navAgenda;

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

  /// No description provided for @agendaEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sem eventos próximos'**
  String get agendaEmptyTitle;

  /// No description provided for @agendaEmptyBody.
  ///
  /// In pt, this message translates to:
  /// **'Os eventos do calendário da igreja aparecem aqui depois de sincronizar.'**
  String get agendaEmptyBody;

  /// No description provided for @agendaNoEventsForDay.
  ///
  /// In pt, this message translates to:
  /// **'Nada neste dia'**
  String get agendaNoEventsForDay;

  /// No description provided for @agendaNoEventsForDayBody.
  ///
  /// In pt, this message translates to:
  /// **'Escolha outro dia na barra acima.'**
  String get agendaNoEventsForDayBody;

  /// No description provided for @agendaEventDetails.
  ///
  /// In pt, this message translates to:
  /// **'Evento'**
  String get agendaEventDetails;

  /// No description provided for @agendaEventNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Evento não encontrado'**
  String get agendaEventNotFound;

  /// No description provided for @agendaEventNotFoundBody.
  ///
  /// In pt, this message translates to:
  /// **'Este evento pode ter sido removido ou ainda não sincronizou.'**
  String get agendaEventNotFoundBody;

  /// No description provided for @agendaFieldDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get agendaFieldDate;

  /// No description provided for @agendaFieldTime.
  ///
  /// In pt, this message translates to:
  /// **'Hora'**
  String get agendaFieldTime;

  /// No description provided for @agendaFieldLocation.
  ///
  /// In pt, this message translates to:
  /// **'Local'**
  String get agendaFieldLocation;

  /// No description provided for @agendaFieldNotes.
  ///
  /// In pt, this message translates to:
  /// **'Notas'**
  String get agendaFieldNotes;

  /// No description provided for @agendaFieldResponsibilities.
  ///
  /// In pt, this message translates to:
  /// **'Equipa'**
  String get agendaFieldResponsibilities;

  /// No description provided for @agendaLinkedService.
  ///
  /// In pt, this message translates to:
  /// **'Culto associado'**
  String get agendaLinkedService;

  /// No description provided for @agendaUnassigned.
  ///
  /// In pt, this message translates to:
  /// **'Sem atribuição'**
  String get agendaUnassigned;

  /// No description provided for @agendaMinutes.
  ///
  /// In pt, this message translates to:
  /// **'{count} min'**
  String agendaMinutes(int count);

  /// No description provided for @agendaResponsibilityCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} atribuídos'**
  String agendaResponsibilityCount(int count);

  /// No description provided for @agendaAssigneeCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} pessoas'**
  String agendaAssigneeCount(int count);

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
  /// **'Ainda sem cânticos'**
  String get songsEmpty;

  /// No description provided for @songsEmptyDesc.
  ///
  /// In pt, this message translates to:
  /// **'Os cânticos da sua igreja aparecem aqui após a sincronização.'**
  String get songsEmptyDesc;

  /// No description provided for @songsNoResults.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum resultado'**
  String get songsNoResults;

  /// No description provided for @songsNoResultsDesc.
  ///
  /// In pt, this message translates to:
  /// **'Experimente outra pesquisa ou limpe os filtros.'**
  String get songsNoResultsDesc;

  /// No description provided for @songsFavoritesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda sem favoritos'**
  String get songsFavoritesEmpty;

  /// No description provided for @songsFavoritesEmptyDesc.
  ///
  /// In pt, this message translates to:
  /// **'Toque no coração num cântico para o guardar aqui.'**
  String get songsFavoritesEmptyDesc;

  /// No description provided for @songsRecentsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda sem recentes'**
  String get songsRecentsEmpty;

  /// No description provided for @songsRecentsEmptyDesc.
  ///
  /// In pt, this message translates to:
  /// **'Os cânticos que abrir aparecem aqui.'**
  String get songsRecentsEmptyDesc;

  /// No description provided for @songsNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Cântico não encontrado'**
  String get songsNotFound;

  /// No description provided for @songsNotFoundDesc.
  ///
  /// In pt, this message translates to:
  /// **'Este cântico pode ter sido removido ou ainda não sincronizou.'**
  String get songsNotFoundDesc;

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

  /// No description provided for @songsFilterByCollection.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar por coleção'**
  String get songsFilterByCollection;

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
  /// **'Pesquisar também na letra'**
  String get songsSearchLyrics;

  /// No description provided for @songsWithChords.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar apenas cânticos com acordes'**
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

  /// No description provided for @songsClearSearch.
  ///
  /// In pt, this message translates to:
  /// **'Limpar pesquisa'**
  String get songsClearSearch;

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

  /// No description provided for @songsCreate.
  ///
  /// In pt, this message translates to:
  /// **'Nova canção'**
  String get songsCreate;

  /// No description provided for @songsEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar canção'**
  String get songsEdit;

  /// No description provided for @songsPreview.
  ///
  /// In pt, this message translates to:
  /// **'Pré-visualizar'**
  String get songsPreview;

  /// No description provided for @songsFieldTitle.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get songsFieldTitle;

  /// No description provided for @songsFieldSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Subtítulo'**
  String get songsFieldSubtitle;

  /// No description provided for @songsFieldArtist.
  ///
  /// In pt, this message translates to:
  /// **'Artista'**
  String get songsFieldArtist;

  /// No description provided for @songsFieldComposer.
  ///
  /// In pt, this message translates to:
  /// **'Compositor'**
  String get songsFieldComposer;

  /// No description provided for @songsFieldLyricist.
  ///
  /// In pt, this message translates to:
  /// **'Letrista'**
  String get songsFieldLyricist;

  /// No description provided for @songsFieldTranslator.
  ///
  /// In pt, this message translates to:
  /// **'Tradutor'**
  String get songsFieldTranslator;

  /// No description provided for @songsFieldArranger.
  ///
  /// In pt, this message translates to:
  /// **'Arranjador'**
  String get songsFieldArranger;

  /// No description provided for @songsFieldSongNumber.
  ///
  /// In pt, this message translates to:
  /// **'Número da canção'**
  String get songsFieldSongNumber;

  /// No description provided for @songsFieldKey.
  ///
  /// In pt, this message translates to:
  /// **'Tom'**
  String get songsFieldKey;

  /// No description provided for @songsFieldOriginalKey.
  ///
  /// In pt, this message translates to:
  /// **'Tom original'**
  String get songsFieldOriginalKey;

  /// No description provided for @songsFieldKeyNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum'**
  String get songsFieldKeyNone;

  /// No description provided for @songsFieldTempo.
  ///
  /// In pt, this message translates to:
  /// **'Tempo (BPM)'**
  String get songsFieldTempo;

  /// No description provided for @songsFieldTime.
  ///
  /// In pt, this message translates to:
  /// **'Compasso'**
  String get songsFieldTime;

  /// No description provided for @songsFieldDuration.
  ///
  /// In pt, this message translates to:
  /// **'Duração (m:ss)'**
  String get songsFieldDuration;

  /// No description provided for @songsFieldCapo.
  ///
  /// In pt, this message translates to:
  /// **'Capo'**
  String get songsFieldCapo;

  /// No description provided for @songsFieldKeyNote.
  ///
  /// In pt, this message translates to:
  /// **'Nota de tom'**
  String get songsFieldKeyNote;

  /// No description provided for @songsFieldAlbum.
  ///
  /// In pt, this message translates to:
  /// **'Álbum'**
  String get songsFieldAlbum;

  /// No description provided for @songsFieldYear.
  ///
  /// In pt, this message translates to:
  /// **'Ano'**
  String get songsFieldYear;

  /// No description provided for @songsFieldCopyright.
  ///
  /// In pt, this message translates to:
  /// **'Copyright'**
  String get songsFieldCopyright;

  /// No description provided for @songsFieldCcli.
  ///
  /// In pt, this message translates to:
  /// **'CCLI'**
  String get songsFieldCcli;

  /// No description provided for @songsFieldYoutube.
  ///
  /// In pt, this message translates to:
  /// **'URL / ID do YouTube'**
  String get songsFieldYoutube;

  /// No description provided for @songsFieldTagsHint.
  ///
  /// In pt, this message translates to:
  /// **'Etiquetas separadas por vírgula'**
  String get songsFieldTagsHint;

  /// No description provided for @songsTabContent.
  ///
  /// In pt, this message translates to:
  /// **'Letra e acordes'**
  String get songsTabContent;

  /// No description provided for @songsTabMetadata.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes'**
  String get songsTabMetadata;

  /// No description provided for @songsTitleRequired.
  ///
  /// In pt, this message translates to:
  /// **'O título é obrigatório.'**
  String get songsTitleRequired;

  /// No description provided for @songsChordProHint.
  ///
  /// In pt, this message translates to:
  /// **'[G]Escreva a letra e os [C]acordes aqui…\nUse as opções acima para verso, refrão e mais.'**
  String get songsChordProHint;

  /// No description provided for @songsEditorInsertVerse.
  ///
  /// In pt, this message translates to:
  /// **'Verso'**
  String get songsEditorInsertVerse;

  /// No description provided for @songsEditorInsertChorus.
  ///
  /// In pt, this message translates to:
  /// **'Refrão'**
  String get songsEditorInsertChorus;

  /// No description provided for @songsEditorInsertBridge.
  ///
  /// In pt, this message translates to:
  /// **'Ponte'**
  String get songsEditorInsertBridge;

  /// No description provided for @songsEditorInsertComment.
  ///
  /// In pt, this message translates to:
  /// **'Comentário'**
  String get songsEditorInsertComment;

  /// No description provided for @songsEditorInsertVersion.
  ///
  /// In pt, this message translates to:
  /// **'Versão'**
  String get songsEditorInsertVersion;

  /// No description provided for @songsLintAllClear.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum problema no ChordPro.'**
  String get songsLintAllClear;

  /// No description provided for @songsLintSummary.
  ///
  /// In pt, this message translates to:
  /// **'{errors} erros · {warnings} avisos · {infos} dicas'**
  String songsLintSummary(int errors, int warnings, int infos);

  /// No description provided for @songsLintLine.
  ///
  /// In pt, this message translates to:
  /// **'L{line}'**
  String songsLintLine(int line);

  /// No description provided for @songsLintDetails.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes'**
  String get songsLintDetails;

  /// No description provided for @songsLintUnclosedBrace.
  ///
  /// In pt, this message translates to:
  /// **'Chavetas por fechar ou desalinhadas.'**
  String get songsLintUnclosedBrace;

  /// No description provided for @songsLintUnclosedBracket.
  ///
  /// In pt, this message translates to:
  /// **'Parênteses de acorde por fechar ou desalinhados.'**
  String get songsLintUnclosedBracket;

  /// No description provided for @songsLintEmptyChord.
  ///
  /// In pt, this message translates to:
  /// **'Acordes vazios.'**
  String get songsLintEmptyChord;

  /// No description provided for @songsLintUnknownChord.
  ///
  /// In pt, this message translates to:
  /// **'Acorde não reconhecido \"{chord}\".'**
  String songsLintUnknownChord(String chord);

  /// No description provided for @songsLintMalformedDirective.
  ///
  /// In pt, this message translates to:
  /// **'Diretiva malformada — verifique chavetas e nome.'**
  String get songsLintMalformedDirective;

  /// No description provided for @songsLintUnknownDirective.
  ///
  /// In pt, this message translates to:
  /// **'Diretiva não reconhecida \"{name}\".'**
  String songsLintUnknownDirective(String name);

  /// No description provided for @songsLintUnclosedSection.
  ///
  /// In pt, this message translates to:
  /// **'Secção {section} por fechar — falta end_of_{section}.'**
  String songsLintUnclosedSection(String section);

  /// No description provided for @songsLintUnexpectedEndSection.
  ///
  /// In pt, this message translates to:
  /// **'end_of_{section} inesperado sem início correspondente.'**
  String songsLintUnexpectedEndSection(String section);

  /// No description provided for @songsLintInvalidYoutube.
  ///
  /// In pt, this message translates to:
  /// **'O valor do YouTube não é um URL ou ID válido.'**
  String get songsLintInvalidYoutube;

  /// No description provided for @songsLintInvalidKey.
  ///
  /// In pt, this message translates to:
  /// **'Tom invulgar \"{value}\". Esperado G, Am, F#m, …'**
  String songsLintInvalidKey(String value);

  /// No description provided for @songsLintInvalidTempo.
  ///
  /// In pt, this message translates to:
  /// **'O tempo deve ser um BPM entre 20 e 400.'**
  String get songsLintInvalidTempo;

  /// No description provided for @songsLintInvalidCapo.
  ///
  /// In pt, this message translates to:
  /// **'O capo deve ser um traste de 0 a 12.'**
  String get songsLintInvalidCapo;

  /// No description provided for @songsLintInvalidTime.
  ///
  /// In pt, this message translates to:
  /// **'O compasso deve parecer 4/4 ou 6/8.'**
  String get songsLintInvalidTime;

  /// No description provided for @songsLintInvalidDuration.
  ///
  /// In pt, this message translates to:
  /// **'A duração deve ser segundos ou m:ss (ex. 3:45).'**
  String get songsLintInvalidDuration;

  /// No description provided for @songsNewSong.
  ///
  /// In pt, this message translates to:
  /// **'Nova canção'**
  String get songsNewSong;

  /// No description provided for @songsCreateManually.
  ///
  /// In pt, this message translates to:
  /// **'Criar manualmente'**
  String get songsCreateManually;

  /// No description provided for @songsCreateManuallyDesc.
  ///
  /// In pt, this message translates to:
  /// **'Título, acordes e letra.'**
  String get songsCreateManuallyDesc;

  /// No description provided for @songsImportWithAi.
  ///
  /// In pt, this message translates to:
  /// **'Importar com IA'**
  String get songsImportWithAi;

  /// No description provided for @songsImportWithAiDesc.
  ///
  /// In pt, this message translates to:
  /// **'De PDF, imagem ou fotografia.'**
  String get songsImportWithAiDesc;

  /// No description provided for @songsAddSong.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar canção'**
  String get songsAddSong;

  /// No description provided for @songsImportSheetMusic.
  ///
  /// In pt, this message translates to:
  /// **'Importe a sua folha de música'**
  String get songsImportSheetMusic;

  /// No description provided for @songsImportSheetMusicBody.
  ///
  /// In pt, this message translates to:
  /// **'Use a Logos AI para converter PDFs, imagens ou fotos em canções com letra, acordes e metadados.'**
  String get songsImportSheetMusicBody;

  /// No description provided for @songsTakePhoto.
  ///
  /// In pt, this message translates to:
  /// **'Tirar fotografia'**
  String get songsTakePhoto;

  /// No description provided for @songsChooseGallery.
  ///
  /// In pt, this message translates to:
  /// **'Escolher da galeria'**
  String get songsChooseGallery;

  /// No description provided for @songsImportPdf.
  ///
  /// In pt, this message translates to:
  /// **'Importar PDF'**
  String get songsImportPdf;

  /// No description provided for @songsHowItWorks.
  ///
  /// In pt, this message translates to:
  /// **'Como funciona?'**
  String get songsHowItWorks;

  /// No description provided for @songsAiAnalyzing.
  ///
  /// In pt, this message translates to:
  /// **'A analisar a folha de música…'**
  String get songsAiAnalyzing;

  /// No description provided for @songsAiAnalyzingBody.
  ///
  /// In pt, this message translates to:
  /// **'A Logos está a extrair letra, acordes e informação.'**
  String get songsAiAnalyzingBody;

  /// No description provided for @songsAiStepProcess.
  ///
  /// In pt, this message translates to:
  /// **'Processar o ficheiro'**
  String get songsAiStepProcess;

  /// No description provided for @songsAiStepExtract.
  ///
  /// In pt, this message translates to:
  /// **'Extrair letra e acordes'**
  String get songsAiStepExtract;

  /// No description provided for @songsAiStepMetadata.
  ///
  /// In pt, this message translates to:
  /// **'Identificar metadados (título, tom, …)'**
  String get songsAiStepMetadata;

  /// No description provided for @songsAiStepVerify.
  ///
  /// In pt, this message translates to:
  /// **'Verificar online e completar metadados'**
  String get songsAiStepVerify;

  /// No description provided for @songsAiStepDraft.
  ///
  /// In pt, this message translates to:
  /// **'Preparar o rascunho'**
  String get songsAiStepDraft;

  /// No description provided for @songsAiPleaseWait.
  ///
  /// In pt, this message translates to:
  /// **'Isto pode demorar alguns segundos…'**
  String get songsAiPleaseWait;

  /// No description provided for @songsAiResultTitle.
  ///
  /// In pt, this message translates to:
  /// **'Resultado da importação'**
  String get songsAiResultTitle;

  /// No description provided for @songsAiCreatedBanner.
  ///
  /// In pt, this message translates to:
  /// **'Canção criada com IA. Confirme e ajuste as informações antes de guardar.'**
  String get songsAiCreatedBanner;

  /// No description provided for @songsAiSave.
  ///
  /// In pt, this message translates to:
  /// **'Guardar'**
  String get songsAiSave;

  /// No description provided for @songsAiEditContent.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get songsAiEditContent;

  /// No description provided for @songsAiImportFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível importar esta folha'**
  String get songsAiImportFailed;

  /// No description provided for @songsAiImportFailedBody.
  ///
  /// In pt, this message translates to:
  /// **'Tente outra foto ou PDF, ou crie a canção manualmente.'**
  String get songsAiImportFailedBody;

  /// No description provided for @songsAiCancelledTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não é uma partitura'**
  String get songsAiCancelledTitle;

  /// No description provided for @songsAiCancelledBody.
  ///
  /// In pt, this message translates to:
  /// **'O Logos cancelou esta importação. Tente uma foto mais nítida de uma cifra, ou crie a canção manualmente.'**
  String get songsAiCancelledBody;

  /// No description provided for @songsAiCancelledGeneric.
  ///
  /// In pt, this message translates to:
  /// **'Esta imagem não parece uma canção importável.'**
  String get songsAiCancelledGeneric;

  /// No description provided for @songsAiCancelledNotASong.
  ///
  /// In pt, this message translates to:
  /// **'Isto não parece uma partitura ou cifra.'**
  String get songsAiCancelledNotASong;

  /// No description provided for @songsAiCancelledUnreadable.
  ///
  /// In pt, this message translates to:
  /// **'A imagem está demasiado desfocada ou escura.'**
  String get songsAiCancelledUnreadable;

  /// No description provided for @songsAiCancelledBlank.
  ///
  /// In pt, this message translates to:
  /// **'A página parece em branco ou vazia.'**
  String get songsAiCancelledBlank;

  /// No description provided for @songsAiCancelledWrongContent.
  ///
  /// In pt, this message translates to:
  /// **'Há texto, mas não é uma canção / cifra.'**
  String get songsAiCancelledWrongContent;

  /// No description provided for @songsAiCancelledMultiple.
  ///
  /// In pt, this message translates to:
  /// **'Parecem várias canções misturadas sem uma principal clara.'**
  String get songsAiCancelledMultiple;

  /// No description provided for @songsAiCancelImport.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get songsAiCancelImport;

  /// No description provided for @songsAiDiscardDraft.
  ///
  /// In pt, this message translates to:
  /// **'Descartar rascunho'**
  String get songsAiDiscardDraft;

  /// No description provided for @songsAiConfidence.
  ///
  /// In pt, this message translates to:
  /// **'Confiança da IA: {percent}%'**
  String songsAiConfidence(String percent);

  /// No description provided for @songsAiLowConfidence.
  ///
  /// In pt, this message translates to:
  /// **'Baixa confiança — reveja bem a letra e os acordes antes de guardar.'**
  String get songsAiLowConfidence;

  /// No description provided for @songsAiSuccessTitle.
  ///
  /// In pt, this message translates to:
  /// **'Importação concluída'**
  String get songsAiSuccessTitle;

  /// No description provided for @songsAiSuccessBody.
  ///
  /// In pt, this message translates to:
  /// **'Letra, acordes e metadados foram capturados.'**
  String get songsAiSuccessBody;

  /// No description provided for @songsAiViewSong.
  ///
  /// In pt, this message translates to:
  /// **'Ver canção'**
  String get songsAiViewSong;

  /// No description provided for @songsAiImportAnother.
  ///
  /// In pt, this message translates to:
  /// **'Importar outra'**
  String get songsAiImportAnother;

  /// No description provided for @songsAiPossibleDuplicates.
  ///
  /// In pt, this message translates to:
  /// **'Possíveis correspondências na biblioteca'**
  String get songsAiPossibleDuplicates;

  /// No description provided for @songsAiPossibleDuplicatesHint.
  ///
  /// In pt, this message translates to:
  /// **'Abra para comparar — volta a este rascunho depois. Guardar cria sempre uma canção nova.'**
  String get songsAiPossibleDuplicatesHint;

  /// No description provided for @songsAiOpenExisting.
  ///
  /// In pt, this message translates to:
  /// **'Abrir'**
  String get songsAiOpenExisting;

  /// No description provided for @songsAiLintIssues.
  ///
  /// In pt, this message translates to:
  /// **'Problemas ChordPro'**
  String get songsAiLintIssues;

  /// No description provided for @songsAiFieldComposer.
  ///
  /// In pt, this message translates to:
  /// **'Compositor'**
  String get songsAiFieldComposer;

  /// No description provided for @songsAiFieldCcli.
  ///
  /// In pt, this message translates to:
  /// **'CCLI'**
  String get songsAiFieldCcli;

  /// No description provided for @songsAiFieldDuration.
  ///
  /// In pt, this message translates to:
  /// **'Duração'**
  String get songsAiFieldDuration;

  /// No description provided for @songsAiFieldYoutube.
  ///
  /// In pt, this message translates to:
  /// **'YouTube'**
  String get songsAiFieldYoutube;

  /// No description provided for @songsAiOpenYoutube.
  ///
  /// In pt, this message translates to:
  /// **'Abrir YouTube'**
  String get songsAiOpenYoutube;

  /// No description provided for @songsAiCaptureTip.
  ///
  /// In pt, this message translates to:
  /// **'Use luz uniforme e evite reflexos ou desfoque para melhores resultados.'**
  String get songsAiCaptureTip;

  /// No description provided for @songsAiCaptureQualityHint.
  ///
  /// In pt, this message translates to:
  /// **'Esta imagem parece pequena ou de baixa qualidade — tente uma foto mais nítida e bem iluminada.'**
  String get songsAiCaptureQualityHint;

  /// No description provided for @songsAiPdfMultiPageHint.
  ///
  /// In pt, this message translates to:
  /// **'Até 5 páginas são enviadas em PDFs com várias páginas.'**
  String get songsAiPdfMultiPageHint;

  /// No description provided for @songsEmptyAddHint.
  ///
  /// In pt, this message translates to:
  /// **'Adicione uma canção manualmente ou importe com a Logos AI.'**
  String get songsEmptyAddHint;

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

  /// No description provided for @songBass.
  ///
  /// In pt, this message translates to:
  /// **'Baixo'**
  String get songBass;

  /// No description provided for @songUkulele.
  ///
  /// In pt, this message translates to:
  /// **'Ukelele'**
  String get songUkulele;

  /// No description provided for @songPiano.
  ///
  /// In pt, this message translates to:
  /// **'Piano'**
  String get songPiano;

  /// No description provided for @instrumentFamilyFretted.
  ///
  /// In pt, this message translates to:
  /// **'Com trastes'**
  String get instrumentFamilyFretted;

  /// No description provided for @instrumentFamilyKeyboard.
  ///
  /// In pt, this message translates to:
  /// **'Teclado'**
  String get instrumentFamilyKeyboard;

  /// No description provided for @settingsInstrumentConfig.
  ///
  /// In pt, this message translates to:
  /// **'Definições do instrumento'**
  String get settingsInstrumentConfig;

  /// No description provided for @settingsInstrumentConfigDesc.
  ///
  /// In pt, this message translates to:
  /// **'Opções do instrumento selecionado — usadas ao desenhar os diagramas de acordes.'**
  String get settingsInstrumentConfigDesc;

  /// No description provided for @settingsTuning.
  ///
  /// In pt, this message translates to:
  /// **'Afinação'**
  String get settingsTuning;

  /// No description provided for @settingsTuningDesc.
  ///
  /// In pt, this message translates to:
  /// **'Configuração das cordas abertas para os diagramas.'**
  String get settingsTuningDesc;

  /// No description provided for @settingsShowFingerNumbers.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar números dos dedos'**
  String get settingsShowFingerNumbers;

  /// No description provided for @settingsShowFingerNumbersDesc.
  ///
  /// In pt, this message translates to:
  /// **'Desenha 1–4 dentro dos pontos no diagrama.'**
  String get settingsShowFingerNumbersDesc;

  /// No description provided for @settingsShowCapoMarker.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar capo nos diagramas'**
  String get settingsShowCapoMarker;

  /// No description provided for @settingsShowCapoMarkerDesc.
  ///
  /// In pt, this message translates to:
  /// **'Desenha o capo no pestana quando está ativo (estilo CifraClub).'**
  String get settingsShowCapoMarkerDesc;

  /// No description provided for @settingsShowStringLabels.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar nomes das cordas'**
  String get settingsShowStringLabels;

  /// No description provided for @settingsShowStringLabelsDesc.
  ///
  /// In pt, this message translates to:
  /// **'Etiqueta cada corda por baixo do diagrama (E A D G B e, etc.).'**
  String get settingsShowStringLabelsDesc;

  /// No description provided for @settingsBassRootNotes.
  ///
  /// In pt, this message translates to:
  /// **'Só notas fundamentais'**
  String get settingsBassRootNotes;

  /// No description provided for @settingsBassRootNotesDesc.
  ///
  /// In pt, this message translates to:
  /// **'Mostra uma única nota (tónica ou baixo do acorde com barra) em vez de formas completas.'**
  String get settingsBassRootNotesDesc;

  /// No description provided for @settingsPianoCompactVoicing.
  ///
  /// In pt, this message translates to:
  /// **'Voicings compactos'**
  String get settingsPianoCompactVoicing;

  /// No description provided for @settingsPianoCompactVoicingDesc.
  ///
  /// In pt, this message translates to:
  /// **'Em acordes de 7ª e extensões, omite a tónica na mão direita (ex.: C7 → Bb-E-G).'**
  String get settingsPianoCompactVoicingDesc;

  /// No description provided for @settingsPianoSlashSplit.
  ///
  /// In pt, this message translates to:
  /// **'Acordes com baixo: baixo na mão esquerda'**
  String get settingsPianoSlashSplit;

  /// No description provided for @settingsPianoSlashSplitDesc.
  ///
  /// In pt, this message translates to:
  /// **'Toca o baixo do acorde com barra na mão esquerda e o acorde na direita (ex.: A/C#).'**
  String get settingsPianoSlashSplitDesc;

  /// No description provided for @tuningGuitarStandard.
  ///
  /// In pt, this message translates to:
  /// **'Padrão'**
  String get tuningGuitarStandard;

  /// No description provided for @tuningGuitarDropD.
  ///
  /// In pt, this message translates to:
  /// **'Drop D'**
  String get tuningGuitarDropD;

  /// No description provided for @tuningGuitarSevenString.
  ///
  /// In pt, this message translates to:
  /// **'7 cordas'**
  String get tuningGuitarSevenString;

  /// No description provided for @tuningBassFiveString.
  ///
  /// In pt, this message translates to:
  /// **'5 cordas'**
  String get tuningBassFiveString;

  /// No description provided for @tuningUkuleleHighG.
  ///
  /// In pt, this message translates to:
  /// **'Sol agudo'**
  String get tuningUkuleleHighG;

  /// No description provided for @tuningUkuleleLowG.
  ///
  /// In pt, this message translates to:
  /// **'Sol grave'**
  String get tuningUkuleleLowG;

  /// No description provided for @tuningUkuleleBaritone.
  ///
  /// In pt, this message translates to:
  /// **'Barítono'**
  String get tuningUkuleleBaritone;

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

  /// No description provided for @songYoutubeOpenPlayer.
  ///
  /// In pt, this message translates to:
  /// **'Ouvir no YouTube'**
  String get songYoutubeOpenPlayer;

  /// No description provided for @songYoutubeClosePlayer.
  ///
  /// In pt, this message translates to:
  /// **'Fechar leitor'**
  String get songYoutubeClosePlayer;

  /// No description provided for @songYoutubePlay.
  ///
  /// In pt, this message translates to:
  /// **'Reproduzir'**
  String get songYoutubePlay;

  /// No description provided for @songYoutubePause.
  ///
  /// In pt, this message translates to:
  /// **'Pausar'**
  String get songYoutubePause;

  /// No description provided for @songYoutubeRewind.
  ///
  /// In pt, this message translates to:
  /// **'Recuar 10 segundos'**
  String get songYoutubeRewind;

  /// No description provided for @songYoutubeForward.
  ///
  /// In pt, this message translates to:
  /// **'Avançar 30 segundos'**
  String get songYoutubeForward;

  /// No description provided for @songYoutubeError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível reproduzir este vídeo'**
  String get songYoutubeError;

  /// No description provided for @songSectionChorus.
  ///
  /// In pt, this message translates to:
  /// **'Refrão'**
  String get songSectionChorus;

  /// No description provided for @songSectionBridge.
  ///
  /// In pt, this message translates to:
  /// **'Ponte'**
  String get songSectionBridge;

  /// No description provided for @songSectionTab.
  ///
  /// In pt, this message translates to:
  /// **'Tablatura'**
  String get songSectionTab;

  /// No description provided for @songSectionInstrumental.
  ///
  /// In pt, this message translates to:
  /// **'Instrumental'**
  String get songSectionInstrumental;

  /// No description provided for @songRepeatChorus.
  ///
  /// In pt, this message translates to:
  /// **'(Repete o refrão)'**
  String get songRepeatChorus;

  /// No description provided for @songKeyPill.
  ///
  /// In pt, this message translates to:
  /// **'Tom: {key}'**
  String songKeyPill(Object key);

  /// No description provided for @songCapoPill.
  ///
  /// In pt, this message translates to:
  /// **'Capo: {fret}ª casa'**
  String songCapoPill(Object fret);

  /// No description provided for @songShapePill.
  ///
  /// In pt, this message translates to:
  /// **'Formato: {key}'**
  String songShapePill(Object key);

  /// No description provided for @songOriginalKeyPill.
  ///
  /// In pt, this message translates to:
  /// **'Tom Orig: {key}'**
  String songOriginalKeyPill(Object key);

  /// No description provided for @songTranslatorCredit.
  ///
  /// In pt, this message translates to:
  /// **'Tradução: {name}'**
  String songTranslatorCredit(String name);

  /// No description provided for @songLyricistCredit.
  ///
  /// In pt, this message translates to:
  /// **'Letra: {name}'**
  String songLyricistCredit(String name);

  /// No description provided for @songArrangerCredit.
  ///
  /// In pt, this message translates to:
  /// **'Arranjo: {name}'**
  String songArrangerCredit(String name);

  /// No description provided for @songNumberPill.
  ///
  /// In pt, this message translates to:
  /// **'Nº {number}'**
  String songNumberPill(Object number);

  /// No description provided for @songCapoOnFret.
  ///
  /// In pt, this message translates to:
  /// **'Capo na {fret}ª casa'**
  String songCapoOnFret(Object fret);

  /// No description provided for @songChangeKey.
  ///
  /// In pt, this message translates to:
  /// **'Mudar tom'**
  String get songChangeKey;

  /// No description provided for @songChordTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dicionário: {chord}'**
  String songChordTitle(Object chord);

  /// No description provided for @songChordNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Acorde \"{chord}\" não registado'**
  String songChordNotFound(Object chord);

  /// No description provided for @songChordNotes.
  ///
  /// In pt, this message translates to:
  /// **'Notas: {notes}'**
  String songChordNotes(Object notes);

  /// No description provided for @songChordSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Acorde {chord}'**
  String songChordSemantics(Object chord);

  /// No description provided for @songPreviousChord.
  ///
  /// In pt, this message translates to:
  /// **'Acorde anterior'**
  String get songPreviousChord;

  /// No description provided for @songNextChord.
  ///
  /// In pt, this message translates to:
  /// **'Acorde seguinte'**
  String get songNextChord;

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
  /// **'Ainda sem pastas'**
  String get foldersEmpty;

  /// No description provided for @foldersEmptyDesc.
  ///
  /// In pt, this message translates to:
  /// **'As pastas organizam a biblioteca de cânticos da sua igreja.'**
  String get foldersEmptyDesc;

  /// No description provided for @folderContentsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Esta pasta está vazia'**
  String get folderContentsEmpty;

  /// No description provided for @folderContentsEmptyDesc.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há cânticos nem subpastas aqui. Adicione um cântico, importe com a Logos AI, ou mova cânticos para esta pasta no Studio.'**
  String get folderContentsEmptyDesc;

  /// No description provided for @folderContentsEmptyReadonlyDesc.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há cânticos nem subpastas aqui. Peça a um líder para os adicionar no Studio, ou volte após a próxima sincronização.'**
  String get folderContentsEmptyReadonlyDesc;

  /// No description provided for @foldersNoResultsDesc.
  ///
  /// In pt, this message translates to:
  /// **'Experimente outra pesquisa ou limpe os filtros.'**
  String get foldersNoResultsDesc;

  /// No description provided for @collectionsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda sem coleções'**
  String get collectionsEmpty;

  /// No description provided for @collectionsEmptyDesc.
  ///
  /// In pt, this message translates to:
  /// **'As coleções aparecem aqui quando a sua igreja as criar.'**
  String get collectionsEmptyDesc;

  /// No description provided for @collectionsSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar coleções…'**
  String get collectionsSearchHint;

  /// No description provided for @collectionContentsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Esta coleção está vazia'**
  String get collectionContentsEmpty;

  /// No description provided for @collectionContentsEmptyDesc.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há cânticos nesta coleção. Adicione-os no Studio — um cântico pode pertencer a várias coleções ao mesmo tempo.'**
  String get collectionContentsEmptyDesc;

  /// No description provided for @collectionContentsEmptyReadonlyDesc.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há cânticos nesta coleção. Peça a um líder para os adicionar no Studio, ou volte após a próxima sincronização.'**
  String get collectionContentsEmptyReadonlyDesc;

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

  /// No description provided for @foldersViewGrid.
  ///
  /// In pt, this message translates to:
  /// **'Ver em grelha'**
  String get foldersViewGrid;

  /// No description provided for @foldersViewList.
  ///
  /// In pt, this message translates to:
  /// **'Ver em lista'**
  String get foldersViewList;

  /// No description provided for @servicesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cultos'**
  String get servicesTitle;

  /// No description provided for @servicesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda sem cultos'**
  String get servicesEmpty;

  /// No description provided for @servicesEmptyDesc.
  ///
  /// In pt, this message translates to:
  /// **'Os cultos e planos de louvor da sua igreja aparecem aqui.'**
  String get servicesEmptyDesc;

  /// No description provided for @servicesSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar cultos…'**
  String get servicesSearchHint;

  /// No description provided for @servicesNoResults.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum culto correspondente'**
  String get servicesNoResults;

  /// No description provided for @servicesNoResultsDesc.
  ///
  /// In pt, this message translates to:
  /// **'Experimente outra pesquisa.'**
  String get servicesNoResultsDesc;

  /// No description provided for @servicesNoResultsFiltersDesc.
  ///
  /// In pt, this message translates to:
  /// **'Nada corresponde a estes filtros. Experimenta limpá-los.'**
  String get servicesNoResultsFiltersDesc;

  /// No description provided for @servicesFilter.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar cultos'**
  String get servicesFilter;

  /// No description provided for @servicesSortDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get servicesSortDate;

  /// No description provided for @servicesSortName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get servicesSortName;

  /// No description provided for @servicesFilterWhen.
  ///
  /// In pt, this message translates to:
  /// **'Quando'**
  String get servicesFilterWhen;

  /// No description provided for @servicesFilterDateAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas as datas'**
  String get servicesFilterDateAll;

  /// No description provided for @servicesFilterUpcoming.
  ///
  /// In pt, this message translates to:
  /// **'Próximos'**
  String get servicesFilterUpcoming;

  /// No description provided for @servicesFilterPast.
  ///
  /// In pt, this message translates to:
  /// **'Passados'**
  String get servicesFilterPast;

  /// No description provided for @servicesFilterToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get servicesFilterToday;

  /// No description provided for @servicesFilterThisWeek.
  ///
  /// In pt, this message translates to:
  /// **'Esta semana'**
  String get servicesFilterThisWeek;

  /// No description provided for @servicesFilterThisMonth.
  ///
  /// In pt, this message translates to:
  /// **'Este mês'**
  String get servicesFilterThisMonth;

  /// No description provided for @servicesFilterStatus.
  ///
  /// In pt, this message translates to:
  /// **'Estado'**
  String get servicesFilterStatus;

  /// No description provided for @servicesFilterActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativos'**
  String get servicesFilterActive;

  /// No description provided for @servicesFilterArchivedOnly.
  ///
  /// In pt, this message translates to:
  /// **'Arquivados'**
  String get servicesFilterArchivedOnly;

  /// No description provided for @servicesFilterIncludeArchived.
  ///
  /// In pt, this message translates to:
  /// **'Ativos + arquivados'**
  String get servicesFilterIncludeArchived;

  /// No description provided for @servicesFilterContent.
  ///
  /// In pt, this message translates to:
  /// **'Plano'**
  String get servicesFilterContent;

  /// No description provided for @servicesFilterContentAny.
  ///
  /// In pt, this message translates to:
  /// **'Qualquer'**
  String get servicesFilterContentAny;

  /// No description provided for @servicesFilterWithSongs.
  ///
  /// In pt, this message translates to:
  /// **'Com músicas'**
  String get servicesFilterWithSongs;

  /// No description provided for @servicesFilterWithNotes.
  ///
  /// In pt, this message translates to:
  /// **'Com notas'**
  String get servicesFilterWithNotes;

  /// No description provided for @servicesFilterEmptyPlan.
  ///
  /// In pt, this message translates to:
  /// **'Plano vazio'**
  String get servicesFilterEmptyPlan;

  /// No description provided for @servicesNextService.
  ///
  /// In pt, this message translates to:
  /// **'Próximo culto'**
  String get servicesNextService;

  /// No description provided for @servicesNoUpcoming.
  ///
  /// In pt, this message translates to:
  /// **'Sem cultos futuros'**
  String get servicesNoUpcoming;

  /// No description provided for @servicesNoUpcomingDesc.
  ///
  /// In pt, this message translates to:
  /// **'Não há cultos agendados de momento.'**
  String get servicesNoUpcomingDesc;

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
  /// **'Culto sem itens'**
  String get servicesNoItems;

  /// No description provided for @servicesNoItemsDesc.
  ///
  /// In pt, this message translates to:
  /// **'Este culto ainda não tem momentos ou cânticos.'**
  String get servicesNoItemsDesc;

  /// No description provided for @servicesNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Culto não encontrado'**
  String get servicesNotFound;

  /// No description provided for @servicesNotFoundDesc.
  ///
  /// In pt, this message translates to:
  /// **'Este culto pode ter sido removido ou ainda não sincronizou.'**
  String get servicesNotFoundDesc;

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

  /// No description provided for @servicesMore.
  ///
  /// In pt, this message translates to:
  /// **'Mais'**
  String get servicesMore;

  /// No description provided for @servicesInProgress.
  ///
  /// In pt, this message translates to:
  /// **'Em andamento'**
  String get servicesInProgress;

  /// No description provided for @servicesItemDetail.
  ///
  /// In pt, this message translates to:
  /// **'Detalhe do Item'**
  String get servicesItemDetail;

  /// No description provided for @servicesEstimatedDuration.
  ///
  /// In pt, this message translates to:
  /// **'Duração estimada'**
  String get servicesEstimatedDuration;

  /// No description provided for @servicesPassage.
  ///
  /// In pt, this message translates to:
  /// **'Passagem'**
  String get servicesPassage;

  /// No description provided for @servicesMarkCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Marcar como concluído'**
  String get servicesMarkCompleted;

  /// No description provided for @servicesLeaderNotes.
  ///
  /// In pt, this message translates to:
  /// **'Notas do Líder'**
  String get servicesLeaderNotes;

  /// No description provided for @servicesLeaderNotesHint.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar notas sobre este momento…'**
  String get servicesLeaderNotesHint;

  /// No description provided for @servicesTeamNotes.
  ///
  /// In pt, this message translates to:
  /// **'Notas da Equipa'**
  String get servicesTeamNotes;

  /// No description provided for @servicesNotesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda sem notas'**
  String get servicesNotesEmpty;

  /// No description provided for @servicesNotesEmptyDesc.
  ///
  /// In pt, this message translates to:
  /// **'Partilhe atualizações com a equipa durante o culto.'**
  String get servicesNotesEmptyDesc;

  /// No description provided for @servicesNotesAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar nota'**
  String get servicesNotesAdd;

  /// No description provided for @servicesNotesEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar nota'**
  String get servicesNotesEdit;

  /// No description provided for @servicesNotesDelete.
  ///
  /// In pt, this message translates to:
  /// **'Eliminar'**
  String get servicesNotesDelete;

  /// No description provided for @servicesNotesDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Eliminar nota?'**
  String get servicesNotesDeleteTitle;

  /// No description provided for @servicesNotesDeleteDesc.
  ///
  /// In pt, this message translates to:
  /// **'Esta nota será removida para todos os que a podem ver.'**
  String get servicesNotesDeleteDesc;

  /// No description provided for @servicesNotesHint.
  ///
  /// In pt, this message translates to:
  /// **'Escreva uma nota para a equipa…'**
  String get servicesNotesHint;

  /// No description provided for @servicesNotesPrivate.
  ///
  /// In pt, this message translates to:
  /// **'Nota privada'**
  String get servicesNotesPrivate;

  /// No description provided for @servicesNotesPrivateDesc.
  ///
  /// In pt, this message translates to:
  /// **'Só você pode ver esta nota.'**
  String get servicesNotesPrivateDesc;

  /// No description provided for @servicesNotesSubscriptionRequired.
  ///
  /// In pt, this message translates to:
  /// **'É necessária uma subscrição ativa para adicionar ou editar notas.'**
  String get servicesNotesSubscriptionRequired;

  /// No description provided for @servicesNotesForbidden.
  ///
  /// In pt, this message translates to:
  /// **'Não tem permissão para alterar esta nota.'**
  String get servicesNotesForbidden;

  /// No description provided for @servicesNotesUnauthorized.
  ///
  /// In pt, this message translates to:
  /// **'Inicie sessão novamente para gerir notas.'**
  String get servicesNotesUnauthorized;

  /// No description provided for @servicesNotesNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Esta nota já não existe.'**
  String get servicesNotesNotFound;

  /// No description provided for @servicesNotesElementNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Esse item do culto não foi encontrado.'**
  String get servicesNotesElementNotFound;

  /// No description provided for @servicesNotesSomeone.
  ///
  /// In pt, this message translates to:
  /// **'Alguém'**
  String get servicesNotesSomeone;

  /// No description provided for @servicesNotesQuickSend.
  ///
  /// In pt, this message translates to:
  /// **'Envio rápido'**
  String get servicesNotesQuickSend;

  /// No description provided for @servicesNotesStale.
  ///
  /// In pt, this message translates to:
  /// **'As notas podem estar desatualizadas'**
  String get servicesNotesStale;

  /// No description provided for @servicesNotesStaleRetry.
  ///
  /// In pt, this message translates to:
  /// **'Toque para atualizar'**
  String get servicesNotesStaleRetry;

  /// No description provided for @servicesNotesServiceSection.
  ///
  /// In pt, this message translates to:
  /// **'Culto inteiro'**
  String get servicesNotesServiceSection;

  /// No description provided for @servicesNotesServiceSectionDesc.
  ///
  /// In pt, this message translates to:
  /// **'Notas visíveis para todo o culto, não ligadas a este item.'**
  String get servicesNotesServiceSectionDesc;

  /// No description provided for @servicesNotesAddService.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar nota do culto'**
  String get servicesNotesAddService;

  /// No description provided for @servicesNotesAddItem.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar nota do item'**
  String get servicesNotesAddItem;

  /// No description provided for @servicesStartService.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar culto'**
  String get servicesStartService;

  /// No description provided for @servicesStartServiceDesc.
  ///
  /// In pt, this message translates to:
  /// **'Inicie o temporizador quando o culto começar.'**
  String get servicesStartServiceDesc;

  /// No description provided for @servicesScheduledWindow.
  ///
  /// In pt, this message translates to:
  /// **'Agendado {window}'**
  String servicesScheduledWindow(String window);

  /// No description provided for @servicesItemRunning.
  ///
  /// In pt, this message translates to:
  /// **'Este item · {elapsed}'**
  String servicesItemRunning(String elapsed);

  /// No description provided for @servicesNotStarted.
  ///
  /// In pt, this message translates to:
  /// **'Não iniciado'**
  String get servicesNotStarted;

  /// No description provided for @noteSugReadyToStart.
  ///
  /// In pt, this message translates to:
  /// **'Prontos para começar'**
  String get noteSugReadyToStart;

  /// No description provided for @noteSugStandbyNext.
  ///
  /// In pt, this message translates to:
  /// **'Standby para o próximo'**
  String get noteSugStandbyNext;

  /// No description provided for @noteSugGoNextItem.
  ///
  /// In pt, this message translates to:
  /// **'A passar para o próximo'**
  String get noteSugGoNextItem;

  /// No description provided for @noteSugHoldWait.
  ///
  /// In pt, this message translates to:
  /// **'Aguardar'**
  String get noteSugHoldWait;

  /// No description provided for @noteSugWrapUp.
  ///
  /// In pt, this message translates to:
  /// **'Encerrar este momento'**
  String get noteSugWrapUp;

  /// No description provided for @noteSugBehindSchedule.
  ///
  /// In pt, this message translates to:
  /// **'Estamos atrasados'**
  String get noteSugBehindSchedule;

  /// No description provided for @noteSugAheadSchedule.
  ///
  /// In pt, this message translates to:
  /// **'Estamos adiantados'**
  String get noteSugAheadSchedule;

  /// No description provided for @noteSugSkipItem.
  ///
  /// In pt, this message translates to:
  /// **'Saltar este item'**
  String get noteSugSkipItem;

  /// No description provided for @noteSugExtendMoment.
  ///
  /// In pt, this message translates to:
  /// **'Prolongar este momento'**
  String get noteSugExtendMoment;

  /// No description provided for @noteSugChangeOfPlan.
  ///
  /// In pt, this message translates to:
  /// **'Mudança de plano'**
  String get noteSugChangeOfPlan;

  /// No description provided for @noteSugLookingGood.
  ///
  /// In pt, this message translates to:
  /// **'Está a correr bem'**
  String get noteSugLookingGood;

  /// No description provided for @noteSugNeedHelp.
  ///
  /// In pt, this message translates to:
  /// **'Preciso de ajuda no palco'**
  String get noteSugNeedHelp;

  /// No description provided for @noteSugQuietMoment.
  ///
  /// In pt, this message translates to:
  /// **'Momento de silêncio'**
  String get noteSugQuietMoment;

  /// No description provided for @noteSugPrayTogether.
  ///
  /// In pt, this message translates to:
  /// **'Vamos orar'**
  String get noteSugPrayTogether;

  /// No description provided for @noteSugDoorsClosing.
  ///
  /// In pt, this message translates to:
  /// **'A fechar portas'**
  String get noteSugDoorsClosing;

  /// No description provided for @noteSugGuestsReady.
  ///
  /// In pt, this message translates to:
  /// **'Recepção / convidados prontos'**
  String get noteSugGuestsReady;

  /// No description provided for @noteSugMicLive.
  ///
  /// In pt, this message translates to:
  /// **'Microfone ao vivo'**
  String get noteSugMicLive;

  /// No description provided for @noteSugMicMute.
  ///
  /// In pt, this message translates to:
  /// **'Silenciar esse microfone'**
  String get noteSugMicMute;

  /// No description provided for @noteSugMicCheck.
  ///
  /// In pt, this message translates to:
  /// **'Precisa de teste de microfone'**
  String get noteSugMicCheck;

  /// No description provided for @noteSugFeedbackMute.
  ///
  /// In pt, this message translates to:
  /// **'Feedback — silenciar já'**
  String get noteSugFeedbackMute;

  /// No description provided for @noteSugSpareMic.
  ///
  /// In pt, this message translates to:
  /// **'Trazer microfone de reserva'**
  String get noteSugSpareMic;

  /// No description provided for @noteSugSlidesReady.
  ///
  /// In pt, this message translates to:
  /// **'Slides prontos'**
  String get noteSugSlidesReady;

  /// No description provided for @noteSugNextSlide.
  ///
  /// In pt, this message translates to:
  /// **'Próximo slide'**
  String get noteSugNextSlide;

  /// No description provided for @noteSugWrongSlide.
  ///
  /// In pt, this message translates to:
  /// **'Slide errado'**
  String get noteSugWrongSlide;

  /// No description provided for @noteSugBlankScreen.
  ///
  /// In pt, this message translates to:
  /// **'Ecrã em preto'**
  String get noteSugBlankScreen;

  /// No description provided for @noteSugLyricsReady.
  ///
  /// In pt, this message translates to:
  /// **'Letras prontas'**
  String get noteSugLyricsReady;

  /// No description provided for @noteSugAdvanceLyrics.
  ///
  /// In pt, this message translates to:
  /// **'Avançar letras'**
  String get noteSugAdvanceLyrics;

  /// No description provided for @noteSugRepeatChorusSlide.
  ///
  /// In pt, this message translates to:
  /// **'Repetir refrão no ecrã'**
  String get noteSugRepeatChorusSlide;

  /// No description provided for @noteSugLightsUp.
  ///
  /// In pt, this message translates to:
  /// **'Luzes mais altas'**
  String get noteSugLightsUp;

  /// No description provided for @noteSugLightsDown.
  ///
  /// In pt, this message translates to:
  /// **'Luzes mais baixas'**
  String get noteSugLightsDown;

  /// No description provided for @noteSugLightsAdjust.
  ///
  /// In pt, this message translates to:
  /// **'Ajustar luzes'**
  String get noteSugLightsAdjust;

  /// No description provided for @noteSugVideoPlay.
  ///
  /// In pt, this message translates to:
  /// **'Reproduzir vídeo'**
  String get noteSugVideoPlay;

  /// No description provided for @noteSugVideoIssue.
  ///
  /// In pt, this message translates to:
  /// **'Problema com o vídeo'**
  String get noteSugVideoIssue;

  /// No description provided for @noteSugStreamIssue.
  ///
  /// In pt, this message translates to:
  /// **'Problema com a transmissão'**
  String get noteSugStreamIssue;

  /// No description provided for @noteSugHouseVolumeDown.
  ///
  /// In pt, this message translates to:
  /// **'Baixar volume da sala'**
  String get noteSugHouseVolumeDown;

  /// No description provided for @noteSugHouseVolumeUp.
  ///
  /// In pt, this message translates to:
  /// **'Subir volume da sala'**
  String get noteSugHouseVolumeUp;

  /// No description provided for @noteSugVocalsUp.
  ///
  /// In pt, this message translates to:
  /// **'Subir vozes'**
  String get noteSugVocalsUp;

  /// No description provided for @noteSugBandDown.
  ///
  /// In pt, this message translates to:
  /// **'Baixar banda na mistura'**
  String get noteSugBandDown;

  /// No description provided for @noteSugVerse1.
  ///
  /// In pt, this message translates to:
  /// **'Estrofe 1'**
  String get noteSugVerse1;

  /// No description provided for @noteSugVerse2.
  ///
  /// In pt, this message translates to:
  /// **'Estrofe 2'**
  String get noteSugVerse2;

  /// No description provided for @noteSugVerse3.
  ///
  /// In pt, this message translates to:
  /// **'Estrofe 3'**
  String get noteSugVerse3;

  /// No description provided for @noteSugChorus.
  ///
  /// In pt, this message translates to:
  /// **'Refrão'**
  String get noteSugChorus;

  /// No description provided for @noteSugBridge.
  ///
  /// In pt, this message translates to:
  /// **'Ponte'**
  String get noteSugBridge;

  /// No description provided for @noteSugPreChorus.
  ///
  /// In pt, this message translates to:
  /// **'Pré-refrão'**
  String get noteSugPreChorus;

  /// No description provided for @noteSugTag.
  ///
  /// In pt, this message translates to:
  /// **'Tag'**
  String get noteSugTag;

  /// No description provided for @noteSugInstrumental.
  ///
  /// In pt, this message translates to:
  /// **'Instrumental'**
  String get noteSugInstrumental;

  /// No description provided for @noteSugRepeatSection.
  ///
  /// In pt, this message translates to:
  /// **'Repetir esta secção'**
  String get noteSugRepeatSection;

  /// No description provided for @noteSugEndSong.
  ///
  /// In pt, this message translates to:
  /// **'Terminar música'**
  String get noteSugEndSong;

  /// No description provided for @noteSugBuildUp.
  ///
  /// In pt, this message translates to:
  /// **'Subir a intensidade'**
  String get noteSugBuildUp;

  /// No description provided for @noteSugBringDown.
  ///
  /// In pt, this message translates to:
  /// **'Baixar a intensidade'**
  String get noteSugBringDown;

  /// No description provided for @noteSugDrumsVocals.
  ///
  /// In pt, this message translates to:
  /// **'Só bateria + vozes'**
  String get noteSugDrumsVocals;

  /// No description provided for @noteSugSoftPads.
  ///
  /// In pt, this message translates to:
  /// **'Só pads suaves'**
  String get noteSugSoftPads;

  /// No description provided for @noteSugCutVocals.
  ///
  /// In pt, this message translates to:
  /// **'Cortar vozes'**
  String get noteSugCutVocals;

  /// No description provided for @noteSugBandTakeIt.
  ///
  /// In pt, this message translates to:
  /// **'Banda assume'**
  String get noteSugBandTakeIt;

  /// No description provided for @noteSugSpontaneousStay.
  ///
  /// In pt, this message translates to:
  /// **'Ficar aqui — espontâneo'**
  String get noteSugSpontaneousStay;

  /// No description provided for @noteSugTempoUp.
  ///
  /// In pt, this message translates to:
  /// **'Acelerar o tempo'**
  String get noteSugTempoUp;

  /// No description provided for @noteSugTempoDown.
  ///
  /// In pt, this message translates to:
  /// **'Abrir o tempo'**
  String get noteSugTempoDown;

  /// No description provided for @noteSugKeyChange.
  ///
  /// In pt, this message translates to:
  /// **'Mudança de tom a chegar'**
  String get noteSugKeyChange;

  /// No description provided for @noteSugMoreMonitor.
  ///
  /// In pt, this message translates to:
  /// **'Mais de mim nos monitores'**
  String get noteSugMoreMonitor;

  /// No description provided for @noteSugLessMonitor.
  ///
  /// In pt, this message translates to:
  /// **'Menos de mim nos monitores'**
  String get noteSugLessMonitor;

  /// No description provided for @noteSugClickLouder.
  ///
  /// In pt, this message translates to:
  /// **'Click / guia mais alto'**
  String get noteSugClickLouder;

  /// No description provided for @noteSugLostClick.
  ///
  /// In pt, this message translates to:
  /// **'Perdi o click'**
  String get noteSugLostClick;

  /// No description provided for @noteSugWrongChart.
  ///
  /// In pt, this message translates to:
  /// **'Cifra / arranjo errado'**
  String get noteSugWrongChart;

  /// No description provided for @noteSugReadyNextSong.
  ///
  /// In pt, this message translates to:
  /// **'Prontos para a próxima música'**
  String get noteSugReadyNextSong;

  /// No description provided for @noteSugStartSong.
  ///
  /// In pt, this message translates to:
  /// **'Começar a música'**
  String get noteSugStartSong;

  /// No description provided for @noteSugStartWelcome.
  ///
  /// In pt, this message translates to:
  /// **'Começar boas-vindas'**
  String get noteSugStartWelcome;

  /// No description provided for @noteSugWrapWelcome.
  ///
  /// In pt, this message translates to:
  /// **'Encerrar boas-vindas'**
  String get noteSugWrapWelcome;

  /// No description provided for @noteSugOpenDoors.
  ///
  /// In pt, this message translates to:
  /// **'Abrir portas'**
  String get noteSugOpenDoors;

  /// No description provided for @noteSugHospitalityReady.
  ///
  /// In pt, this message translates to:
  /// **'Equipa de hospitalidade pronta'**
  String get noteSugHospitalityReady;

  /// No description provided for @noteSugReaderReady.
  ///
  /// In pt, this message translates to:
  /// **'Leitor pronto'**
  String get noteSugReaderReady;

  /// No description provided for @noteSugPassageOnScreen.
  ///
  /// In pt, this message translates to:
  /// **'Passagem no ecrã'**
  String get noteSugPassageOnScreen;

  /// No description provided for @noteSugAdvanceVerse.
  ///
  /// In pt, this message translates to:
  /// **'Avançar versículo'**
  String get noteSugAdvanceVerse;

  /// No description provided for @noteSugSoftUnderscore.
  ///
  /// In pt, this message translates to:
  /// **'Fundo musical suave'**
  String get noteSugSoftUnderscore;

  /// No description provided for @noteSugAfterReading.
  ///
  /// In pt, this message translates to:
  /// **'Após a leitura — próximo'**
  String get noteSugAfterReading;

  /// No description provided for @noteSugPastorWalkingUp.
  ///
  /// In pt, this message translates to:
  /// **'Pastor a subir'**
  String get noteSugPastorWalkingUp;

  /// No description provided for @noteSugPastorMicLive.
  ///
  /// In pt, this message translates to:
  /// **'Microfone do pastor ao vivo'**
  String get noteSugPastorMicLive;

  /// No description provided for @noteSugSermonSlidesReady.
  ///
  /// In pt, this message translates to:
  /// **'Slides da mensagem prontos'**
  String get noteSugSermonSlidesReady;

  /// No description provided for @noteSugNextSermonSlide.
  ///
  /// In pt, this message translates to:
  /// **'Próximo slide da mensagem'**
  String get noteSugNextSermonSlide;

  /// No description provided for @noteSugTimerCheck.
  ///
  /// In pt, this message translates to:
  /// **'Verificar tempo'**
  String get noteSugTimerCheck;

  /// No description provided for @noteSugAltarCallComing.
  ///
  /// In pt, this message translates to:
  /// **'Apelo a chegar'**
  String get noteSugAltarCallComing;

  /// No description provided for @noteSugClosingPrayer.
  ///
  /// In pt, this message translates to:
  /// **'Oração final'**
  String get noteSugClosingPrayer;

  /// No description provided for @noteSugSoftMusicUnder.
  ///
  /// In pt, this message translates to:
  /// **'Música suave por baixo'**
  String get noteSugSoftMusicUnder;

  /// No description provided for @noteSugMessageLights.
  ///
  /// In pt, this message translates to:
  /// **'Iluminação da mensagem'**
  String get noteSugMessageLights;

  /// No description provided for @noteSugAnnouncementsStart.
  ///
  /// In pt, this message translates to:
  /// **'Anúncios a começar'**
  String get noteSugAnnouncementsStart;

  /// No description provided for @noteSugNextAnnouncement.
  ///
  /// In pt, this message translates to:
  /// **'Próximo anúncio'**
  String get noteSugNextAnnouncement;

  /// No description provided for @noteSugWrapAnnouncements.
  ///
  /// In pt, this message translates to:
  /// **'Encerrar anúncios'**
  String get noteSugWrapAnnouncements;

  /// No description provided for @noteSugGivingMoment.
  ///
  /// In pt, this message translates to:
  /// **'Oferta / dádivas'**
  String get noteSugGivingMoment;

  /// No description provided for @noteSugConnectionReminder.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete de ligação'**
  String get noteSugConnectionReminder;

  /// No description provided for @servicesElementEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nada preparado para este momento'**
  String get servicesElementEmpty;

  /// No description provided for @servicesElementEmptyDesc.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há passagem, conteúdo ou notas neste item.'**
  String get servicesElementEmptyDesc;

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

  /// No description provided for @settingsTabService.
  ///
  /// In pt, this message translates to:
  /// **'Culto'**
  String get settingsTabService;

  /// No description provided for @settingsTabAppearance.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get settingsTabAppearance;

  /// No description provided for @settingsSubscriptionInactive.
  ///
  /// In pt, this message translates to:
  /// **'Sem subscrição ativa'**
  String get settingsSubscriptionInactive;

  /// No description provided for @settingsSubscriptionInactiveDesc.
  ///
  /// In pt, this message translates to:
  /// **'Esta organização está só de leitura até haver uma subscrição ou período de avaliação ativo. Ainda pode consultar o conteúdo sincronizado.'**
  String get settingsSubscriptionInactiveDesc;

  /// No description provided for @settingsOrgSwitching.
  ///
  /// In pt, this message translates to:
  /// **'A mudar de organização…'**
  String get settingsOrgSwitching;

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
  /// **'Modo músico'**
  String get settingsMusicianMode;

  /// No description provided for @settingsMusicianModeDesc.
  ///
  /// In pt, this message translates to:
  /// **'Abre os cultos no primeiro cântico com acordes e anotações. Desative para a vista de ordem do culto com letras e tempos.'**
  String get settingsMusicianModeDesc;

  /// No description provided for @settingsServiceOrderSidePanel.
  ///
  /// In pt, this message translates to:
  /// **'Painel lateral da ordem do culto'**
  String get settingsServiceOrderSidePanel;

  /// No description provided for @settingsServiceOrderSidePanelDesc.
  ///
  /// In pt, this message translates to:
  /// **'Em tablets, mantém a ordem do culto visível ao lado do item atual nos modos músico e não músico.'**
  String get settingsServiceOrderSidePanelDesc;

  /// No description provided for @servicesCollapseOrderPanel.
  ///
  /// In pt, this message translates to:
  /// **'Recolher painel da ordem'**
  String get servicesCollapseOrderPanel;

  /// No description provided for @servicesExpandOrderPanel.
  ///
  /// In pt, this message translates to:
  /// **'Expandir painel da ordem'**
  String get servicesExpandOrderPanel;

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

  /// No description provided for @settingsPedalEnabled.
  ///
  /// In pt, this message translates to:
  /// **'Pedais page-turner'**
  String get settingsPedalEnabled;

  /// No description provided for @settingsPedalEnabledDesc.
  ///
  /// In pt, this message translates to:
  /// **'Usa um pedal Bluetooth emparelhado nas definições do sistema. A maioria dos pedais aparece como teclado.'**
  String get settingsPedalEnabledDesc;

  /// No description provided for @settingsPedalActionMode.
  ///
  /// In pt, this message translates to:
  /// **'Ação do pedal'**
  String get settingsPedalActionMode;

  /// No description provided for @settingsPedalActionNavigate.
  ///
  /// In pt, this message translates to:
  /// **'Cântico seguinte / anterior'**
  String get settingsPedalActionNavigate;

  /// No description provided for @settingsPedalActionScroll.
  ///
  /// In pt, this message translates to:
  /// **'Deslizar página'**
  String get settingsPedalActionScroll;

  /// No description provided for @settingsPedalPreset.
  ///
  /// In pt, this message translates to:
  /// **'Disposição do pedal'**
  String get settingsPedalPreset;

  /// No description provided for @settingsPedalPresetUniversal.
  ///
  /// In pt, this message translates to:
  /// **'Universal'**
  String get settingsPedalPresetUniversal;

  /// No description provided for @settingsPedalPresetAirTurn.
  ///
  /// In pt, this message translates to:
  /// **'AirTurn'**
  String get settingsPedalPresetAirTurn;

  /// No description provided for @settingsPedalPresetBlueTurn.
  ///
  /// In pt, this message translates to:
  /// **'iRig BlueTurn'**
  String get settingsPedalPresetBlueTurn;

  /// No description provided for @settingsPedalPresetDonner.
  ///
  /// In pt, this message translates to:
  /// **'Donner / genérico'**
  String get settingsPedalPresetDonner;

  /// No description provided for @settingsPedalPresetCustom.
  ///
  /// In pt, this message translates to:
  /// **'Personalizado'**
  String get settingsPedalPresetCustom;

  /// No description provided for @settingsPedalCustomNext.
  ///
  /// In pt, this message translates to:
  /// **'Tecla seguinte'**
  String get settingsPedalCustomNext;

  /// No description provided for @settingsPedalCustomPrev.
  ///
  /// In pt, this message translates to:
  /// **'Tecla anterior'**
  String get settingsPedalCustomPrev;

  /// No description provided for @settingsPedalCustomUnset.
  ///
  /// In pt, this message translates to:
  /// **'Não definida'**
  String get settingsPedalCustomUnset;

  /// No description provided for @settingsPedalCustomCaptureTitle.
  ///
  /// In pt, this message translates to:
  /// **'Prima uma tecla do pedal'**
  String get settingsPedalCustomCaptureTitle;

  /// No description provided for @settingsPedalCustomCaptureMessage.
  ///
  /// In pt, this message translates to:
  /// **'Prima o botão do pedal que pretende atribuir. Emparelhe o pedal primeiro nas definições Bluetooth do sistema.'**
  String get settingsPedalCustomCaptureMessage;

  /// No description provided for @settingsPedalCustomCaptureCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get settingsPedalCustomCaptureCancel;

  /// No description provided for @settingsNotifications.
  ///
  /// In pt, this message translates to:
  /// **'Permitir notificações neste dispositivo'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsDesc.
  ///
  /// In pt, this message translates to:
  /// **'Permite que o servidor envie notificações para esta sessão. É independente da permissão de notificações do sistema.'**
  String get settingsNotificationsDesc;

  /// No description provided for @notificationConsentTitle.
  ///
  /// In pt, this message translates to:
  /// **'Permitir notificações neste dispositivo?'**
  String get notificationConsentTitle;

  /// No description provided for @notificationConsentMessage.
  ///
  /// In pt, this message translates to:
  /// **'Se permitir, o servidor poderá enviar-lhe avisos de cultos e novidades da biblioteca neste dispositivo. Pode alterar isto nas Definições.'**
  String get notificationConsentMessage;

  /// No description provided for @notificationConsentAllow.
  ///
  /// In pt, this message translates to:
  /// **'Permitir'**
  String get notificationConsentAllow;

  /// No description provided for @notificationConsentNotNow.
  ///
  /// In pt, this message translates to:
  /// **'Agora não'**
  String get notificationConsentNotNow;

  /// No description provided for @notificationOpenAction.
  ///
  /// In pt, this message translates to:
  /// **'Abrir'**
  String get notificationOpenAction;

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

  /// No description provided for @metronomePlay.
  ///
  /// In pt, this message translates to:
  /// **'Reproduzir'**
  String get metronomePlay;

  /// No description provided for @metronomePause.
  ///
  /// In pt, this message translates to:
  /// **'Pausar'**
  String get metronomePause;

  /// No description provided for @metronomeAudioUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'O som do metrónomo não está disponível neste dispositivo.'**
  String get metronomeAudioUnavailable;

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

  /// No description provided for @annotationRemoteChanges.
  ///
  /// In pt, this message translates to:
  /// **'Novas alterações de outro dispositivo'**
  String get annotationRemoteChanges;

  /// No description provided for @annotationKeepMine.
  ///
  /// In pt, this message translates to:
  /// **'Manter as minhas'**
  String get annotationKeepMine;

  /// No description provided for @annotationReload.
  ///
  /// In pt, this message translates to:
  /// **'Recarregar'**
  String get annotationReload;

  /// No description provided for @songVariant.
  ///
  /// In pt, this message translates to:
  /// **'Versão'**
  String get songVariant;

  /// No description provided for @songVariantTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Versão: {name}'**
  String songVariantTooltip(String name);

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In pt, this message translates to:
  /// **'Sistema'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsFontPreview.
  ///
  /// In pt, this message translates to:
  /// **'Exemplo'**
  String get settingsFontPreview;
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
