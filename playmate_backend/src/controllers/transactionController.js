const fs = require('fs').promises;
const path = require('path');

// 데이터 파일 경로
const DATA_DIR = path.join(__dirname, '../data');
const TRANSACTIONS_FILE = path.join(DATA_DIR, 'transactions.json');

// 거래 컨트롤러
class TransactionController {
  // 거래 목록 조회
  async getTransactions(req, res) {
    try {
      const { category, status, sellerId, buyerId, limit = 20, offset = 0 } = req.query;

      let transactions = await this._loadTransactions();

      // 필터링
      if (category) {
        transactions = transactions.filter(t => t.category === category);
      }
      if (status) {
        transactions = transactions.filter(t => t.status === status);
      }
      if (sellerId) {
        transactions = transactions.filter(t => t.sellerId === parseInt(sellerId));
      }
      if (buyerId) {
        transactions = transactions.filter(t => t.buyerId === parseInt(buyerId));
      }

      // 정렬 (최신순)
      transactions.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

      // 페이지네이션
      const total = transactions.length;
      const paginatedTransactions = transactions.slice(parseInt(offset), parseInt(offset) + parseInt(limit));

      res.json({
        success: true,
        data: paginatedTransactions,
        total,
        limit: parseInt(limit),
        offset: parseInt(offset),
      });
    } catch (error) {
      console.error('거래 목록 조회 오류:', error);
      res.status(500).json({
        success: false,
        error: '거래 목록 조회 실패'
      });
    }
  }

  // 거래 상세 조회
  async getTransactionById(req, res) {
    try {
      const { id } = req.params;
      const transactions = await this._loadTransactions();
      const transaction = transactions.find(t => t.id === parseInt(id));

      if (!transaction) {
        return res.status(404).json({
          success: false,
          error: '거래를 찾을 수 없습니다'
        });
      }

      res.json({
        success: true,
        data: transaction
      });
    } catch (error) {
      console.error('거래 상세 조회 오류:', error);
      res.status(500).json({
        success: false,
        error: '거래 상세 조회 실패'
      });
    }
  }

  // 거래 생성
  async createTransaction(req, res) {
    try {
      const userId = req.user.id;
      const { title, description, category, price, images, location } = req.body;

      // 유효성 검사
      if (!title || !description || !category || !price) {
        return res.status(400).json({
          success: false,
          error: '필수 필드가 누락되었습니다'
        });
      }

      const transactions = await this._loadTransactions();

      // 새 거래 생성
      const newTransaction = {
        id: transactions.length > 0 ? Math.max(...transactions.map(t => t.id)) + 1 : 1,
        title,
        description,
        category,
        price: parseInt(price),
        images: images || [],
        sellerId: userId,
        status: 'available',
        location: location || null,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        soldAt: null,
        chatRoomId: null,
      };

      transactions.push(newTransaction);
      await this._saveTransactions(transactions);

      res.status(201).json({
        success: true,
        data: newTransaction
      });
    } catch (error) {
      console.error('거래 생성 오류:', error);
      res.status(500).json({
        success: false,
        error: '거래 생성 실패'
      });
    }
  }

