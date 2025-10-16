# Security Notes

## NSSecureCoding Warning

If you see this warning in the console:
```
*** -[NSXPCDecoder validateAllowedClass:forKey:]: NSSecureCoding allowed classes list contains [NSObject class], which bypasses security by allowing any Objective-C class to be implicitly decoded.
```

This is a **system-level warning** from macOS and is **not critical** for the app's functionality. It occurs because:

1. **System APIs**: The app uses macOS system APIs (Keychain, UserDefaults, NotificationCenter) that internally use NSSecureCoding
2. **Inter-process Communication**: macOS uses NSXPC for secure communication between processes
3. **Legacy Compatibility**: Some system frameworks still allow NSObject for backward compatibility

## What We've Done

### Enhanced Security Measures

1. **Keychain Security**:
   - Added `kSecMatchLimitOne` to limit query results
   - Used `CFTypeRef` instead of `AnyObject` for better type safety
   - Added `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` for device-only access
   - Proper error handling and type checking

2. **UserDefaults Security**:
   - Added data validation (checking for empty data)
   - Proper error handling with try-catch
   - Added `synchronize()` for immediate persistence
   - Input validation before saving

3. **Data Validation**:
   - All data is validated before storage
   - JSON encoding/decoding with proper error handling
   - Type-safe operations throughout the codebase

## Security Best Practices

### Data Storage
- **Keychain**: Used for sensitive data (encryption keys)
- **UserDefaults**: Used for non-sensitive configuration
- **SQLite**: Local database with encryption at rest

### Encryption
- **AES-256**: Database encryption using CryptoKit
- **Key Management**: Keys stored securely in Keychain
- **No Hardcoded Secrets**: All sensitive data is dynamically generated

### Privacy
- **Local-Only**: No data leaves the device
- **No Telemetry**: No analytics or data collection
- **User Control**: Full export/delete capabilities

## If the Warning Persists

This warning is **harmless** and will not affect app functionality. It's a system-level warning that Apple will address in future macOS updates. The app implements proper security measures regardless of this warning.

### To Minimize the Warning (Optional)
1. Ensure you're using the latest macOS version
2. The warning may be reduced in future macOS updates
3. It's related to system frameworks, not our app code

## Reporting Security Issues

If you discover any security vulnerabilities in the app:
1. Please report them privately
2. Do not disclose publicly until fixed
3. Include steps to reproduce the issue

## Security Audit

The app has been designed with security in mind:
- ✅ No network communication
- ✅ Local data storage only
- ✅ Encrypted sensitive data
- ✅ Proper key management
- ✅ Input validation
- ✅ Error handling
- ✅ No hardcoded secrets
