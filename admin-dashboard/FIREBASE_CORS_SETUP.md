# Firebase Storage CORS Configuration

## Issue
Videos uploaded to Firebase Storage may not play due to CORS (Cross-Origin Resource Sharing) restrictions.

## Solution

### Option 1: Using Google Cloud Console (Recommended)

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com/
   - Select project: `botleji`

2. **Open Cloud Shell**
   - Click the terminal icon (">_") in the top right
   - This opens a command line interface

3. **Apply CORS Configuration**
   ```bash
   # Create CORS configuration file
   cat > cors.json << 'EOF'
   [
     {
       "origin": ["*"],
       "method": ["GET", "HEAD", "PUT", "POST", "DELETE"],
       "maxAgeSeconds": 3600,
       "responseHeader": [
         "Content-Type",
         "Content-Length",
         "Content-Range",
         "Accept-Ranges"
       ]
     }
   ]
   EOF
   
   # Apply CORS to your bucket
   gsutil cors set cors.json gs://botleji.firebasestorage.app
   ```

4. **Verify CORS is applied**
   ```bash
   gsutil cors get gs://botleji.firebasestorage.app
   ```

### Option 2: Using Firebase Console

1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project: `botleji`
3. Go to **Storage** → **Rules**
4. Ensure rules allow read access:
   ```
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /{allPaths=**} {
         allow read: if true;
         allow write: if request.auth != null;
       }
     }
   }
   ```

### Option 3: Make Files Public

1. Go to Firebase Storage in console
2. Click on the file
3. Click "Access" tab
4. Add permission: "allUsers" with role "Storage Object Viewer"

## Testing

After applying CORS:

1. **Clear browser cache** (Ctrl+Shift+Delete / Cmd+Shift+Delete)
2. **Hard refresh** the admin dashboard (Ctrl+F5 / Cmd+Shift+R)
3. Try playing a video

## Why This Happens

- Firebase Storage by default blocks cross-origin requests
- HTML5 video player needs proper CORS headers to stream video
- The `crossOrigin="anonymous"` attribute in the video tag requires CORS

## Current Configuration

The admin dashboard is configured to:
- Set proper Content-Type metadata during upload
- Use `crossOrigin="anonymous"` on video/image elements
- Include both MP4 and WebM sources for compatibility
- Use poster image (thumbnail) while video loads

## Troubleshooting

### Video still won't play?

1. **Check browser console** (F12) for CORS errors
2. **Verify the URL** - it should look like:
   ```
   https://firebasestorage.googleapis.com/v0/b/botleji.firebasestorage.app/o/...
   ```
3. **Test the URL directly** - paste it in a new tab
4. **Check file format** - ensure it's MP4 or WebM
5. **Re-upload the video** - new uploads will have correct metadata

### Alternative: Use Firebase CDN

Firebase Storage URLs automatically use Google's CDN, which handles CORS better:
- URLs include authentication tokens
- Content is cached globally
- Fast delivery worldwide

## Security Note

Setting `"origin": ["*"]` allows all domains to access your files. This is fine for public training content, but for private content, specify allowed domains:

```json
{
  "origin": ["https://yourdomain.com", "http://localhost:3001"],
  "method": ["GET"],
  "maxAgeSeconds": 3600
}
```

## Quick Fix for Immediate Testing

If you can't apply CORS right now, you can:

1. **Download the video**
2. **Re-upload it** (new uploads have correct metadata)
3. The new URL should work immediately

Or use a CORS proxy (not recommended for production):
```javascript
const proxyUrl = `https://cors-anywhere.herokuapp.com/${videoUrl}`;
```

