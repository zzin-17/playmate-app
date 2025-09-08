const mongoose = require('mongoose');

const matchingSchema = new mongoose.Schema({
  host: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  title: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
  },
  description: {
    type: String,
    required: true,
    maxlength: 500
  },
  gameType: {
    type: String,
    enum: ['badminton', 'tennis', 'pingpong', 'squash'],
    required: true
  },
  date: {
    type: Date,
    required: true
  },
  timeSlot: {
    type: String,
    required: true
  },
  location: {
    name: {
      type: String,
      required: true
    },
    address: {
      type: String,
      required: true
    },
    lat: {
      type: Number,
      required: true
    },
    lng: {
      type: Number,
      required: true
    }
  },
  maxParticipants: {
    type: Number,
    required: true,
    min: 2,
    max: 20
  },
  currentParticipants: {
    type: Number,
    default: 1
  },
  maleRecruitCount: {
    type: Number,
    default: 0
  },
  femaleRecruitCount: {
    type: Number,
    default: 0
  },
  status: {
    type: String,
    enum: ['recruiting', 'confirmed', 'completed', 'cancelled'],
    default: 'recruiting'
  },
  guests: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    status: {
      type: String,
      enum: ['pending', 'confirmed', 'rejected'],
      default: 'pending'
    },
    joinedAt: {
      type: Date,
      default: Date.now
    }
  }],
  isPublic: {
    type: Boolean,
    default: true
  },
  tags: [{
    type: String,
    trim: true
  }]
}, {
  timestamps: true
});

// 인덱스 설정
matchingSchema.index({ host: 1 });
matchingSchema.index({ gameType: 1 });
matchingSchema.index({ date: 1 });
matchingSchema.index({ status: 1 });
matchingSchema.index({ 'location.lat': 1, 'location.lng': 1 });

module.exports = mongoose.model('Matching', matchingSchema);