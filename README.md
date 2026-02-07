# Business Pilot 🚀

**Business Pilot** is a powerful and comprehensive Flutter application designed to streamline business management. From inventory tracking and point-of-sale (POS) operations to expense management and AI-driven insights, Business Pilot empowers business owners to take control of their operations with ease.

## ✨ Features

- **📊 Dashboard**: Get a real-time overview of your business performance with interactive charts and key metrics.
- **📦 Inventory Management**: Track products, manage stock levels, and organize your catalog with barcode scanning support.
- **🛒 Point of Sale (POS)**: A streamlined checkout process for quick and efficient sales transactions.
- **💸 Expenses**: Log and categorize business expenses to keep your finances in check.
- **📝 Invoicing**: Generate professional PDF invoices and share them directly with clients.
- **👥 Customer Management**: Maintain a database of your customers and their transaction history.
- **📈 Reports**: Visualize your business data with detailed reports on sales, expenses, and more.
- **🤖 AI Assistant**: Built-in AI chat to answer questions about your business data and provide insights.
- **🔒 Secure Auth**: Secure email and password authentication powered by Supabase.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **Language**: [Dart](https://dart.dev/)
- **Backend**: [Supabase](https://supabase.com/) (Auth, Database, Storage)
- **State Management**: [Riverpod](https://riverpod.dev/)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **AI Integration**: [GenUI](https://pub.dev/packages/genui), [Google ML Kit](https://pub.dev/packages/google_mlkit_text_recognition)
- **Charts**: [FL Chart](https://pub.dev/packages/fl_chart)
- **PDF**: [pdf](https://pub.dev/packages/pdf), [printing](https://pub.dev/packages/printing)

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- A [Supabase](https://supabase.com/) project.

### Installation

1.  **Clone the repository**:

    ```bash
    git clone https://github.com/chetan2921/business_pilot.git
    cd business_pilot
    ```

2.  **Install dependencies**:

    ```bash
    flutter pub get
    ```

3.  **Configuration**:
    - Create a `.env` file or update `lib/core/config/supabase_config.dart` (depending on your setup) with your Supabase URL and Anon Key.
    - _Note: Ensure you have the necessary database tables set up in Supabase._

4.  **Run the app**:
    ```bash
    flutter run
    ```

## 📱 Screenshots

_(Add screenshots of your app here)_

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
