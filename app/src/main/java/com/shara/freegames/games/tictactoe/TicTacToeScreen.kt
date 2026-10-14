package com.shara.freegames.games.tictactoe

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.shara.freegames.ui.theme.BrandBlue
import com.shara.freegames.ui.theme.BrandDark
import com.shara.freegames.ui.theme.BrandGold
import kotlinx.coroutines.delay

private const val EMPTY = ' '
private const val HUMAN = 'X'
private const val AI = 'O'

@Composable
fun TicTacToeScreen(onBack: () -> Unit) {
    // Board is 9 cells, index 0..8. ' ' means empty.
    var board by remember { mutableStateOf(List(9) { EMPTY }) }
    var status by remember { mutableStateOf("Your turn (X)") }
    var gameOver by remember { mutableStateOf(false) }
    var humanTurn by remember { mutableStateOf(true) }
    var winCount by remember { mutableIntStateOf(0) }
    var lossCount by remember { mutableIntStateOf(0) }
    var drawCount by remember { mutableIntStateOf(0) }

    fun reset() {
        board = List(9) { EMPTY }
        status = "Your turn (X)"
        gameOver = false
        humanTurn = true
    }

    fun finishIfOver(): Boolean {
        val winner = winnerOf(board)
        if (winner == HUMAN) {
            status = "You win! 🎉"; gameOver = true; winCount++; return true
        }
        if (winner == AI) {
            status = "Computer wins"; gameOver = true; lossCount++; return true
        }
        if (board.none { it == EMPTY }) {
            status = "It's a draw"; gameOver = true; drawCount++; return true
        }
        return false
    }

    // When it becomes the AI's turn, let it move after a short "thinking" pause.
    LaunchedEffect(humanTurn, gameOver) {
        if (!humanTurn && !gameOver) {
            status = "Computer thinking…"
            delay(500)
            val move = bestAiMove(board)
            if (move >= 0) {
                board = board.toMutableList().also { it[move] = AI }
            }
            if (!finishIfOver()) {
                humanTurn = true
                status = "Your turn (X)"
            }
        }
    }

    fun onCellTap(index: Int) {
        if (gameOver || !humanTurn || board[index] != EMPTY) return
        board = board.toMutableList().also { it[index] = HUMAN }
        if (!finishIfOver()) {
            humanTurn = false
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Brush.verticalGradient(listOf(BrandDark, BrandBlue, BrandDark)))
            .padding(20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        // Top bar
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(onClick = onBack) {
                Icon(
                    Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Back",
                    tint = Color.White,
                )
            }
            Text(
                text = "Tic-Tac-Toe",
                color = BrandGold,
                fontSize = 24.sp,
                fontWeight = FontWeight.ExtraBold,
                modifier = Modifier.padding(start = 4.dp),
            )
        }

        ScoreBar(win = winCount, loss = lossCount, draw = drawCount)

        Text(
            text = status,
            color = Color.White,
            fontSize = 20.sp,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(vertical = 18.dp),
        )

        // Board
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(1f)
                .background(BrandBlue, RoundedCornerShape(18.dp))
                .padding(10.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            for (r in 0 until 3) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    for (c in 0 until 3) {
                        val index = r * 3 + c
                        Cell(
                            value = board[index],
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxSize(),
                            onClick = { onCellTap(index) },
                        )
                    }
                }
            }
        }

        Button(
            onClick = { reset() },
            colors = ButtonDefaults.buttonColors(
                containerColor = BrandGold,
                contentColor = BrandDark,
            ),
            shape = RoundedCornerShape(14.dp),
            modifier = Modifier
                .padding(top = 24.dp)
                .fillMaxWidth()
                .height(54.dp),
        ) {
            Text(
                text = if (gameOver) "Play Again" else "Restart",
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
            )
        }
    }
}

@Composable
private fun ScoreBar(win: Int, loss: Int, draw: Int) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 12.dp),
        horizontalArrangement = Arrangement.SpaceEvenly,
    ) {
        ScoreChip("Wins", win, BrandGold)
        ScoreChip("Draws", draw, Color.White)
        ScoreChip("Losses", loss, Color(0xFFE57373))
    }
}

@Composable
private fun ScoreChip(label: String, value: Int, color: Color) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(text = value.toString(), color = color, fontSize = 26.sp, fontWeight = FontWeight.Bold)
        Text(text = label, color = Color.White.copy(alpha = 0.7f), fontSize = 13.sp)
    }
}

@Composable
private fun Cell(value: Char, modifier: Modifier, onClick: () -> Unit) {
    val scale by animateFloatAsState(
        targetValue = if (value == EMPTY) 0.6f else 1f,
        label = "cellScale",
    )
    Box(
        modifier = modifier
            .background(BrandDark, RoundedCornerShape(14.dp))
            .border(2.dp, BrandGold.copy(alpha = 0.25f), RoundedCornerShape(14.dp))
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        if (value != EMPTY) {
            Text(
                text = value.toString(),
                color = if (value == HUMAN) BrandGold else Color.White,
                fontSize = 56.sp,
                fontWeight = FontWeight.ExtraBold,
                modifier = Modifier.scale(scale),
            )
        }
    }
}

// --- Game logic -----------------------------------------------------------

private val WIN_LINES = listOf(
    intArrayOf(0, 1, 2), intArrayOf(3, 4, 5), intArrayOf(6, 7, 8), // rows
    intArrayOf(0, 3, 6), intArrayOf(1, 4, 7), intArrayOf(2, 5, 8), // cols
    intArrayOf(0, 4, 8), intArrayOf(2, 4, 6),                      // diagonals
)

private fun winnerOf(board: List<Char>): Char {
    for (line in WIN_LINES) {
        val (a, b, c) = Triple(line[0], line[1], line[2])
        if (board[a] != EMPTY && board[a] == board[b] && board[b] == board[c]) {
            return board[a]
        }
    }
    return EMPTY
}

/**
 * Simple but decent AI:
 * 1. win now if possible, 2. block the human's win, 3. take center,
 * 4. take a corner, 5. take any side.
 */
private fun bestAiMove(board: List<Char>): Int {
    findWinningMove(board, AI)?.let { return it }   // win
    findWinningMove(board, HUMAN)?.let { return it } // block

    if (board[4] == EMPTY) return 4                  // center

    val corners = listOf(0, 2, 6, 8).filter { board[it] == EMPTY }
    if (corners.isNotEmpty()) return corners.random()

    val sides = listOf(1, 3, 5, 7).filter { board[it] == EMPTY }
    if (sides.isNotEmpty()) return sides.random()

    return board.indexOfFirst { it == EMPTY }
}

private fun findWinningMove(board: List<Char>, player: Char): Int? {
    for (i in board.indices) {
        if (board[i] == EMPTY) {
            val test = board.toMutableList().also { it[i] = player }
            if (winnerOf(test) == player) return i
        }
    }
    return null
}