  // 거래 수정
  async updateTransaction(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;
      const { title, description, category, price, images, location, status } = req.body;

      const transactions = await this._loadTransactions();
      const transactionIndex = transactions.findIndex(t => t.id === parseInt(id));

      if (transactionIndex === -1) {
        return res.status(404).json({
          success: false,
          error: '거래를 찾을 수 없습니다'
        });
      }

      const transaction = transactions[transactionIndex];

      // 권한 확인 (판매자만 수정 가능)
      if (transaction.sellerId !== userId) {
        return res.status(403).json({
          success: false,
          error: '거래를 수정할 권한이 없습니다'
        });
      }

      // 상태가 'sold' 또는 'cancelled'인 경우 수정 불가
      if (transaction.status === 'sold' || transaction.status === 'cancelled') {
        return res.status(400).json({
          success: false,
          error: '완료되거나 취소된 거래는 수정할 수 없습니다'
        });
      }

      // 업데이트
      if (title !== undefined) transaction.title = title;
      if (description !== undefined) transaction.description = description;
      if (category !== undefined) transaction.category = category;
      if (price !== undefined) transaction.price = parseInt(price);
      if (images !== undefined) transaction.images = images;
      if (location !== undefined) transaction.location = location;
      if (status !== undefined) {
        transaction.status = status;
        if (status === 'sold') {
          transaction.soldAt = new Date().toISOString();
        }
      }
      transaction.updatedAt = new Date().toISOString();

      transactions[transactionIndex] = transaction;
      await this._saveTransactions(transactions);

      res.json({
        success: true,
        data: transaction
      });
    } catch (error) {
      console.error('거래 수정 오류:', error);
      res.status(500).json({
        success: false,
        error: '거래 수정 실패'
      });
    }
  }

  // 거래 삭제
  async deleteTransaction(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      const transactions = await this._loadTransactions();
      const transactionIndex = transactions.findIndex(t => t.id === parseInt(id));

      if (transactionIndex === -1) {
        return res.status(404).json({
          success: false,
          error: '거래를 찾을 수 없습니다'
        });
      }

      const transaction = transactions[transactionIndex];

      // 권한 확인 (판매자만 삭제 가능)
      if (transaction.sellerId !== userId) {
        return res.status(403).json({
          success: false,
          error: '거래를 삭제할 권한이 없습니다'
        });
      }

      // 상태가 'sold'인 경우 삭제 불가
      if (transaction.status === 'sold') {
        return res.status(400).json({
          success: false,
          error: '판매 완료된 거래는 삭제할 수 없습니다'
        });
      }

      transactions.splice(transactionIndex, 1);
      await this._saveTransactions(transactions);

      res.json({
        success: true,
        message: '거래가 삭제되었습니다'
      });
    } catch (error) {
      console.error('거래 삭제 오류:', error);
      res.status(500).json({
        success: false,
        error: '거래 삭제 실패'
      });
    }
  }

  // 내 거래 목록 조회
  async getMyTransactions(req, res) {
    try {
      const userId = req.user.id;
      const { type = 'all' } = req.query; // 'all', 'selling', 'buying'

      let transactions = await this._loadTransactions();

      if (type === 'selling') {
        transactions = transactions.filter(t => t.sellerId === userId);
      } else if (type === 'buying') {
        transactions = transactions.filter(t => t.buyerId === userId);
      } else {
        transactions = transactions.filter(t => 
          t.sellerId === userId || t.buyerId === userId
        );
      }

      // 정렬 (최신순)
      transactions.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

      res.json({
        success: true,
        data: transactions
      });
    } catch (error) {
      console.error('내 거래 목록 조회 오류:', error);
      res.status(500).json({
        success: false,
        error: '내 거래 목록 조회 실패'
      });
    }
  }

  // 거래 상태 변경 (예약, 완료, 취소)
  async updateTransactionStatus(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;
      const { status, buyerId } = req.body;

      if (!status) {
        return res.status(400).json({
          success: false,
          error: '상태가 필요합니다'
        });
      }

      const transactions = await this._loadTransactions();
      const transactionIndex = transactions.findIndex(t => t.id === parseInt(id));

      if (transactionIndex === -1) {
        return res.status(404).json({
          success: false,
          error: '거래를 찾을 수 없습니다'
        });
      }

      const transaction = transactions[transactionIndex];

      // 권한 확인
      if (status === 'reserved' || status === 'sold') {
        // 구매자는 예약/구매만 가능
        if (transaction.sellerId === userId) {
          return res.status(403).json({
            success: false,
            error: '판매자는 거래 상태를 변경할 수 없습니다'
          });
        }
        if (buyerId && parseInt(buyerId) !== userId) {
          return res.status(403).json({
            success: false,
            error: '권한이 없습니다'
          });
        }
      } else if (status === 'cancelled') {
        // 판매자만 취소 가능
        if (transaction.sellerId !== userId) {
          return res.status(403).json({
            success: false,
            error: '판매자만 거래를 취소할 수 있습니다'
          });
        }
      }

      // 상태 업데이트
      transaction.status = status;
      if (status === 'sold') {
        transaction.buyerId = buyerId ? parseInt(buyerId) : userId;
        transaction.soldAt = new Date().toISOString();
      } else if (status === 'reserved') {
        transaction.buyerId = buyerId ? parseInt(buyerId) : userId;
      } else if (status === 'cancelled') {
        transaction.buyerId = null;
      }
      transaction.updatedAt = new Date().toISOString();

      transactions[transactionIndex] = transaction;
      await this._saveTransactions(transactions);

      res.json({
        success: true,
        data: transaction
      });
    } catch (error) {
      console.error('거래 상태 변경 오류:', error);
      res.status(500).json({
        success: false,
        error: '거래 상태 변경 실패'
      });
    }
  }

  // 내부 헬퍼 메서드
  async _loadTransactions() {
    try {
      const data = await fs.readFile(TRANSACTIONS_FILE, 'utf8');
      return JSON.parse(data);
    } catch (error) {
      if (error.code === 'ENOENT') {
        // 파일이 없으면 빈 배열 반환
        return [];
      }
      throw error;
    }
  }

  async _saveTransactions(transactions) {
    await fs.writeFile(TRANSACTIONS_FILE, JSON.stringify(transactions, null, 2), 'utf8');
  }
}

const transactionController = new TransactionController();

module.exports = {
  getTransactions: (req, res) => transactionController.getTransactions(req, res),
  getTransactionById: (req, res) => transactionController.getTransactionById(req, res),
  createTransaction: (req, res) => transactionController.createTransaction(req, res),
  updateTransaction: (req, res) => transactionController.updateTransaction(req, res),
  deleteTransaction: (req, res) => transactionController.deleteTransaction(req, res),
  getMyTransactions: (req, res) => transactionController.getMyTransactions(req, res),
  updateTransactionStatus: (req, res) => transactionController.updateTransactionStatus(req, res),
};

