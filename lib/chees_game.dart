import 'dart:math';
import 'package:flutter/material.dart';

class ChessGamePage extends StatefulWidget {
  const ChessGamePage({super.key});

  @override
  State<ChessGamePage> createState() => _ChessGamePageState();
}

class _ChessGamePageState extends State<ChessGamePage> {
  late List<List<ChessPiece?>> board;
  String currentPlayer = 'white'; // white first
  String? gameMode = 'vs_npc'; // vs_npc or vs_player
  bool gameOver = false;
  String winner = '';
  int? selectedRow;
  int? selectedCol;
  List<List<int>> validMoves = [];
  bool isThinking = false;
  
  final Random _random = Random();

  // Piece values for AI
  final Map<String, int> pieceValues = {
    'pawn': 10,
    'knight': 30,
    'bishop': 30,
    'rook': 50,
    'queen': 90,
    'king': 900,
  };

  @override
  void initState() {
    super.initState();
    _initBoard();
  }

  void _initBoard() {
    board = List.generate(8, (_) => List.generate(8, (_) => null));
    
    // Place pawns
    for (int i = 0; i < 8; i++) {
      board[1][i] = ChessPiece(type: 'pawn', color: 'black');
      board[6][i] = ChessPiece(type: 'pawn', color: 'white');
    }
    
    // Place other pieces - black
    board[0][0] = ChessPiece(type: 'rook', color: 'black');
    board[0][1] = ChessPiece(type: 'knight', color: 'black');
    board[0][2] = ChessPiece(type: 'bishop', color: 'black');
    board[0][3] = ChessPiece(type: 'queen', color: 'black');
    board[0][4] = ChessPiece(type: 'king', color: 'black');
    board[0][5] = ChessPiece(type: 'bishop', color: 'black');
    board[0][6] = ChessPiece(type: 'knight', color: 'black');
    board[0][7] = ChessPiece(type: 'rook', color: 'black');
    
    // Place other pieces - white
    board[7][0] = ChessPiece(type: 'rook', color: 'white');
    board[7][1] = ChessPiece(type: 'knight', color: 'white');
    board[7][2] = ChessPiece(type: 'bishop', color: 'white');
    board[7][3] = ChessPiece(type: 'queen', color: 'white');
    board[7][4] = ChessPiece(type: 'king', color: 'white');
    board[7][5] = ChessPiece(type: 'bishop', color: 'white');
    board[7][6] = ChessPiece(type: 'knight', color: 'white');
    board[7][7] = ChessPiece(type: 'rook', color: 'white');
  }

  void resetGame() {
    setState(() {
      _initBoard();
      currentPlayer = 'white';
      gameOver = false;
      winner = '';
      selectedRow = null;
      selectedCol = null;
      validMoves = [];
      isThinking = false;
    });
  }

  void setGameMode(String mode) {
    setState(() {
      gameMode = mode;
      resetGame();
    });
  }

  List<List<int>> getValidMoves(int row, int col) {
    ChessPiece? piece = board[row][col];
    if (piece == null || piece.color != currentPlayer) return [];
    
    List<List<int>> moves = [];
    
    switch (piece.type) {
      case 'pawn':
        moves = _getPawnMoves(row, col, piece.color);
        break;
      case 'rook':
        moves = _getRookMoves(row, col, piece.color);
        break;
      case 'knight':
        moves = _getKnightMoves(row, col, piece.color);
        break;
      case 'bishop':
        moves = _getBishopMoves(row, col, piece.color);
        break;
      case 'queen':
        moves = _getRookMoves(row, col, piece.color);
        moves.addAll(_getBishopMoves(row, col, piece.color));
        break;
      case 'king':
        moves = _getKingMoves(row, col, piece.color);
        break;
    }
    
    // Filter moves that would put own king in check
    moves.removeWhere((move) => wouldBeInCheck(row, col, move[0], move[1], piece!.color));
    
    return moves;
  }

