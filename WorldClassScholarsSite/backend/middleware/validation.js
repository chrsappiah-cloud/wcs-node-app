const { body, validationResult } = require('express-validator');

/**
 * Validation middleware for image generation requests
 */
const validateImageGeneration = [
  body('prompt')
    .trim()
    .notEmpty().withMessage('Prompt is required')
    .isLength({ min: 5, max: 1000 }).withMessage('Prompt must be between 5 and 1000 characters')
    .escape(), // Prevent XSS
  body('style')
    .optional()
    .isIn(['realistic', 'artistic', 'cartoon', 'sketch']).withMessage('Invalid style'),
  body('quantity')
    .optional()
    .isInt({ min: 1, max: 4 }).withMessage('Quantity must be between 1 and 4'),
];

/**
 * Error handler for validation
 */
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ 
      error: 'Validation failed',
      details: errors.array() 
    });
  }
  next();
};

module.exports = {
  validateImageGeneration,
  handleValidationErrors,
};
