import '../../../l10n/generated/app_localizations.dart';

/// Where a note is being composed relative to the service.
enum NoteSuggestionScope {
  /// Service-wide notes (order / notes tab).
  service,

  /// Notes tied to a specific element.
  element,
}

/// Inputs used to rank quick-send note suggestions.
class NoteSuggestionContext {
  const NoteSuggestionContext({
    required this.musicianMode,
    this.elementType,
    this.scope = NoteSuggestionScope.service,
  });

  final bool musicianMode;

  /// Element type currently in focus (`song`, `welcome`, …), even when the
  /// note itself is service-scoped (ambient “what’s happening now”).
  final String? elementType;

  final NoteSuggestionScope scope;

  bool get hasElementFocus =>
      elementType != null && elementType!.trim().isNotEmpty;
}

/// Stable suggestion ids. Labels are resolved via [labelForNoteSuggestion].
abstract final class NoteSuggestionIds {
  // —— Universal service flow ——
  static const readyToStart = 'readyToStart';
  static const standbyNext = 'standbyNext';
  static const goNextItem = 'goNextItem';
  static const holdWait = 'holdWait';
  static const wrapUp = 'wrapUp';
  static const behindSchedule = 'behindSchedule';
  static const aheadSchedule = 'aheadSchedule';
  static const skipItem = 'skipItem';
  static const extendMoment = 'extendMoment';
  static const changeOfPlan = 'changeOfPlan';
  static const lookingGood = 'lookingGood';
  static const needHelp = 'needHelp';
  static const quietMoment = 'quietMoment';
  static const prayTogether = 'prayTogether';
  static const doorsClosing = 'doorsClosing';
  static const guestsReady = 'guestsReady';

  // —— Production / tech (non-musician heavy) ——
  static const micLive = 'micLive';
  static const micMute = 'micMute';
  static const micCheck = 'micCheck';
  static const feedbackMute = 'feedbackMute';
  static const spareMic = 'spareMic';
  static const slidesReady = 'slidesReady';
  static const nextSlide = 'nextSlide';
  static const wrongSlide = 'wrongSlide';
  static const blankScreen = 'blankScreen';
  static const lyricsReady = 'lyricsReady';
  static const advanceLyrics = 'advanceLyrics';
  static const repeatChorusSlide = 'repeatChorusSlide';
  static const lightsUp = 'lightsUp';
  static const lightsDown = 'lightsDown';
  static const lightsAdjust = 'lightsAdjust';
  static const videoPlay = 'videoPlay';
  static const videoIssue = 'videoIssue';
  static const streamIssue = 'streamIssue';
  static const houseVolumeDown = 'houseVolumeDown';
  static const houseVolumeUp = 'houseVolumeUp';
  static const vocalsUp = 'vocalsUp';
  static const bandDown = 'bandDown';

  // —— Musician / band ——
  static const verse1 = 'verse1';
  static const verse2 = 'verse2';
  static const verse3 = 'verse3';
  static const chorus = 'chorus';
  static const bridge = 'bridge';
  static const preChorus = 'preChorus';
  static const tag = 'tag';
  static const instrumental = 'instrumental';
  static const repeatSection = 'repeatSection';
  static const endSong = 'endSong';
  static const buildUp = 'buildUp';
  static const bringDown = 'bringDown';
  static const drumsVocals = 'drumsVocals';
  static const softPads = 'softPads';
  static const cutVocals = 'cutVocals';
  static const bandTakeIt = 'bandTakeIt';
  static const spontaneousStay = 'spontaneousStay';
  static const tempoUp = 'tempoUp';
  static const tempoDown = 'tempoDown';
  static const keyChange = 'keyChange';
  static const moreMonitor = 'moreMonitor';
  static const lessMonitor = 'lessMonitor';
  static const clickLouder = 'clickLouder';
  static const lostClick = 'lostClick';
  static const wrongChart = 'wrongChart';
  static const readyNextSong = 'readyNextSong';
  static const startSong = 'startSong';

  // —— Welcome ——
  static const startWelcome = 'startWelcome';
  static const wrapWelcome = 'wrapWelcome';
  static const openDoors = 'openDoors';
  static const hospitalityReady = 'hospitalityReady';

