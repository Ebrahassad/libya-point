import '../services/content_store.dart';
import 'directory.dart';

/// فندق في الدليل.
///
/// [phone] و[web] لا يُملآن إلا إذا كانا موثّقين من موقع الفندق الرسمي أو
/// من دليل منشور. أي فندق بلا رقم يبقى له زر الخريطة الذي يبحث باسمه
/// ومدينته مباشرة في خرائط جوجل.
class Hotel {
  final String name;
  final String city;
  final int stars; // 0 = غير معروف
  final String note;
  final String? phone; // بصيغة دولية بدون مسافات، مثل +218213351990
  final String? phoneLabel;
  final String? web;
  const Hotel(
    this.name,
    this.city, {
    this.stars = 0,
    this.note = '',
    this.phone,
    this.phoneLabel,
    this.web,
  });

  Uri get mapsUri => mapsSearchUri(name, city);
  Uri? get phoneUri => phone == null ? null : Uri.parse('tel:$phone');
  Uri? get webUri => web == null ? null : Uri.parse(web!);
}

/// مصادر البيانات (تظهر أسفل الشاشة).
const List<DirItem> hotelSources = [
  DirItem.web(
    'فنادق صندوق الضمان الاجتماعي',
    'القائمة الرسمية للفنادق الحكومية مع تصنيفها وعدد غرفها.',
    'https://ssf.gov.ly/?page_id=99',
  ),
  DirItem.web(
    'فنادق طرابلس على Booking',
    'حجز وتقييمات فنادق طرابلس.',
    'https://www.booking.com/city/ly/tarabulus.ar.html',
  ),
  DirItem.web(
    'فنادق بنغازي على Booking',
    'حجز وتقييمات فنادق بنغازي.',
    'https://www.booking.com/city/ly/banghazi.html',
  ),
];

/// رابط بحث الفنادق في مدينة على Booking.
Uri bookingSearchUri(String city) => Uri.parse(
  'https://www.booking.com/searchresults.ar.html?ss=${Uri.encodeComponent('$city، ليبيا')}',
);

