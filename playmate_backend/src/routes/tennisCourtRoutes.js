const express = require('express');
const router = express.Router();
const tennisCourtController = require('../controllers/tennisCourtController');

// 모든 테니스장 조회 (필터링 지원)
router.get('/', tennisCourtController.getTennisCourts);

// ID로 테니스장 조회
router.get('/:id', tennisCourtController.getTennisCourtById);

// 테니스장 검색
router.get('/search', tennisCourtController.searchTennisCourts);

// 인기 테니스장 조회
router.get('/popular', tennisCourtController.getPopularTennisCourts);

// 지역별 테니스장 조회
router.get('/region/:region', tennisCourtController.getTennisCourtsByRegion);

module.exports = router;
