# Moments

A SwiftUI iOS app for capturing and tracking special moments in your life.

## Features

- **Moment Creation**: Create and edit personal moments with custom colors and symbols
- **Home Screen Widgets**: View your moments directly from your home screen
- **Live Activities**: Real-time updates with Dynamic Island and Lock Screen integration
- **Smart Notifications**: Stay connected to your important moments
- **Time Tracking**: Built-in time engine for moment timing and progress
- **Customization**: Personalize moments with colors and symbols
- **Moments Board**: Visual overview of all your tracked moments

## Technical Details

- Built with **SwiftUI** for iOS
- **WidgetKit** integration for home screen widgets
- **ActivityKit** for Live Activities support
- **App Groups** for seamless data sharing between app and widgets
- **UserNotifications** framework for smart reminders

## Screenshots

*Coming soon...*

## Installation

1. Clone the repository:
```bash
git clone https://github.com/JoshOn360Hz/MomentsApp.git
cd MomentsApp
```

2. Open the project in Xcode:
```bash
open Moments.xcodeproj
```

3. Build and run the project on your device or simulator

## Project Structure

```
MomentsApp/
├── MomentsWidgetsExtension.entitlements
├── Moments/                                 # Main iOS app target
│   ├── AppDelegate.swift
│   ├── ContentView.swift
│   ├── MomentsApp.swift
│   ├── Info.plist
│   ├── Moments.entitlements
│   ├── Splash.storyboard
│   ├── Assets.xcassets/                     # App icons and assets
│   ├── Core/                                # Core logic
│   │   ├── AppGroup.swift
│   │   ├── LiveActivityManager.swift
│   │   ├── NotificationManager.swift
│   │   ├── TimeEngine.swift
│   │   └── WidgetDataManager.swift
│   ├── Models/                              # Data models
│   │   ├── Moment.swift
│   │   └── MomentsActivityAttributes.swift
│   ├── Shared/                              # Shared components
│   │   └── SharedModels.swift
│   └── UI/                                  # User interface
│       ├── Components/                      # Reusable UI components
│       │   ├── ColorPickerGrid.swift
│       │   ├── MomentTileView.swift
│       │   ├── ProgressRingView.swift
│       │   └── SymbolPickerView.swift
│       └── Views/                           # Main views
│           ├── MomentDetailView.swift
│           ├── MomentEditorView.swift
│           ├── MomentsBoardView.swift
│           ├── OnboardingView.swift
│           └── SettingsView.swift
├── MomentsWidgets/                          # Widget extension
│   ├── AppIntent.swift
│   ├── MomentsWidgetsBundle.swift
│   ├── MomentsWidgetsLiveActivity.swift
│   ├── SimpleWidgets.swift
│   ├── Info.plist
│   └── Assets.xcassets/
└── Moments.xcodeproj/                       # Xcode project files
```

## Usage

1. **Creating Moments**: Tap the "+" button to create a new moment with custom colors and symbols
2. **Tracking Progress**: View your moments on the main board with real-time progress indicators
3. **Widgets**: Add Moments widgets to your home screen for quick access
4. **Live Activities**: Enable Live Activities for Dynamic Island and Lock Screen updates
5. **Notifications**: Configure smart notifications to stay connected to your moments

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Requirements

- iOS 26.0+
- Xcode 26.0+
- Swift 6.0+

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