/// الفنادق المضمّنة. المحتوى البعيد (content.json) يمكنه استبدال القائمة.
const List<Hotel> defaultHotels = [
  // ---------- طرابلس ----------
  Hotel(
    'فندق كورنثيا طرابلس',
    'طرابلس',
    stars: 5,
    note: 'سوق الثلاثاء القديم. أشهر فنادق العاصمة.',
    phone: '+218213351990',
    phoneLabel: '+218 21 335 1990',
    web: 'https://www.corinthia.com/en-gb/tripoli/',
  ),
  Hotel(
    'فندق راديسون بلو المهاري',
    'طرابلس',
    stars: 5,
    note: 'شارع الفتح، على الكورنيش.',
    phone: '+218213407878',
    phoneLabel: '021-3407878',
    web: 'https://www.radissonhotels.com/ar-ae/hotels/radisson-blu-tripoli-al-mahary',
  ),
  Hotel(
    'الفندق الكبير',
    'طرابلس',
    stars: 4,
    note: 'شارع الفتح، يطل على الكورنيش. نحو 300 غرفة وجناح.',
  ),
  Hotel(
    'فندق باب البحر',
    'طرابلس',
    stars: 4,
    note: 'سوق الثلاثاء القديم. أكثر من 400 غرفة.',
  ),
  Hotel('فندق الواحات', 'طرابلس', stars: 3, note: 'شارع عمر المختار.'),
  Hotel('فندق باب المدينة', 'طرابلس', stars: 3, note: 'سوق الثلاثاء القديم.'),
  Hotel('فندق باب الجديد', 'طرابلس', stars: 2, note: 'سوق الثلاثاء القديم.'),
  Hotel('فندق الخان', 'طرابلس'),
  Hotel('فندق طرابلس الدولي', 'طرابلس'),
  Hotel('فندق الضيافة', 'طرابلس'),
  Hotel('فندق الشاطئ الذهبي', 'طرابلس'),
  Hotel('فندق النهر', 'طرابلس'),
  Hotel('فندق الكندي', 'طرابلس'),
  Hotel('فندق الصافي', 'طرابلس'),
  Hotel('فندق أوال', 'طرابلس'),
  Hotel('فندق فكتوريا', 'طرابلس'),
  Hotel('فندق صحراء ليبيا', 'طرابلس'),
  Hotel('فندق الودان', 'طرابلس'),
  Hotel('فندق الأندلس', 'طرابلس'),
  Hotel('فندق بلازما', 'طرابلس'),
  Hotel('فندق هارون', 'طرابلس'),
  Hotel('فندق الصفوة', 'طرابلس'),
  Hotel('فندق التوفيق بلازا', 'طرابلس'),
  // ---------- جنزور ----------
  Hotel(
    'القرية العائلية - فندق النصر',
    'جنزور',
    stars: 3,
    note: 'فندق وقمرات وفيلات. نحو 440 غرفة.',
  ),
  // ---------- بنغازي ----------
  Hotel(
    'فندق تبستي',
    'بنغازي',
    stars: 5,
    note: 'وسط المدينة، يطل على بحيرة 23 يوليو. 250 غرفة.',
  ),
  Hotel(
    'فندق أوزو',
    'بنغازي',
    stars: 4,
    note: 'على بحيرة بنغازي والبحر. 262 غرفة.',
  ),
  Hotel(
    'القرية العائلية - قاريونس',
    'بنغازي',
    stars: 3,
    note: 'تبعد نحو 5 كم عن وسط بنغازي. فندق وفيلات وشقق.',
  ),
  Hotel('فندق فينيسيا', 'بنغازي'),
  Hotel('فندق الحرير', 'بنغازي'),
  Hotel('فندق يوسف', 'بنغازي'),
  Hotel('فندق الفضيل', 'بنغازي'),
  Hotel('فندق القصر', 'بنغازي'),
  Hotel('فندق الواحات', 'بنغازي'),
  Hotel('فندق إبريز', 'بنغازي'),
  Hotel('منتجع النخلة الذهبية', 'بنغازي'),
  // ---------- مصراتة ----------
  Hotel('فندق قوز التيك', 'مصراتة', stars: 3, note: '173 غرفة وجناحاً.'),
  // ---------- سرت ----------
  Hotel(
    'فندق قصر المؤتمرات',
    'سرت',
    stars: 4,
    note: 'أربع عمارات ومبنى خدمي. 240 غرفة.',
  ),
  // ---------- سبها ----------
  Hotel('فندق الجبل', 'سبها', stars: 2, note: '25 غرفة.'),
  // ---------- زليتن ----------
  Hotel('فندق زليتن', 'زليتن', stars: 3, note: 'محطة المنطحة. 64 غرفة.'),
  // ---------- غريان ----------
  Hotel('فندق الرابطة', 'غريان', stars: 2, note: '68 غرفة.'),
  // ---------- بني وليد ----------
  Hotel('فندق الزيتونة', 'بني وليد', stars: 2, note: '37 غرفة.'),
  // ---------- طبرق ----------
  Hotel('فندق المسيرة', 'طبرق', stars: 4, note: '240 غرفة وجناحاً.'),
];

/// الفنادق الحالية.
List<Hotel> get libyaHotels => ContentStore.instance.hotels;

List<Hotel> hotelsInCity(String city) =>
    libyaHotels.where((h) => h.city == city).toList();

/// كل الفنادق كعناصر قابلة للبحث والمفضلة (الفتح على الخريطة).
List<DirItem> hotelSearchItems() => [
  for (final h in libyaHotels)
    DirItem.web(
      'فندق: ${h.name} - ${h.city}',
      h.note.isEmpty ? 'افتح موقعه على خرائط جوجل.' : h.note,
      h.mapsUri.toString(),
    ),
];