  // —— Scripture ——
  static const readerReady = 'readerReady';
  static const passageOnScreen = 'passageOnScreen';
  static const advanceVerse = 'advanceVerse';
  static const softUnderscore = 'softUnderscore';
  static const afterReading = 'afterReading';

  // —— Message ——
  static const pastorWalkingUp = 'pastorWalkingUp';
  static const pastorMicLive = 'pastorMicLive';
  static const sermonSlidesReady = 'sermonSlidesReady';
  static const nextSermonSlide = 'nextSermonSlide';
  static const timerCheck = 'timerCheck';
  static const altarCallComing = 'altarCallComing';
  static const closingPrayer = 'closingPrayer';
  static const softMusicUnder = 'softMusicUnder';
  static const messageLights = 'messageLights';

  // —— Announcement ——
  static const announcementsStart = 'announcementsStart';
  static const nextAnnouncement = 'nextAnnouncement';
  static const wrapAnnouncements = 'wrapAnnouncements';
  static const givingMoment = 'givingMoment';
  static const connectionReminder = 'connectionReminder';
}

/// Ranked suggestion ids for [context] (deduped, capped for the chip row).
List<String> selectNoteSuggestionIds(
  NoteSuggestionContext context, {
  int limit = 18,
}) {
  final ranked = <String>[];

  void addAll(Iterable<String> ids) {
    for (final id in ids) {
      if (!ranked.contains(id)) ranked.add(id);
    }
  }

  final type = context.elementType?.trim().toLowerCase();
  final musician = context.musicianMode;

  // Element-type buckets first (most contextual).
  switch (type) {
    case 'song':
      if (musician) {
        addAll(const [
          NoteSuggestionIds.startSong,
          NoteSuggestionIds.verse1,
          NoteSuggestionIds.chorus,
          NoteSuggestionIds.bridge,
          NoteSuggestionIds.repeatSection,
          NoteSuggestionIds.buildUp,
          NoteSuggestionIds.bringDown,
          NoteSuggestionIds.instrumental,
          NoteSuggestionIds.drumsVocals,
          NoteSuggestionIds.tag,
          NoteSuggestionIds.endSong,
          NoteSuggestionIds.spontaneousStay,
          NoteSuggestionIds.tempoUp,
          NoteSuggestionIds.tempoDown,
          NoteSuggestionIds.moreMonitor,
          NoteSuggestionIds.lessMonitor,
          NoteSuggestionIds.clickLouder,
          NoteSuggestionIds.lostClick,
          NoteSuggestionIds.keyChange,
          NoteSuggestionIds.wrongChart,
          NoteSuggestionIds.softPads,
          NoteSuggestionIds.cutVocals,
          NoteSuggestionIds.bandTakeIt,
          NoteSuggestionIds.readyNextSong,
          NoteSuggestionIds.preChorus,
          NoteSuggestionIds.verse2,
          NoteSuggestionIds.verse3,
        ]);
      } else {
        addAll(const [
          NoteSuggestionIds.lyricsReady,
          NoteSuggestionIds.advanceLyrics,
          NoteSuggestionIds.repeatChorusSlide,
          NoteSuggestionIds.standbyNext,
          NoteSuggestionIds.endSong,
          NoteSuggestionIds.blankScreen,
          NoteSuggestionIds.wrongSlide,
          NoteSuggestionIds.vocalsUp,
          NoteSuggestionIds.bandDown,
          NoteSuggestionIds.houseVolumeDown,
          NoteSuggestionIds.micMute,
          NoteSuggestionIds.feedbackMute,
          NoteSuggestionIds.lightsAdjust,
          NoteSuggestionIds.buildUp,
          NoteSuggestionIds.bringDown,
          NoteSuggestionIds.readyNextSong,
          NoteSuggestionIds.goNextItem,
        ]);
      }
    case 'welcome':
      addAll(const [
        NoteSuggestionIds.startWelcome,
        NoteSuggestionIds.openDoors,
        NoteSuggestionIds.guestsReady,
        NoteSuggestionIds.hospitalityReady,
        NoteSuggestionIds.micLive,
        NoteSuggestionIds.slidesReady,
        NoteSuggestionIds.wrapWelcome,
        NoteSuggestionIds.doorsClosing,
        NoteSuggestionIds.goNextItem,
        NoteSuggestionIds.standbyNext,
      ]);
    case 'scripture':
      addAll(const [
        NoteSuggestionIds.readerReady,
        NoteSuggestionIds.passageOnScreen,
        NoteSuggestionIds.micLive,
        NoteSuggestionIds.advanceVerse,
        NoteSuggestionIds.softUnderscore,
        NoteSuggestionIds.afterReading,
        NoteSuggestionIds.blankScreen,
        NoteSuggestionIds.standbyNext,
        NoteSuggestionIds.goNextItem,
      ]);
    case 'message':
      addAll(const [
        NoteSuggestionIds.pastorWalkingUp,
        NoteSuggestionIds.pastorMicLive,
        NoteSuggestionIds.sermonSlidesReady,
        NoteSuggestionIds.nextSermonSlide,
        NoteSuggestionIds.messageLights,
        NoteSuggestionIds.softMusicUnder,
        NoteSuggestionIds.timerCheck,
        NoteSuggestionIds.altarCallComing,
        NoteSuggestionIds.closingPrayer,
        NoteSuggestionIds.micMute,
        NoteSuggestionIds.feedbackMute,
        NoteSuggestionIds.houseVolumeDown,
        NoteSuggestionIds.streamIssue,
        NoteSuggestionIds.wrapUp,
        NoteSuggestionIds.extendMoment,
      ]);
    case 'announcement':
      addAll(const [
        NoteSuggestionIds.announcementsStart,
        NoteSuggestionIds.nextAnnouncement,
        NoteSuggestionIds.slidesReady,
        NoteSuggestionIds.micLive,
        NoteSuggestionIds.givingMoment,
        NoteSuggestionIds.connectionReminder,
        NoteSuggestionIds.wrapAnnouncements,
        NoteSuggestionIds.goNextItem,
        NoteSuggestionIds.standbyNext,
      ]);
  }

  // Mode-specific general cues.
  if (musician) {
    addAll(const [
      NoteSuggestionIds.readyNextSong,
      NoteSuggestionIds.moreMonitor,
      NoteSuggestionIds.lessMonitor,
      NoteSuggestionIds.clickLouder,
      NoteSuggestionIds.lostClick,
      NoteSuggestionIds.buildUp,
      NoteSuggestionIds.bringDown,
      NoteSuggestionIds.spontaneousStay,
      NoteSuggestionIds.endSong,
      NoteSuggestionIds.wrongChart,
      NoteSuggestionIds.keyChange,
    ]);
  } else {
    addAll(const [
      NoteSuggestionIds.slidesReady,
      NoteSuggestionIds.nextSlide,
      NoteSuggestionIds.wrongSlide,
      NoteSuggestionIds.blankScreen,
      NoteSuggestionIds.lyricsReady,
      NoteSuggestionIds.advanceLyrics,
      NoteSuggestionIds.micLive,
      NoteSuggestionIds.micMute,
      NoteSuggestionIds.micCheck,
      NoteSuggestionIds.feedbackMute,
      NoteSuggestionIds.spareMic,
      NoteSuggestionIds.lightsUp,
      NoteSuggestionIds.lightsDown,
      NoteSuggestionIds.lightsAdjust,
      NoteSuggestionIds.videoPlay,
      NoteSuggestionIds.videoIssue,
      NoteSuggestionIds.streamIssue,
      NoteSuggestionIds.houseVolumeDown,
      NoteSuggestionIds.houseVolumeUp,
      NoteSuggestionIds.vocalsUp,
      NoteSuggestionIds.bandDown,
    ]);
  }

  // Universal flow — always available, lower priority.
  addAll(const [
    NoteSuggestionIds.readyToStart,
    NoteSuggestionIds.standbyNext,
    NoteSuggestionIds.goNextItem,
    NoteSuggestionIds.holdWait,
    NoteSuggestionIds.wrapUp,
    NoteSuggestionIds.behindSchedule,
    NoteSuggestionIds.aheadSchedule,
    NoteSuggestionIds.skipItem,
    NoteSuggestionIds.extendMoment,
    NoteSuggestionIds.changeOfPlan,
    NoteSuggestionIds.lookingGood,
    NoteSuggestionIds.needHelp,
    NoteSuggestionIds.quietMoment,
    NoteSuggestionIds.prayTogether,
    NoteSuggestionIds.doorsClosing,
    NoteSuggestionIds.guestsReady,
  ]);

  if (ranked.length <= limit) return ranked;
  return ranked.sublist(0, limit);
}

