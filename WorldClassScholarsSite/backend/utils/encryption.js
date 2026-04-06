const crypto = require('crypto');

/**
 * Encryption utility for sensitive data (API keys, tokens)
 */
class EncryptionService {
  constructor(encryptionKey) {
    // Use SHA-256 to derive a 32-byte key from the encryption key
    this.key = crypto.createHash('sha256').update(String(encryptionKey)).digest();
  }

  /**
   * Encrypt sensitive data using AES-256-CBC
   * @param {string} plaintext - The data to encrypt
   * @returns {string} - Encrypted data in format: iv:encrypted (hex-encoded)
   */
  encrypt(plaintext) {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv('aes-256-cbc', this.key, iv);
    
    let encrypted = cipher.update(plaintext, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    return `${iv.toString('hex')}:${encrypted}`;
  }

  /**
   * Decrypt encrypted data
   * @param {string} encryptedData - Data in format: iv:encrypted (hex-encoded)
   * @returns {string} - Decrypted plaintext
   */
  decrypt(encryptedData) {
    const [ivHex, encrypted] = encryptedData.split(':');
    const iv = Buffer.from(ivHex, 'hex');
    const decipher = crypto.createDecipheriv('aes-256-cbc', this.key, iv);
    
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    
    return decrypted;
  }

  /**
   * Generate a secure random token
   * @param {number} length - Token length in bytes
   * @returns {string} - Hex-encoded token
   */
  static generateSecureToken(length = 32) {
    return crypto.randomBytes(length).toString('hex');
  }

  /**
   * Hash a value using SHA-256
   * @param {string} value - Value to hash
   * @returns {string} - Hex-encoded hash
   */
  static hash(value) {
    return crypto.createHash('sha256').update(value).digest('hex');
  }
}

module.exports = EncryptionService;
