import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/privacy_settings.dart';
import '../providers/auth_provider.dart';
import '../services/privacy_service.dart';
import '../theme/app_colors.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  PrivacySettings _settings = const PrivacySettings();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    final s = await PrivacyService.getSettings(user.id);
    if (mounted) setState(() { _settings = s; _loading = false; });
  }

  Future<void> _save() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    await PrivacyService.saveSettings(user.id, _settings);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Mipangilio ya faragha imehifadhiwa'),
        backgroundColor: AppColors.leaf,
      ));
    }
  }

  void _update(PrivacySettings updated) =>
      setState(() => _settings = updated);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EE),
      appBar: AppBar(
        title: Text('🔒 Mipangilio ya Faragha',
            style: GoogleFonts.playfairDisplay(
                color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Hifadhi',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.leaf))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section1Messages(),
                  _section2Profile(),
                  _section3Forum(),
                  _section4Data(),
                  _section5Presence(),
                  _section6Notifications(),
                  _section7Rights(),
                  _sectionAiPolicy(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ── SECTION 1: Messages ────────────────────────────────────────────────────

  Widget _section1Messages() => _sectionCard(
        title: '💬 Ujumbe',
        subtitle: 'Nani Anaweza Kuniandikia?',
        child: Column(
          children: [
            _radioTile(
              title: 'Kila mtu',
              subtitle: 'Wakulima wote na wataalamu wanaweza kuandika',
              value: MessagePermission.everyone,
              groupValue: _settings.whoCanMessage,
              onChanged: (v) =>
                  _update(_settings.copyWith(whoCanMessage: v)),
            ),
            _radioTile(
              title: 'Wataalamu tu',
              subtitle: 'Maafisa kilimo na agronomists tu',
              value: MessagePermission.officersOnly,
              groupValue: _settings.whoCanMessage,
              onChanged: (v) =>
                  _update(_settings.copyWith(whoCanMessage: v)),
            ),
            _radioTile(
              title: 'Hakuna mtu',
              subtitle: 'Zima ujumbe wote',
              value: MessagePermission.nobody,
              groupValue: _settings.whoCanMessage,
              onChanged: (v) =>
                  _update(_settings.copyWith(whoCanMessage: v)),
              warning: _settings.whoCanMessage == MessagePermission.nobody
                  ? 'Huwezi kupokea msaada wa haraka ukichagua hili'
                  : null,
            ),
          ],
        ),
      );

  // ── SECTION 2: Profile ─────────────────────────────────────────────────────

  Widget _section2Profile() => _sectionCard(
        title: '👤 Wasifu Wangu',
        subtitle: 'Watu Wanaona Nini?',
        child: Column(
          children: [
            _switchTile(
              title: 'Onyesha Jina Langu Halisi',
              subtitle: 'Jina lako linaonekana kwenye ujumbe',
              value: _settings.showRealName,
              onChanged: (v) =>
                  _update(_settings.copyWith(showRealName: v)),
            ),
            _switchTile(
              title: 'Onyesha Eneo la Shamba',
              subtitle: 'Wilaya na mkoa tu — si GPS halisi',
              value: _settings.showFarmLocation,
              onChanged: (v) =>
                  _update(_settings.copyWith(showFarmLocation: v)),
            ),
            _switchTile(
              title: 'Onyesha Nambari ya Simu',
              subtitle: 'Ifikie tu baada ya kuruhusu',
              value: _settings.showPhoneNumber,
              onChanged: (v) =>
                  _update(_settings.copyWith(showPhoneNumber: v)),
            ),
            _switchTile(
              title: 'Onyesha Ukubwa wa Shamba',
              subtitle: 'Ekari za shamba lako zinaonekana',
              value: _settings.showFarmSize,
              onChanged: (v) =>
                  _update(_settings.copyWith(showFarmSize: v)),
            ),
          ],
        ),
      );

  // ── SECTION 3: Forum ───────────────────────────────────────────────────────

  Widget _section3Forum() => _sectionCard(
        title: '🌱 Jamii',
        subtitle: 'Machapisho ya Jamii',
        child: Column(
          children: [
            _switchTile(
              title: 'Tumia Jina la Siri Kwenye Jamii',
              subtitle: 'Machapisho yako: "Mkulima wa [Mkoa]"',
              value: _settings.useAnonymousInForum,
              onChanged: (v) =>
                  _update(_settings.copyWith(useAnonymousInForum: v)),
            ),
            _switchTile(
              title: 'Ruhusu Wengine Kujibu Machapisho',
              subtitle: 'Wengine wanaweza kunukuu na kujibu',
              value: _settings.allowForumQuotes,
              onChanged: (v) =>
                  _update(_settings.copyWith(allowForumQuotes: v)),
            ),
          ],
        ),
      );

  // ── SECTION 4: Data ────────────────────────────────────────────────────────

  Widget _section4Data() => _sectionCard(
        title: '📊 Data Yangu',
        subtitle: 'Matumizi ya Data',
        child: Column(
          children: [
            _switchTile(
              title: 'Shiriki Data ya Magonjwa (Bila Jina)',
              subtitle:
                  'Husaidia kujenga ramani ya magonjwa Tanzania — bila taarifa zako binafsi',
              value: _settings.shareDiseaseData,
              onChanged: (v) =>
                  _update(_settings.copyWith(shareDiseaseData: v)),
            ),
            _switchTile(
              title: 'Ruhusu Utafiti wa Kilimo',
              subtitle:
                  'Data yako bila jina inatumika kuboresha Shamba Smart na kilimo Tanzania',
              value: _settings.allowResearchUse,
              onChanged: (v) =>
                  _update(_settings.copyWith(allowResearchUse: v)),
            ),
          ],
        ),
      );

  // ── SECTION 5: Online presence ─────────────────────────────────────────────

  Widget _section5Presence() => _sectionCard(
        title: '🟢 Upatikanaji',
        subtitle: 'Upatikanaji na Muda',
        child: Column(
          children: [
            _switchTile(
              title: 'Onyesha kama Niko Mtandaoni',
              subtitle: 'Wengine wanaona dot ya kijani unapokuwa online',
              value: _settings.showOnlineStatus,
              onChanged: (v) =>
                  _update(_settings.copyWith(showOnlineStatus: v)),
            ),
            _switchTile(
              title: 'Onyesha Wakati Niliotembelea Mwisho',
              subtitle: 'Wengine wanaona "Mwisho kuonekana: saa 2 zilizopita"',
              value: _settings.showLastSeen,
              onChanged: (v) =>
                  _update(_settings.copyWith(showLastSeen: v)),
            ),
            _switchTile(
              title: 'Tuma Risiti za Kusoma',
              subtitle: 'Wengine wanajua umeisoma ujumbe wao',
              value: _settings.sendReadReceipts,
              onChanged: (v) =>
                  _update(_settings.copyWith(sendReadReceipts: v)),
            ),
          ],
        ),
      );

  // ── SECTION 6: Notifications ───────────────────────────────────────────────

  Widget _section6Notifications() => _sectionCard(
        title: '🔔 Matangazo',
        subtitle: 'Aina za Ujumbe Unaopokea',
        child: Column(
          children: [
            _switchTile(
              title: 'Matangazo ya Afisa Kilimo',
              subtitle: 'Habari na ushauri kutoka serikalini',
              value: _settings.receiveOfficerBroadcasts,
              onChanged: (v) =>
                  _update(_settings.copyWith(receiveOfficerBroadcasts: v)),
            ),
            _switchTile(
              title: 'Ujumbe wa Biashara',
              subtitle: 'Matangazo ya maduka na bidhaa',
              value: _settings.receiveMarketing,
              onChanged: (v) =>
                  _update(_settings.copyWith(receiveMarketing: v)),
            ),
            // Disaster alerts — locked ON
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock, size: 16, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tahadhari za Dharura',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        Text(
                          'Tahadhari za mafuriko, ukame, magonjwa makubwa — haiwezi kuzimwa',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: true,
                    onChanged: null, // locked
                    activeColor: Colors.grey,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // ── SECTION 7: Data rights ─────────────────────────────────────────────────

  Widget _section7Rights() => _sectionCard(
        title: '⚖️ Haki Zako',
        subtitle: 'Udhibiti wa Data Yako',
        child: Column(
          children: [
            _actionTile(
              icon: Icons.download_outlined,
              title: 'Pakua Data Yangu',
              subtitle: 'Pata nakala ya data yote yako',
              color: const Color(0xFF1565C0),
              onTap: _exportData,
            ),
            const SizedBox(height: 8),
            _actionTile(
              icon: Icons.restore,
              title: 'Rejesha Mipangilio ya Awali',
              subtitle: 'Rudisha mipangilio yote ya faragha',
              color: Colors.orange.shade700,
              onTap: _resetToDefaults,
            ),
            const SizedBox(height: 8),
            _actionTile(
              icon: Icons.delete_forever_outlined,
              title: 'Futa Akaunti Yangu',
              subtitle: 'Futa akaunti na data yote kabisa',
              color: const Color(0xFFB71C1C),
              onTap: _showDeleteAccountDialog,
            ),
          ],
        ),
      );

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(
          'Sehemu ya kupakua data itakuwa tayari hivi karibuni.'),
      backgroundColor: AppColors.leaf,
    ));
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rejesha Mipangilio?'),
        content: const Text(
            'Mipangilio yote ya faragha itarudi kwenye ya awali.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ghairi')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _update(const PrivacySettings());
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700),
            child: const Text('Rejesha',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final phoneCtrl = TextEditingController();
    int step = 1;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            step == 1
                ? '⚠️ Futa Akaunti?'
                : step == 2
                    ? 'Thibitisha Utambulisho'
                    : '🗑️ Thibitisha Mara ya Mwisho',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (step == 1)
                const Text(
                  'Una uhakika? Hatua hii haiwezi kurudishwa.\n\n'
                  'Data yote itafutwa: mashamba, magonjwa, diary, ujumbe.',
                  style: TextStyle(height: 1.5),
                )
              else if (step == 2) ...[
                const Text('Andika nambari yako ya simu kuthibitisha:'),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '+255 7XX XXX XXX',
                    border: OutlineInputBorder(),
                  ),
                ),
              ] else
                const Text(
                  'Gonga "Futa" kwa mwisho. '
                  'Akaunti yako na data yote vitafutwa kabisa.',
                  style: TextStyle(color: Color(0xFFB71C1C)),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ghairi'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (step < 3) {
                  setDialogState(() => step++);
                } else {
                  Navigator.pop(ctx);
                  final user = context.read<AuthProvider>().currentUser;
                  if (user != null) {
                    final userId = user.id;
                    await PrivacyService.deleteAccount(userId);
                    if (context.mounted) {
                      await context.read<AuthProvider>().logout();
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C)),
              child: Text(
                step < 3 ? 'Endelea →' : 'Futa Kabisa',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper widgets ─────────────────────────────────────────────────────────

  // ── AI / photo handling policy (expandable, text-only) ─────────────────────
  Widget _policyHeading(String t) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 4),
        child: Text(t,
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.soil)),
      );

  Widget _policySub(String t) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13)),
      );

  Widget _policyBody(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(t,
            style: TextStyle(
                fontSize: 13, height: 1.5, color: Colors.grey.shade800)),
      );

  Widget _sectionAiPolicy() => Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 1,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Text('🌿 Jinsi Tunavyochambua Picha za Mazao Yako',
                style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.soil)),
            subtitle: Text('Sera ya faragha — picha za mazao na AI',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _policyBody(
                        'Tunapojaribu kukutambulisha ugonjwa, wadudu, au tatizo '
                        'kwenye zao lako kwa picha, hatua zifuatazo hutokea:'),
                    _policySub('1. Kwanza — kwenye simu yako (bila intaneti)'),
                    _policyBody(
                        'Mkulima AI, mfumo wetu wa AI uliojengwa ndani ya '
                        'programu, huchambua picha yako moja kwa moja kwenye simu '
                        'yako. Hatua hii haihitaji intaneti na hakuna taarifa '
                        'inayotumwa popote.'),
                    _policySub(
                        '2. Ikiwa Mkulima AI hana uhakika — picha hutumwa mtandaoni'),
                    _policyBody(
                        'Wakati Mkulima AI haina uhakika wa kutosha (mfano picha '
                        'si wazi, au tatizo ni geni), nakala ya picha yako '
                        '(iliyopunguzwa ukubwa) hutumwa mtandaoni kwa uchambuzi wa '
                        'pili kutoka:'),
                    _policyBody(
                        '• Google Gemini — hutumika kutambua ugonjwa, wadudu, au '
                        'tatizo kwenye picha.\n'
                        '• Anthropic Claude — hutumika kuandaa maelezo na ushauri '
                        'kwa Kiswahili rahisi.'),
                    _policyBody(
                        'Makampuni haya ni washirika wetu wa kiteknolojia (third-'
                        'party processors) — hawatumii picha zako kwa kusudi '
                        'lingine lolote zaidi ya kukupatia jibu lako.'),
                    _policySub('3. Eneo (GPS) huondolewa kabla ya kutuma mtandaoni'),
                    _policyBody(
                        'Kabla ya picha kutumwa kwa Google Gemini, taarifa za eneo '
                        '(GPS) na maelezo ya kiufundi ya picha (EXIF) huondolewa '
                        'kabisa. Google haipokei kamwe eneo halisi la shamba lako.'),
                    _policySub('4. Picha asili huhifadhiwa kwenye seva zetu (Supabase)'),
                    _policyBody(
                        'Nakala ya picha yako ya awali huhifadhiwa kwenye '
                        'hifadhidata yetu salama (Supabase), iliyolindwa na sheria '
                        'za ufikiaji (RLS) — wewe peke yako na mfumo wetu mnaoweza '
                        'kuifikia. Hutumika kuboresha Mkulima AI ili siku zijazo '
                        'itambue magonjwa kwa usahihi zaidi bila kuhitaji intaneti '
                        '— faida ya moja kwa moja kwako na kwa wakulima wenzako.'),
                    _policyHeading('Usalama wa Ushauri wa Dawa'),
                    _policyBody(
                        'Shamba Smart HAIPENDEKEZI KAMWE dawa kutoka kwa AI peke '
                        'yake. Kila ushauri wa dawa hupitishwa kwanza kwenye orodha '
                        'ya dawa zilizoidhinishwa rasmi na TPHPA. Ikiwa dawa '
                        'haijaidhinishwa au orodha bado haijapakiwa, mfumo '
                        'utakushauri kuwasiliana na Afisa Kilimo badala ya kukupa '
                        'jibu lisilo salama.'),
                    _policyHeading('Haki Zako'),
                    _policyBody(
                        '• Unaweza kuomba taarifa zako (ikiwemo picha) zifutwe '
                        'wakati wowote, kupitia Akaunti → Toa Maoni au kwa '
                        'kuwasiliana nasi.\n'
                        '• Hatuuzi wala kushiriki picha zako kwa madhumuni ya '
                        'matangazo.\n'
                        '• Taarifa zako binafsi (jina, namba ya simu, eneo la '
                        'shamba) hazitumwi kwa Google au Anthropic — ni picha pekee '
                        '(bila GPS) inayotumwa, na hiyo tu Mkulima AI inapohitaji '
                        'msaada wa pili.'),
                    const SizedBox(height: 10),
                    Text(
                      'Sehemu hii inasasishwa kuonyesha jinsi Shamba Smart '
                      'inavyotumia AI ya mtandaoni (Google Gemini na Anthropic '
                      'Claude) pamoja na Mkulima AI yetu ya ndani.',
                      style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) =>
      Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.soil)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      );

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.leaf,
            ),
          ],
        ),
      );

  Widget _radioTile<T>({
    required String title,
    required String subtitle,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
    String? warning,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RadioListTile<T>(
            title: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(subtitle,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade600)),
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
            activeColor: AppColors.leaf,
            contentPadding: EdgeInsets.zero,
          ),
          if (warning != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text('⚠️ $warning',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFB71C1C))),
            ),
        ],
      );

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontSize: 14)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: color.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 18),
            ],
          ),
        ),
      );
}