/// Localized label for a suggestion id, or null if unknown.
String? labelForNoteSuggestion(AppLocalizations l10n, String id) {
  return switch (id) {
    NoteSuggestionIds.readyToStart => l10n.noteSugReadyToStart,
    NoteSuggestionIds.standbyNext => l10n.noteSugStandbyNext,
    NoteSuggestionIds.goNextItem => l10n.noteSugGoNextItem,
    NoteSuggestionIds.holdWait => l10n.noteSugHoldWait,
    NoteSuggestionIds.wrapUp => l10n.noteSugWrapUp,
    NoteSuggestionIds.behindSchedule => l10n.noteSugBehindSchedule,
    NoteSuggestionIds.aheadSchedule => l10n.noteSugAheadSchedule,
    NoteSuggestionIds.skipItem => l10n.noteSugSkipItem,
    NoteSuggestionIds.extendMoment => l10n.noteSugExtendMoment,
    NoteSuggestionIds.changeOfPlan => l10n.noteSugChangeOfPlan,
    NoteSuggestionIds.lookingGood => l10n.noteSugLookingGood,
    NoteSuggestionIds.needHelp => l10n.noteSugNeedHelp,
    NoteSuggestionIds.quietMoment => l10n.noteSugQuietMoment,
    NoteSuggestionIds.prayTogether => l10n.noteSugPrayTogether,
    NoteSuggestionIds.doorsClosing => l10n.noteSugDoorsClosing,
    NoteSuggestionIds.guestsReady => l10n.noteSugGuestsReady,
    NoteSuggestionIds.micLive => l10n.noteSugMicLive,
    NoteSuggestionIds.micMute => l10n.noteSugMicMute,
    NoteSuggestionIds.micCheck => l10n.noteSugMicCheck,
    NoteSuggestionIds.feedbackMute => l10n.noteSugFeedbackMute,
    NoteSuggestionIds.spareMic => l10n.noteSugSpareMic,
    NoteSuggestionIds.slidesReady => l10n.noteSugSlidesReady,
    NoteSuggestionIds.nextSlide => l10n.noteSugNextSlide,
    NoteSuggestionIds.wrongSlide => l10n.noteSugWrongSlide,
    NoteSuggestionIds.blankScreen => l10n.noteSugBlankScreen,
    NoteSuggestionIds.lyricsReady => l10n.noteSugLyricsReady,
    NoteSuggestionIds.advanceLyrics => l10n.noteSugAdvanceLyrics,
    NoteSuggestionIds.repeatChorusSlide => l10n.noteSugRepeatChorusSlide,
    NoteSuggestionIds.lightsUp => l10n.noteSugLightsUp,
    NoteSuggestionIds.lightsDown => l10n.noteSugLightsDown,
    NoteSuggestionIds.lightsAdjust => l10n.noteSugLightsAdjust,
    NoteSuggestionIds.videoPlay => l10n.noteSugVideoPlay,
    NoteSuggestionIds.videoIssue => l10n.noteSugVideoIssue,
    NoteSuggestionIds.streamIssue => l10n.noteSugStreamIssue,
    NoteSuggestionIds.houseVolumeDown => l10n.noteSugHouseVolumeDown,
    NoteSuggestionIds.houseVolumeUp => l10n.noteSugHouseVolumeUp,
    NoteSuggestionIds.vocalsUp => l10n.noteSugVocalsUp,
    NoteSuggestionIds.bandDown => l10n.noteSugBandDown,
    NoteSuggestionIds.verse1 => l10n.noteSugVerse1,
    NoteSuggestionIds.verse2 => l10n.noteSugVerse2,
    NoteSuggestionIds.verse3 => l10n.noteSugVerse3,
    NoteSuggestionIds.chorus => l10n.noteSugChorus,
    NoteSuggestionIds.bridge => l10n.noteSugBridge,
    NoteSuggestionIds.preChorus => l10n.noteSugPreChorus,
    NoteSuggestionIds.tag => l10n.noteSugTag,
    NoteSuggestionIds.instrumental => l10n.noteSugInstrumental,
    NoteSuggestionIds.repeatSection => l10n.noteSugRepeatSection,
    NoteSuggestionIds.endSong => l10n.noteSugEndSong,
    NoteSuggestionIds.buildUp => l10n.noteSugBuildUp,
    NoteSuggestionIds.bringDown => l10n.noteSugBringDown,
    NoteSuggestionIds.drumsVocals => l10n.noteSugDrumsVocals,
    NoteSuggestionIds.softPads => l10n.noteSugSoftPads,
    NoteSuggestionIds.cutVocals => l10n.noteSugCutVocals,
    NoteSuggestionIds.bandTakeIt => l10n.noteSugBandTakeIt,
    NoteSuggestionIds.spontaneousStay => l10n.noteSugSpontaneousStay,
    NoteSuggestionIds.tempoUp => l10n.noteSugTempoUp,
    NoteSuggestionIds.tempoDown => l10n.noteSugTempoDown,
    NoteSuggestionIds.keyChange => l10n.noteSugKeyChange,
    NoteSuggestionIds.moreMonitor => l10n.noteSugMoreMonitor,
    NoteSuggestionIds.lessMonitor => l10n.noteSugLessMonitor,
    NoteSuggestionIds.clickLouder => l10n.noteSugClickLouder,
    NoteSuggestionIds.lostClick => l10n.noteSugLostClick,
    NoteSuggestionIds.wrongChart => l10n.noteSugWrongChart,
    NoteSuggestionIds.readyNextSong => l10n.noteSugReadyNextSong,
    NoteSuggestionIds.startSong => l10n.noteSugStartSong,
    NoteSuggestionIds.startWelcome => l10n.noteSugStartWelcome,
    NoteSuggestionIds.wrapWelcome => l10n.noteSugWrapWelcome,
    NoteSuggestionIds.openDoors => l10n.noteSugOpenDoors,
    NoteSuggestionIds.hospitalityReady => l10n.noteSugHospitalityReady,
    NoteSuggestionIds.readerReady => l10n.noteSugReaderReady,
    NoteSuggestionIds.passageOnScreen => l10n.noteSugPassageOnScreen,
    NoteSuggestionIds.advanceVerse => l10n.noteSugAdvanceVerse,
    NoteSuggestionIds.softUnderscore => l10n.noteSugSoftUnderscore,
    NoteSuggestionIds.afterReading => l10n.noteSugAfterReading,
    NoteSuggestionIds.pastorWalkingUp => l10n.noteSugPastorWalkingUp,
    NoteSuggestionIds.pastorMicLive => l10n.noteSugPastorMicLive,
    NoteSuggestionIds.sermonSlidesReady => l10n.noteSugSermonSlidesReady,
    NoteSuggestionIds.nextSermonSlide => l10n.noteSugNextSermonSlide,
    NoteSuggestionIds.timerCheck => l10n.noteSugTimerCheck,
    NoteSuggestionIds.altarCallComing => l10n.noteSugAltarCallComing,
    NoteSuggestionIds.closingPrayer => l10n.noteSugClosingPrayer,
    NoteSuggestionIds.softMusicUnder => l10n.noteSugSoftMusicUnder,
    NoteSuggestionIds.messageLights => l10n.noteSugMessageLights,
    NoteSuggestionIds.announcementsStart => l10n.noteSugAnnouncementsStart,
    NoteSuggestionIds.nextAnnouncement => l10n.noteSugNextAnnouncement,
    NoteSuggestionIds.wrapAnnouncements => l10n.noteSugWrapAnnouncements,
    NoteSuggestionIds.givingMoment => l10n.noteSugGivingMoment,
    NoteSuggestionIds.connectionReminder => l10n.noteSugConnectionReminder,
    _ => null,
  };
}
