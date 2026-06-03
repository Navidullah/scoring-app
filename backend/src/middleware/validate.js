// Wraps a zod schema into Express validation middleware.
// On success, replaces req.body with the parsed (typed) value.
const validate = (schema) => (req, res, next) => {
  const result = schema.safeParse(req.body);
  if (!result.success) {
    const message = result.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ');
    return res.status(422).json({ success: false, error: message });
  }
  req.body = result.data;
  next();
};

// Wraps an async route handler so thrown errors hit the error middleware.
const asyncHandler = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

module.exports = { validate, asyncHandler };
