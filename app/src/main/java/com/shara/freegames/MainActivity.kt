package com.shara.freegames

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.shara.freegames.games.tictactoe.TicTacToeScreen
import com.shara.freegames.ui.theme.FreeGamesTheme

/** The one screen we are currently on. Simple enum-based navigation, no extra libraries. */
enum class Screen {
    Home,
    TicTacToe,
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            FreeGamesTheme {
                var screen by remember { mutableStateOf(Screen.Home) }

                when (screen) {
                    Screen.Home -> HomeScreen(
                        onOpenGame = { screen = it }
                    )
                    Screen.TicTacToe -> TicTacToeScreen(
                        onBack = { screen = Screen.Home }
                    )
                }
            }
        }
    }
}
