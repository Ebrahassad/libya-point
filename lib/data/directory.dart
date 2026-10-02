import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../services/content_store.dart';
import 'apps_data.dart';
import 'hotels.dart';

/// نوع الرابط الأساسي داخل البطاقة.
enum LinkKind { web, app, phone, email }

/// رابط إضافي داخل نفس البطاقة.
///
/// الهدف هو أن تكون بطاقة الجهة الواحدة «مركز خدمات» بدلاً من تكرارها في عدة
/// بطاقات: موقع، تطبيق، هاتف، خدمة إلكترونية، أخبار، خريطة... إلخ.
class DirAction {
  final String label;
  final LinkKind kind;
  final String? url;
  final String? package;
  final String? phone;
  final String? searchName;
  final IconData iconData;

  const DirAction.web(this.label, this.url, {this.iconData = Icons.open_in_new})
    : kind = LinkKind.web,
      package = null,
      phone = null,
      searchName = null;

  const DirAction.app(
    this.label, {
    this.package,
    this.searchName,
    this.iconData = Icons.download,
  }) : kind = LinkKind.app,
       url = null,
       phone = null;

  const DirAction.phone(this.label, this.phone, {this.iconData = Icons.call})
    : kind = LinkKind.phone,
      url = null,
      package = null,
      searchName = null;

  const DirAction.email(
    this.label,
    this.url, {
    this.iconData = Icons.email_outlined,
  }) : kind = LinkKind.email,
       package = null,
       phone = null,
       searchName = null;

  Uri get uri {
    switch (kind) {
      case LinkKind.web:
      case LinkKind.email:
        return Uri.parse(url!);
      case LinkKind.phone:
        return Uri.parse('tel:$phone');
      case LinkKind.app:
        if (package != null) {
          return Uri.parse(
            'https://play.google.com/store/apps/details?id=$package',
          );
        }
        return Uri.parse(
          'https://play.google.com/store/search?q=${Uri.encodeComponent(searchName ?? label)}&c=apps',
        );
    }
  }
}

/// عنصر في الدليل.
///
/// [actions] اختيارية وتُستخدم لبناء بطاقات متعددة الروابط. العناصر القديمة
/// التي لا تملكها تستمر في العمل برابط واحد.
class DirItem {
  final String title;
  final String desc;
  final LinkKind kind;
  final String? url;
  final String? package;
  final String? phone;
  final String? searchName;
  final String? id;
  final List<DirAction> actions;
  final bool official;
  final String? source;
  final String? sourceUrl;
  final String? verifiedAt;
  final String? tag;

  const DirItem.web(
    this.title,
    this.desc,
    String this.url, {
    this.id,
    this.actions = const [],
    this.official = false,
    this.source,
    this.sourceUrl,
    this.verifiedAt,
    this.tag,
  }) : kind = LinkKind.web,
       package = null,
       phone = null,
       searchName = null;

  const DirItem.app(
    this.title,
    this.desc, {
    this.package,
    this.searchName,
    this.id,
    this.actions = const [],
    this.official = false,
    this.source,
    this.sourceUrl,
    this.verifiedAt,
    this.tag,
  }) : kind = LinkKind.app,
       url = null,
       phone = null;

  const DirItem.phone(
    this.title,
    this.desc,
    String this.phone, {
    this.id,
    this.actions = const [],
    this.official = false,
    this.source,
    this.sourceUrl,
    this.verifiedAt,
    this.tag,
  }) : kind = LinkKind.phone,
       url = null,
       package = null,
       searchName = null;

  /// مفتاح فريد للمفضلة. عند توفير id يصبح هو المرجع الثابت حتى لو تغير الاسم.
  String get key => id ?? '${kind.name}|$title';

  DirAction get primaryAction {
    if (actions.isNotEmpty) return actions.first;
    switch (kind) {
      case LinkKind.web:
        return DirAction.web('open_site'.tr(), url!);
      case LinkKind.phone:
        return DirAction.phone('call'.tr(), phone!);
      case LinkKind.app:
        return DirAction.app(
          package != null ? 'download_play'.tr() : 'search_play'.tr(),
          package: package,
          searchName: searchName,
        );
      case LinkKind.email:
        return DirAction.email('email'.tr(), url!);
    }
  }

  Uri get uri => primaryAction.uri;

  IconData get icon => primaryAction.iconData;

  List<DirAction> get visibleActions {
    if (actions.isNotEmpty) return actions;
    return [primaryAction];
  }
}

class DirGroup {
  final String title;
  final List<DirItem> items;
  const DirGroup(this.title, this.items);
}

class DirSection {
  final String id;
  final IconData icon;
  final Color color;
  final List<DirGroup> groups;
  final String? title;
  final String? subtitle;
  const DirSection(
    this.id,
    this.icon,
    this.color,
    this.groups, {
    this.title,
    this.subtitle,
  });

  int get count => groups.fold(0, (a, g) => a + g.items.length);
}

const String _verified = '2026-10-02';
const String _cbl = 'https://cbl.gov.ly/';

/// يبني بطاقة مصرف موحدة: موقع + تطبيق + اتصال + خريطة + المصدر.
DirItem _bank({
  required String id,
  required String title,
  required String website,
  required String phone,
  required String appName,
  String? package,
  String? serviceUrl,
  String? serviceLabel,
  List<DirAction> extraActions = const [],
}) {
  final app = package == null
      ? DirAction.app('تطبيق $appName', searchName: '$appName ليبيا')
      : DirAction.app('تطبيق $appName', package: package);
  final service = serviceUrl == null
      ? null
      : DirAction.web(
          serviceLabel ?? 'الخدمات الإلكترونية',
          serviceUrl,
          iconData: Icons.apps_outlined,
        );
  return DirItem.web(
    title,
    'الصفحة الرسمية والروابط الأساسية للمصرف: الموقع، التطبيق، الاتصال والخريطة.',
    website,
    id: id,
    official: true,
    source: 'دليل المصارف التجارية - مصرف ليبيا المركزي',
    sourceUrl: _cbl,
    verifiedAt: _verified,
    tag: 'bank',
    actions: [
      DirAction.web('الموقع الرسمي', website),
      app,
      ...extraActions,
      if (service != null) service,
      DirAction.phone('اتصال', phone),
      DirAction.web(
        'الخريطة',
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$title، ليبيا')}',
        iconData: Icons.location_on_outlined,
      ),
    ],
  );
}

