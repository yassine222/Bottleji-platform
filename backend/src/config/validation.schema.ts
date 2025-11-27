import * as Joi from 'joi';

export const validationSchema = Joi.object({
  // Environment
  NODE_ENV: Joi.string()
    .valid('development', 'production', 'test', 'provision')
    .default('development'),
  
  // Server
  PORT: Joi.number().default(3000),
  
  // Database
  MONGODB_URI: Joi.string().optional(),
  
  // JWT Authentication
  JWT_SECRET: Joi.string().min(32).required()
    .messages({
      'string.min': 'JWT_SECRET must be at least 32 characters long',
      'any.required': 'JWT_SECRET is required',
    }),
  JWT_EXPIRES_IN: Joi.string().default('7d'),
  
  // Email Service (Gmail)
  EMAIL_USER: Joi.string().email().optional(),
  EMAIL_PASS: Joi.string().optional(),
  // Alternative names (for compatibility)
  MAIL_USER: Joi.string().email().optional(),
  MAIL_PASS: Joi.string().optional(),
  
  // Google Maps
  GOOGLE_MAPS_API_KEY: Joi.string().optional(),
  
  // Firebase (FCM)
  FIREBASE_SERVICE_ACCOUNT_KEY: Joi.string().optional(),
  
  // CORS
  ALLOWED_ORIGINS: Joi.string().optional(),
});
