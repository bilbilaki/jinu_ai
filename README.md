# AI Studio Flutter

A comprehensive Flutter application built with Clean Architecture, featuring responsive design and AI model integration capabilities.

## 🏗️ Architecture

This project follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── core/                    # Core utilities and shared components
│   ├── constants/          # App-wide constants
│   ├── di/                 # Dependency injection setup
│   ├── errors/             # Error handling and failures
│   ├── navigation/         # App routing configuration
│   ├── theme/              # Theme and styling
│   └── utils/              # Utility functions and helpers
├── data/                   # Data layer
│   ├── datasources/        # Remote and local data sources
│   ├── models/             # Data models with JSON serialization
│   └── repositories/       # Repository implementations
├── domain/                 # Domain layer (business logic)
│   ├── entities/           # Core business entities
│   ├── repositories/       # Repository interfaces
│   └── usecases/           # Business use cases
└── presentation/           # Presentation layer
    ├── blocs/              # State management (BLoC pattern)
    ├── pages/              # Screen widgets
    └── widgets/            # Reusable UI components
```

## 🎨 Features

### ✅ Implemented
- **Clean Architecture** with proper layer separation
- **Responsive Design** for mobile, tablet, and desktop
- **Theme System** with light/dark mode support
- **Navigation System** using GoRouter
- **State Management** with BLoC pattern
- **Dependency Injection** using GetIt
- **AI Chat Interface** with message history
- **Media Generation** for images and audio
- **Settings Management** with persistence
- **Profile System** with usage statistics

### 🔄 Ready for AI Integration
- **Modular AI Services** - Easy to connect different AI providers
- **Streaming Support** - Real-time response handling
- **Parameter Configuration** - Customizable AI model settings
- **Error Handling** - Robust error management for AI operations
- **Local Storage** - Chat history and media caching

## 📱 Responsive Design

The app adapts to different screen sizes:

- **Mobile** (< 600px): Bottom navigation, single column layout
- **Tablet** (600px - 1200px): Navigation rail, two-column layout
- **Desktop** (> 1200px): Side navigation, multi-column layout

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ai_studio_flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Development Setup

1. **Generate code** (for models and dependency injection)
   ```bash
   flutter packages pub run build_runner build
   ```

2. **Run tests**
   ```bash
   flutter test
   ```

## 🔧 Configuration

### AI Model Integration

To connect your AI models, update the data sources in `lib/data/datasources/`:

1. **AI Remote Data Source** (`ai_remote_datasource.dart`)
   - Configure API endpoints
   - Add authentication headers
   - Implement streaming responses

2. **Media Remote Data Source** (`media_remote_datasource.dart`)
   - Set up image generation APIs
   - Configure audio generation services
   - Handle file uploads/downloads

### Environment Variables

Create a `.env` file in the root directory:

```env
OPENAI_API_KEY=your_openai_api_key
ANTHROPIC_API_KEY=your_anthropic_api_key
STABILITY_API_KEY=your_stability_api_key
```

## 🎯 Usage Examples

### Adding a New AI Provider

1. **Create a new data source**
   ```dart
   class CustomAIDataSource implements AIRemoteDataSource {
     // Implement your custom AI provider
   }
   ```

2. **Register in dependency injection**
   ```dart
   sl.registerLazySingleton<AIRemoteDataSource>(
     () => CustomAIDataSource(client: sl()),
   );
   ```

### Customizing Themes

Modify `lib/core/theme/app_theme.dart`:

```dart
static ThemeData get lightTheme => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue, // Change primary color
    brightness: Brightness.light,
  ),
  // Add custom styling
);
```

### Adding New Pages

1. **Create page widget** in `lib/presentation/pages/`
2. **Add route** in `lib/core/navigation/app_router.dart`
3. **Update navigation** in main layout

## 📦 Dependencies

### Core Dependencies
- `flutter_bloc` - State management
- `get_it` - Dependency injection
- `go_router` - Navigation
- `dartz` - Functional programming
- `equatable` - Value equality

### UI Dependencies
- `cached_network_image` - Image caching
- `shimmer` - Loading animations
- `lottie` - Vector animations

### Data Dependencies
- `http` - HTTP client
- `shared_preferences` - Local storage
- `hive` - NoSQL database

### Development Dependencies
- `build_runner` - Code generation
- `bloc_test` - BLoC testing
- `mocktail` - Mocking

## 🧪 Testing

The project includes comprehensive testing setup:

- **Unit Tests** - Business logic and use cases
- **Widget Tests** - UI components
- **Integration Tests** - End-to-end workflows
- **BLoC Tests** - State management

Run tests with:
```bash
flutter test
flutter test --coverage
```

## 🔒 Security

- API keys are stored securely using environment variables
- Local data is encrypted using Hive
- Network requests include proper authentication
- Input validation prevents injection attacks

## 🌐 Internationalization

The app supports multiple languages:
- English (default)
- Spanish, French, German
- Italian, Portuguese, Russian
- Japanese, Korean, Chinese

Add new translations in `lib/l10n/`.

## 📈 Performance

- **Lazy loading** for heavy widgets
- **Image caching** for better performance
- **Efficient state management** with BLoC
- **Responsive layouts** optimized for each platform

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Follow the existing code style
4. Add tests for new features
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue on GitHub
- Check the documentation
- Review the example implementations

## 🚀 Deployment

### Web
```bash
flutter build web
```

### Mobile
```bash
flutter build apk --release
flutter build ios --release
```

### Desktop
```bash
flutter build windows
flutter build macos
flutter build linux
```

---

**Built with ❤️ using Flutter and Clean Architecture**