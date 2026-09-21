// Better Stack (Logtail) structured logger for Next.js Server Actions
//
// Setup:
// 1. Create free account at https://betterstack.com/
// 2. Go to Logs → Create Source → Node.js
// 3. Copy the "Source Token" and add to .env.local:
//    LOGTAIL_SOURCE_TOKEN=your_token_here
// 4. npm install @logtail/next
//
// Usage in Server Actions:
//   import { logger } from '@/lib/logger'
//   logger.info('User signed in', { userId: '...' })
//   logger.error('Supabase query failed', { error: err.message })

type LogLevel = 'debug' | 'info' | 'warn' | 'error'
type LogContext = Record<string, unknown>

class AppLogger {
  private isProduction = process.env.NODE_ENV === 'production'
  private sourceToken = process.env.LOGTAIL_SOURCE_TOKEN

  private async sendToLogtail(level: LogLevel, message: string, context?: LogContext) {
    if (!this.sourceToken) return  // silently skip if not configured

    try {
      await fetch('https://in.logtail.com', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.sourceToken}`,
        },
        body: JSON.stringify({
          dt: new Date().toISOString(),
          level,
          message,
          ...context,
          service: 'encore-web',
        }),
      })
    } catch {
      // never let logging crash the app
    }
  }

  debug(message: string, context?: LogContext) {
    if (!this.isProduction) {
      console.debug(`[DEBUG] ${message}`, context ?? '')
    }
  }

  info(message: string, context?: LogContext) {
    console.info(`[INFO] ${message}`, context ?? '')
    if (this.isProduction) {
      this.sendToLogtail('info', message, context)
    }
  }

  warn(message: string, context?: LogContext) {
    console.warn(`[WARN] ${message}`, context ?? '')
    this.sendToLogtail('warn', message, context)
  }

  error(message: string, context?: LogContext) {
    console.error(`[ERROR] ${message}`, context ?? '')
    this.sendToLogtail('error', message, context)
  }
}

export const logger = new AppLogger()
