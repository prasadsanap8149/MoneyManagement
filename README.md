# SecureMoney - Personal Finance Manager

A secure and privacy-focused Flutter application for managing personal expenses and income with end-to-end encryption and modern Android compatibility.

## 🚀 Key Features

### 🔒 **Security & Privacy**
- **End-to-end encryption** for all financial data using AES-256
- **Local-only storage** - your data never leaves your device
- **No cloud dependencies** - complete offline functionality
- **Privacy-first design** - no personal information collection

### 💰 **Financial Management**
- Track income and expenses with detailed categorization
- Real-time balance calculation and spending analysis
- Visual dashboards with charts and spending insights
- Comprehensive transaction history and search

### 📁 **Import/Export Capabilities**
- **Smart JSON Import**: Add new transactions without replacing existing data
- **Duplicate Detection**: Automatically skip duplicate transactions during import
- **Multiple Export Formats**: CSV, PDF, Excel, and JSON
- **Modern File Access**: Uses Storage Access Framework (SAF) on Android 11+

### 🎨 **User Experience**
- **Dark Theme Support** with system-wide theme switching
- **Material Design 3** for modern, intuitive interface
- **No Storage Permissions Required** on Android 11+ (API 30+)
- **Responsive design** optimized for various screen sizes

### 🔧 **Technical Excellence**
- **Flutter Framework** for cross-platform compatibility
- **SAF Integration** for secure file operations without permissions
- **Encrypted Storage** with data integrity verification
- **Modern Android Support** (API 21+ with Android 11+ optimizations)

## 📱 **Android Compatibility**

### **Android 11+ (API 30+)**
- Uses **Storage Access Framework (SAF)** via `file_picker`
- **No storage permissions required** for file operations
- Automatic permission-free file import/export
- Enhanced security with scoped storage compliance

### **Android 10 and Below**
- Legacy storage permissions only when necessary
- Maintains backward compatibility
- Smooth migration path for older devices

## 🛠 **Technical Architecture**

### **Security Implementation**
- `SecureTransactionService`: Encrypted data management
- `EncryptionService`: AES-256 encryption with data integrity checks
- `DataMigrationService`: Secure migration from plain-text storage

### **File Operations**
- `FileOperationsService`: SAF-compatible file handling
- JSON-only transaction imports with validation
- Append-mode imports (no data replacement)
- Automatic duplicate detection and prevention

### **Theme System**
- `ThemeService`: Persistent theme management
- System theme detection and manual overrides
- Smooth theme transitions and state preservation

## 📦 **Installation & Setup**

### **Prerequisites**
- Flutter SDK 3.3.4+
- Dart SDK 3.0.0+
- Android SDK API 21+ (Android 5.0+)

### **Quick Start**
```bash
# Clone the repository
git clone <repository-url>
cd MoneyManagement

# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Build for release
flutter build apk --release
```

### **Development Commands**
```bash
# Code analysis
flutter analyze

# Run tests
flutter test

# Generate release build
flutter build appbundle --release
```

## 🔐 **Privacy & Security**

### **Data Protection**
- All financial data encrypted with AES-256
- Local-only storage with no cloud synchronization
- Data integrity verification with cryptographic hashes
- Secure export/import with format validation

### **Permission Model**
- **Android 11+**: Zero storage permissions required
- **Android 10-**: Minimal storage permissions only when needed
- **Internet**: Only for optional advertising features
- **No personal data collection** beyond voluntary transaction entries

## 📊 **Import/Export Features**

### **Smart Import System**
- **JSON-only imports** for transaction data
- **Append mode**: New transactions added to existing data
- **Duplicate prevention**: Automatic ID-based duplicate detection
- **Data validation**: Format verification before import
- **User feedback**: Clear reporting of import results

### **Export Options**
- **JSON**: Full transaction data with metadata
- **CSV**: Spreadsheet-compatible format
- **PDF**: Formatted reports with charts
- **Excel**: Advanced spreadsheet with formulas

## 🎨 **Theme Support**

The app includes comprehensive theme support:
- **Light Theme**: Clean, modern interface
- **Dark Theme**: OLED-friendly dark mode
- **System Theme**: Automatic detection of system preferences
- **Theme Persistence**: Remembers user theme choices
- **Smooth Transitions**: Animated theme switching

## 🚀 **Getting Started**

This project serves as a comprehensive example of:
- Modern Flutter app architecture
- Security-first design principles
- Android Storage Access Framework integration
- Privacy-compliant data handling
- Professional UI/UX implementation

### **Learning Resources**
- [Flutter Documentation](https://docs.flutter.dev/)
- [Storage Access Framework Guide](https://developer.android.com/guide/topics/providers/document-provider)
- [Android Security Best Practices](https://developer.android.com/training/articles/security-tips)
- [Material Design 3](https://m3.material.io/)

## 🔄 **Recent Updates**

### **v1.0.0 - Latest Release**
- ✅ **SAF Integration**: Permission-free file operations on Android 11+
- ✅ **Smart Import**: Append-only JSON imports with duplicate detection
- ✅ **Dark Theme**: Complete theme system with persistence
- ✅ **Security Enhancements**: AES-256 encryption with integrity verification
- ✅ **Modern UI**: Material Design 3 implementation
- ✅ **Performance**: Optimized for smooth operation on all devices

---

## 📄 **License & Contributing**

This project demonstrates best practices for Flutter app development with a focus on security, privacy, and modern Android compatibility. Contributions and feedback are welcome to help improve the codebase and documentation.

**Built with ❤️ using Flutter**
