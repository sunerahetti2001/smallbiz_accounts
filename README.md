# SmallBiz Accounts 📈

SmallBiz Accounts is a robust, lightweight accounting and financial tracking application tailored for small business owners and shopkeepers. Built with Flutter, it offers a hybrid data architecture combining the security of Firebase Authentication with the reliability and speed of local SQLite storage.

## ✨ Features

- **Hybrid Data Management**: Fast local storage with SQLite and secure cloud-based authentication via Firebase.
- **Smart Tracking**: Easily record Income, Expenses, and Credit Sales.
- **Credit Management**: Track pending payments from customers, set due dates, and record partial payments.
- **Google Authentication**: Quick and secure sign-in with Google account integration.
- **Insightful Dashboard**: Real-time summary of today's income, expenses, and current cash balance.
- **Overdue Alerts**: Automatic notifications for pending credit payments that have passed their due date.
- **Custom Categories**: Organize your finances with built-in or custom business categories.

## 🏗️ Architecture

- **State Management**: [Provider](https://pub.dev/packages/provider) for clean, reactive UI updates.
- **Local Database**: [sqflite](https://pub.dev/packages/sqflite) for high-performance offline data persistence.
- **Authentication**: [Firebase Auth](https://firebase.google.com/products/auth) with Google Sign-In support.
- **UI Components**: Material 3 design system with custom-themed components.

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
   - Enable **Google Sign-In** in the Authentication section of Firebase.

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

## 📱 Screenshots

*Coming Soon...*

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---
Built with ❤️ for Small Business Owners.
