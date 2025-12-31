const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  getTransactions,
  getTransactionById,
  createTransaction,
  updateTransaction,
  deleteTransaction,
  getMyTransactions,
  updateTransactionStatus
} = require('../controllers/transactionController');

// 거래 관련 라우트
router.route('/')
  .get(protect, getTransactions)
  .post(protect, createTransaction);

router.route('/my')
  .get(protect, getMyTransactions);

router.route('/:id')
  .get(protect, getTransactionById)
  .put(protect, updateTransaction)
  .delete(protect, deleteTransaction);

router.route('/:id/status')
  .put(protect, updateTransactionStatus);

module.exports = router;

