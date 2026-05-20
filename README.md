# Home Service AI

An AI-powered platform bridging service providers and seekers in the informal economy. We build trust through technology by connecting communities and empowering livelihoods.

## 🌟 Overview

Home Service AI is a comprehensive Flutter application that connects service seekers with skilled service providers using AI-powered matching algorithms. The platform supports multiple service categories and provides real-time booking, ratings, and earnings management features.

### Key Features

- **Dual User Roles**: Service Seekers and Service Providers with role-based dashboards
- **AI-Powered Matching**: Natural Language Understanding (NLU) engine that parses service requests in Roman Urdu, Urdu, and English
- **Real-Time Bookings**: Live booking system with real-time notifications and status updates
- **Multi-Category Support**: 17+ service categories including Electrician, Plumber, AC Technician, Carpenter, and more
- **Rating & Review System**: Comprehensive feedback system for both seekers and providers
- **Earnings Dashboard**: Financial overview for service providers
- **Client Management**: Track and manage customer relationships
- **Email Verification**: Secure authentication with email verification
- **Responsive Design**: Optimized for both mobile and desktop platforms
- **Firebase Integration**: Authentication, Firestore database, and real-time sync

## 🏗️ Architecture

### Project Structure

```
home_service_ai/
├── lib/
│   ├── main.dart                    # App entry point with Firebase initialization
│   ├── repositories/
│   │   └── auth_repository.dart     # Authentication logic and user management
│   ├── services/
│   │   └── env_config.dart          # Environment configuration loader
│   └── screens/
│       ├── about_screen.dart                    # About us page
│       ├── ai_messaging_screen.dart              # AI-powered service matching
│       ├── auth_screen.dart                     # Authentication (login/signup)
│       ├── bookings_dashboard.dart               # Booking management
│       ├── clients_dashboard.dart                # Client management (providers)
│       ├── earnings_dashboard.dart               # Financial overview (providers)
│       ├── email_verification_screen.dart        # Email verification flow
│       ├── forgot_password_screen.dart           # Password reset
│       ├── provider_dashboard.dart               # Provider main dashboard
│       ├── provider_profile_dashboard.dart       # Provider profile management
│       ├── rating_dashboard.dart                 # Reviews and ratings
│       └── seeker_dashboard.dart                 # Seeker main dashboard
├── .env                          # Firebase configuration
├── pubspec.yaml                  # Dependencies
└── README.md                     # This file
```

### Technology Stack

- **Framework**: Flutter (Dart SDK ^3.8.1)
- **Backend**: Firebase
  - Firebase Auth (^5.4.1) - Authentication
  - Cloud Firestore (^5.6.1) - Real-time database
  - Firebase Core (^3.10.1) - Core Firebase services
- **UI Libraries**:
  - google_fonts (^6.2.1) - Typography
  - cupertino_icons (^1.0.8) - iOS-style icons
- **Utilities**:
  - flutter_dotenv (^5.1.0) - Environment variable management
  - url_launcher (^6.3.0) - URL and SMS launching
  - google_sign_in (^6.2.2) - Google authentication

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Firebase project with Authentication and Firestore enabled
- Android Studio / VS Code
- For mobile: Android SDK / iOS Xcode

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd home_service_ai
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com) and enable:
   - Authentication (Email/Password)
   - Firestore Database

   Update the `.env` file with your Firebase configuration:
   ```env
   # Firebase Android Configuration
   ANDROID_API_KEY=your_android_api_key
   ANDROID_APP_ID=your_android_app_id
   ANDROID_PROJECT_ID=your_project_id
   ANDROID_MESSAGING_SENDER_ID=your_sender_id

   # Firebase iOS Configuration
   IOS_API_KEY=your_ios_api_key
   IOS_APP_ID=your_ios_app_id
   IOS_PROJECT_ID=your_project_id
   IOS_MESSAGING_SENDER_ID=your_sender_id
   IOS_BUNDLE_ID=com.your.bundle.id

   # Firebase Web Configuration
   WEB_API_KEY=your_web_api_key
   WEB_APP_ID=your_web_app_id
   WEB_PROJECT_ID=your_project_id
   WEB_MESSAGING_SENDER_ID=your_sender_id
   WEB_AUTH_DOMAIN=your_project_id.firebaseapp.com
   WEB_STORAGE_BUCKET=your_project_id.appspot.com
   WEB_MEASUREMENT_ID=your_measurement_id
   ```

4. **Platform-specific setup**

   **Android:**
   - Add `google-services.json` to `android/app/`
   - Update `android/build.gradle` with Google Services classpath

   **iOS:**
   - Add `GoogleService-Info.plist` to `ios/Runner/`
   - Update `ios/Runner/Info.plist` with required permissions

   **Web:**
   - Firebase configuration is handled via `.env` file

5. **Run the application**
   ```bash
   # For development
   flutter run

   # For specific platform
   flutter run -d chrome    # Web
   flutter run -d android   # Android
   flutter run -d ios       # iOS (macOS only)
   ```

## 📱 User Roles & Features

### Service Seeker

