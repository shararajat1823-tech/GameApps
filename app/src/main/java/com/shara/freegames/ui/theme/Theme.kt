package com.shara.freegames.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

val BrandDark = Color(0xFF0B1E3F)
val BrandBlue = Color(0xFF1C3C78)
val BrandGold = Color(0xFFF2C14E)

private val AppColorScheme = darkColorScheme(
    primary = BrandGold,
    onPrimary = BrandDark,
    secondary = BrandBlue,
    background = BrandDark,
    surface = BrandBlue,
    onBackground = Color.White,
    onSurface = Color.White,
)

@Composable
fun FreeGamesTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    // The app leans into a premium dark look, so we use the dark scheme by default.
    val colorScheme = AppColorScheme

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = BrandDark.toArgb()
            window.navigationBarColor = BrandDark.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = false
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        content = content,
    )
}
