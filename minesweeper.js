class Minesweeper {
  constructor(rows, cols, mines) {
      this.rows = rows;
      this.cols = cols;
      this.mines = mines;
      this.board = [];
      this.revealed = new Set();
      this.flagged = new Set();
      this.gameOver = false;
      this.gridElement = document.getElementById('grid');
      this.restartButton = document.getElementById('restart-btn');
      this.flagsnMinesElement = document.getElementById('flags&Mines');
      this.init();
  }

  init() {
      this.gridElement.style.gridTemplateColumns = `repeat(${this.cols}, 30px)`;
      this.restartButton.addEventListener('click', () => this.reset());
      this.createBoard();
      this.placeMines();
      this.calculateNumbers();
      this.render();
      this.updateFlaggedRatio();
  }

  createBoard() {
      this.board = Array(this.rows).fill().map(() => 
          Array(this.cols).fill(0));
  }

  placeMines() {
      let minesPlaced = 0;
      while (minesPlaced < this.mines) {
          const row = Math.floor(Math.random() * this.rows);
          const col = Math.floor(Math.random() * this.cols);
          if (this.board[row][col] !== 'M') {
              this.board[row][col] = 'M';
              minesPlaced++;
          }
      }
  }

  calculateNumbers() {
      for (let i = 0; i < this.rows; i++) {
          for (let j = 0; j < this.cols; j++) {
              if (this.board[i][j] === 'M') continue; // only check non-mine squares
              
              let count = 0;
              for (let di = -1; di <= 1; di++) {
                  for (let dj = -1; dj <= 1; dj++) {
                      if (di === 0 && dj === 0) continue; // Basically, don't check if the non-mine square has a mine
                      const ni = i + di;
                      const nj = j + dj;
                      if (ni >= 0 && ni < this.rows && 
                          nj >= 0 && nj < this.cols && 
                          this.board[ni][nj] === 'M') {
                          count++;
                      }
                  }
              }
              this.board[i][j] = count;
          }
      }
  }

  revealCell(row, col) {
      const key = `${row},${col}`;
      if (this.flagged.has(key)) {
        return;
      }

      if (this.gameOver || this.revealed.has(key)) {
        if (this.revealed.has(key) && this.board[row][col] !== 'M') {
            this.chordCell(row, col);
        }
        return;
      }

      this.revealed.add(key);

      if (this.board[row][col] === 'M') {
        this.gameOver = true;
        this.revealAllMines();
        this.gridElement.style.border = '5px solid red';
        return;
      }

      if (this.board[row][col] === 0) {
          this.floodFill(row, col);
      }

      this.render();
      this.checkWin();
  }

  chordCell(row, col) {
    if (this.gameOver || this.board[row][col] === 0) return;

    let flagCount = 0;
    const adjacentCells = [];
    for (let di = -1; di <= 1; di++) {
        for (let dj = -1; dj <= 1; dj++) {
            if (di === 0 && dj === 0) continue;
            const ni = row + di;
            const nj = col + dj;
            if (ni >= 0 && ni < this.rows && nj >= 0 && nj < this.cols) {
                const adjKey = `${ni},${nj}`;
              if (this.flagged.has(adjKey)) {
                  flagCount++;
              }
              if (!this.revealed.has(adjKey) && !this.flagged.has(adjKey)) {
                  adjacentCells.push([ni, nj]);
              }
            }
        }
    }

    if (flagCount === this.board[row][col]) {
        for (const [ni, nj] of adjacentCells) {
            const adjKey = `${ni},${nj}`;
            if (this.board[ni][nj] === 'M') {
                this.revealed.add(adjKey);
                this.gameOver = true;
                this.revealAllMines();
                this.gridElement.style.border = '5px solid red';
                return;
            }
            this.revealed.add(adjKey);
            if (this.board[ni][nj] === 0) {
                this.floodFill(ni, nj);
            }
        }
        this.render();
        this.checkWin();
    }
  }

  updateFlaggedRatio() {
    this.flagsnMinesElement.textContent = `🚩${this.flagged.size} 🔹 💣${this.mines}`;
  }

  toggleFlag(row, col) {
    if (this.gameOver || this.revealed.has(`${row},${col}`)) return;

    const key = `${row},${col}`;
    if (this.flagged.has(key)) {
      this.flagged.delete(key);
    } else {
      this.flagged.add(key);
    }
    this.render();
    this.checkWin();
    this.updateFlaggedRatio();
  }

  floodFill(row, col) {
      for (let di = -1; di <= 1; di++) {
          for (let dj = -1; dj <= 1; dj++) {
              if (di === 0 && dj === 0) continue;
              const ni = row + di;
              const nj = col + dj;
              if (ni >= 0 && ni < this.rows && 
                  nj >= 0 && nj < this.cols && 
                  !this.revealed.has(`${ni},${nj}`) &&
                  !this.flagged.has(`${ni},${nj}`)) {
                  this.revealCell(ni, nj);
              }
          }
      }
  }

  revealAllMines() {
      for (let i = 0; i < this.rows; i++) {
          for (let j = 0; j < this.cols; j++) {
              if (this.board[i][j] === 'M') {
                  this.revealed.add(`${i},${j}`);
              }
          }
      }
      this.render();
  }

  revealAllNonMines() {
    for (let i = 0; i < this.rows; i++) {
      for (let j = 0; j < this.cols; j++) {
        if (this.board[i][j] !== 'M') {
          this.revealed.add(`${i},${j}`);
        }
      }
    }
    this.render();
  }

  checkWin() {
      const totalCells = this.rows * this.cols;
      const nonMineCells = totalCells - this.mines;
      const allMinesFlagged = this.flagged.size === this.mines && 
        [...this.flagged].every(key => {
          const [row, col] = key.split(',').map(Number);
          return this.board[row][col] === 'M';
        });

      if (this.revealed.size === nonMineCells || allMinesFlagged) {
          this.gameOver = true;
          if (allMinesFlagged) {
            this.revealAllNonMines();
          }
          this.gridElement.style.border = '5px solid green';
      }
  }

  render() {
      this.gridElement.innerHTML = '';
      for (let i = 0; i < this.rows; i++) {
          for (let j = 0; j < this.cols; j++) {
              const cell = document.createElement('div');
              cell.className = 'cell';
              
              const key = `${i},${j}`;
              if (this.revealed.has(key)) {
                  cell.classList.add('revealed');
                  if (this.board[i][j] === 'M') {
                      cell.classList.add('mine');
                      cell.textContent = '💣';
                  } else if (this.board[i][j] > 0) {
                      cell.textContent = this.board[i][j];
                  }
              } else if (this.flagged.has(key)) {
                cell.textContent = '🚩';
              }

              cell.addEventListener('click', () => this.revealCell(i, j));
              cell.addEventListener('contextmenu', (e) => {
                e.preventDefault();
                this.toggleFlag(i, j);
              });
              this.gridElement.appendChild(cell);
          }
      }
  }

  reset() {
      this.revealed.clear();
      this.flagged.clear();
      this.gameOver = false;
      this.gridElement.style.border = 'none';
      this.createBoard();
      this.placeMines();
      this.calculateNumbers();
      this.render();
      this.updateFlaggedRatio();
  }
}

// Start the game with 16x16 grid and 40 mines
const game = new Minesweeper(16, 16, 40);
