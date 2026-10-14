package com.shara.freegames

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Casino
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.SportsEsports
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.shara.freegames.ui.theme.BrandBlue
import com.shara.freegames.ui.theme.BrandDark
import com.shara.freegames.ui.theme.BrandGold

private data class GameEntry(
    val title: String,
    val subtitle: String,
    val icon: ImageVector,
    val target: Screen?, // null = coming soon
)

private val games = listOf(
    GameEntry("Tic-Tac-Toe", "Beat the computer in 3-in-a-row", Icons.Filled.GridView, Screen.TicTacToe),
    GameEntry("Ludo", "Classic 4-player board game", Icons.Filled.Casino, null),
    GameEntry("Ragdoll Archers", "Slingshot archery duel", Icons.Filled.SportsEsports, null),
)

@Composable
fun HomeScreen(onOpenGame: (Screen) -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(listOf(BrandDark, BrandBlue, BrandDark))
            )
    ) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            item { Header() }
            items(games) { game ->
                GameCard(game = game, onClick = {
                    if (game.target != null) onOpenGame(game.target)
                })
            }
            item {
                Spacer(Modifier.height(8.dp))
                Text(
                    text = "More games coming soon",
                    color = Color.White.copy(alpha = 0.5f),
                    fontSize = 13.sp,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }
    }
}

@Composable
private fun Header() {
    Column(modifier = Modifier.padding(bottom = 10.dp)) {
        Text(
            text = "FREE GAMES",
            color = BrandGold,
            fontSize = 34.sp,
            fontWeight = FontWeight.ExtraBold,
            letterSpacing = 2.sp,
        )
        Text(
            text = "Pick a game and play",
            color = Color.White.copy(alpha = 0.7f),
            fontSize = 15.sp,
        )
    }
}

@Composable
private fun GameCard(game: GameEntry, onClick: () -> Unit) {
    val locked = game.target == null
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(enabled = !locked, onClick = onClick),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (locked) BrandBlue.copy(alpha = 0.4f) else BrandBlue
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 6.dp),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .size(52.dp)
                    .background(BrandGold.copy(alpha = if (locked) 0.4f else 1f), CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = game.icon,
                    contentDescription = null,
                    tint = BrandDark,
                    modifier = Modifier.size(28.dp),
                )
            }
            Spacer(Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = game.title,
                    color = Color.White,
                    fontSize = 19.sp,
                    fontWeight = FontWeight.Bold,
                )
                Text(
                    text = if (locked) "Coming soon" else game.subtitle,
                    color = Color.White.copy(alpha = 0.65f),
                    fontSize = 13.sp,
                )
            }
            if (locked) {
                Icon(
                    imageVector = Icons.Filled.Lock,
                    contentDescription = "Locked",
                    tint = Color.White.copy(alpha = 0.6f),
                )
            }
        }
    }
}
