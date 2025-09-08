const notFound = (req, res, next) => {
  const error = new Error(`요청한 경로를 찾을 수 없습니다 - ${req.originalUrl}`);
  res.status(404);
  next(error);
};

module.exports = notFound;
