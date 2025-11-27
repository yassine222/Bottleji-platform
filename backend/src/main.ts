import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe, Logger } from '@nestjs/common';
import { HttpException, HttpStatus } from '@nestjs/common';

// Global error handlers for unhandled promise rejections
process.on('unhandledRejection', (reason: any, promise: Promise<any>) => {
  Logger.error('Unhandled Promise Rejection', reason?.stack || reason, 'Bootstrap');
  // In production, you might want to gracefully shutdown
  // process.exit(1);
});

process.on('uncaughtException', (error: Error) => {
  Logger.error('Uncaught Exception', error.stack, 'Bootstrap');
  // In production, you might want to gracefully shutdown
  // process.exit(1);
});

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  
  try {
    const app = await NestFactory.create(AppModule, {
      logger: ['error', 'warn', 'log', 'debug', 'verbose'],
    });
    
    // Enable CORS - Environment-specific configuration
    let allowedOrigins: string[] | boolean;
    
    if (process.env.NODE_ENV === 'production') {
      // In production, use ALLOWED_ORIGINS
      if (process.env.ALLOWED_ORIGINS) {
        const origins = process.env.ALLOWED_ORIGINS.split(',').map(o => o.trim()).filter(Boolean);
        
        // If any localhost or local IP patterns are found, add common localhost variants
        const hasLocalhost = origins.some(o => 
          o.includes('localhost') || 
          o.includes('127.0.0.1') || 
          o.match(/^http:\/\/172\.\d+\.\d+\.\d+/) ||
          o.match(/^http:\/\/192\.168\.\d+\.\d+/)
        );
        
        if (hasLocalhost) {
          // Add common localhost variants for easier testing
          const localhostVariants = [
            'http://localhost:3000',
            'http://localhost:3001',
            'http://127.0.0.1:3000',
            'http://127.0.0.1:3001',
          ];
          allowedOrigins = [...new Set([...origins, ...localhostVariants])];
        } else {
          allowedOrigins = origins;
        }
      } else {
        // TEMPORARY: Allow localhost for testing when ALLOWED_ORIGINS is not set
        // TODO: Remove this fallback and require ALLOWED_ORIGINS to be set in production
        logger.warn('⚠️ ALLOWED_ORIGINS not set in production - allowing localhost for testing');
        logger.warn('⚠️ Set ALLOWED_ORIGINS environment variable for production security');
        // Allow localhost and Render subdomains for testing
        allowedOrigins = [
          'http://localhost:3000',
          'http://localhost:3001',
          'http://127.0.0.1:3000',
          'http://127.0.0.1:3001',
        ];
        
      }
    } else {
      // In development, allow all origins for easier local testing
      allowedOrigins = true;
    }
    
    // Configure CORS with dynamic origin handler
    app.enableCors({
      origin: (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
        // Allow requests with no origin (like mobile apps or curl)
        if (!origin) {
          return callback(null, true);
        }
        
        // If allowedOrigins is boolean (true = allow all in dev)
        if (allowedOrigins === true) {
          return callback(null, true);
        }
        
        // Check if origin is in allowed list
        if (Array.isArray(allowedOrigins) && allowedOrigins.includes(origin)) {
          return callback(null, true);
        }
        
        // Allow Render subdomains (*.onrender.com) when ALLOWED_ORIGINS is not set
        if (Array.isArray(allowedOrigins) && !process.env.ALLOWED_ORIGINS && origin.includes('.onrender.com')) {
          return callback(null, true);
        }
        
        callback(new Error('Not allowed by CORS'));
      },
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
      credentials: true,
      allowedHeaders: ['Content-Type', 'Authorization', 'Origin', 'Accept'],
    });

    // Set global prefix
    app.setGlobalPrefix('api');

    // Add root route handler after global prefix is set
    // This handles requests to / (without /api prefix)
    const expressApp = app.getHttpAdapter().getInstance();
    expressApp.get('/', (req, res) => {
      res.status(200).json({
        message: 'Bottleji API Server',
        version: '1.0.0',
        status: 'running',
        environment: process.env.NODE_ENV || 'development',
        api: {
          baseUrl: '/api',
          endpoints: {
            health: '/api',
            auth: '/api/auth',
            dropoffs: '/api/dropoffs',
            notifications: '/api/notifications',
            rewards: '/api/rewards',
            admin: '/api/admin',
            collectorApplications: '/api/collector-applications',
            supportTickets: '/api/support-tickets',
            training: '/api/training',
            earnings: '/api/earnings',
          },
        },
        timestamp: new Date().toISOString(),
      });
    });

    // Handle favicon requests to prevent 404 errors in logs
    expressApp.get('/favicon.ico', (req, res) => {
      res.status(204).end(); // No Content - standard response for favicon
    });

    // Enable validation with better error handling
    app.useGlobalPipes(new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
      exceptionFactory: (errors) => {
        const messages = errors.map(error => 
          Object.values(error.constraints || {}).join(', ')
        );
        return new HttpException(
          { message: 'Validation failed', errors: messages },
          HttpStatus.BAD_REQUEST,
        );
      },
    }));

    // Global exception filter for better error responses
    app.useGlobalFilters({
      catch(exception: any, host: any) {
        const ctx = host.switchToHttp();
        const response = ctx.getResponse();
        const request = ctx.getRequest();
        
        const status = exception instanceof HttpException
          ? exception.getStatus()
          : HttpStatus.INTERNAL_SERVER_ERROR;
        
        const message = exception instanceof HttpException
          ? exception.getResponse()
          : { message: 'Internal server error' };
        
        logger.error(
          `Exception caught: ${exception.message}`,
          exception.stack,
          `${request.method} ${request.url}`,
        );
        
        response.status(status).json({
          statusCode: status,
          timestamp: new Date().toISOString(),
          path: request.url,
          ...(typeof message === 'object' ? message : { message }),
        });
      },
    });

    const port = process.env.PORT ?? 3000;
    await app.listen(port, '0.0.0.0');
    
    logger.log(`🚀 Application is running on: http://0.0.0.0:${port}/api`);
    logger.log(`📝 Environment: ${process.env.NODE_ENV || 'development'}`);
    logger.log(`🌐 CORS allowed origins: ${Array.isArray(allowedOrigins) ? allowedOrigins.join(', ') : 'All origins (development mode)'}`);
  } catch (error) {
    logger.error('❌ Error starting the application', error.stack, 'Bootstrap');
    process.exit(1);
  }
}

bootstrap().catch((error) => {
  Logger.error('Failed to start application', error.stack, 'Bootstrap');
  process.exit(1);
});
