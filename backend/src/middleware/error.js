// 404 handler for unknown routes.
const notFound = (req, res) => {
  res.status(404).json({ success: false, error: `Route not found: ${req.method} ${req.originalUrl}` });
};

// Centralized error handler. Never leaks stack traces in production.
// eslint-disable-next-line no-unused-vars
const errorHandler = (err, req, res, next) => {
  const status = err.statusCode || 500;
  const message = err.message || 'Internal server error';

  if (process.env.NODE_ENV !== 'production') {
    console.error(err);
  }

  res.status(status).json({
    success: false,
    error: message,
  });
};

module.exports = { notFound, errorHandler };
