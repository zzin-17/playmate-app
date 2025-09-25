const mongoose = require('mongoose');

// 대용량 데이터 처리를 위한 MongoDB 설정
const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGODB_URI || 'mongodb://localhost:27017/playmate';
    
    // 대용량 데이터 처리를 위한 최적화된 연결 옵션
    const options = {
      // 연결 풀 설정 (대용량 동시 접속 처리)
      maxPoolSize: 50,        // 최대 연결 수 (기본값: 10)
      minPoolSize: 5,         // 최소 연결 수 (기본값: 0)
      maxIdleTimeMS: 30000,   // 유휴 연결 유지 시간 (30초)
      
      // 타임아웃 설정
      serverSelectionTimeoutMS: 5000,  // 서버 선택 타임아웃 (5초)
      socketTimeoutMS: 45000,          // 소켓 타임아웃 (45초)
      connectTimeoutMS: 10000,         // 연결 타임아웃 (10초)
      
      // 버퍼링 설정 (대용량 데이터 처리 최적화)
      bufferMaxEntries: 0,    // 버퍼링 비활성화 (즉시 오류 반환)
      bufferCommands: false,  // 명령어 버퍼링 비활성화
      
      // 성능 최적화
      readPreference: 'primary',  // 읽기 기본 설정
      writeConcern: {             // 쓰기 보장 설정
        w: 1,                     // 최소 1개 서버 확인
        j: true,                  // 저널링 활성화
        wtimeout: 10000           // 쓰기 타임아웃 (10초)
      },
      
      // 압축 설정 (네트워크 대역폭 절약)
      compressors: ['zlib'],
      zlibCompressionLevel: 6,
      
      // 인덱스 설정
      autoIndex: true,         // 자동 인덱스 생성
      autoCreate: true,        // 자동 컬렉션 생성
      
      // 로깅 설정 (개발 환경에서만)
      loggerLevel: process.env.NODE_ENV === 'development' ? 'debug' : 'error'
    };

    await mongoose.connect(mongoURI, options);
    
    console.log('✅ MongoDB 연결 성공');
    console.log(`📊 연결 풀 크기: ${options.maxPoolSize}`);
    console.log(`🔗 데이터베이스: ${mongoose.connection.name}`);
    
    // 연결 이벤트 리스너 설정
    mongoose.connection.on('error', (error) => {
      console.error('❌ MongoDB 연결 오류:', error);
    });
    
    mongoose.connection.on('disconnected', () => {
      console.warn('⚠️ MongoDB 연결 끊어짐');
    });
    
    mongoose.connection.on('reconnected', () => {
      console.log('🔄 MongoDB 재연결됨');
    });
    
    // 프로세스 종료 시 연결 정리
    process.on('SIGINT', async () => {
      await mongoose.connection.close();
      console.log('🛑 MongoDB 연결 종료');
      process.exit(0);
    });
    
  } catch (error) {
    console.error('❌ MongoDB 연결 실패:', error.message);
    process.exit(1);
  }
};

// 스키마 최적화 설정
const optimizeSchema = (schema) => {
  // 자동 인덱스 생성 비활성화 (수동으로 최적화된 인덱스 사용)
  schema.set('autoIndex', false);
  
  // 버퍼링 비활성화 (대용량 데이터 처리 시 즉시 오류 반환)
  schema.set('bufferCommands', false);
  
  // 가상 필드 JSON 변환 시 포함하지 않음 (성능 향상)
  schema.set('toJSON', { virtuals: false });
  schema.set('toObject', { virtuals: false });
  
  return schema;
};

// 대용량 데이터 처리를 위한 인덱스 설정
const createIndexes = async () => {
  try {
    const db = mongoose.connection.db;
    
    // 사용자 컬렉션 인덱스
    await db.collection('users').createIndexes([
      { key: { email: 1 }, unique: true, sparse: true },
      { key: { nickname: 1 }, unique: true, sparse: true },
      { key: { id: 1 }, unique: true },
      { key: { createdAt: -1 } },
      { key: { location: '2dsphere' } }, // 지리적 검색용
      { key: { gender: 1, birthYear: 1 } }, // 복합 인덱스
      { key: { isVerified: 1 } }
    ]);
    
    // 매칭 컬렉션 인덱스
    await db.collection('matchings').createIndexes([
      { key: { id: 1 }, unique: true },
      { key: { hostId: 1 } },
      { key: { status: 1 } },
      { key: { gameDate: -1 } },
      { key: { createdAt: -1 } },
      { key: { location: '2dsphere' } },
      { key: { skillLevel: 1, gameDate: -1 } }, // 복합 인덱스
      { key: { status: 1, gameDate: -1 } }, // 복합 인덱스
      { key: { hostId: 1, status: 1 } }, // 복합 인덱스
      { key: { cityId: 1, districtIds: 1 } } // 지역 검색용
    ]);
    
    // 게시글 컬렉션 인덱스
    await db.collection('posts').createIndexes([
      { key: { id: 1 }, unique: true },
      { key: { authorId: 1 } },
      { key: { createdAt: -1 } },
      { key: { updatedAt: -1 } },
      { key: { isActive: 1, createdAt: -1 } }, // 복합 인덱스
      { key: { authorId: 1, createdAt: -1 } }, // 복합 인덱스
      { key: { content: 'text' } }, // 텍스트 검색용
      { key: { tags: 1 } }, // 태그 검색용
      { key: { likeCount: -1, createdAt: -1 } } // 인기순 정렬용
    ]);
    
    // 댓글 컬렉션 인덱스
    await db.collection('comments').createIndexes([
      { key: { id: 1 }, unique: true },
      { key: { postId: 1 } },
      { key: { authorId: 1 } },
      { key: { createdAt: -1 } },
      { key: { postId: 1, createdAt: -1 } }, // 복합 인덱스
      { key: { parentId: 1, createdAt: -1 } } // 대댓글용
    ]);
    
    // 채팅 컬렉션 인덱스
    await db.collection('chatrooms').createIndexes([
      { key: { id: 1 }, unique: true },
      { key: { participants: 1 } },
      { key: { matchingId: 1 } },
      { key: { updatedAt: -1 } },
      { key: { participants: 1, updatedAt: -1 } } // 복합 인덱스
    ]);
    
    await db.collection('messages').createIndexes([
      { key: { id: 1 }, unique: true },
      { key: { roomId: 1 } },
      { key: { senderId: 1 } },
      { key: { createdAt: -1 } },
      { key: { roomId: 1, createdAt: -1 } }, // 복합 인덱스
      { key: { roomId: 1, createdAt: -1, senderId: 1 } } // 복합 인덱스
    ]);
    
    console.log('✅ 모든 인덱스 생성 완료');
    
  } catch (error) {
    console.error('❌ 인덱스 생성 실패:', error);
  }
};

module.exports = {
  connectDB,
  optimizeSchema,
  createIndexes
};