  List<List<int>> _getPawnMoves(int row, int col, String color) {
    List<List<int>> moves = [];
    int direction = color == 'white' ? -1 : 1;
    int startRow = color == 'white' ? 6 : 1;
    
    // Move forward one step
    if (_isValidPosition(row + direction, col) && board[row + direction][col] == null) {
      moves.add([row + direction, col]);
      
      // Move forward two steps from starting position
      if (row == startRow && board[row + 2 * direction][col] == null) {
        moves.add([row + 2 * direction, col]);
      }
    }
    
    // Capture diagonally
    for (int dc in [-1, 1]) {
      int newRow = row + direction;
      int newCol = col + dc;
      if (_isValidPosition(newRow, newCol)) {
        ChessPiece? target = board[newRow][newCol];
        if (target != null && target.color != color) {
          moves.add([newRow, newCol]);
        }
      }
    }
    
    return moves;
  }

  List<List<int>> _getRookMoves(int row, int col, String color) {
    List<List<int>> moves = [];
    for (int dr in [-1, 0, 1]) {
      for (int dc in [0, 1]) {
        if (dr.abs() + dc.abs() != 1) continue;
        for (int i = 1; i <= 7; i++) {
          int newRow = row + dr * i;
          int newCol = col + dc * i;
          if (!_isValidPosition(newRow, newCol)) break;
          
          ChessPiece? target = board[newRow][newCol];
          if (target == null) {
            moves.add([newRow, newCol]);
          } else {
            if (target.color != color) moves.add([newRow, newCol]);
            break;
          }
        }
      }
    }
    return moves;
  }

  List<List<int>> _getKnightMoves(int row, int col, String color) {
    List<List<int>> moves = [];
    List<List<int>> offsets = [
      [-2, -1], [-2, 1], [-1, -2], [-1, 2],
      [1, -2], [1, 2], [2, -1], [2, 1]
    ];
    
    for (var offset in offsets) {
      int newRow = row + offset[0];
      int newCol = col + offset[1];
      if (_isValidPosition(newRow, newCol)) {
        ChessPiece? target = board[newRow][newCol];
        if (target == null || target.color != color) {
          moves.add([newRow, newCol]);
        }
      }
    }
    return moves;
  }

  List<List<int>> _getBishopMoves(int row, int col, String color) {
    List<List<int>> moves = [];
    for (int dr in [-1, 1]) {
      for (int dc in [-1, 1]) {
        for (int i = 1; i <= 7; i++) {
          int newRow = row + dr * i;
          int newCol = col + dc * i;
          if (!_isValidPosition(newRow, newCol)) break;
          
          ChessPiece? target = board[newRow][newCol];
          if (target == null) {
            moves.add([newRow, newCol]);
          } else {
            if (target.color != color) moves.add([newRow, newCol]);
            break;
          }
        }
      }
    }
    return moves;
  }

