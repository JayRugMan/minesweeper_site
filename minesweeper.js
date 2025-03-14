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
      this.init();
  }

  init() {
      this.gridElement.style.gridTemplateColumns = `repeat(${this.cols}, 30px)`;
      this.restartButton.addEventListener('click', () => this.reset());
      this.createBoard();
      this.placeMines();
      this.calculateNumbers();
      this.render();
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
              if (this.board[i][j] === 'M') continue;
              
              let count = 0;
              for (let di = -1; di <= 1; di++) {
                  for (let dj = -1; dj <= 1; dj++) {
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
          alert('Game Over! You hit a mine.');
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
                alert('Game Over! Incorrect flag placement revealed a mine.');
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
  }

  floodFill(row, col) {
      for (let di = -1; di <= 1; di++) {
          for (let dj = -1; dj <= 1; dj++) {
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
          alert('Congratulations! You won!');
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
  }
}

// Start the game with 10x10 grid and 10 mines
const game = new Minesweeper(10, 10, 10);
