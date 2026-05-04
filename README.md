# SmallBiz Accounts 📈

SmallBiz Accounts is a robust, lightweight accounting and financial tracking application tailored for small business owners and shopkeepers. Built with Flutter, it offers a hybrid data architecture combining the security of Firebase Authentication with the reliability and speed of local SQLite storage.

## ✨ Features

- **Hybrid Data Management**: Fast local storage with SQLite and secure cloud-based authentication via Firebase.
- **Smart Tracking**: Easily record Income, Expenses, and Credit Sales.
- **Credit Management**: Track pending payments from customers, set due dates, and record partial payments.
- **Google & Email Authentication**: Quick and secure sign-in with Google account integration or email/password.
- **Guest Mode**: Start tracking immediately without signing up. All data stays on your device.
- **Account Linking**: Seamlessly convert guest accounts to permanent Firebase accounts while preserving all transaction data.
- **Bilingual Support (English & Sinhala)**: Full localization with dynamic language switching throughout the app.
- **Insightful Dashboard**: Real-time summary of today's income, expenses, current cash balance, and credit outstanding.
- **Overdue Alerts**: Automatic visual indicators for pending credit payments that have passed their due date.
- **Custom Categories**: Organize your finances with built-in or custom business categories with emoji icons.
- **Financial Reports**: Generate and share professional PDF statements (Summary & Detailed) with income/expense breakdowns.
- **Comparative Analysis**: Month-to-month comparison and 3-month performance analysis with profit margins.
- **Profile Management**: View connected email, account type (Guest/Connected), and update business details.

## 🏗️ Architecture

- **State Management**: [Provider](https://pub.dev/packages/provider) for clean, reactive UI updates.
- **Local Database**: [sqflite](https://pub.dev/packages/sqflite) for high-performance offline data persistence.
- **Authentication**: [Firebase Auth](https://firebase.google.com/products/auth) with Google Sign-In and Email/Password support.
- **Localization**: Custom JSON-based localization system with [SharedPreferences](https://pub.dev/packages/shared_preferences) for language persistence.
- **PDF Generation**: [pdf](https://pub.dev/packages/pdf) and [printing](https://pub.dev/packages/printing) packages for statement exports.
- **UI Components**: Material 3 design system with custom-themed components and gradient backgrounds.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>= 3.0.0)
- Android Studio / Xcode
- A Firebase Project

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/smallbiz_accounts.git
   cd smallbiz_accounts
   ```
   
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup:**
   - Create a project in the [Firebase Console](https://console.firebase.google.com/).
   - Add an Android/iOS app to your project.
   - Download `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) and place them in the respective directories.
   - Enable **Email/Password** and **Google Sign-In** in the Authentication section of Firebase.

4. **Run the app:**
   ```bash
   flutter run
   ```

## 🛠️ Configuration

To enable Google Sign-In on Android, you must add your SHA-1 fingerprint to the Firebase console. You can generate it by running:

```bash
cd android
./gradlew signingReport
```
## 🌐 Language Configuration

The app supports English and Sinhala. Language files are located in:
```
assets/lang/
├── en.json    # English translations
└── si.json    # Sinhala translations
```

## 📱 Screenshots

*Coming Soon...*

## 📂 Project Structure
```
lib/
├── main.dart
├── l10n/
│   ├── app_localizations.dart    # Localization delegate
│   └── language_provider.dart    # Language state management
├── models/
│   ├── user_model.dart
│   ├── transaction_model.dart
│   ├── business_model.dart
│   └── category_model.dart
├── providers/
│   ├── user_provider.dart        # Auth & user state
│   ├── transaction_provider.dart # Transaction state & summaries
│   └── category_provider.dart    # Category management
├── services/
│   ├── auth_service.dart         # Firebase authentication
│   ├── sqlite_service.dart       # Local database operations
│   └── pdf_export_service.dart   # PDF generation
├── utils/
│   ├── colors.dart               # App color palette
│   ├── constants.dart            # App constants & defaults
│   ├── theme.dart                # Material 3 theme
│   └── currency_formatter.dart   # LKR currency formatting
├── views/
│   ├── onboarding/               # Welcome, auth, setup screens
│   ├── home/                     # Dashboard & widgets
│   ├── transactions/             # Income, expense, credit screens
│   ├── categories/               # Category management
│   ├── reports/                  # Comparison, analysis, statements
│   └── profile/                  # User profile & settings
└── widgets/                      # Reusable UI components
```
## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---
Built with ❤️ for Small Business Owners.