**Dashboard Features:**
- **Find Services**: Browse and search for service providers by category
- **AI Match**: Natural language service request parsing (supports Roman Urdu, Urdu, English)
- **My Bookings**: Track booking status (Pending, Accepted, Confirmed, Completed)
- **Reviews**: View and manage service reviews
- **Profile Settings**: Update personal information

**Service Categories:**
- Electrician
- Plumber
- AC Technician
- Carpenter
- Home Appliances Repair
- Deep Cleaning
- Water Tank Cleaning
- Pest Control
- Gardener
- Laundry & Dry Cleaning
- Home Tutor
- Generator Mechanic
- Painter
- Solar Panel Cleaning
- Home Maid
- Home Beauticians
- Others

### Service Provider

**Dashboard Features:**
- **Overview**: Real-time emergency match alerts and booking notifications
- **Manage Bookings**: Accept, confirm, and complete service requests
- **Earnings**: Financial overview with total balance and transaction history
- **Clients**: Customer relationship management
- **Reviews**: View customer feedback and ratings
- **Profile**: Manage professional profile, skills, hourly rate, and availability

**Profile Fields:**
- Service Category
- Skills (comma-separated)
- Hourly Rate (PKR)
- Availability (Full-time, Part-time, Weekends, Evenings, Flexible)
- Experience (years)
- Bio/Description

## 🔐 Authentication Flow

### Registration
1. User selects role (Seeker or Provider)
2. Fills registration form with required fields
3. Email verification sent automatically
4. User data stored in Firestore with role designation
5. Role cached in Firebase Auth photoURL for fast access

### Login
1. User enters email and password
2. System validates credentials
3. Role verification against Firestore
4. Redirected to appropriate dashboard
5. Email verification check if not verified

### Security Features
- Email verification required
- Role-based access control
- Timeout protection for network operations
- Graceful offline fallback
- Password reset functionality

## 🤖 AI-Powered Service Matching

The AI Messaging Screen features a custom NLU (Natural Language Understanding) engine that:

- **Parses natural language requests** in multiple languages
- **Detects service categories** using keyword matching
- **Extracts urgency** from user input
- **Provides instant matching** with available providers
- **Supports Roman Urdu, Urdu, and English**

**Example inputs:**
- "washroom ka sink leak ho raha hai jaldi kisi ko bhejo" → Plumber
- "kitchen light not working abhi bhejo" → Electrician
- "AC not cooling" → AC Technician

## 📊 Database Schema

### Collections

**users**
```javascript
{
  uid: string,
  email: string,
  fullName: string,
  phoneNumber: string,
  location: string,
  role: 'seeker' | 'provider',
  createdAt: timestamp,
  isEmailVerified: boolean,
  // Provider-specific fields
  serviceCategory?: string,
  skills?: string[],
  hourlyRate?: number,
  availability?: string,
  experienceYears?: number,
  bio?: string,
  rating?: number,
  reviewsCount?: number
}
```

**bookings**
```javascript
{
  seekerId: string,
  providerId: string,
  seekerName: string,
  providerName: string,
  service: string,
  status: 'Pending' | 'ProviderAccepted' | 'Confirmed' | 'Completed',
  createdAt: timestamp,
  // Additional booking details
}
```

**reviews**
```javascript
{
  seekerId: string,
  providerId: string,
  rating: number,
  comment: string,
  createdAt: timestamp
}
```

**notifications** (subcollection under users)
```javascript
{
  type: 'provider_accepted' | 'seeker_confirmed' | 'booking_confirmed',
  providerName?: string,
  seekerName?: string,
  service: string,
  bookingId?: string,
  createdAt: timestamp
}
```

## 🎨 UI/UX Design

### Design Principles
- **Material Design 3**: Modern, clean interface
- **Responsive Layout**: Adaptive for mobile and desktop
- **Accessibility**: High contrast, readable fonts
- **Color Palette**: Purple theme (#6B46C1) with complementary colors
- **Typography**: Google Fonts (Inter) for consistent typography

### Responsive Breakpoints
- **Mobile**: < 800px width
- **Desktop**: ≥ 800px width

### Key UI Components
- Hover cards with animations
- Real-time notification snackbars
- Stream-based data loading
- Form validation with error handling
- Loading states and skeletons

## 🔧 Development

### Code Style
- Follow Flutter/Dart conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Separate UI from business logic

### Testing
```bash
# Run unit tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```

### Build for Production

**Android:**
```bash
flutter build apk --release
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

**Web:**
```bash
flutter build web --release
```

## 📝 Environment Variables

The application uses `flutter_dotenv` to manage Firebase configuration. Ensure `.env` is:
- Added to `.gitignore` (already done)
- Contains valid Firebase credentials
- Not committed to version control

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is private and proprietary. All rights reserved.

## 📞 Support

For support, email support@homeserviceai.com or contact through the in-app About section.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Google Fonts for typography
- The open-source community

---

**Version**: 1.0.0+1  
**Last Updated**: May 2026  
**Platform**: Flutter (Android, iOS, Web, Windows, macOS, Linux)
