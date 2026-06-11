enum MessagePermission { everyone, officersOnly, nobody }

class PrivacySettings {
  final MessagePermission whoCanMessage;
  final bool showRealName;
  final bool showPhoneNumber;
  final bool showFarmLocation;
  final bool showFarmSize;
  final bool useAnonymousInForum;
  final bool allowForumQuotes;
  final bool shareDiseaseData;
  final bool allowResearchUse;
  final bool receiveMarketing;
  final bool receiveOfficerBroadcasts;
  final bool receiveDisasterAlerts; // always true — cannot be disabled
  final bool showOnlineStatus;
  final bool showLastSeen;
  final bool sendReadReceipts;

  const PrivacySettings({
    this.whoCanMessage = MessagePermission.everyone,
    this.showRealName = true,
    this.showPhoneNumber = false,
    this.showFarmLocation = true,
    this.showFarmSize = true,
    this.useAnonymousInForum = false,
    this.allowForumQuotes = true,
    this.shareDiseaseData = true,
    this.allowResearchUse = true,
    this.receiveMarketing = false,
    this.receiveOfficerBroadcasts = true,
    this.receiveDisasterAlerts = true,
    this.showOnlineStatus = true,
    this.showLastSeen = true,
    this.sendReadReceipts = true,
  });

  PrivacySettings copyWith({
    MessagePermission? whoCanMessage,
    bool? showRealName,
    bool? showPhoneNumber,
    bool? showFarmLocation,
    bool? showFarmSize,
    bool? useAnonymousInForum,
    bool? allowForumQuotes,
    bool? shareDiseaseData,
    bool? allowResearchUse,
    bool? receiveMarketing,
    bool? receiveOfficerBroadcasts,
    bool? showOnlineStatus,
    bool? showLastSeen,
    bool? sendReadReceipts,
  }) =>
      PrivacySettings(
        whoCanMessage: whoCanMessage ?? this.whoCanMessage,
        showRealName: showRealName ?? this.showRealName,
        showPhoneNumber: showPhoneNumber ?? this.showPhoneNumber,
        showFarmLocation: showFarmLocation ?? this.showFarmLocation,
        showFarmSize: showFarmSize ?? this.showFarmSize,
        useAnonymousInForum: useAnonymousInForum ?? this.useAnonymousInForum,
        allowForumQuotes: allowForumQuotes ?? this.allowForumQuotes,
        shareDiseaseData: shareDiseaseData ?? this.shareDiseaseData,
        allowResearchUse: allowResearchUse ?? this.allowResearchUse,
        receiveMarketing: receiveMarketing ?? this.receiveMarketing,
        receiveOfficerBroadcasts:
            receiveOfficerBroadcasts ?? this.receiveOfficerBroadcasts,
        receiveDisasterAlerts: true, // always locked on
        showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
        showLastSeen: showLastSeen ?? this.showLastSeen,
        sendReadReceipts: sendReadReceipts ?? this.sendReadReceipts,
      );

  factory PrivacySettings.fromMap(Map<String, dynamic> map) => PrivacySettings(
        whoCanMessage: _parsePermission(map['who_can_message'] as String?),
        showRealName: map['show_real_name'] as bool? ?? true,
        showPhoneNumber: map['show_phone_number'] as bool? ?? false,
        showFarmLocation: map['show_farm_location'] as bool? ?? true,
        showFarmSize: map['show_farm_size'] as bool? ?? true,
        useAnonymousInForum: map['use_anonymous_in_forum'] as bool? ?? false,
        allowForumQuotes: map['allow_forum_quotes'] as bool? ?? true,
        shareDiseaseData: map['share_disease_data'] as bool? ?? true,
        allowResearchUse: map['allow_research_use'] as bool? ?? true,
        receiveMarketing: map['receive_marketing'] as bool? ?? false,
        receiveOfficerBroadcasts:
            map['receive_officer_broadcasts'] as bool? ?? true,
        receiveDisasterAlerts: true,
        showOnlineStatus: map['show_online_status'] as bool? ?? true,
        showLastSeen: map['show_last_seen'] as bool? ?? true,
        sendReadReceipts: map['send_read_receipts'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'who_can_message': _permissionKey(whoCanMessage),
        'show_real_name': showRealName,
        'show_phone_number': showPhoneNumber,
        'show_farm_location': showFarmLocation,
        'show_farm_size': showFarmSize,
        'use_anonymous_in_forum': useAnonymousInForum,
        'allow_forum_quotes': allowForumQuotes,
        'share_disease_data': shareDiseaseData,
        'allow_research_use': allowResearchUse,
        'receive_marketing': receiveMarketing,
        'receive_officer_broadcasts': receiveOfficerBroadcasts,
        'receive_disaster_alerts': true,
        'show_online_status': showOnlineStatus,
        'show_last_seen': showLastSeen,
        'send_read_receipts': sendReadReceipts,
        'updated_at': DateTime.now().toIso8601String(),
      };

  static MessagePermission _parsePermission(String? key) {
    switch (key) {
      case 'officers_only':
        return MessagePermission.officersOnly;
      case 'nobody':
        return MessagePermission.nobody;
      default:
        return MessagePermission.everyone;
    }
  }

  static String _permissionKey(MessagePermission p) {
    switch (p) {
      case MessagePermission.officersOnly:
        return 'officers_only';
      case MessagePermission.nobody:
        return 'nobody';
      case MessagePermission.everyone:
        return 'everyone';
    }
  }
}
