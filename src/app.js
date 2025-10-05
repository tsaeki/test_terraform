const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

// Logging utility function
const log = (level, message, data = {}) => {
  const timestamp = new Date().toISOString();
  const logEntry = {
    timestamp,
    level,
    message,
    ...data
  };
  console.log(JSON.stringify(logEntry));
};

// Request logging middleware
app.use((req, res, next) => {
  const start = Date.now();
  
  // Log incoming request
  log('info', 'Incoming request', {
    method: req.method,
    url: req.url,
    userAgent: req.get('User-Agent'),
    ip: req.ip || req.connection.remoteAddress,
    headers: {
      'x-forwarded-for': req.get('x-forwarded-for'),
      'x-real-ip': req.get('x-real-ip')
    }
  });

  // Override res.end to log response
  const originalEnd = res.end;
  res.end = function(...args) {
    const duration = Date.now() - start;
    
    // Log response
    log('info', 'Request completed', {
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      ip: req.ip || req.connection.remoteAddress
    });
    
    originalEnd.apply(this, args);
  };
  
  next();
});

// Root endpoint - returns 200
app.get('/', (req, res) => {
  log('info', 'Root endpoint accessed', {
    endpoint: '/',
    method: 'GET',
    ip: req.ip || req.connection.remoteAddress
  });
  
  res.status(200).json({
    message: 'Hello World',
    status: 'success',
    timestamp: new Date().toISOString()
  });
});

// 500 error endpoint
app.get('/500', (req, res) => {
  log('error', 'Error endpoint accessed', {
    endpoint: '/500',
    method: 'GET',
    ip: req.ip || req.connection.remoteAddress,
    simulatedError: true
  });
  
  res.status(500).json({
    message: 'Internal Server Error',
    status: 'error',
    timestamp: new Date().toISOString()
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  const uptime = process.uptime();
  
  log('info', 'Health check accessed', {
    endpoint: '/health',
    method: 'GET',
    ip: req.ip || req.connection.remoteAddress,
    uptime: `${uptime}s`,
    memoryUsage: process.memoryUsage()
  });
  
  res.status(200).json({
    message: 'Healthy',
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: uptime
  });
});

// Start server
app.listen(port, '0.0.0.0', () => {
  log('info', 'Server started', {
    port: port,
    environment: process.env.NODE_ENV || 'development',
    nodeVersion: process.version,
    platform: process.platform,
    pid: process.pid
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  log('info', 'SIGTERM received, shutting down gracefully', {
    signal: 'SIGTERM',
    pid: process.pid
  });
  process.exit(0);
});

process.on('SIGINT', () => {
  log('info', 'SIGINT received, shutting down gracefully', {
    signal: 'SIGINT',
    pid: process.pid
  });
  process.exit(0);
});