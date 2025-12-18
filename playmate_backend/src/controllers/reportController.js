const fs = require('fs');
const path = require('path');
const {
  sendSuccessResponse,
  sendCreatedResponse,
  sendErrorResponse,
  sendBadRequestResponse
} = require('../utils/responseHelper');

// 신고 데이터 파일 경로
const REPORTS_FILE = path.join(__dirname, '../data/reports.json');

// 메모리 스토어
let reports = [];
let nextReportId = 1;

// 파일에서 데이터 로드
function loadFromFile() {
  try {
    if (fs.existsSync(REPORTS_FILE)) {
      const data = fs.readFileSync(REPORTS_FILE, 'utf8');
      const loadedData = JSON.parse(data);
      
      if (Array.isArray(loadedData)) {
        reports = loadedData;
      } else if (loadedData.reports) {
        reports = loadedData.reports;
      }
      
      if (reports.length > 0) {
        nextReportId = Math.max(...reports.map(r => r.id), 0) + 1;
      }
      
      console.log(`📁 파일에서 ${reports.length}개 신고 로드됨`);
    } else {
      // 디렉토리 생성
      const dir = path.dirname(REPORTS_FILE);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      reports = [];
      nextReportId = 1;
    }
  } catch (error) {
    console.error('신고 데이터 로드 오류:', error);
    reports = [];
    nextReportId = 1;
  }
}

// 파일에 데이터 저장
function saveToFile() {
  try {
    const dir = path.dirname(REPORTS_FILE);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    
    const dataToSave = {
      reports: reports,
      nextId: nextReportId
    };
    
    fs.writeFileSync(REPORTS_FILE, JSON.stringify(dataToSave, null, 2));
    console.log(`💾 ${reports.length}개 신고를 파일에 저장됨`);
  } catch (error) {
    console.error('신고 데이터 저장 오류:', error);
  }
}

// 서버 시작 시 데이터 로드
loadFromFile();

// 신고 생성
const createReport = (req, res) => {
  try {
    const { type, targetId, reason, description } = req.body;
    const reporterId = req.user.id;

    if (!type || !targetId || !reason) {
      return sendBadRequestResponse(res, '신고 타입, 대상 ID, 신고 이유는 필수입니다.');
    }

    // 신고 타입 검증
    const validTypes = ['post', 'comment', 'user'];
    if (!validTypes.includes(type)) {
      return sendBadRequestResponse(res, '유효하지 않은 신고 타입입니다.');
    }

    // 신고 이유 검증
    const validReasons = ['spam', 'inappropriate', 'harassment', 'violence', 'copyright', 'other'];
    if (!validReasons.includes(reason)) {
      return sendBadRequestResponse(res, '유효하지 않은 신고 이유입니다.');
    }

    console.log(`신고 생성 요청: 타입=${type}, 대상ID=${targetId}, 이유=${reason}`);

    // 중복 신고 확인 (같은 사용자가 같은 대상을 같은 이유로 신고한 경우)
    const existingReport = reports.find(
      r => r.reporterId === reporterId && 
           r.type === type && 
           r.targetId === targetId && 
           r.reason === reason &&
           // 24시간 이내 신고만 중복으로 간주
           (new Date() - new Date(r.createdAt)) < 24 * 60 * 60 * 1000
    );

    if (existingReport) {
      return sendBadRequestResponse(res, '이미 신고한 내용입니다. 24시간 후 다시 신고할 수 있습니다.');
    }

    const newReport = {
      id: nextReportId++,
      type: type,
      targetId: parseInt(targetId),
      reporterId: reporterId,
      reason: reason,
      description: description || null,
      status: 'pending', // pending, reviewed, resolved, rejected
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    reports.push(newReport);
    saveToFile();

    console.log(`신고 생성 완료: ID ${newReport.id}`);

    sendCreatedResponse(res, newReport, '신고가 접수되었습니다. 검토 후 조치하겠습니다.');
  } catch (error) {
    console.error('신고 생성 오류:', error);
    sendErrorResponse(res, '신고 생성에 실패했습니다.', 500, error);
  }
};

// 내 신고 목록 조회
const getMyReports = (req, res) => {
  try {
    const reporterId = req.user.id;
    const myReports = reports
      .filter(r => r.reporterId === reporterId)
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    res.json({
      success: true,
      data: myReports
    });
  } catch (error) {
    console.error('내 신고 목록 조회 오류:', error);
    sendErrorResponse(res, '신고 목록 조회에 실패했습니다.', 500, error);
  }
};

module.exports = {
  createReport,
  getMyReports
};

