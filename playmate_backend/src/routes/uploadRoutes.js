const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  upload,
  uploadProfileImage,
  uploadPostImages,
  uploadChatImages
} = require('../controllers/uploadController');

// 파일 업로드 관련 라우트
router.route('/profile')
  .post(protect, upload.single('image'), uploadProfileImage);

router.route('/post')
  .post(protect, upload.array('images', 5), uploadPostImages);

router.route('/chat')
  .post(protect, upload.single('image'), uploadChatImages);

module.exports = router;