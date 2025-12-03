/// 1C API ni sozlash bo'yicha qo'llanma
/// Bu faylni o'qing va keyin api_config.dart ni sozlang

/*

═══════════════════════════════════════════════════════
  1C API SOZLASH QO'LLANMASI
═══════════════════════════════════════════════════════

1. SERVER MANZILINI YOZISH
───────────────────────────

lib/core/config/api_config.dart faylini oching va quyidagini o'zgartiring:

// ESKI:
static const String baseUrl = 'https://your-1c-server.com/api';

// YANGI (1C chilar bergan manzil):
static const String baseUrl = 'http://192.168.1.100:8080/api';

// yoki internet orqali:
static const String baseUrl = 'https://kassam-api.uz/api';


═══════════════════════════════════════════════════════

2. API KEY SOZLASH (agar kerak bo'lsa)
──────────────────────────────────────

Agar 1C server API Key talab qilsa:

// ESKI:
static const String? apiKey = null;

// YANGI:
static const String? apiKey = 'your-api-key-from-1c';


═══════════════════════════════════════════════════════

3. PAROL SOZLASH (Basic Auth)
──────────────────────────────

Agar 1C server foydalanuvchi nomi va parol talab qilsa:

// ESKI:
static const String? basicAuthUsername = null;
static const String? basicAuthPassword = null;

// YANGI:
static const String? basicAuthUsername = 'admin';
static const String? basicAuthPassword = 'SecurePassword123';


═══════════════════════════════════════════════════════

4. ENDPOINT NOMLARI
───────────────────

Agar 1C chilar boshqa endpoint nomlari bersa:

// ESKI:
static const String getSms = '/get-sms';

// YANGI (1C chilar aytgan nom):
static const String getSms = '/api/auth/send-sms';


═══════════════════════════════════════════════════════

5. TO'LIQ MISOL
───────────────

1C chilar bergan ma'lumotlar:
  - Server: http://192.168.1.50:8080
  - API Key: ABC123XYZ456
  - Endpoint: /api/v1/sms/send

api_config.dart da:

static const String baseUrl = 'http://192.168.1.50:8080';
static const String? apiKey = 'ABC123XYZ456';
static const String getSms = '/api/v1/sms/send';


═══════════════════════════════════════════════════════

6. TEST QILISH
──────────────

Sozlaganingizdan keyin dasturni ishga tushiring va:

1. Telefon raqam kiriting
2. "Davom Etish" tugmasini bosing
3. Console da loglarni ko'ring
4. Agar xatolik bo'lsa, 1C chilar bilan tekshiring


═══════════════════════════════════════════════════════

7. KERAKsiz sozlamalar
──────────────────────

Agar API Key yoki Basic Auth kerak bo'lmasa, null qoldiring:

static const String? apiKey = null;  // API Key kerak emas
static const String? basicAuthUsername = null;  // Parol kerak emas
static const String? basicAuthPassword = null;


═══════════════════════════════════════════════════════

YORDAM KERAKMI?
───────────────

1C chilar bilan gaplashing va quyidagilarni so'rang:
  ✓ Server manzili (IP yoki domen)
  ✓ Port raqami (masalan: 8080, 443)
  ✓ API Key bormi?
  ✓ Foydalanuvchi nomi va parol kerakmi?
  ✓ Endpoint nomlari (/get-sms, /send-sms, va hokazo)

*/
