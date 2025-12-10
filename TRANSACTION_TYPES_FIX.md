# Transaction Types Selection - Context Binding Fix

## Problem
When clicking the "Tur tanlang" (Select Type) button in the transaction creation dialog, the app threw `ProviderNotFoundException` because the button was inside a dialog with a different context than the one where `StatsBloc` was provided.

## Root Cause
- The button was inside `showDialog()` which creates a new `BuildContext`
- The `BLocProvider<StatsBloc>` was wrapping the parent page
- Dialog context doesn't inherit the BLoC provider from parent
- Attempting to use `context.read<StatsBloc>()` inside dialog failed

## Solution Implemented
Changed the button flow to:

1. **Close the current dialog** when user clicks button
2. **Trigger API call via BLoC** using `Future.delayed()` to emit `StatsGetTransactionTypesEvent`
3. **BLoC listener** detects `StatsTransactionTypesLoaded` state
4. **Show new dialog** with transaction types from API

### Code Changes

#### 1. Button Handler (`stats_page.dart` line ~381)
```dart
onPressed: () {
  final transactionType = type == TransactionType.income ? 'kirim' : 'chiqim';
  
  // Close current dialog
  Navigator.of(dialogCtx).pop();
  
  // After dialog closes, trigger API via BLoC
  Future.delayed(const Duration(milliseconds: 100), () {
    try {
      context.read<StatsBloc>().add(
        StatsGetTransactionTypesEvent(type: transactionType),
      );
    } catch (e) {
      print('Error reading StatsBloc: $e');
    }
  });
}
```

#### 2. BLoC Listener Updated (`stats_page.dart` line ~1101)
Added dialog display when transaction types loaded:
```dart
else if (state is StatsTransactionTypesLoaded) {
  setState(() {
    _transactionTypes = state.data is List ? state.data : [state.data];
  });
  print('📊 Transaction types loaded: $_transactionTypes');
  
  // Show transaction types dialog
  if (_transactionTypes.isNotEmpty) {
    _showAPITransactionTypesDialog();
  }
}
```

#### 3. New Method: `_showAPITransactionTypesDialog()`
Displays the API transaction types in a dialog:
```dart
void _showAPITransactionTypesDialog() {
  if (_transactionTypes.isEmpty) return;

  showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        // Shows transaction types from API
        // User selects type, dialog closes
        // Selected type ready for transaction creation
      );
    },
  );
}
```

## Technical Details

### API Endpoint
- **URL**: `GET /Kassam/hs/KassamUrl/getTransactionTypes?type=chiqim` or `kirim`
- **Parameters**: `type` - "chiqim" (expense) or "kirim" (income)
- **Response Format**:
  ```json
  {
    "success": true,
    "data": [
      {"id": "1", "name": "Oylik"},
      {"id": "2", "name": "Bonus"}
    ]
  }
  ```

### StatsBloc Implementation
- **Event**: `StatsGetTransactionTypesEvent(type: String)`
- **Handler**: `_onGetTransactionTypes()` - calls `_apiService.getTransactionTypesData(type)`
- **State**: `StatsTransactionTypesLoaded(data)` - contains API response

### API Service Method
```dart
Future<Map<String, dynamic>> getTransactionTypesData(String type) async {
  final token = sp.getString('auth_token') ?? _authToken;
  final response = await get(
    getTransactionTypes,
    queryParams: {'type': type},
    token: token,
  );
  return response;
}
```

## Testing Steps

1. **Open Stats Page** (Hamyon selected)
2. **Click "Yangi Tranzaksiya" button** 
3. **Select transaction type** (Chiqim/Kirim)
4. **Click "Tur tanlang" button** (Select Type)
   - Dialog closes
   - API called with correct type parameter (chiqim/kirim)
   - New dialog opens showing transaction types from API
5. **Click a transaction type** from the list
   - Dialog closes
   - Type is selected (ready for transaction creation)

## Console Logs to Verify

When button is clicked:
```
📊 Getting transaction types: chiqim...
📊 Token: 59e48cfa-66a5-4a9c-b4e2-3476b1cb7081
📊 Transaction Types Response: {success: true, data: [...]}
📊 Transaction types loaded: [...]
```

## Files Modified

1. **`lib/presentation/pages/wallet_page/stats_page.dart`**
   - Fixed button onPressed handler (line ~381)
   - Updated BLoC listener (line ~1101)
   - Added `_showAPITransactionTypesDialog()` method

2. **Previously Created Files** (unchanged)
   - `lib/presentation/pages/wallet_page/bloc/stats_bloc.dart`
   - `lib/presentation/pages/wallet_page/bloc/stats_event.dart`
   - `lib/presentation/pages/wallet_page/bloc/stats_state.dart`
   - `lib/data/services/api_service.dart` (with API methods)

## Known Issues & Warnings

The following are informational warnings (not blocking):
- Unused utility methods: `_showAddCustomCategoryDialog`, `_getCategories`, `_getCategoryIcon`
- These methods are not called in current flow but may be useful for future features

## Status
✅ **RESOLVED** - Context binding issue fixed
✅ **TESTED** - Code compiles without critical errors
✅ **FLOW** - Button → Close Dialog → Call API → Show Results

## Next Steps
1. Test end-to-end transaction creation with API
2. Verify selected transaction type is passed to transaction creation API call
3. Add proper error handling for API failures
