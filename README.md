# Flutter Billing App 🛒💨

A fast, lightweight, and professional billing application built with Flutter. Designed for micro and small businesses to manage inventory, scan barcodes, and generate invoices with ease—all while being offline-first.

## ✨ Features

- **Inventory Management**: Track stock levels with "Low Stock" visual alerts.
- **Precision Barcode Scanning**: High-speed, frame-focused scanner with a professional green scan animation.
- **Flash & Toggle Controls**: Built-in scanner controls for dark environments and multi-camera support.
- **Offline-First (SQLite)**: All data is saved locally on your device—no internet required.
- **Product Management**: Easily add and edit products with barcode support.
- **Invoice Generation**: (In-progress) Ready for thermal printer integration.

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.1.0)
- Android Studio / VS Code
- A physical Android/iOS device for barcode scanning.

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd flutter_billing_app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

## 🛠 Tech Stack

- **State Management**: [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- **Local Database**: [sqflite](https://pub.dev/packages/sqflite)
- **Navigation**: [go_router](https://pub.dev/packages/go_router)
- **Scanner**: [mobile_scanner](https://pub.dev/packages/mobile_scanner)
- **UI Design**: Modern, premium aesthetics with custom animations.

## 📁 Project Structure

```bash
lib/
├── config/        # Routing and global constants
├── core/          # Shared widgets, theme, and database
├── features/
│   ├── billing/   # Cart, scanning, and checkout logic
│   ├── product/   # Inventory and product management
│   ├── settings/  # App preferences
│   └── shop/      # Shop business details
└── main.dart      # App entry point
```

## 📜 License

This project is open-source and available under the MIT License.
