import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class EmergencyModal extends StatefulWidget {
  final VoidCallback onClose;
  const EmergencyModal({super.key, required this.onClose});

  @override
  State<EmergencyModal> createState() => _EmergencyModalState();
}

class _EmergencyModalState extends State<EmergencyModal> {
  String curatorPhone = '+7-800-123-45-67'; // Телефон по умолчанию
  String inputValue = '';
  bool isEditing = false;
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    inputValue = curatorPhone;
    _phoneController.text = curatorPhone;
  }

  void _handleSave() {
    final trimmed = inputValue.trim();
    setState(() {
      curatorPhone = trimmed;
      isEditing = false;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: GestureDetector(
          onTap: () {},
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: const BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: Column(
                          children: [
                            _buildAlertMessage(),
                            const SizedBox(height: 16),
                            _buildContacts(),
                            const SizedBox(height: 16),
                            _buildQuickTechniques(),
                            const SizedBox(height: 16),
                            _buildTipsList(),
                            const SizedBox(height: 12),
                            _buildCloseButton(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(230, 57, 70, 0.2),
            Color.fromRGBO(230, 57, 70, 0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.destructive.withOpacity(0.15)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.destructive.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.destructive.withOpacity(0.3)),
            ),
            child: const Center(child: Text('\u{1F198}', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u042D\u043A\u0441\u0442\u0440\u0435\u043D\u043D\u0430\u044F \u043F\u043E\u043C\u043E\u0449\u044C',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '\u0422\u044B \u043D\u0435 \u043E\u0434\u0438\u043D, \u043F\u043E\u043C\u043E\u0449\u044C \u0440\u044F\u0434\u043E\u043C',
                  style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close, color: AppColors.mutedForeground, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.destructive.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.destructive.withOpacity(0.2)),
      ),
      child: const Text(
        '\u0415\u0441\u043B\u0438 \u0442\u044B \u0432 \u043A\u0440\u0438\u0437\u0438\u0441\u043D\u043E\u0439 \u0441\u0438\u0442\u0443\u0430\u0446\u0438\u0438 \u2014 \u043D\u0435\u043C\u0435\u0434\u043B\u0435\u043D\u043D\u043E \u043E\u0431\u0440\u0430\u0442\u0438\u0441\u044C \u0437\u0430 \u043F\u043E\u043C\u043E\u0449\u044C\u044E. \u0422\u044B \u0432\u0430\u0436\u0435\u043D, \u0438 \u0442\u0435\u0431\u0435 \u043F\u043E\u043C\u043E\u0433\u0443\u0442 24/7.',
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFFFFADA5),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildContacts() {
    final contacts = [
      {
        'name': '\u0422\u0435\u043B\u0435\u0444\u043E\u043D \u0434\u043E\u0432\u0435\u0440\u0438\u044F',
        'number': '8-800-2000-122',
        'desc': '\u0411\u0435\u0441\u043F\u043B\u0430\u0442\u043D\u043E \u00B7 \u041A\u0440\u0443\u0433\u043B\u043E\u0441\u0443\u0442\u043E\u0447\u043D\u043E',
        'icon': Icons.phone,
        'color': AppColors.destructive,
      },
      {
        'name': '\u0421\u043B\u0443\u0436\u0431\u0430 112',
        'number': '112',
        'desc': '\u042D\u043A\u0441\u0442\u0440\u0435\u043D\u043D\u044B\u0435 \u0441\u043B\u0443\u0436\u0431\u044B',
        'icon': Icons.phone,
        'color': AppColors.citrusOrange,
      },
      {
        'name': '\u041F\u0441\u0438\u0445\u043E\u043B\u043E\u0433 \u0412\u0423\u0417\u0430',
        'number': '\u0417\u0430\u043F\u0438\u0441\u0430\u0442\u044C\u0441\u044F',
        'desc': '\u041F\u043E\u0434\u0434\u0435\u0440\u0436\u043A\u0430 \u0441\u0442\u0443\u0434\u0435\u043D\u0442\u043E\u0432',
        'icon': Icons.people,
        'color': AppColors.citrusPurple,
      },
    ];

    return Column(
      children: [
        ...contacts.map((c) => _buildContactCard(
          name: c['name'] as String,
          number: c['number'] as String,
          desc: c['desc'] as String,
          icon: c['icon'] as IconData,
          color: c['color'] as Color,
        )),
        const SizedBox(height: 8),
        _buildCuratorCard(),
      ],
    );
  }

  Widget _buildContactCard({
    required String name,
    required String number,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  number,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.phone, color: color, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCuratorCard() {
    final color = AppColors.citrusGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.school, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '\u041A\u0443\u0440\u0430\u0442\u043E\u0440 \u0443\u0447\u0435\u0431\u043D\u043E\u0439 \u0433\u0440\u0443\u043F\u043F\u044B',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 6),
                if (isEditing)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          style: const TextStyle(fontSize: 12, color: AppColors.foreground),
                          decoration: InputDecoration(
                            hintText: '+7 (___) ___-__-__',
                            hintStyle: const TextStyle(fontSize: 12, color: AppColors.dimForeground),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.07),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: color.withOpacity(0.25)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.phone,
                          onSubmitted: (_) => _handleSave(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _handleSave,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.check, size: 16),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        curatorPhone.isEmpty ? '\u041D\u043E\u043C\u0435\u0440 \u043D\u0435 \u0443\u043A\u0430\u0437\u0430\u043D' : curatorPhone,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const Text(
                        '\u041A\u0443\u0440\u0430\u0442\u043E\u0440 \u0432\u0430\u0448\u0435\u0439 \u0433\u0440\u0443\u043F\u043F\u044B',
                        style: TextStyle(fontSize: 10, color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (!isEditing)
            curatorPhone.isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.phone, color: color, size: 16),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            inputValue = curatorPhone;
                            _phoneController.text = curatorPhone;
                            isEditing = true;
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.edit, color: AppColors.mutedForeground, size: 14),
                        ),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() => isEditing = true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Text(
                        '\u0414\u043E\u0431\u0430\u0432\u0438\u0442\u044C',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildQuickTechniques() {
    final techniques = [
      {
        'icon': Icons.air,
        'label': '\u0414\u044B\u0445\u0430\u043D\u0438\u0435 4-4-4',
        'desc': '\u0412\u0434\u043E\u0445 4\u0441 \u00B7 \u041F\u0430\u0443\u0437\u0430 4\u0441 \u00B7 \u0412\u044B\u0434\u043E\u0445 4\u0441',
        'color': AppColors.citrusPurple,
      },
      {
        'icon': Icons.favorite,
        'label': '5-4-3-2-1',
        'desc': '5 \u0432\u0438\u0434\u0438\u0448\u044C \u00B7 4 \u043F\u043E\u0442\u0440\u043E\u0433\u0430\u0442\u044C \u00B7 3 \u0441\u043B\u044B\u0448\u0438\u0448\u044C',
        'color': AppColors.citrusGreen,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            '\u0411\u042B\u0421\u0422\u0420\u042B\u0415 \u0422\u0415\u0425\u041D\u0418\u041A\u0418 \u0421\u0410\u041C\u041E\u041F\u041E\u041C\u041E\u0429\u0418',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.dimForeground,
              letterSpacing: 0.8,
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.4,
          children: techniques.map((t) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (t['color'] as Color).withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: (t['color'] as Color).withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(t['icon'] as IconData, color: t['color'] as Color, size: 20),
                  const SizedBox(height: 6),
                  Text(
                    t['label'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t['desc'] as String,
                    style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTipsList() {
    final tips = [
      '\u0425\u043E\u043B\u043E\u0434\u043D\u0430\u044F \u0432\u043E\u0434\u0430 \u043D\u0430 \u0437\u0430\u043F\u044F\u0441\u0442\u044C\u044F \u0438\u043B\u0438 \u043B\u0438\u0446\u043E',
      '\u041F\u043E\u0437\u0432\u043E\u043D\u0438 \u0431\u043B\u0438\u0437\u043A\u043E\u043C\u0443 \u0447\u0435\u043B\u043E\u0432\u0435\u043A\u0443',
      '\u0412\u044B\u0439\u0434\u0438 \u043D\u0430 \u0441\u0432\u0435\u0436\u0438\u0439 \u0432\u043E\u0437\u0434\u0443\u0445',
      '\u041D\u0430\u043F\u0438\u0448\u0438 \u043E \u0441\u0432\u043E\u0438\u0445 \u0447\u0443\u0432\u0441\u0442\u0432\u0430\u0445 \u0432 \u0434\u043D\u0435\u0432\u043D\u0438\u043A',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '\u0427\u0442\u043E \u0434\u0435\u043B\u0430\u0442\u044C \u043F\u0440\u044F\u043C\u043E \u0441\u0435\u0439\u0447\u0430\u0441:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u2192',
                  style: TextStyle(color: AppColors.citrusPurple, fontSize: 12),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          '\u0417\u0430\u043A\u0440\u044B\u0442\u044C',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }
}
