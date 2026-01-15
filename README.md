Welcome to SmartPantry! ��🍎

Hey there! Thanks for checking out SmartPantry. 

I built this app because I was tired of buying ingredients I already had or throwing away food that expired at the back of my fridge. SmartPantry is your intelligent kitchen assistant designed to help you organize your food, save money, and maybe even inspire your next meal!

What Can It Do? ✨

Here's how SmartPantry helps you run a smarter kitchen:

*   🧐 See Everything: Keep a digital inventory of your pantry, fridge, and freezer. No more guessing if you have eggs while you're at the store.
*   📷 Scan & Go: Adding items is a breeze—just scan the barcode!
*   👩‍🍳 Chef AI: Not sure what to cook? Our AI (powered by Claude 3) looks at what you have and suggests delicious recipes.
*   🛒 Shopping Simplified: It automatically tracks what you need and builds your shopping list for you.
*   📉 Waste Not: Track your consumption habits and get nudges before food expires. Let's fight food waste together!

Under the Hood 🛠️

For the developers out there, here's what makes SmartPantry tick:

*   Native iOS: Built 100% in Swift and SwiftUI for that smooth, buttery Apple experience.
*   AI Brain: Leverages the OpenRouter API (Claude 3 Haiku) to generate creative recipes.
*   Machine Learning: Uses Google ML Kit for fast and accurate barcode scanning.

Let's Get Cooking (Setup) 🚀

Want to run this locally? Awesome! Here is how to get started:

You'll Need
*   Xcode 15 or later
*   iOS 16.0+
*   A cup of coffee (or tea!) ☕️

Installation Steps

1.  Clone the magic:
    ```bash
    git clone https://github.com/AbhiChikhalkar/Smart-Pantry.git
    cd Smart-Pantry
    ```

2.  Install the pods:
    ```bash
    pod install
    ```

3.  Open the project:
    Make sure to open the workspace file, not the project file!
    ```bash
    open SmartPantry.xcworkspace
    ```

4.  The Secret Sauce (API Key):
    To get the AI chef working, you'll need an API key from OpenRouter.
    *   Go to SmartPantry/Services/OpenRouterService.swift
    *   Find the apiKey property and add your key:
        ```swift
        private let apiKey = "YOUR_SUPER_SECRET_KEY"
        ```

5.  Run it!
    Hit that Play button in Xcode and start scanning!

Contributing 🤝

Got an idea to make SmartPantry even better? I'd love to hear it! Feel free to open an issue or submit a Pull Request. Let's make kitchen management fun.

License 📄

This project is licensed under the MIT License. Feel free to use it, learn from it, and build upon it!