/// الأقسام المضمّنة في التطبيق. يمكن للمحتوى البعيد تعديلها أو إضافة أقسام.
final List<DirSection> defaultSections = [
  appsSection,

  // -------------------------------------------------------------------------
  // الدولة والمؤسسات الرسمية
  // -------------------------------------------------------------------------
  DirSection('state', Icons.account_balance, const Color(0xFF1565C0), [
    DirGroup('المؤسسات التشريعية والتنفيذية', [
      DirItem.web(
        'مجلس النواب',
        'الموقع الرسمي للمجلس والنواب واللجان والقرارات والقوانين والمركز الإعلامي.',
        'https://parl.ly/',
        id: 'state-parliament',
        official: true,
        source: 'الموقع الرسمي لمجلس النواب',
        sourceUrl: 'https://parl.ly/',
        verifiedAt: _verified,
        tag: 'state',
        actions: [
          const DirAction.web('الموقع الرسمي', 'https://parl.ly/'),
          DirAction.web(
            'أخبار المجلس',
            "https://www.google.com/search?q=${Uri.encodeComponent('site:parl.ly ليبيا مجلس النواب أخبار')}",
            iconData: Icons.newspaper_outlined,
          ),
          DirAction.web(
            'القوانين والقرارات',
            "https://www.google.com/search?q=${Uri.encodeComponent('site:parl.ly قوانين قرارات مجلس النواب')}",
            iconData: Icons.gavel_outlined,
          ),
          DirAction.web(
            'الجريدة الرسمية',
            "https://www.google.com/search?q=${Uri.encodeComponent('site:parl.ly الجريدة الرسمية ليبيا')}",
            iconData: Icons.description_outlined,
          ),
        ],
      ),
      DirItem.web(
        'المجلس الأعلى للدولة',
        'الموقع الرسمي والبيانات والمواد الإعلامية والملفات المنشورة للمجلس.',
        'https://hcs.gov.ly/',
        id: 'state-hcs',
        official: true,
        source: 'الموقع الرسمي للمجلس الأعلى للدولة',
        sourceUrl: 'https://hcs.gov.ly/',
        verifiedAt: _verified,
        tag: 'state',
        actions: [
          const DirAction.web('الموقع الرسمي', 'https://hcs.gov.ly/'),
          DirAction.web(
            'الأخبار والبيانات',
            "https://www.google.com/search?q=${Uri.encodeComponent('site:hcs.gov.ly ليبيا المجلس الأعلى للدولة أخبار')}",
            iconData: Icons.newspaper_outlined,
          ),
        ],
      ),
      DirItem.web(
        'حكومة الوحدة الوطنية',
        'الموقع الرسمي للحكومة. الصفحة الحالية تشير إلى أن الموقع قيد التطوير.',
        'https://gnu.gov.ly/',
        id: 'state-gnu',
        official: true,
        source: 'الموقع الرسمي لحكومة الوحدة الوطنية',
        sourceUrl: 'https://gnu.gov.ly/',
        verifiedAt: _verified,
        tag: 'state',
        actions: [
          const DirAction.web('الموقع الرسمي', 'https://gnu.gov.ly/'),
          const DirAction.web(
            'رئاسة مجلس الوزراء',
            'https://pm.gov.ly/',
            iconData: Icons.account_balance_outlined,
          ),
          DirAction.web(
            'قرارات وقوانين',
            "https://www.google.com/search?q=${Uri.encodeComponent('site:gnu.gov.ly ليبيا قرارات قوانين')}",
            iconData: Icons.gavel_outlined,
          ),
        ],
      ),
      DirItem.web(
        'رئاسة مجلس الوزراء',
        'بوابة رئاسة مجلس الوزراء. الموقع الحالي يعلن أنه قيد التطوير.',
        'https://pm.gov.ly/',
        id: 'state-pm',
        official: true,
        source: 'الموقع الرسمي لرئاسة مجلس الوزراء',
        sourceUrl: 'https://pm.gov.ly/',
        verifiedAt: _verified,
        tag: 'state',
        actions: [
          const DirAction.web('الموقع الرسمي', 'https://pm.gov.ly/'),
          DirAction.web(
            'أخبار الرئاسة',
            "https://www.google.com/search?q=${Uri.encodeComponent('site:pm.gov.ly حكومة ليبيا رئاسة مجلس الوزراء')}",
            iconData: Icons.newspaper_outlined,
          ),
        ],
      ),
    ]),
    DirGroup('الرقابة والاقتصاد والمالية', [
      DirItem.web(
        'ديوان المحاسبة الليبي',
        'التقارير والقوانين والإصدارات والأخبار المنشورة في الموقع الرسمي.',
        'https://www.audit.gov.ly/ar/',
        id: 'state-audit',
        official: true,
        source: 'ديوان المحاسبة الليبي',
        sourceUrl: 'https://www.audit.gov.ly/ar/',
        verifiedAt: _verified,
        tag: 'state',
        actions: [
          const DirAction.web('الموقع', 'https://www.audit.gov.ly/ar/'),
          DirAction.web(
            'التقارير',
            "https://www.google.com/search?q=${Uri.encodeComponent('site:audit.gov.ly ليبيا ديوان المحاسبة التقارير')}",
            iconData: Icons.assessment_outlined,
          ),
          DirAction.web(
            'الأخبار',
            "https://www.google.com/search?q=${Uri.encodeComponent('site:audit.gov.ly ليبيا ديوان المحاسبة أخبار')}",
            iconData: Icons.newspaper_outlined,
          ),
        ],
      ),
      const DirItem.web(
        'وزارة المالية',
        'أخبار الوزارة والمركز الإعلامي والجهات التابعة ومعلومات الاتصال.',
        'https://mof.gov.ly/',
        id: 'state-finance-ministry',
        official: true,
        source: 'وزارة المالية الليبية',
        sourceUrl: 'https://mof.gov.ly/',
        verifiedAt: _verified,
        tag: 'state',
        actions: [
          DirAction.web('الموقع الرسمي', 'https://mof.gov.ly/'),
          DirAction.web(
            'المركز الإعلامي',
            'https://mof.gov.ly/blog/',
            iconData: Icons.newspaper_outlined,
          ),
          DirAction.web(
            'الجهات التابعة',
            'https://mof.gov.ly/mof-entities-affiliated/',
            iconData: Icons.account_tree_outlined,
          ),
        ],
      ),
      const DirItem.web(
        'وزارة الاقتصاد والتجارة',
        'معلومات وخدمات متعلقة بالشركات والأعمال وإجراءات الوزارة.',
        'https://economy.gov.ly/',
        id: 'state-economy',
        official: true,
        source: 'وزارة الاقتصاد والتجارة - بيانات الاتصال عبر منظومة إجراءات حكومية',
        sourceUrl: 'https://ejraat.gov.ly/Contacts/21?l=ar',
        verifiedAt: _verified,
        tag: 'state',
        actions: [
          DirAction.web('الموقع', 'https://economy.gov.ly/'),
          DirAction.web(
            'بوابة الإجراءات',
            'https://ejraat.gov.ly/Contacts/21?l=ar',
            iconData: Icons.apps_outlined,
          ),
        ],
      ),
      const DirItem.web(
        'وزارة التخطيط',
        'الموقع الرسمي ولوحة معلومات المشاريع التنموية.',
        'https://www.planning.gov.ly/',
        id: 'state-planning',
        official: true,
        source: 'وزارة التخطيط',
        sourceUrl: 'https://www.planning.gov.ly/',
        verifiedAt: _verified,
        tag: 'state',
        actions: [
          DirAction.web('الموقع الرسمي', 'https://www.planning.gov.ly/'),
          DirAction.web(
            'لوحة المشاريع التنموية',
            'https://dashboard.planning.gov.ly/',
            iconData: Icons.dashboard_outlined,
          ),
        ],
      ),
    ]),
    DirGroup('الأمن والجوازات', [
      DirItem.web(
        'وزارة الداخلية الليبية',
        'الموقع الرسمي والأخبار والأنظمة والخدمات المنشورة من الوزارة.',
        'https://www.moi.gov.ly/',
        id: 'state-moi',
        official: true,
        source: 'وزارة الداخلية الليبية',
        sourceUrl: 'https://www.moi.gov.ly/',
        verifiedAt: _verified,
        tag: 'security',
        actions: [
          const DirAction.web('الموقع الرسمي', 'https://www.moi.gov.ly/'),
          DirAction.web(
            'أخبار الوزارة',
            "https://www.google.com/search?q=${Uri.encodeComponent('site:moi.gov.ly ليبيا وزارة الداخلية أخبار')}",
            iconData: Icons.newspaper_outlined,
          ),
        ],
      ),
      DirItem.web(
        'وزارة الدفاع الليبية',
        'آخر الأخبار والبيانات المنشورة على الموقع الرسمي لوزارة الدفاع.',
        'https://www.mod.gov.ly/',
        id: 'state-mod',
        official: true,
        source: 'وزارة الدفاع الليبية',
        sourceUrl: 'https://www.mod.gov.ly/category/last-news/',
        verifiedAt: _verified,
        tag: 'security',
        actions: [
          const DirAction.web('الموقع الرسمي', 'https://www.mod.gov.ly/'),
          const DirAction.web(
            'آخر الأخبار',
            'https://www.mod.gov.ly/category/last-news/',
            iconData: Icons.newspaper_outlined,
          ),
          DirAction.web(
            'بحث في أخبار الدفاع',
            "https://www.google.com/search?q=${Uri.encodeComponent('site:mod.gov.ly ليبيا وزارة الدفاع')}",
            iconData: Icons.search,
          ),
        ],
      ),
      DirItem.web(
        'مصلحة الجوازات والجنسية وشؤون الأجانب',
        'الأخبار والقرارات والفروع والنماذج والأسئلة الشائعة المنشورة عبر الموقع.',
        'https://lpa.gov.ly/',
        id: 'state-passports',
        official: true,
        source: 'مصلحة الجوازات والجنسية وشؤون الأجانب',
        sourceUrl: 'https://lpa.gov.ly/',
        verifiedAt: _verified,
        tag: 'citizen',
        actions: [
          const DirAction.web('الموقع الرسمي', 'https://lpa.gov.ly/'),
          DirAction.web(
            'الأخبار',
            "https://www.google.com/search?q=${Uri.encodeComponent('site:lpa.gov.ly ليبيا الجوازات أخبار')}",
            iconData: Icons.newspaper_outlined,
          ),
          DirAction.web(
            'الفروع',
            "https://www.google.com/search?q=${Uri.encodeComponent('site:lpa.gov.ly فروع مصلحة الجوازات ليبيا')}",
            iconData: Icons.location_on_outlined,
          ),
          DirAction.web(
            'النماذج',
            "https://www.google.com/search?q=${Uri.encodeComponent('site:lpa.gov.ly نماذج مصلحة الجوازات ليبيا')}",
            iconData: Icons.description_outlined,
          ),
        ],
      ),
    ]),
    const DirGroup('وزارات وخدمات رسمية إضافية', [
      DirItem.web(
        'وزارة الخارجية والتعاون الدولي',
        'الأخبار والبعثات الليبية بالخارج وخدمات المواطنين بالخارج.',
        'https://foreign.gov.ly/MOFA/',
        id: 'state-foreign',
        official: true,
        source: 'وزارة الخارجية والتعاون الدولي',
        sourceUrl: 'https://foreign.gov.ly/MOFA/',
        verifiedAt: _verified,
        tag: 'state',
        actions: [
          DirAction.web('الموقع الرسمي', 'https://foreign.gov.ly/MOFA/'),
          DirAction.web(
            'البعثات الليبية بالخارج',
            'https://embassies.foreign.gov.ly/',
            iconData: Icons.public,
          ),
          DirAction.web(
            'الخدمات القنصلية',
            'https://foreign.gov.ly/MOFA/',
            iconData: Icons.badge_outlined,
          ),
        ],
      ),
      DirItem.web(
        'وزارة العدل',
        'الأخبار والقوانين والقرارات ومواقع الجهات التابعة للوزارة.',
        'https://aladel.gov.ly/home/',
        id: 'state-justice',
        official: true,
        source: 'وزارة العدل - دولة ليبيا',
        sourceUrl: 'https://aladel.gov.ly/home/',
        verifiedAt: _verified,
        tag: 'state',
        actions: [
          DirAction.web('الموقع الرسمي', 'https://aladel.gov.ly/home/'),
          DirAction.web(
            'القوانين والقرارات',
            'https://aladel.gov.ly/home/category/%D8%A7%D9%84%D9%82%D9%88%D8%A7%D9%86%D9%8A%D9%86-%D9%88%D8%A7%D9%84%D9%82%D8%B1%D8%A7%D8%B1%D8%A7%D8%AA/',
            iconData: Icons.gavel_outlined,
          ),
          DirAction.web(
            'مواقع تهمك',
            'https://aladel.gov.ly/home/%D9%85%D9%88%D8%A7%D9%82%D8%B9-%D8%AA%D9%87%D9%85%D9%83/',
            iconData: Icons.link,
          ),
        ],
      ),
      DirItem.web(
        'وزارة العمل والتأهيل',
        'الأخبار ومنظومات الباحثين عن العمل وخدمات التشغيل.',
        'https://labour.gov.ly/',
        id: 'state-labour',
        official: true,
        source: 'وزارة العمل والتأهيل',
        sourceUrl: 'https://labour.gov.ly/',
        verifiedAt: _verified,
        tag: 'state',
        actions: [
          DirAction.web('الموقع الرسمي', 'https://labour.gov.ly/'),
          DirAction.web(
            'أخبار الوزارة',
            'https://labour.gov.ly/labour-news/',
            iconData: Icons.newspaper_outlined,
          ),
          DirAction.web(
            'خدمات التشغيل',
            'https://ejraat.gov.ly/Contacts/26?l=ar',
            iconData: Icons.work_outline,
          ),
        ],
      ),
      DirItem.web(
        'وزارة التعليم العالي والبحث العلمي',
        'البوابة الإلكترونية الرسمية وخدمات شؤون الجامعات والجامعات المدرجة.',
        'https://www.mohe.edu.ly/',
        id: 'state-higher-education',
        official: true,
        source: 'وزارة التعليم العالي والبحث العلمي',
        sourceUrl: 'https://www.mohe.edu.ly/',
        verifiedAt: _verified,
        tag: 'state',
        actions: [
          DirAction.web('البوابة الرسمية', 'https://www.mohe.edu.ly/'),
          DirAction.web(
            'البوابة الجامعية',
            'https://www.mohe.edu.ly/',
            iconData: Icons.school_outlined,
          ),
        ],
      ),
      DirItem.web(
        'الهيئة العامة للمعلومات',
        'المعلومات والبيانات والتحول الرقمي والخدمات الإلكترونية.',
        'https://www.gia.gov.ly/',
        id: 'state-gia',
        official: true,
        source: 'الهيئة العامة للمعلومات',
        sourceUrl: 'https://www.gia.gov.ly/',
        verifiedAt: _verified,
        tag: 'state',
        actions: [
          DirAction.web('الموقع الرسمي', 'https://www.gia.gov.ly/'),
          DirAction.web(
            'المعلومات والتحول الرقمي',
            'https://www.gia.gov.ly/',
            iconData: Icons.data_object_outlined,
          ),
        ],
      ),
    ]),
  ]),

  // خدمات المواطن
  // -------------------------------------------------------------------------
  DirSection('citizen', Icons.how_to_reg, const Color(0xFF00838F), [
    const DirGroup('الخدمات الإلكترونية والدفع الحكومي', [
      DirItem.web(
        'لي باي LYPay',
        'خدمة دفع وتحويل إلكتروني عبر مزودي الدفع المشاركين.',
        'https://lypay.gov.ly/',
        id: 'citizen-lypay',
        official: true,
        source: 'بوابة LYPay',
        sourceUrl: 'https://lypay.gov.ly/',
        verifiedAt: _verified,
      ),
      DirItem.web(
        'وزارة الحكم المحلي',
        'الموقع والأخبار وخدمات الإدارة المحلية والبلديات، مع رابط الوظيفة المحلية ومركز الاتصال.',
        'https://www.lgm.gov.ly/',
        id: 'citizen-lga',
        official: true,
        source: 'وزارة الحكم المحلي',
        sourceUrl: 'https://www.lgm.gov.ly/',
        verifiedAt: _verified,
        actions: [
          DirAction.web('الموقع الرسمي', 'https://www.lgm.gov.ly/'),
          DirAction.web(
            'الوظيفة المحلية',
            'https://www.lgm.gov.ly/hr/',
            iconData: Icons.work_outline,
          ),
          DirAction.phone('مركز الاتصال المحلي 1415', '1415'),
        ],
      ),
    ]),
    DirGroup('الهوية والخدمات الحكومية', [
      DirItem.web(
        'مصلحة الجوازات والجنسية وشؤون الأجانب',
        'الأخبار والقرارات والفروع والنماذج والأسئلة الشائعة.',
        'https://lpa.gov.ly/',
        id: 'citizen-passports',
        official: true,
        source: 'مصلحة الجوازات والجنسية وشؤون الأجانب',
        sourceUrl: 'https://lpa.gov.ly/',
        verifiedAt: _verified,
        actions: [
          const DirAction.web('الموقع الرسمي', 'https://lpa.gov.ly/'),
          DirAction.web(
            'الأخبار',
            "https://www.google.com/search?q=${Uri.encodeComponent('site:lpa.gov.ly ليبيا الجوازات أخبار')}",
            iconData: Icons.newspaper_outlined,
          ),
          DirAction.web(
            'الفروع',
            "https://www.google.com/search?q=${Uri.encodeComponent('site:lpa.gov.ly فروع مصلحة الجوازات ليبيا')}",
            iconData: Icons.location_on_outlined,
          ),
          DirAction.web(
            'النماذج',
            "https://www.google.com/search?q=${Uri.encodeComponent('site:lpa.gov.ly نماذج مصلحة الجوازات ليبيا')}",
            iconData: Icons.description_outlined,
          ),
        ],
      ),
      const DirItem.web(
        'مصلحة الجمارك الليبية',
        'الخدمات الجمركية والبوابة الإلكترونية والتعريفة والمنافذ.',
        'https://customs.gov.ly/',
        id: 'citizen-customs',
        official: true,
        source: 'مصلحة الجمارك الليبية',
        sourceUrl: 'https://customs.gov.ly/',
        verifiedAt: _verified,
        actions: [
          DirAction.web('الموقع الرسمي', 'https://customs.gov.ly/'),
          DirAction.web(
            'الخدمات الجمركية',
            'https://customs.gov.ly/services/',
            iconData: Icons.apps_outlined,
          ),
          DirAction.web(
            'البوابة الإلكترونية',
            'https://e-portal.customs.gov.ly/',
            iconData: Icons.language,
          ),
        ],
      ),
      DirItem.web(
        'ديوان المحاسبة الليبي',
        'التقارير والقوانين والإصدارات والأخبار المنشورة في الموقع الرسمي.',
        'https://www.audit.gov.ly/ar/',
        id: 'citizen-audit',
        official: true,
        source: 'ديوان المحاسبة الليبي',
        sourceUrl: 'https://www.audit.gov.ly/ar/',
        verifiedAt: _verified,
        actions: [
          const DirAction.web('الموقع', 'https://www.audit.gov.ly/ar/'),
          DirAction.web(
            'التقارير',
            "https://www.google.com/search?q=${Uri.encodeComponent('site:audit.gov.ly ليبيا ديوان المحاسبة التقارير')}",
            iconData: Icons.assessment_outlined,
          ),
        ],
      ),
    ]),
    DirGroup('الضمان والمرافق', [
      DirItem.web(
        'صندوق الضمان الاجتماعي',
        'الموقع الرسمي والأخبار ومعلومات وخدمات الضمان الاجتماعي.',
        'https://ssf.gov.ly/',
        id: 'citizen-social-security',
        official: true,
        source: 'صندوق الضمان الاجتماعي - ليبيا',
        sourceUrl: 'https://ssf.gov.ly/',
        verifiedAt: _verified,
        actions: [
          const DirAction.web('الموقع الرسمي', 'https://ssf.gov.ly/'),
          DirAction.web(
            'الأخبار',
            "https://www.google.com/search?q=${Uri.encodeComponent('site:ssf.gov.ly ليبيا صندوق الضمان الاجتماعي أخبار')}",
            iconData: Icons.newspaper_outlined,
          ),
          const DirAction.web(
            'تواصل',
            'https://ssf.gov.ly/?page_id=134',
            iconData: Icons.support_agent,
          ),
        ],
      ),
      const DirItem.web(
        'الشركة العامة للمياه والصرف الصحي',
        'الخدمات المنزلية والصرف الصحي والنماذج وأخبار الشركة.',
        'https://gcww.gov.ly/',
        id: 'citizen-water',
        official: true,
        source: 'الشركة العامة للمياه والصرف الصحي',
        sourceUrl: 'https://gcww.gov.ly/',
        verifiedAt: _verified,
        actions: [
          DirAction.web('الموقع والخدمات', 'https://gcww.gov.ly/'),
          DirAction.web(
            'الخدمات المنزلية',
            'https://gcww.gov.ly/',
            iconData: Icons.water_drop_outlined,
          ),
        ],
      ),
    ]),
  ]),

  // -------------------------------------------------------------------------
  // الشكاوى والبلاغات
  // -------------------------------------------------------------------------
  const DirSection('complaints', Icons.report_problem, Color(0xFFAD1457), [
    DirGroup('بلاغات وشكاوى رسمية', [
      DirItem.web(
        'منصة رقيب للشكاوى والبلاغات',
        'منصة هيئة الرقابة الإدارية لتقديم الشكاوى والبلاغات ومتابعتها عبر الإنترنت.',
        'https://raqeb.aca.gov.ly/',
        id: 'complaint-raqeb',
        official: true,
        source: 'هيئة الرقابة الإدارية - منصة رقيب',
        sourceUrl: 'https://www.aca.gov.ly/public/complaint_report',
        verifiedAt: _verified,
        tag: 'complaint',
        actions: [
          DirAction.web(
            'منصة الشكاوى',
            'https://raqeb.aca.gov.ly/',
            iconData: Icons.edit_note,
          ),
          DirAction.web(
            'معلومات البلاغ',
            'https://www.aca.gov.ly/public/complaint_report',
            iconData: Icons.info_outline,
          ),
          DirAction.web(
            'الموقع الرسمي للهيئة',
            'https://www.aca.gov.ly/',
            iconData: Icons.account_balance,
          ),
        ],
      ),
      DirItem.web(
        'مركز الاتصال المحلي',
        'خدمة وزارة الحكم المحلي للبلاغات والشكاوى العاجلة وربط المواطن بالجهات المحلية.',
        'https://www.lgm.gov.ly/',
        id: 'complaint-local-call',
        official: true,
        source: 'وزارة الحكم المحلي',
        sourceUrl: 'https://www.lgm.gov.ly/1415/terms',
        verifiedAt: _verified,
        actions: [
          DirAction.app(
            'تطبيق مركز الاتصال المحلي',
            package: 'ly.gov.lgm.callcenter',
            iconData: Icons.phone_android,
          ),
          DirAction.phone('مركز الاتصال المحلي 1415', '1415'),
          DirAction.web('الموقع الرسمي', 'https://www.lgm.gov.ly/'),
        ],
      ),
      DirItem.web(
        'مصلحة الجمارك - الشكاوى والتواصل',
        'الاستفسارات والملاحظات والشكاوى ونموذج التواصل مع مصلحة الجمارك.',
        'https://customs.gov.ly/contact-us/',
        id: 'complaint-customs',
        official: true,
        source: 'مصلحة الجمارك الليبية',
        sourceUrl: 'https://customs.gov.ly/contact-us/',
        verifiedAt: _verified,
        actions: [
          DirAction.web(
            'نموذج التواصل والشكاوى',
            'https://customs.gov.ly/contact-us/',
            iconData: Icons.feedback_outlined,
          ),
          DirAction.phone('اتصال بالجمارك +218 21 491 7821', '+218214917821'),
          DirAction.web(
            'أخبار الجمارك',
            'https://customs.gov.ly/news/',
            iconData: Icons.newspaper_outlined,
          ),
        ],
      ),
      DirItem.web(
        'الشركة العامة للكهرباء - بلاغات الأعطال',
        'الموقع الرسمي ورقم البلاغات للأعطال والحالات الكهربائية الطارئة.',
        'https://www.gecol.ly/',
        id: 'complaint-gecol',
        official: true,
        source: 'الشركة العامة للكهرباء',
        sourceUrl: 'https://www.gecol.ly/',
        verifiedAt: _verified,
        actions: [
          DirAction.phone('بلاغات الأعطال 1418', '1418', iconData: Icons.call),
          DirAction.web('الموقع الرسمي', 'https://www.gecol.ly/'),
          DirAction.web(
            'الاستعلام عن الفاتورة',
            'https://www.gecol.ly/Home/BalanceInquiry',
            iconData: Icons.receipt_long_outlined,
          ),
        ],
      ),
      DirItem.web(
        'المدار الجديد - خدمة العملاء',
        'مركز المساعدة وخدمة العملاء وخدمات الدفع المرتبطة بالمدار الجديد.',
        'https://customercare.almadar.ly/hc/ar',
        id: 'complaint-almadar',
        official: true,
        source: 'المدار الجديد',
        sourceUrl: 'https://customercare.almadar.ly/hc/ar',
        verifiedAt: _verified,
        actions: [
          DirAction.web(
            'مركز المساعدة',
            'https://customercare.almadar.ly/hc/ar',
            iconData: Icons.support_agent,
          ),
          DirAction.phone('خدمة العملاء 1211', '1211'),
          DirAction.phone(
            'دعم سداد 1216',
            '1216',
            iconData: Icons.payments_outlined,
          ),
        ],
      ),
    ]),
  ]),

  // -------------------------------------------------------------------------
  // المصارف
  // -------------------------------------------------------------------------
  DirSection('banks', Icons.account_balance_wallet, const Color(0xFF00796B), [
    const DirGroup('المصرف المركزي', [
      DirItem.web(
        'مصرف ليبيا المركزي',
        'الموقع الرسمي.',
        _cbl,
        id: 'bank-cbl',
        official: true,
        source: 'مصرف ليبيا المركزي',
        sourceUrl: _cbl,
        verifiedAt: _verified,
      ),
      DirItem.web(
        'أسعار الصرف الرسمية',
        'الأسعار اليومية المنشورة من مصرف ليبيا المركزي.',
        'https://cbl.gov.ly/currency-exchange-rates/',
        id: 'bank-cbl-rates',
        official: true,
        source: 'مصرف ليبيا المركزي',
        sourceUrl: 'https://cbl.gov.ly/currency-exchange-rates/',
        verifiedAt: _verified,
      ),
      DirItem.web(
        'دليل المصارف التجارية',
        'قائمة المصارف التجارية المرخصة كما يعرضها المصرف المركزي.',
        'https://cbl.gov.ly/banks/',
        id: 'bank-directory',
        official: true,
        source: 'مصرف ليبيا المركزي',
        sourceUrl: 'https://cbl.gov.ly/banks/',
        verifiedAt: _verified,
      ),
    ]),
    DirGroup('المصارف التجارية - بطاقات شاملة', [
      _bank(
        id: 'bank-nubank',
        title: 'مصرف الاتحاد الوطني',
        website: 'https://nubank.ly/wp/',
        phone: '+218910756655',
        appName: 'National Union Bank',
      ),
      _bank(
        id: 'bank-imaar',
        title: 'مصرف إعمار',
        website: 'https://imaarbank.ly/',
        phone: '+218912957777',
        appName: 'Imaar Bank',
      ),
      _bank(
        id: 'bank-ifb',
        title: 'مصرف التمويل الإسلامي',
        website: 'https://ifb.ly/ar/',
        phone: '+218920818181',
        appName: 'IFB Digital bank',
        package: 'org.android.ifb',
      ),
      _bank(
        id: 'bank-dib',
        title: 'مصرف الضمان الإسلامي',
        website: 'https://dib.ly/',
        phone: '+218918765555',
        appName: 'الضمان موبايل',
        package: 'com.mitt.aldamanislami',
        extraActions: [
          const DirAction.app('Daman 360', package: 'com.mitf.DIBBusiness'),
        ],
      ),
      _bank(
        id: 'bank-sib',
        title: 'مصرف السراج الإسلامي',
        website: 'https://sib.com.ly/',
        phone: '+218912502709',
        appName: 'Al Seraj Mobile',
        package: 'com.mitt.alserajmobile',
        extraActions: [
          const DirAction.app('Al Seraj Pay', package: 'com.mitt.alserajpay'),
        ],
      ),
      _bank(
        id: 'bank-aiib',
        title: 'مصرف الاستثمار العربي الإسلامي',
        website: 'https://aiib.ly/',
        phone: '+218913845001',
        appName: 'AIIB Mobile',
      ),
      _bank(
        id: 'bank-jbank',
        title: 'مصرف الجمهورية',
        website: 'https://www.jbank.ly/',
        phone: '+218214442541',
        appName: 'مصرفي بلس',
        package: 'mitt.JamBank',
        extraActions: [
          const DirAction.app('مصرفي أعمال', package: 'com.mitt.Jumbusiness'),
          const DirAction.app('مصرفي باي', package: 'ly.mitf.musrefypay'),
        ],
        serviceUrl: 'https://www.jbank.ly/ar/e-service/electronic-services/masrifi-plus/',
        serviceLabel: 'مصرفي بلس',
      ),
      _bank(
        id: 'bank-ncb',
        title: 'المصرف التجاري الوطني',
        website: 'https://www.ncb.ly/',
        phone: '+218694630006',
        appName: 'موبي مال',
        extraActions: [
          const DirAction.app('NCB Business', package: 'mitt.NCBBusiness'),
        ],
        serviceUrl: 'https://www.ncb.ly/ar/personal/mobi-mal/',
        serviceLabel: 'موبي مال',
      ),
      _bank(
        id: 'bank-wahda',
        title: 'مصرف الوحدة',
        website: 'https://www.wahdabank.com/',
        phone: '+218612231315',
        appName: 'Wahda Bank',
        package: 'com.wahda.obdxmobileapp',
        extraActions: [
          const DirAction.app(
            'الوحدة موبايل - توا',
            package: 'com.wahdabank.future',
          ),
        ],
      ),
      _bank(
        id: 'bank-sahara',
        title: 'مصرف الصحارى',
        website: 'https://www.saharabank.ly/',
        phone: '+218213337182',
        appName: 'صحارى موبايل',
        package: 'com.mitf.SaharaMobile',
      ),
      _bank(
        id: 'bank-bcd',
        title: 'مصرف التجارة والتنمية',
        website: 'https://www.bcd.ly/',
        phone: '+218512239206',
        appName: 'BCD Digital Bank',
        package: 'com.tedmob.bcd',
        serviceUrl:
            'https://play.google.com/store/apps/details?id=edfal.bcd.ly',
        serviceLabel: 'ادفع لي',
      ),
      _bank(
        id: 'bank-nab',
        title: 'مصرف شمال أفريقيا',
        website: 'https://www.nab.ly/',
        phone: '+218902524510',
        appName: 'NAB Mobile',
        package: 'ly.nab.nabmobileapp',
      ),
      _bank(
        id: 'bank-aman',
        title: 'مصرف الأمان للتجارة والاستثمار',
        website: 'https://www.aman-bank.com/',
        phone: '+218214780025',
        appName: 'Aman Mobile',
        extraActions: [
          const DirAction.app(
            'Aman Secure',
            package: 'com.ofss.amanbank.authenticator',
          ),
        ],
      ),
      _bank(
        id: 'bank-ejmaa',
        title: 'مصرف الإجماع العربي',
        website: 'https://ejmaa.aabank.ly/',
        phone: '+218619090128',
        appName: 'Alejma’a Alarabi Bank',
      ),
      _bank(
        id: 'bank-lfb',
        title: 'المصرف الليبي الخارجي',
        website: 'https://www.lfb.ly/',
        phone: '+218213350155',
        appName: 'Libyan Foreign Bank',
      ),
      _bank(
        id: 'bank-fg',
        title: 'مصرف الخليج الأول الليبي',
        website: 'https://www.bankfab.com/ar-ly/',
        phone: '+21836322262',
        appName: 'First Gulf Libyan Bank',
      ),
      _bank(
        id: 'bank-waha',
        title: 'مصرف الواحة',
        website: 'https://www.alwahabank.ly/',
        phone: '+218213513490',
        appName: 'Alwaha Pay',
        package: 'com.mitt.WahaMobile',
      ),
      _bank(
        id: 'bank-ubci',
        title: 'المصرف المتحد للتجارة والاستثمار',
        website: 'https://www.ubci-libya.com/',
        phone: '+218910052333',
        appName: 'UBCI Mobile',
      ),
      _bank(
        id: 'bank-assaray',
        title: 'مصرف السراي للتجارة والاستثمار',
        website: 'https://www.atib.ly/',
        phone: '+218213660780',
        appName: 'ATIB Mobile',
      ),
      _bank(
        id: 'bank-medit',
        title: 'مصرف المتوسط',
        website: 'https://www.meditbank.ly/',
        phone: '+218619082161',
        appName: 'المصرف الذكي من المتوسط',
      ),
      _bank(
        id: 'bank-nuran',
        title: 'مصرف النوران',
        website: 'https://www.nub.ly/',
        phone: '+218213351460',
        appName: 'Nuran Mobile',
        package: 'ly.nub.app',
      ),
      _bank(
        id: 'bank-wafa',
        title: 'مصرف الوفاء',
        website: 'https://www.alwafabank.com/',
        phone: '+218214815139',
        appName: 'Alwafa Mobile',
      ),
      _bank(
        id: 'bank-tadhamon',
        title: 'مصرف التضامن',
        website: 'https://www.tab.ly/',
        phone: '+218213620292',
        appName: 'محفظتي',
        package: 'com.tiib.mahfathati',
      ),
      _bank(
        id: 'bank-lib',
        title: 'المصرف الإسلامي الليبي',
        website: 'https://www.lib.com.ly/',
        phone: '+218214440035',
        appName: 'DIGITAL LIB',
        package: 'com.lib.retail',
        serviceUrl:
            'https://play.google.com/store/apps/details?id=com.lib.business',
        serviceLabel: 'Digital LIB Corporate',
      ),
      _bank(
        id: 'bank-yaqeen',
        title: 'مصرف اليقين',
        website: 'https://www.yaqeenbank.ly/',
        phone: '+218213623501',
        appName: 'Al Yaqeen Bank',
        package: 'com.profinch.yaqeen',
        serviceUrl: 'https://play.google.com/store/apps/details?id=com.yaqeen_mastercard',
        serviceLabel: 'Yaqeen Mastercard',
      ),
      _bank(
        id: 'bank-andalus',
        title: 'مصرف الأندلس',
        website: 'https://www.andalusbank.com/',
        phone: '+218214445024',
        appName: 'Andalus Mobile',
        package: 'ly.andaa.app',
      ),
    ]),
    const DirGroup('محافظ ودفع إلكتروني خارج بطاقات المصارف', [
      DirItem.app(
        'مسارات للخدمات المالية',
        'منصة/خدمات تقنية مالية تدعم خدمات مصرفية ودفع لعدة جهات.',
        searchName: 'مسارات للخدمات المالية ليبيا',
        id: 'item-dacf0a7374',
      ),
      DirItem.app(
        'ماتل موني',
        'محفظة مالية إلكترونية.',
        searchName: 'ماتل موني ليبيا',
        id: 'item-26455237ab',
      ),
      DirItem.app(
        'سداد',
        'خدمة دفع إلكتروني مرتبطة بخدمات المدار.',
        searchName: 'سداد ليبيا المدار',
        id: 'item-a8436ce4b2',
      ),
      DirItem.app(
        'iCard',
        'خدمات شحن ودفع إلكتروني.',
        searchName: 'iCard ليبيا',
        id: 'item-b3c639f4cc',
      ),
    ]),
  ]),

  // -------------------------------------------------------------------------
  // اتصالات وإنترنت
  // -------------------------------------------------------------------------
  const DirSection('telecom', Icons.cell_tower, Color(0xFF3949AB), [
    DirGroup('المشغلون والاتصالات', [
      DirItem.web(
        'المدار الجديد',
        'الموقع وخدمات العملاء والخدمات المباشرة والدعم.',
        'https://almadar.ly/',
        id: 'telecom-almadar',
        official: true,
        source: 'المدار الجديد',
        sourceUrl: 'https://almadar.ly/',
        verifiedAt: _verified,
        actions: [
          DirAction.web('الموقع', 'https://almadar.ly/'),
          DirAction.web(
            'مركز المساعدة',
            'https://customercare.almadar.ly/hc/ar',
            iconData: Icons.support_agent,
          ),
          DirAction.web(
            'مركز التطبيق والخدمات',
            'https://customercare.almadar.ly/hc/ar',
            iconData: Icons.download,
          ),
          DirAction.phone(
            'خدمة العملاء 1211/1213',
            '1211',
            iconData: Icons.call,
          ),
          DirAction.phone(
            'دعم سداد 1216',
            '1216',
            iconData: Icons.payments_outlined,
          ),
        ],
      ),
      DirItem.web(
        'ليبيانا',
        'الموقع الرسمي وخدمات الشركة.',
        'https://libyana.ly/',
        id: 'telecom-libyana',
        official: true,
        source: 'ليبيانا',
        sourceUrl: 'https://libyana.ly/',
        verifiedAt: _verified,
      ),
      DirItem.web(
        'الشركة القابضة للاتصالات',
        'الشركة الأم لشركات الاتصالات الحكومية.',
        'https://lptic.ly/',
        id: 'telecom-lptic',
        official: true,
        source: 'الشركة القابضة للاتصالات',
        sourceUrl: 'https://lptic.ly/',
        verifiedAt: _verified,
      ),
      DirItem.web(
        'ليبيا للاتصالات والتقنية LTT',
        'خدمات الإنترنت والاتصالات وتقنية المعلومات.',
        'https://ltt.ly/',
        id: 'telecom-ltt',
        official: true,
        source: 'LTT',
        sourceUrl: 'https://ltt.ly/',
        verifiedAt: _verified,
      ),
      DirItem.web(
        'العنكبوت الليبي',
        'استضافة ودومينات وخدمات رقمية.',
        'https://libyanspider.com/',
        id: 'telecom-spider',
        source: 'الموقع الرسمي',
        sourceUrl: 'https://libyanspider.com/',
        verifiedAt: _verified,
      ),
    ]),
  ]),

  // -------------------------------------------------------------------------
  // الجمارك والسفر
  // -------------------------------------------------------------------------
  DirSection('travel', Icons.flight, const Color(0xFF0288D1), [
    const DirGroup('المطارات والطيران', [
      DirItem.web(
        'مصلحة المطارات',
        'الموقع الرسمي للمطارات والأخبار والإعلانات وبيانات الحركة.',
        'https://laa.gov.ly/',
        id: 'travel-airports',
        official: true,
        source: 'مصلحة المطارات',
        sourceUrl: 'https://laa.gov.ly/',
        verifiedAt: _verified,
        actions: [
          DirAction.web('الموقع', 'https://laa.gov.ly/'),
          DirAction.web(
            'الأخبار',
            'https://laa.gov.ly/category/news/',
            iconData: Icons.newspaper_outlined,
          ),
        ],
      ),
      DirItem.web(
        'الخطوط الجوية الأفريقية',
        'الحجز والرحلات والخدمات.',
        'https://afriqiyah.aero/',
        id: 'item-22f93a6c42',
      ),
      DirItem.web(
        'الخطوط الجوية الليبية',
        'الناقل الوطني والحجز والرحلات.',
        'https://libyanairlines.aero/',
        id: 'item-a24cfb366d',
      ),
    ]),
    DirGroup('الجمارك والمنافذ', [
      const DirItem.web(
        'مصلحة الجمارك الليبية',
        'الموقع الرسمي للخدمات الجمركية والأخبار والتعريفة والمنافذ.',
        'https://customs.gov.ly/',
        id: 'travel-customs',
        official: true,
        source: 'مصلحة الجمارك الليبية',
        sourceUrl: 'https://customs.gov.ly/',
        verifiedAt: _verified,
        actions: [
          DirAction.web('الموقع', 'https://customs.gov.ly/'),
          DirAction.web(
            'الخدمات الجمركية',
            'https://customs.gov.ly/services/',
            iconData: Icons.apps_outlined,
          ),
          DirAction.web(
            'البوابة الإلكترونية',
            'https://e-portal.customs.gov.ly/',
            iconData: Icons.language,
          ),
          DirAction.web(
            'الأسيكودا / ACI / AEO',
            'https://customs.gov.ly/services/',
            iconData: Icons.local_shipping_outlined,
          ),
        ],
      ),
      DirItem.web(
        'الموانئ والنقل البحري',
        'بحث الوصول إلى الجهات والجهات المينائية والخدمات البحرية في ليبيا.',
        "https://www.google.com/search?q=${Uri.encodeComponent('الموانئ والنقل البحري ليبيا')}",
        id: 'travel-maritime',
        official: false,
        source: 'بحث عام - تحقق من الجهة قبل استخدام أي خدمة',
        verifiedAt: _verified,
      ),
    ]),
  ]),

  // -------------------------------------------------------------------------
  // الطاقة والنفط
  // -------------------------------------------------------------------------
  DirSection('energy', Icons.bolt, const Color(0xFFF9A825), [
    const DirGroup('الكهرباء', [
      DirItem.web(
        'الشركة العامة للكهرباء',
        'الموقع الرسمي والبلاغات وأخبار الشبكة.',
        'https://www.gecol.ly/',
        id: 'energy-gecol',
        official: true,
        source: 'الشركة العامة للكهرباء',
        sourceUrl: 'https://www.gecol.ly/',
        verifiedAt: _verified,
        actions: [
          DirAction.web('الموقع الرسمي', 'https://www.gecol.ly/'),
          DirAction.web(
            'الاستعلام عن الفاتورة',
            'https://www.gecol.ly/Home/BalanceInquiry',
            iconData: Icons.receipt_long_outlined,
          ),
          DirAction.phone('بلاغات الأعطال 1418', '1418'),
        ],
      ),
    ]),
    DirGroup('النفط والغاز', [
      DirItem.web(
        'المؤسسة الوطنية للنفط NOC',
        'الأخبار والبيانات وأسعار النفط والشركات التابعة والعطاءات.',
        'https://noc.ly/',
        id: 'energy-noc',
        official: true,
        source: 'المؤسسة الوطنية للنفط',
        sourceUrl: 'https://noc.ly/',
        verifiedAt: _verified,
        actions: [
          const DirAction.web('الموقع', 'https://noc.ly/'),
          DirAction.web(
            'الأخبار',
            "https://www.google.com/search?q=${Uri.encodeComponent('site:noc.ly ليبيا المؤسسة الوطنية للنفط أخبار')}",
            iconData: Icons.newspaper_outlined,
          ),
          DirAction.web(
            'العطاءات',
            "https://www.google.com/search?q=${Uri.encodeComponent('site:noc.ly ليبيا المؤسسة الوطنية للنفط عطاءات')}",
            iconData: Icons.description_outlined,
          ),
        ],
      ),
      const DirItem.web(
        'شركة البريقة لتسويق النفط',
        'الموقع الرسمي والأخبار وخدمات تسويق وتوزيع المنتجات النفطية.',
        'https://brega.ly/',
        id: 'energy-brega',
        official: true,
        source: 'شركة البريقة لتسويق النفط',
        sourceUrl: 'https://brega.ly/',
        verifiedAt: _verified,
        actions: [
          DirAction.web('الموقع الرسمي', 'https://brega.ly/'),
          DirAction.web(
            'الأخبار',
            'https://brega.ly/',
            iconData: Icons.newspaper_outlined,
          ),
        ],
      ),
    ]),
  ]),

  // -------------------------------------------------------------------------
  // الصحة
  // -------------------------------------------------------------------------
  const DirSection('health', Icons.local_hospital, Color(0xFFC62828), [
    DirGroup('وزارة الصحة والمراكز التابعة', [
      DirItem.web(
        'وزارة الصحة الليبية',
        'الموقع الرسمي والمرافق والمراكز والخدمات الإلكترونية والأخبار.',
        'https://moh.gov.ly/',
        id: 'health-moh',
        official: true,
        source: 'وزارة الصحة الليبية',
        sourceUrl: 'https://moh.gov.ly/',
        verifiedAt: _verified,
        actions: [
          DirAction.web('الموقع', 'https://moh.gov.ly/'),
          DirAction.web(
            'المراكز والمكاتب',
            'https://moh.gov.ly/',
            iconData: Icons.local_hospital_outlined,
          ),
          DirAction.web(
            'خدمات الصيدلة',
            'https://pharmacy.moh.gov.ly/',
            iconData: Icons.medication_outlined,
          ),
        ],
      ),
      DirItem.web(
        'مركز طب الطوارئ والدعم',
        'الاستجابة الطبية للطوارئ والبلاغات.',
        'https://moh.gov.ly/',
        id: 'health-emergency-center',
        official: true,
        source: 'وزارة الصحة الليبية',
        sourceUrl: 'https://moh.gov.ly/',
        verifiedAt: _verified,
        actions: [
          DirAction.phone('غرفة الطوارئ 1412', '1412'),
          DirAction.web('مصدر رسمي', 'https://moh.gov.ly/'),
        ],
      ),
      DirItem.web(
        'المركز الوطني لمكافحة الأمراض',
        'الموقع الرسمي للمركز ومعلومات الوقاية والمراكز الصحية وصحة المسافرين.',
        'https://ncdc.org.ly/Ar/',
        id: 'health-ncdc',
        official: true,
        source: 'المركز الوطني لمكافحة الأمراض',
        sourceUrl: 'https://ncdc.org.ly/Ar/',
        verifiedAt: _verified,
        actions: [
          DirAction.web('الموقع الرسمي', 'https://ncdc.org.ly/Ar/'),
          DirAction.web(
            'المراكز الصحية',
            'https://ncdc.org.ly/Ar/',
            iconData: Icons.local_hospital_outlined,
          ),
          DirAction.web(
            'صحة المسافرين',
            'https://ncdc.org.ly/Ar/',
            iconData: Icons.flight_outlined,
          ),
        ],
      ),
      DirItem.web(
        'دليل ليبيا الطبي',
        'دليل أطباء ومرافق صحية.',
        'https://lmd.ly/',
        id: 'health-lmd',
        source: 'دليل طبي',
        sourceUrl: 'https://lmd.ly/',
        verifiedAt: _verified,
      ),
    ]),
  ]),

  // -------------------------------------------------------------------------
  // التعليم والعمل
  // -------------------------------------------------------------------------
  const DirSection('edu', Icons.school, Color(0xFF6A1B9A), [
    DirGroup('التعليم والامتحانات', [
      DirItem.web(
        'وزارة التربية والتعليم',
        'الامتحانات والنتائج والتسجيل والأخبار.',
        'https://moe.gov.ly/',
        id: 'edu-moe',
        official: true,
        source: 'وزارة التربية والتعليم',
        sourceUrl: 'https://moe.gov.ly/',
        verifiedAt: _verified,
      ),
      DirItem.web(
        'المركز الوطني للامتحانات - النتائج',
        'الاستعلام عن نتائج الشهادات وفق النظام المتاح.',
        'https://finalresults.nec.gov.ly/',
        id: 'edu-results',
        official: true,
        source: 'المركز الوطني للامتحانات',
        sourceUrl: 'https://finalresults.nec.gov.ly/',
        verifiedAt: _verified,
      ),
    ]),
    DirGroup('جامعات ومنصات', [
      DirItem.app(
        'الجامعة الليبية',
        'خدمات جامعية.',
        searchName: 'الجامعة الليبية',
        id: 'item-3377f53ab6',
      ),
      DirItem.app(
        'أكاديميك ليبيا',
        'خدمات أكاديمية للطلبة.',
        searchName: 'أكاديميك ليبيا',
        id: 'item-c71b93194b',
      ),
      DirItem.app(
        'منصة لبيب التعليمية',
        'منصة تعليمية.',
        searchName: 'لبيب ليبيا',
        id: 'item-007c37b291',
      ),
      DirItem.app(
        'أكاديمية التعليم المفتوح',
        'دورات ومنصات تعليمية.',
        searchName: 'أكاديمية التعليم المفتوح ليبيا',
        id: 'item-c136af0584',
      ),
    ]),
  ]),

  DirSection('jobs', Icons.work, const Color(0xFF303F9F), [
    DirGroup('وظائف رسمية ومنصات', [
      const DirItem.web(
        'مصرف ليبيا المركزي - الوظائف',
        'إعلانات التوظيف الرسمية.',
        'https://cbl.gov.ly/career/',
        official: true,
        source: 'مصرف ليبيا المركزي',
        sourceUrl: _cbl,
        verifiedAt: _verified,
        id: 'item-493c8ddf51',
      ),
      const DirItem.web(
        'المؤسسة الوطنية للنفط',
        'الموقع الرسمي وفرص العمل/الأخبار والإعلانات.',
        'https://noc.ly/',
        official: true,
        source: 'المؤسسة الوطنية للنفط',
        sourceUrl: 'https://noc.ly/',
        verifiedAt: _verified,
        id: 'item-d0e4ae2a4d',
      ),
      const DirItem.web(
        'LinkedIn - وظائف ليبيا',
        'وظائف من شركات ومنظمات.',
        'https://www.linkedin.com/jobs/search/?location=Libya',
        id: 'item-6a2588fc96',
      ),
      const DirItem.web(
        'ReliefWeb - وظائف ليبيا',
        'وظائف المنظمات الدولية في ليبيا.',
        'https://reliefweb.int/jobs?search=libya',
        id: 'item-1b076cc1ef',
      ),
      DirItem.web(
        'بحث وظائف ليبيا',
        'بحث عام عن الوظائف المفتوحة.',
        "https://www.google.com/search?q=${Uri.encodeComponent('وظائف ليبيا')}",
        id: 'item-509c12ba4f',
      ),
    ]),
    const DirGroup('تطبيقات الوظائف', [
      DirItem.app(
        'صبّار',
        'منصة توظيف.',
        searchName: 'صبار وظائف ليبيا',
        id: 'item-8014389d53',
      ),
      DirItem.app(
        'وظفني Wzfni',
        'البحث عن الوظائف.',
        searchName: 'Wzfni ليبيا',
        id: 'item-4e60e8d2ba',
      ),
    ]),
  ]),

  // -------------------------------------------------------------------------
  // أخبار الدولة والإعلام
  // -------------------------------------------------------------------------
  const DirSection('news', Icons.newspaper, Color(0xFFD84315), [
    DirGroup('مصادر رسمية', [
      DirItem.web(
        'وكالة الأنباء الليبية - وال',
        'المصدر الإخباري الرسمي للأخبار الليبية.',
        'https://lana.gov.ly/?lang=ar',
        id: 'news-lana',
        official: true,
        source: 'وكالة الأنباء الليبية',
        sourceUrl: 'https://lana.gov.ly/?lang=ar',
        verifiedAt: _verified,
      ),
      DirItem.web(
        'مجلس النواب - أخبار',
        'الأخبار والجلسات والبيانات من الموقع الرسمي للمجلس.',
        'https://parl.ly/',
        official: true,
        source: 'مجلس النواب',
        sourceUrl: 'https://parl.ly/',
        verifiedAt: _verified,
        id: 'item-4e8ae5953f',
      ),
      DirItem.web(
        'المجلس الأعلى للدولة - أخبار',
        'الأخبار والبيانات والمواد الإعلامية.',
        'https://hcs.gov.ly/',
        official: true,
        source: 'المجلس الأعلى للدولة',
        sourceUrl: 'https://hcs.gov.ly/',
        verifiedAt: _verified,
        id: 'item-ff0975f7f0',
      ),
      DirItem.web(
        'وزارة الدفاع - آخر الأخبار',
        'آخر الأخبار المنشورة رسميًا من وزارة الدفاع.',
        'https://www.mod.gov.ly/category/last-news/',
        official: true,
        source: 'وزارة الدفاع الليبية',
        sourceUrl: 'https://www.mod.gov.ly/category/last-news/',
        verifiedAt: _verified,
        id: 'item-b358bbcc3b',
      ),
      DirItem.web(
        'ديوان المحاسبة - الأخبار',
        'أخبار وتقارير الجهة الرقابية الرسمية.',
        'https://www.audit.gov.ly/ar/',
        official: true,
        source: 'ديوان المحاسبة',
        sourceUrl: 'https://www.audit.gov.ly/ar/',
        verifiedAt: _verified,
        id: 'item-062abd4146',
      ),
      DirItem.web(
        'مصرف ليبيا المركزي - الأخبار',
        'الأخبار والبيانات المصرفية.',
        'https://cbl.gov.ly/blog/',
        official: true,
        source: 'مصرف ليبيا المركزي',
        sourceUrl: 'https://cbl.gov.ly/blog/',
        verifiedAt: _verified,
        id: 'item-3d5cfde049',
      ),
      DirItem.web(
        'مصلحة المطارات - الأخبار',
        'آخر أخبار المطارات والإعلانات التشغيلية.',
        'https://laa.gov.ly/',
        official: true,
        source: 'مصلحة المطارات',
        sourceUrl: 'https://laa.gov.ly/',
        verifiedAt: _verified,
        id: 'item-71a70ebbca',
      ),
      DirItem.web(
        'مصلحة الجمارك - الأخبار',
        'آخر مستجدات الجمارك.',
        'https://customs.gov.ly/',
        official: true,
        source: 'مصلحة الجمارك',
        sourceUrl: 'https://customs.gov.ly/',
        verifiedAt: _verified,
        id: 'item-7dafb652fe',
      ),
      DirItem.web(
        'وزارة الصحة - الأخبار',
        'أخبار وخدمات وزارة الصحة.',
        'https://moh.gov.ly/',
        official: true,
        source: 'وزارة الصحة',
        sourceUrl: 'https://moh.gov.ly/',
        verifiedAt: _verified,
        id: 'item-a1ba743f53',
      ),
      DirItem.web(
        'المؤسسة الوطنية للنفط - الأخبار',
        'الأخبار والبيانات الرسمية لقطاع النفط.',
        'https://noc.ly/',
        official: true,
        source: 'المؤسسة الوطنية للنفط',
        sourceUrl: 'https://noc.ly/',
        verifiedAt: _verified,
        id: 'item-a705bc27c7',
      ),
      DirItem.web(
        'وزارة الخارجية - الأخبار',
        'الأخبار والبيانات والبعثات والخدمات القنصلية.',
        'https://foreign.gov.ly/MOFA/',
        official: true,
        source: 'وزارة الخارجية والتعاون الدولي',
        sourceUrl: 'https://foreign.gov.ly/MOFA/',
        verifiedAt: _verified,
        id: 'item-2aef4d8c19',
      ),
      DirItem.web(
        'وزارة العدل - الأخبار والقوانين',
        'الأخبار والقوانين والقرارات والجهات التابعة.',
        'https://aladel.gov.ly/home/',
        official: true,
        source: 'وزارة العدل',
        sourceUrl: 'https://aladel.gov.ly/home/',
        verifiedAt: _verified,
        id: 'item-0cc43205a6',
      ),
      DirItem.web(
        'وزارة المالية - المركز الإعلامي',
        'أخبار الوزارة والملفات المالية والجهات التابعة.',
        'https://mof.gov.ly/blog/',
        official: true,
        source: 'وزارة المالية',
        sourceUrl: 'https://mof.gov.ly/blog/',
        verifiedAt: _verified,
        id: 'item-6073d1a744',
      ),
      DirItem.web(
        'وزارة العمل - الأخبار',
        'أخبار الوزارة وإعلانات وخدمات التشغيل.',
        'https://labour.gov.ly/',
        official: true,
        source: 'وزارة العمل والتأهيل',
        sourceUrl: 'https://labour.gov.ly/',
        verifiedAt: _verified,
        id: 'item-39b37067a1',
      ),
      DirItem.web(
        'وزارة التعليم العالي - الأخبار',
        'الأخبار والخدمات الجامعية والبحث العلمي.',
        'https://www.mohe.edu.ly/',
        official: true,
        source: 'وزارة التعليم العالي والبحث العلمي',
        sourceUrl: 'https://www.mohe.edu.ly/',
        verifiedAt: _verified,
        id: 'item-2bbd56e0a3',
      ),
      DirItem.web(
        'وزارة الحكم المحلي - الأخبار',
        'أخبار الإدارة المحلية والبلديات والخدمات المحلية.',
        'https://www.lgm.gov.ly/',
        official: true,
        source: 'وزارة الحكم المحلي',
        sourceUrl: 'https://www.lgm.gov.ly/',
        verifiedAt: _verified,
        id: 'item-8aa9425d09',
      ),
    ]),
    DirGroup('إعلام ليبي مستقل', [
      DirItem.web(
        'بوابة الوسط',
        'أخبار ليبيا وتقاريرها.',
        'https://alwasat.ly/',
        id: 'item-66f316301d',
      ),
      DirItem.web(
        'عين ليبيا',
        'أخبار وتقارير وأسعار.',
        'https://www.eanlibya.com/',
        id: 'item-0c50f95937',
      ),
      DirItem.web(
        'ليبيا هيرالد',
        'أخبار ليبيا بالإنجليزية.',
        'https://libyaherald.com/',
        id: 'item-47d2a04ba3',
      ),
      DirItem.web(
        'ليبيا أوبزرفر',
        'أخبار ليبيا بالإنجليزية والعربية.',
        'https://www.libyaobserver.ly/',
        id: 'item-9a5631ff2d',
      ),
      DirItem.web(
        'ليبيا ريفيو',
        'أخبار وتحليلات باللغة الإنجليزية.',
        'https://libyareview.com/',
        id: 'item-2e109528f8',
      ),
      DirItem.web(
        'المرصد',
        'أخبار وتقارير ليبية.',
        'https://almarsad.co/',
        id: 'item-78f4d41312',
      ),
      DirItem.web(
        'ليبيا الأحرار',
        'أخبار ومواد إعلامية.',
        'https://libyaalahrar.net/',
        id: 'item-dac6d9d2c8',
      ),
    ]),
  ]),

  // -------------------------------------------------------------------------
  // التجارة والتسوق والنقل والعقارات
  // -------------------------------------------------------------------------
  const DirSection('stores', Icons.storefront, Color(0xFFEF6C00), [
    DirGroup('تسوق إلكتروني', [
      DirItem.web(
        'باهي',
        'متجر إلكتروني ليبي.',
        'https://baahy.com/',
        id: 'item-689834b505',
      ),
      DirItem.web(
        'النورس',
        'سوق إلكتروني.',
        'https://nawris.net/',
        id: 'item-ca5cc89ee6',
      ),
      DirItem.web(
        'المستودع',
        'متجر إلكتروني.',
        'https://big.ly/',
        id: 'item-04535d42f0',
      ),
      DirItem.web(
        'تسوق ليبيا',
        'متجر وتوصيل داخل ليبيا.',
        'https://www.shoppinglibya.com/',
        id: 'item-dba75ef010',
      ),
      DirItem.web(
        'Ubuy Libya',
        'منتجات دولية إلى ليبيا.',
        'https://www.ubuy.com.ly/ar/',
        id: 'item-17751e5aa3',
      ),
    ]),
  ]),
];

