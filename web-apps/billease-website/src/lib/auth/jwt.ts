import jwt from 'jsonwebtoken'

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key'

export interface TokenPayload {
  userId: string
  appId: string
  email: string
  role: string
  type: 'app_access'
}

export function generateToken(payload: Omit<TokenPayload, 'type'>): string {
  return jwt.sign(
    { ...payload, type: 'app_access' },
    JWT_SECRET,
    { expiresIn: '24h' }
  )
}

export function verifyToken(token: string): TokenPayload {
  try {
    return jwt.verify(token, JWT_SECRET) as TokenPayload
  } catch (error) {
    throw new Error('Invalid or expired token')
  }
}

export function decodeToken(token: string): TokenPayload | null {
  try {
    return jwt.decode(token) as TokenPayload
  } catch (error) {
    return null
  }
}