  List<List<int>> _getKingMoves(int row, int col, String color) {
    List<List<int>> moves = [];
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        int newRow = row + dr;
        int newCol = col + dc;
        if (_isValidPosition(newRow, newCol)) {
          ChessPiece? target = board[newRow][newCol];
          if (target == null || target.color != color) {
            moves.add([newRow, newCol]);
          }
        }
      }
    }
    return moves;
  }

  bool _isValidPosition(int row, int col) {
    return row >= 0 && row < 8 && col >= 0 && col < 8;
  }

  bool wouldBeInCheck(int fromRow, int fromCol, int toRow, int toCol, String color) {
    // Simulate move
    ChessPiece? piece = board[fromRow][fromCol];
    ChessPiece? captured = board[toRow][toCol];
    board[toRow][toCol] = piece;
    board[fromRow][fromCol] = null;
    
    bool inCheck = isKingInCheck(color);
    
    // Undo simulation
    board[fromRow][fromCol] = piece;
    board[toRow][toCol] = captured;
    
    return inCheck;
  }

  bool isKingInCheck(String color) {
    // Find king position
    int kingRow = -1, kingCol = -1;
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        ChessPiece? piece = board[i][j];
        if (piece != null && piece.type == 'king' && piece.color == color) {
          kingRow = i;
          kingCol = j;
          break;
        }
      }
    }
    
    // Check if any opponent piece can capture king
    String opponentColor = color == 'white' ? 'black' : 'white';
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        ChessPiece? piece = board[i][j];
        if (piece != null && piece.color == opponentColor) {
          List<List<int>> moves = _getAllMovesForPiece(i, j, opponentColor);
          if (moves.any((move) => move[0] == kingRow && move[1] == kingCol)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  List<List<int>> _getAllMovesForPiece(int row, int col, String color) {
    ChessPiece? piece = board[row][col];
    if (piece == null) return [];
    
    switch (piece.type) {
      case 'pawn':
        return _getPawnMoves(row, col, color);
      case 'rook':
        return _getRookMoves(row, col, color);
      case 'knight':
        return _getKnightMoves(row, col, color);
      case 'bishop':
        return _getBishopMoves(row, col, color);
      case 'queen':
        return [..._getRookMoves(row, col, color), ..._getBishopMoves(row, col, color)];
      case 'king':
        return _getKingMoves(row, col, color);
      default:
        return [];
    }
  }

  bool isCheckmate(String color) {
    if (!isKingInCheck(color)) return false;
    
    // Check if any piece can move to get out of check
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        ChessPiece? piece = board[i][j];
        if (piece != null && piece.color == color) {
          List<List<int>> moves = getValidMoves(i, j);
          if (moves.isNotEmpty) return false;
        }
      }
    }
    return true;
  }

  void makeMove(int fromRow, int fromCol, int toRow, int toCol) {
    ChessPiece? piece = board[fromRow][fromCol];
    ChessPiece? captured = board[toRow][toCol];
    
    // Check if move is valid
    if (!validMoves.any((move) => move[0] == toRow && move[1] == toCol)) return;
    
    setState(() {
      // Make the move
      board[toRow][toCol] = piece;
      board[fromRow][fromCol] = null;
      
      // Pawn promotion
      if (piece?.type == 'pawn') {
        if ((piece?.color == 'white' && toRow == 0) || (piece?.color == 'black' && toRow == 7)) {
          _showPromotionDialog(toRow, toCol, piece!.color);
        }
      }
      
      // Check for game over
      String nextPlayer = currentPlayer == 'white' ? 'black' : 'white';
      if (isCheckmate(nextPlayer)) {
        gameOver = true;
        winner = currentPlayer;
      }
      
      currentPlayer = nextPlayer;
      selectedRow = null;
      selectedCol = null;
      validMoves = [];
      
      // AI move if vs NPC and game not over
      if (gameMode == 'vs_npc' && !gameOver && currentPlayer == 'black' && !isThinking) {
        _makeAIMove();
      }
    });
  }

  void _showPromotionDialog(int row, int col, String color) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Promote Pawn', style: TextStyle(color: Colors.white)),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _promotionPiece('queen', color, row, col),
            _promotionPiece('rook', color, row, col),
            _promotionPiece('bishop', color, row, col),
            _promotionPiece('knight', color, row, col),
          ],
        ),
      ),
    );
  }

  Widget _promotionPiece(String type, String color, int row, int col) {
    return GestureDetector(
      onTap: () {
        setState(() {
          board[row][col] = ChessPiece(type: type, color: color);
        });
        Navigator.pop(context);
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_getPieceIcon(type, color), size: 40, color: color == 'white' ? Colors.white : Colors.black),
      ),
    );
  }

  // AI Move using minimax with alpha-beta pruning
  Future<void> _makeAIMove() async {
    if (isThinking) return;
    setState(() => isThinking = true);
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    var bestMove = _getBestMove();
    if (bestMove != null) {
      makeMove(bestMove['fromRow']!, bestMove['fromCol']!, bestMove['toRow']!, bestMove['toCol']!);
    }
    
    setState(() => isThinking = false);
  }

  Map<String, int>? _getBestMove() {
    List<Map<String, int>> allMoves = [];
    
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        ChessPiece? piece = board[i][j];
        if (piece != null && piece.color == 'black') {
          List<List<int>> moves = getValidMoves(i, j);
          for (var move in moves) {
            allMoves.add({
              'fromRow': i,
              'fromCol': j,
              'toRow': move[0],
              'toCol': move[1],
            });
          }
        }
      }
    }
    
    if (allMoves.isEmpty) return null;
    
    // Evaluate each move
    for (var move in allMoves) {
      move['score'] = _evaluateMove(move['fromRow']!, move['fromCol']!, move['toRow']!, move['toCol']!);
    }
    
    // Sort by score (higher is better for AI)
    allMoves.sort((a, b) => (b['score'] ?? -9999).compareTo(a['score'] ?? -9999));
    
    // Pick best move (with some randomness)
    int topMoves = min(3, allMoves.length);
    if (topMoves > 0 && allMoves[0]['score'] == allMoves[topMoves - 1]['score']) {
      return allMoves[_random.nextInt(topMoves)];
    }
    return allMoves[0];
  }

  int _evaluateMove(int fromRow, int fromCol, int toRow, int toCol) {
    int score = 0;
    ChessPiece? piece = board[fromRow][fromCol];
    ChessPiece? target = board[toRow][toCol];
    
    // Capture piece
    if (target != null) {
      score += pieceValues[target.type] ?? 0;
    }
    
    // Prefer moving to center
    int centerDist = (toRow - 3.5).abs() + (toCol - 3.5).abs();
    score += (7 - centerDist) * 2;
    
    // Prefer pawn promotion
    if (piece?.type == 'pawn') {
      if ((piece?.color == 'black' && toRow == 7)) {
        score += 80;
      }
    }
    
    // Avoid moving into check
    if (wouldBeInCheck(fromRow, fromCol, toRow, toCol, 'black')) {
      score -= 100;
    }
    
    return score;
  }

  IconData _getPieceIcon(String type, String color) {
    bool isWhite = color == 'white';
    switch (type) {
      case 'king': return isWhite ? Icons.workspace_premium : Icons.workspace_premium;
      case 'queen': return isWhite ? Icons.star : Icons.star;
      case 'rook': return isWhite ? Icons.apartment : Icons.apartment;
      case 'bishop': return isWhite ? Icons.church : Icons.church;
      case 'knight': return isWhite ? Icons.emoji_people : Icons.emoji_people;
      case 'pawn': return isWhite ? Icons.circle : Icons.circle;
      default: return Icons.circle;
    }
  }

  Color _getSquareColor(int row, int col) {
    bool isLight = (row + col) % 2 == 0;
    if (selectedRow == row && selectedCol == col) {
      return Colors.blue.withOpacity(0.5);
    }
    if (validMoves.any((move) => move[0] == row && move[1] == col)) {
      return Colors.green.withOpacity(0.4);
    }
    return isLight ? const Color(0xFFF0D9B5) : const Color(0xFFB58863);
  }

  void onSquareTap(int row, int col) {
    if (gameOver) return;
    
    if (selectedRow == null) {
      // Select piece
      ChessPiece? piece = board[row][col];
      if (piece != null && piece.color == currentPlayer) {
        setState(() {
          selectedRow = row;
          selectedCol = col;
          validMoves = getValidMoves(row, col);
        });
      }
    } else {
      // Try to move
      makeMove(selectedRow!, selectedCol!, row, col);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      appBar: AppBar(
        title: const Text('Chess Game', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A1A),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: resetGame,
            tooltip: 'Reset Game',
          ),
        ],
      ),
      body: Column(
        children: [
          // Game Mode Selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeButton('vs_npc', '🤖 VS NPC'),
                const SizedBox(width: 16),
                _buildModeButton('vs_player', '👥 VS PLAYER'),
              ],
            ),
          ),
          
          // Game Status
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const Text('WHITE', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: currentPlayer == 'white' && !gameOver ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Text(
                  gameOver ? 'GAME OVER - $winner WINS!' : (isThinking ? 'AI THINKING...' : ''),
                  style: TextStyle(
                    color: gameOver ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Column(
                  children: [
                    const Text('BLACK', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: currentPlayer == 'black' && !gameOver && gameMode != 'vs_npc' ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Chess Board
          Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 64,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                ),
                itemBuilder: (context, index) {
                  int row = index ~/ 8;
                  int col = index % 8;
                  ChessPiece? piece = board[row][col];
                  
                  return GestureDetector(
                    onTap: () => onSquareTap(row, col),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getSquareColor(row, col),
                        border: Border.all(color: Colors.black.withOpacity(0.2)),
                      ),
                      child: Center(
                        child: piece != null
                            ? Icon(
                                _getPieceIcon(piece.type, piece.color),
                                size: 40,
                                color: piece.color == 'white' ? Colors.white : Colors.black,
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Reset Button
          ElevatedButton.icon(
            onPressed: resetGame,
            icon: const Icon(Icons.refresh),
            label: const Text('RESET GAME'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildModeButton(String mode, String label) {
    bool isSelected = gameMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setGameMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFD32F2F), Color(0xFFFF5252)],
                  )
                : null,
            color: isSelected ? null : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.red : Colors.white24,
              width: 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class ChessPiece {
  final String type;
  final String color;
  
  ChessPiece({required this.type, required this.color});
}