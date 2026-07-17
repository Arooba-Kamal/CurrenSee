---

# 📑 Table of Contents

- [📖 About](#-about)
- [✨ Features](#-features)
- [📸 App Screenshots](#-app-screenshots)
- [🛠 Tech Stack](#-tech-stack)
- [📂 Project Structure](#-project-structure)
- [🚀 Getting Started](#-getting-started)
- [🔑 Configuration](#-configuration)
- [🌟 Future Enhancements](#-future-enhancements)
- [👩‍💻 Developer](#-developer)
- [⭐ Support](#-support)

---

# 📖 About

CurrenSee is a modern **Flutter-based Currency Converter & Financial Assistant** developed to make currency exchange easier, smarter, and more interactive.

The application combines **live exchange rates**, **AI-powered chatbot assistance**, **market analysis**, **budget planning**, and **financial management tools** into one elegant mobile application.

Designed with a premium **Glassmorphism UI**, smooth animations, and Firebase integration, CurrenSee delivers a fast, secure, and user-friendly experience across multiple platforms.

---

# ✨ Features

## 💱 Currency Conversion

- 🌍 Live Currency Conversion
- 📶 Offline Currency Conversion
- ❤️ Favorite Currency Pairs
- ⚖ Currency Comparison
- 📱 QR Code Sharing

---

## 🤖 AI Financial Assistant

- Gemini AI Integration
- Smart Financial Suggestions
- Currency Information
- AI Chat Support
- Quick Responses

---

## 📈 Market Insights

- 📊 Live Exchange Rates
- 🪙 Gold Prices
- ₿ Cryptocurrency Rates
- 📰 Market News
- 📉 Exchange Rate Charts
- 📈 Trend Analysis

---

## 💼 Finance Management

- Budget Planner
- Spending Tracker
- Travel Cost Estimator
- Conversion History
- PDF Report Export

---

## 🔔 Smart Notifications

- Exchange Rate Alerts
- Smart Notifications
- Personalized Updates
- Important Market Changes

---

## 🔐 Authentication

- Firebase Authentication
- Secure Login
- User Registration
- Forgot Password
- Biometric Login
- User Profile Management

---

## 👨‍💼 Admin Dashboard

- Admin Dashboard
- User Management
- Currency Management
- Exchange Rate Management
- Reports
- Analytics
- Feedback Management

---

# 📸 App Screenshots

<div align="center">

## 🚀 Splash & Authentication

| Splash | Login | Register |
|--------|--------|----------|
| <img src="assets/screenshots/splash.jpeg" width="220"> | <img src="assets/screenshots/login.jpeg" width="220"> | <img src="assets/screenshots/register.jpeg" width="220"> |

---

## 🏠 Main Screens

| Home | Dashboard | More |
|------|-----------|------|
| <img src="assets/screenshots/home.jpeg" width="220"> | <img src="assets/screenshots/dashboard.jpeg" width="220"> | <img src="assets/screenshots/more.jpeg" width="220"> |
| Converter | Live Rates | Offline |
|-----------|------------|----------|
| <img src="assets/screenshots/converter.jpeg" width="220"> | <img src="assets/screenshots/live_rates.jpeg" width="220"> | <img src="assets/screenshots/offline.jpeg" width="220"> |

---

## 🤖 AI Assistant

| AI Chatbot |
|------------|
| <img src="assets/screenshots/chatbot.jpeg" width="260"> |

---

## 📈 Market & Analytics

| Market News | Crypto | Gold |
|-------------|---------|------|
| <img src="assets/screenshots/market_news.jpeg" width="220"> | <img src="assets/screenshots/crypto.jpeg" width="220"> | <img src="assets/screenshots/gold.jpeg" width="220"> |

| Exchange Chart | Trends |
|----------------|--------|
| <img src="assets/screenshots/chart.jpeg" width="220"> | <img src="assets/screenshots/trends.jpeg" width="220"> |

---

## 💼 Budget Planner

| Budget Planner | Spending Tracker | Travel Estimator |
|----------------|------------------|------------------|
| <img src="assets/screenshots/budget.jpeg" width="220"> | <img src="assets/screenshots/spending.jpeg" width="220"> | <img src="assets/screenshots/travel.jpeg" width="220"> |

---

## 📂 History

| Conversion History | PDF Export |
|--------------------|------------|
| <img src="assets/screenshots/history.jpeg" width="220"> | <img src="assets/screenshots/pdf.jpeg" width="220"> |

---

## 🔔 Notifications

| Notifications | Smart Alerts |
|---------------|--------------|
| <img src="assets/screenshots/notifications.jpeg" width="220"> | <img src="assets/screenshots/alerts.jpeg" width="220"> |

---

## 👤 User Profile

| Profile |
|---------|
| <img src="assets/screenshots/profile.jpeg" width="260"> |

---

## 👨‍💼 Admin Panel

| Dashboard | Users | Reports |
|------------|-------|----------|
| <img src="assets/screenshots/admin_dashboard.jpeg" width="220"> | <img src="assets/screenshots/manage_users.jpeg" width="220"> | <img src="assets/screenshots/reports.jpeg" width="220"> |

| Analytics | Feedback | Settings |
|------------|----------|----------|
| <img src="assets/screenshots/analytics.jpeg" width="220"> | <img src="assets/screenshots/feedback.jpeg" width="220"> | <img src="assets/screenshots/admin_settings.jpeg" width="220"> |

</div>

---

# 🛠 Tech Stack

<div align="center">

| Technology | Purpose |
|------------|---------|
| 🩵 Flutter | Cross-platform App Development |
| 🎯 Dart | Programming Language |
| 🔥 Firebase Authentication | User Authentication |
| ☁ Cloud Firestore | Cloud Database |
| 🖼 Cloudinary | Image Storage |
| 🤖 Gemini AI | AI Chatbot |
| 💱 ExchangeRate API | Live Currency Rates |
| 📄 PDF Package | Export Reports |
| 📱 QR Flutter | QR Code Sharing |
| 🎨 Glassmorphism UI | Modern User Interface |

</div>

---

# 🌟 Highlights

- ✅ Beautiful Glassmorphism UI
- ✅ Real-Time Currency Conversion
- ✅ Gemini AI Powered Chatbot
- ✅ Live Exchange Rates
- ✅ Gold & Cryptocurrency Prices
- ✅ Firebase Authentication
- ✅ Offline Currency Conversion
- ✅ Budget Planner
- ✅ Spending Tracker
- ✅ PDF Export
- ✅ Smart Notifications
- ✅ Admin Dashboard
- ✅ Cross Platform Support
- ✅ Smooth Animations
- ✅ Responsive Design

---# 📂 Project Structure

```text
CurrenSee
│
├── android/
├── ios/
├── linux/
├── macos/
├── windows/
├── web/
│
├── assets/
│   ├── data/
│   └── screenshots/    # All app screenshots
│
├── lib/
│   ├── core/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── services/
│   │   ├── theme/
│   │   └── utils/
│   │
│   ├── screens/
│   │   ├── admin/
│   │   ├── alerts/
│   │   ├── auth/
│   │   ├── calculator/
│   │   ├── chatbot/
│   │   ├── converter/
│   │   ├── currency/
│   │   ├── history/
│   │   ├── home/
│   │   ├── market/
│   │   ├── onboarding/
│   │   ├── planner/
│   │   ├── settings/
│   │   └── splash/
│   │
│   ├── widgets/
│   │
│   ├── firebase_options.dart
│   └── main.dart
│
├── pubspec.yaml
└── README.md
```

---

# 🚀 Getting Started

## 1️⃣ Clone Repository

```bash
git clone https://github.com/Arooba-Kamal/CurrenSee.git
```

---

## 2️⃣ Navigate to Project

```bash
cd CurrenSee
```

---

## 3️⃣ Install Packages

```bash
flutter pub get
```

---

## 4️⃣ Run the App

```bash
flutter run
```

---

# 🔑 Configuration

Before running the project, configure the following services:

- 🔥 Firebase Authentication
- ☁ Cloud Firestore
- 🖼 Cloudinary
- 🤖 Gemini AI API
- 💱 ExchangeRate API


---

# 🎯 Future Enhancements

- 🎤 Voice Assistant
- 🌍 Multi-language Support
- 📈 AI Currency Forecasting
- 📊 Advanced Expense Analytics
- 🌙 Dark / Light Theme Switching
- ⌚ Wear OS Support
- 🍎 Apple Watch Support
- 📱 Home Screen Widgets
- 🔔 Push Notifications
- 📡 Real-time Sync

---

# 🤝 Contributing

Contributions are always welcome!

1. Fork this repository
2. Create a new feature branch

```bash
git checkout -b feature-name
```

3. Commit your changes

```bash
git commit -m "Add new feature"
```

4. Push your branch

```bash
git push origin feature-name
```

5. Open a Pull Request 🚀

---

# 👩‍💻 Developer

<div align="center">

## **Arooba Kamal**

Flutter Developer 💙

Passionate about building modern mobile applications using Flutter, Firebase, REST APIs and AI technologies.

### 🌐 Connect with Me

[![GitHub](https://img.shields.io/badge/GitHub-Arooba--Kamal-181717?style=for-the-badge&logo=github)](https://github.com/Arooba-Kamal)

</div>

---

# 💙 Acknowledgements

Special thanks to:

- Flutter Team
- Firebase
- Google Gemini AI
- ExchangeRate API
- Open Source Community ❤️

---

<div align="center">

# ⭐ If you like this project...

### Please consider giving it a ⭐ on GitHub!

It motivates me to build more amazing Flutter projects.

<br>

Made with ❤️ using Flutter

</div>

---

