// Qarz tranzaksiyasi test qilish uchun debug file

// Test qilish kerak:
// 1. 12,000 UZS asosiy miqdor
// 2. Dropdown da USD tanlash
// 3. USD miqdori ~1.02 ko'rinishi kerak
// 4. API ga yuborish
// 5. Transaction list da qarz miqdori USD da ko'rinishi kerak

// API Request expected:
// {
//   "type": "qarzPulBerish",
//   "walletId": "...",
//   "debtorCreditorId": "...",
//   "previousDebt": true/false,
//   "currency": "usd",
//   "amount": 12000,
//   "amountDebt": 1.02,
//   "comment": "..."
// }

// API Response expected:
// Response da debt amount va currency qaytishi kerak
// Transaction parsing da bu fieldlar parse qilinishi kerak:
// - debtAmount yoki amountdebit
// - currency field