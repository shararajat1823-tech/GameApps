# Free Games

A free mobile game collection for Android, built with **Kotlin + Jetpack Compose**.

The app is a launcher: a home screen lists games, and each game opens as its own
screen. Right now **Tic-Tac-Toe** (vs a computer opponent) is fully playable, with
Ludo and Ragdoll Archers stubbed in as "coming soon" cards to grow into.

## How to get the app on your phone

You don't need Android Studio installed. Every push to `main` triggers a GitHub
Actions build that compiles a debug APK and publishes it to the **`latest-debug`**
release.

1. Go to the repo's **Releases** page → **Latest Debug Build**.
2. Download `app-debug.apk` onto your Android phone.
3. Open it and allow "install from unknown sources" when prompted.

## Project layout

```
app/
  src/main/
    AndroidManifest.xml
    java/com/shara/freegames/
      MainActivity.kt            # entry point + simple screen navigation
      HomeScreen.kt              # the game launcher menu
      ui/theme/Theme.kt          # colors + Material3 theme
      games/tictactoe/
        TicTacToeScreen.kt       # a complete game: UI + logic + AI
    res/                         # icons, colors, strings
.github/workflows/build.yml      # CI: builds the APK and publishes a release
```

## Adding a new game

1. Add a `Screen` value in `MainActivity.kt`.
2. Create `games/<yourgame>/<YourGame>Screen.kt` with a `@Composable` screen.
3. Wire it into the `when (screen)` block in `MainActivity.kt`.
4. Add a `GameEntry` to the list in `HomeScreen.kt` (set `target` to your new
   `Screen` to make the card tappable).

## Building locally (optional)

If you install Android Studio, open this folder and press **Run**. Android Studio
will set up the Gradle wrapper and SDK for you. From the command line (with the
Android SDK configured) you can run:

```
gradle assembleDebug
```

## Tech

- Kotlin `2.0.21`, Android Gradle Plugin `8.7.3`, Gradle `8.10.2`
- Jetpack Compose (BOM `2024.12.01`), Material 3
- `compileSdk` / `targetSdk` 35, `minSdk` 26