/// الأقسام الحالية (المضمّنة + أي تحديث من المحتوى البعيد).
List<DirSection> get directorySections => ContentStore.instance.sections;

String sectionTitle(DirSection s) {
  final key = 'sec_${s.id}';
  final t = key.tr();
  return t == key ? (s.title ?? s.id) : t;
}

String sectionSubtitle(DirSection s) {
  final key = 'sub_${s.id}';
  final t = key.tr();
  return t == key ? (s.subtitle ?? '') : t;
}

List<DirItem> allDirectoryItems() => [
  for (final s in directorySections)
    for (final g in s.groups) ...g.items,
];

DirSection? sectionById(String id) {
  for (final s in directorySections) {
    if (s.id == id) return s;
  }
  return null;
}

/// أرقام الطوارئ. الأرقام التي لم نجد لها تأكيداً رسميًا حديثًا تحمل وسمًا
/// يطلب التحقق محليًا، بينما 1412 و1418 مرتبطان بمصادر رسمية منشورة.
const List<DirItem> emergencyNumbers = [
  DirItem.phone(
    'الشرطة',
    'رقم متداول للشرطة في ليبيا؛ يُنصح بالتأكد محليًا حسب المنطقة.',
    '1515',
    id: 'emergency-police',
    official: false,
    source: 'أدلة طوارئ خارجية',
    sourceUrl: 'https://cesr.sesric.org/cif-ar.php?c_code=26',
    verifiedAt: '2026-06',
    tag: 'emergency',
  ),
  DirItem.phone(
    'الإسعاف',
    'رقم طوارئ الإسعاف المتداول على مصادر الطوارئ العامة؛ تحقق محليًا.',
    '193',
    id: 'emergency-ambulance',
    official: false,
    source: 'أدلة طوارئ خارجية',
    sourceUrl: 'https://cesr.sesric.org/cif-ar.php?c_code=26',
    verifiedAt: '2026-06',
    tag: 'emergency',
  ),
  DirItem.phone(
    'مركز طب الطوارئ والدعم',
    'رقم مجاني لغرفة الطوارئ والبلاغات، يعمل على مدار الساعة بحسب إعلان رسمي منشور عبر وكالة الأنباء الليبية.',
    '1412',
    id: 'emergency-1412',
    official: true,
    source: 'وكالة الأنباء الليبية نقلًا عن مركز طب الطوارئ والدعم',
    sourceUrl: 'https://lana.gov.ly/post.php?id=366252&lang=ar',
    verifiedAt: '2026-09-25',
    tag: 'emergency',
  ),
  DirItem.phone(
    'جهاز الإسعاف والطوارئ',
    'رقم ورد في تنبيه صحي رسمي عبر وكالة الأنباء الليبية لعمليات الإسعاف والطوارئ؛ تحقق محليًا عند الحاجة.',
    '0931911191',
    id: 'emergency-ambulance-field',
    official: true,
    source: 'وكالة الأنباء الليبية نقلاً عن وزارة الصحة',
    sourceUrl: 'https://lana.gov.ly/post.php?id=332565&lang=ar',
    verifiedAt: '2025-05-12',
    tag: 'emergency',
  ),
  DirItem.phone(
    'غرفة العمليات المركزية',
    'رقم ورد في تنبيه صحي رسمي عبر وكالة الأنباء الليبية للتنسيق الطبي العاجل؛ تحقق محليًا عند الحاجة.',
    '0921910191',
    id: 'emergency-central-ops',
    official: true,
    source: 'وكالة الأنباء الليبية نقلاً عن وزارة الصحة',
    sourceUrl: 'https://lana.gov.ly/post.php?id=332565&lang=ar',
    verifiedAt: '2025-05-12',
    tag: 'emergency',
  ),
  DirItem.phone(
    'غرفة عمليات الطب الميداني',
    'رقم ورد في تنبيه صحي رسمي سابق للتواصل على مدار الساعة في الحالات الطبية الطارئة.',
    '0916288000',
    id: 'emergency-field-ops',
    official: true,
    source: 'وكالة الأنباء الليبية نقلاً عن وزارة الصحة',
    sourceUrl: 'https://lana.gov.ly/post.php?id=332565&lang=ar',
    verifiedAt: '2025-05-12',
    tag: 'emergency',
  ),
  DirItem.phone(
    'بلاغات الكهرباء',
    'رقم غرفة البلاغات للأعطال والحالات الكهربائية الطارئة.',
    '1418',
    id: 'emergency-electricity',
    official: true,
    source: 'الشركة العامة للكهرباء',
    sourceUrl: 'https://www.gecol.ly/',
    verifiedAt: '2026-10-02',
    tag: 'emergency',
  ),
];

