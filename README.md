# Safe Budget - Student Wallet App

A comprehensive Flutter application designed to help students manage their finances effectively. The app provides tools for budgeting, tracking expenses, and managing allocated funds for different purposes.

## Features

### 💰 Financial Management
- **Balance Tracking**: Real-time balance updates
- **Fund Allocation**: Allocate funds to different categories (Tuition, Rent, Meals, Books, etc.)
- **Deposits**: Add funds to your wallet with purpose categorization
- **Withdrawals**: Withdraw funds for specific purposes with allocation limits
- **Transaction History**: Complete transaction log with detailed information

### 📊 Analytics & Insights
- **Spending Breakdown**: Visual pie chart showing spending by category
- **Budget Overview**: Track allocated vs. spent amounts
- **Financial Reports**: Detailed transaction history and analytics

### 🔔 Smart Notifications
- **Transaction Alerts**: Instant notifications for all deposits and withdrawals
- **Success Confirmations**: Notifications for successful transactions
- **Error Alerts**: Notifications for failed transactions or insufficient funds
- **Customizable Settings**: Manage notification preferences from profile

### 👤 User Management
- **Secure Authentication**: Firebase Auth integration
- **Profile Management**: Update personal information and profile picture
- **Password Management**: Change password functionality
- **Data Persistence**: Cloud Firestore for reliable data storage

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / VS Code
- Firebase project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd safe_budget
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Set up a Firebase project
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Enable Authentication and Firestore in Firebase Console

4. **Run the app**
   ```bash
   flutter run
   ```

## Dependencies

- **Firebase Core**: `firebase_core: ^2.25.4`
- **Firebase Auth**: `firebase_auth: ^4.17.4`
- **Cloud Firestore**: `cloud_firestore: ^4.9.2`
- **Local Notifications**: `flutter_local_notifications: ^17.2.2`
- **Charts**: `fl_chart: ^0.66.2`
- **Image Picker**: `image_picker: ^1.0.7`
- **Firebase Storage**: `firebase_storage: ^11.6.6`

## Project Structure

```
lib/
├── constants/
│   ├── app_colors.dart
│   └── colors.dart
├── screens/
│   ├── deposit_screen.dart
│   ├── forgot_password_screen.dart
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── profile_screen.dart
│   ├── signup_screen.dart
│   ├── transactions_screen.dart
│   └── withdraw_screen.dart
├── services/
│   └── notification_service.dart
├── widgets/
│   └── bottom_nav_bar.dart
├── firebase_options.dart
├── main.dart
└── main_wrapper.dart
```

## Usage

### For Students
1. **Sign Up/Login**: Create an account or sign in
2. **Allocate Funds**: Set up budget categories and amounts
3. **Make Deposits**: Add money to your wallet
4. **Track Spending**: Monitor your expenses and stay within budget
5. **Manage Notifications**: Customize notification preferences

### For Developers
- The app uses Firebase for backend services
- Local notifications are handled through `flutter_local_notifications`
- State management is done through StreamBuilder and Firebase streams
- UI follows Material Design principles with custom theming

## Platform Support

- **Android**: Full support with native notifications
- **iOS**: Full support with proper permission handling
- **Web**: Limited support (notifications may not work in all browsers)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue in the repository or contact the development team.
