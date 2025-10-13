# Transition
It is important to know, currently, our application is built based for MacOS.

## Reason
Our key feature, reading user-input from anywhere, is not allowed in iOS system from privacy and security reason.
Therefore, our interface will be changed a little bit.
Instead of of trigger, we will be developing a new input keyboard (based off existing open Source project).

## Evalution/Idea
Given that on iOS, switching between input method is rather simple, with little friction, and potentially can give us advanced and interesting feature given the flexibility of customized keyboard.

e.g. more potential interaction, right on keyboard however, we need to be careful, we want to emphasize on the frictionless, simple to none interaction. 

## PENDING Design philosophy
One idea is that, our keyboard must have a different design language than the built in keyboard for user to not rely on it as the daily use one.
On the other hand, we definitely hope that, if we make the keyboard good enough, we want user to use our keyboard for daily use -> decrease application use friction. In this case, we want our keyboard perform just like the built in keyboard. [Chinese handling is really tough in this part]

# iOS Design (need to update)
This goes back to the problem of usage:
1. if it is a notate info only keyboard, no trigger needed
2. if we build it to be a good-for-daily-use keyboard ( we might even be able to make some interesting keyboard based product from this point), then we still need trigger.

# Potential Open Source Keyboard [chatgpt as source]
1. KeyboardKit
	•	Language: Swift / SwiftUI
	•	Description: A modern SDK for building custom keyboard extensions. Provides base keyboard UI, input actions, locale support, and themes.
	•	Highlights:
	•	Modular architecture for input views and behaviors
	•	Ready-made layouts (alphabetic, numeric, symbolic)
	•	Localization and custom theme support
	•	Limitations: You’ll need to implement features like autocorrect and suggestions manually.

⸻

2. CustomKeyboard by EthanSK
	•	Language: Swift 5
	•	Description: A lightweight custom keyboard extension example project.
	•	Highlights:
	•	Great starting point for beginners
	•	Simple layout with basic key actions
	•	Limitations: Minimal functionality — designed primarily for educational purposes.

⸻

3. AkifKeyboard
	•	Language: Swift
	•	Description: A functional custom iOS keyboard written from scratch, works without internet access.
	•	Highlights:
	•	Custom key layout and styling
	•	Handles text input cleanly with minimal dependencies
	•	Limitations: Limited advanced features (e.g., predictive text).

⸻

4. KeyboardLayoutEngine
	•	Language: Swift
	•	Description: A layout utility framework for dynamically arranging keyboard keys.
	•	Highlights:
	•	Provides flexible layout engine for key grids
	•	Supports dynamic resizing and reflow
	•	Limitations: Focuses only on layout — no typing logic or input handling.

⸻

5. SimpleKeyboard
	•	Language: Swift
	•	Description: A simple iOS keyboard clone with customizable 2D-array-based layout.
	•	Highlights:
	•	Easy to modify key placement and appearance
	•	Clean structure for building from scratch
	•	Limitations: No predictive text or gesture typing.

⸻

6. Tasty-Imitation-Keyboard
	•	Language: Swift (legacy Objective-C parts)
	•	Description: A reverse-engineered imitation of Apple’s iOS keyboard.
	•	Highlights:
	•	Mimics native look and feel surprisingly well
	•	Demonstrates advanced layout and animation handling
	•	Limitations: Slightly outdated (last active around iOS 9–11 era).

⸻

7. Giella Keyboard (giellakbd-ios)
	•	Language: Swift
	•	Description: A near full-feature keyboard implementation supporting multilingual and minority languages.
	•	Highlights:
	•	Advanced layout and localization system
	•	Close to Apple keyboard experience
	•	Uses shared backend with Android counterpart (Giella keyboards)
	•	Limitations: Complex setup; designed for localization first.