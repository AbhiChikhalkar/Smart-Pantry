# SmartPantry 🍎

SmartPantry is an intelligent iOS application designed to help you manage your kitchen inventory, reduce food waste, and discover new recipes.

## Features ✨

- **Inventory Management**: Keep track of what's in your pantry, fridge, and freezer.
- **Barcode Scanning**: Quickly add items by scanning their barcodes.
- **Recipe Generation**: Get AI-powered recipe suggestions based on your available ingredients.
- **Shopping List**: Automatically generate shopping lists for missing items.
- **Insights**: Visualize your consumption habits and track food waste.
- **Expiration Tracking**: Get notified before your food goes bad.

## Tech Stack 🛠️

- **Language**: Swift
- **UI Framework**: SwiftUI
- **AI Integration**: OpenRouter API (Claude 3 Haiku) for recipe generation
- **Dependencies**: Google ML Kit (for barcode scanning)

## Getting Started 🚀

### Prerequisites

- Xcode 15+
- iOS 16.0+
- Ruby (for CocoaPods)

### Installation

1.  Clone the repository:
    ```bash
    git clone https://github.com/AbhiChikhalkar/Smart-Pantry.git
    cd Smart-Pantry
    ```

2.  Install dependencies:
    ```bash
    pod install
    ```

3.  Open the workspace:
    ```bash
    open SmartPantry.xcworkspace
    ```

4.  **API Key Configuration**:
    - The `OpenRouterService.swift` file requires a valid OpenRouter API key.
    - Locate `OpenRouterService.swift` and uncomment/add your key:
      ```swift
      private let apiKey = "YOUR_API_KEY_HERE"
      ```

5.  Build and Run in Xcode.

## Contributing 🤝

Contributions are welcome! Please feel free to submit a Pull Request.

## License 📄

This project is licensed under the MIT License.
