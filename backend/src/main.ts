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
    const allowedOrigins = process.env.NODE_ENV === 'production'
      ? (process.env.ALLOWED_ORIGINS?.split(',') || [])
      : true; // Allow all in development
    
    app.enableCors({
      origin: allowedOrigins,
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
      credentials: true,
      allowedHeaders: ['Content-Type', 'Authorization', 'Origin', 'Accept'],
    });

    // Set global prefix
    app.setGlobalPrefix('api');

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
  } catch (error) {
    logger.error('❌ Error starting the application', error.stack, 'Bootstrap');
    process.exit(1);
  }
}

bootstrap().catch((error) => {
  Logger.error('Failed to start application', error.stack, 'Bootstrap');
  process.exit(1);
});