class NearbyKind {
  final String id;
  final String query;
  final IconData icon;
  final Color color;
  const NearbyKind(this.id, this.query, this.icon, this.color);
}

const List<NearbyKind> nearbyKinds = [
  NearbyKind('hospital', 'مستشفى', Icons.local_hospital, Color(0xFFC62828)),
  NearbyKind('pharmacy', 'صيدلية', Icons.local_pharmacy, Color(0xFF7B1FA2)),
  NearbyKind('police', 'مركز شرطة', Icons.local_police, Color(0xFF1565C0)),
  NearbyKind('bank', 'بنك', Icons.account_balance, Color(0xFF00796B)),
  NearbyKind('atm', 'صراف آلي ATM', Icons.atm, Color(0xFF00796B)),
  NearbyKind('fuel', 'محطة وقود', Icons.local_gas_station, Color(0xFFF9A825)),
  NearbyKind('restaurant', 'مطعم', Icons.restaurant, Color(0xFFE65100)),
  NearbyKind('market', 'متجر', Icons.storefront, Color(0xFFEF6C00)),
  NearbyKind('hotel', 'فندق', Icons.hotel, Color(0xFF6A1B9A)),
];

Uri mapsSearchUri(String query, String city) => Uri.parse(
  'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$query، $city، ليبيا')}',
);

/// كل عناصر الدليل + الفنادق للبحث والمفضلة.
List<DirItem> allSearchableItems() => [
  ...allDirectoryItems(),
  ...hotelSearchItems(),
];
