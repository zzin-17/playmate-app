const fs = require('fs');
const path = require('path');

// 사용자 데이터 파일 경로
const USERS_FILE = path.join(__dirname, '../data/users.json');

/**
 * 통합 사용자 저장소
 * 모든 사용자 관련 컨트롤러에서 공유하는 단일 저장소
 */
class UserStore {
  constructor() {
    this.users = new Map(); // ID를 키로 사용
    this.usersByEmail = new Map(); // 이메일을 키로 사용 (중복 체크용)
    this.nextId = 1;
    this.maxUsers = 1000000; // 최대 100만 사용자 지원
    this.idRange = {
      min: 100000, // 6자리 ID 시작 (100000부터)
      max: 999999  // 6자리 ID 끝 (999999까지)
    };
    this.isLoaded = false;
  }

  /**
   * 고유 사용자 ID 생성 함수 (대규모 사용자 대응)
   */
  generateUniqueUserId() {
    const maxAttempts = 1000; // 최대 시도 횟수
    let attempts = 0;
    
    while (attempts < maxAttempts) {
      // 6자리 랜덤 ID 생성 (100000 ~ 999999)
      const randomId = Math.floor(Math.random() * (this.idRange.max - this.idRange.min + 1)) + this.idRange.min;
      
      // ID 중복 확인
      if (!this.users.has(randomId)) {
        return randomId;
      }
      
      attempts++;
    }
    
    // 시퀀셜 ID로 폴백 (100000부터 시작)
    let sequentialId = this.idRange.min;
    while (sequentialId <= this.idRange.max) {
      if (!this.users.has(sequentialId)) {
        return sequentialId;
      }
      sequentialId++;
    }
    
    return null; // 사용 가능한 ID가 없음
  }

  /**
   * 사용자 데이터를 파일에서 로드 (비동기)
   */
  async loadUsersFromFile() {
    try {
      // 디렉토리가 없으면 미리 생성
      const dir = path.dirname(USERS_FILE);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      
      if (fs.existsSync(USERS_FILE)) {
        const data = await fs.promises.readFile(USERS_FILE, 'utf8');
        const usersData = JSON.parse(data);
        
        // Map으로 변환
        this.users.clear();
        this.usersByEmail.clear();
        
        // users가 배열인지 확인
        if (Array.isArray(usersData.users)) {
          usersData.users.forEach(user => {
            this.users.set(user.id, user);
            this.usersByEmail.set(user.email, user);
          });
        } else {
          console.log('⚠️ 사용자 데이터가 배열이 아닙니다. 빈 배열로 시작합니다.');
        }
        
        // nextId 설정
        this.nextId = usersData.nextId || 1;
        console.log(`✅ 사용자 데이터 로드 완료: ${this.users.size}명, 다음 ID: ${this.nextId}`);
      } else {
        console.log('📝 사용자 데이터 파일이 없습니다. 새로 시작합니다.');
      }
      
      this.isLoaded = true;
    } catch (error) {
      console.error('❌ 사용자 데이터 로드 실패:', error.message);
      this.users.clear();
      this.usersByEmail.clear();
      this.nextId = 1;
      this.isLoaded = true;
    }
  }

  /**
   * 사용자 데이터를 파일에 저장 (비동기)
   */
  async saveUsersToFile() {
    try {
      const usersData = {
        users: Array.from(this.users.values()),
        nextId: this.nextId
      };
      
      // 디렉토리가 없으면 생성
      const dir = path.dirname(USERS_FILE);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      
      await fs.promises.writeFile(USERS_FILE, JSON.stringify(usersData, null, 2));
      console.log(`💾 사용자 데이터 저장 완료: ${this.users.size}명`);
    } catch (error) {
      console.error('❌ 사용자 데이터 저장 실패:', error.message);
    }
  }

  /**
   * 이메일로 사용자 찾기
   */
  getUserByEmail(email) {
    return this.usersByEmail.get(email);
  }

  /**
   * ID로 사용자 찾기
   */
  getUserById(id) {
    return this.users.get(id);
  }

  /**
   * 새 사용자 추가
   */
  addUser(user) {
    this.users.set(user.id, user);
    this.usersByEmail.set(user.email, user);
  }

  /**
   * 사용자 업데이트
   */
  updateUser(id, updateData) {
    const user = this.users.get(id);
    if (!user) return null;

    // 이메일이 변경되는 경우 이메일 인덱스도 업데이트
    if (updateData.email && updateData.email !== user.email) {
      this.usersByEmail.delete(user.email);
      this.usersByEmail.set(updateData.email, user);
    }

    // 사용자 데이터 업데이트
    Object.assign(user, updateData);
    user.updatedAt = new Date();
    
    this.users.set(id, user);
    return user;
  }

  /**
   * 사용자 검색 (닉네임만)
   */
  searchUsers(query, limit = 20) {
    const searchQuery = query.toLowerCase().trim();
    const results = [];
    
    for (const [userId, user] of this.users) {
      // 활성 사용자만 검색 (isActive가 false가 아닌 경우)
      if (user.isActive !== false) {
        // 닉네임에서만 검색 (부분 일치)
        const nickname = (user.nickname || '').toLowerCase();
        
        if (nickname.includes(searchQuery)) {
          // 비밀번호와 이메일 제외하고 추가 (개인정보 보호)
          const { password, email, ...userWithoutSensitiveData } = user;
          results.push(userWithoutSensitiveData);
          
          // 최대 limit개까지만 반환
          if (results.length >= limit) {
            break;
          }
        }
      }
    }
    
    return results;
  }

  /**
   * 모든 사용자 목록 반환 (배열 형태)
   */
  getAllUsersArray() {
    return Array.from(this.users.values());
  }

  /**
   * 사용자 수 반환
   */
  getUserCount() {
    return this.users.size;
  }

  /**
   * 이메일 중복 체크
   */
  isEmailExists(email) {
    return this.usersByEmail.has(email);
  }
}

// 싱글톤 인스턴스 생성
const userStore = new UserStore();

module.exports = userStore;
