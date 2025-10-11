# Fix Video Playback - Complete Guide

## Current Status
Videos uploaded to Firebase Storage are not playing in the browser.

## Quick Diagnosis

Open your browser console (F12) and look for errors. Common issues:

### 1. CORS Error
```
Access to video at 'https://firebasestorage.googleapis.com/...' from origin 
'http://localhost:3001' has been blocked by CORS policy
```

**Solution:** Apply CORS configuration (see below)

### 2. Network Error (403 Forbidden)
```
Failed to load resource: the server responded with a status of 403
```

**Solution:** Update Firebase Storage Rules (see below)

### 3. Format Error
```
Video format or MIME type is not supported
```

**Solution:** Re-upload video as MP4

---

## Solutions (Try in Order)

### SOLUTION 1: Update Firebase Storage Rules (Easiest)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **botleji**
3. Click **Storage** in left menu
4. Click **Rules** tab
5. Replace with this code:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /training/{allPaths=**} {
      allow read: if true;  // Public read
      allow write: if request.auth != null;
    }
    match /{allPaths=**} {
      allow read: if true;  // Make everything readable
      allow write: if request.auth != null;
    }
  }
}
```

6. Click **Publish**
7. Wait 30 seconds
8. **Hard refresh** browser (Ctrl+F5 or Cmd+Shift+R)
9. Try playing video

---

### SOLUTION 2: Apply CORS Configuration

**Using Google Cloud Console:**

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **botleji**
3. Click **Activate Cloud Shell** (">_" icon, top right)
4. Run these commands:

```bash
# Create CORS file
cat > cors.json << 'EOF'
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"]
  }
]
EOF

# Apply to your bucket
gsutil cors set cors.json gs://botleji.firebasestorage.app

# Verify
gsutil cors get gs://botleji.firebasestorage.app
```

5. **Clear browser cache** completely
6. **Hard refresh** (Ctrl+F5)
7. Try again

---

### SOLUTION 3: Make Specific File Public

If you just want to test one video:

1. Go to [Firebase Console](https://console.firebase.google.com/) → **Storage**
2. Navigate to your video file: `training/videos/...`
3. Click the three dots (⋮) → **Edit permissions**
4. Click **Add member**
5. Enter: `allUsers`
6. Role: **Storage Object Viewer**
7. Click **Save**
8. Try playing the video

---

### SOLUTION 4: Re-upload with Correct Settings

The new VideoPlayer component will show detailed errors. To fix:

1. **Delete the problematic video** from training content
2. **Re-upload it** using the upload form
3. New uploads include:
   - ✅ Correct Content-Type metadata
   - ✅ Proper file naming
   - ✅ Cache headers
4. New video should work immediately

---

## Testing the Video URL

### Test 1: Direct URL Access

1. Copy the video URL from the error message
2. Paste it in a new browser tab
3. **Expected:** Video downloads or plays
4. **If 403 error:** Rules problem
5. **If CORS error:** CORS problem

### Test 2: Using curl

```bash
curl -I "YOUR_VIDEO_URL_HERE"
```

**Look for:**
```
HTTP/2 200 
content-type: video/mp4
access-control-allow-origin: *
```

If missing `access-control-allow-origin`, you need CORS.

---

## Verify Current Setup

### Check Firebase Storage Rules

1. Firebase Console → Storage → Rules
2. Should have: `allow read: if true;` for training content

### Check CORS

```bash
gsutil cors get gs://botleji.firebasestorage.app
```

Should return:
```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD"],
    ...
  }
]
```

### Check File Metadata

In Firebase Console → Storage → Click file:
- **Content-Type:** should be `video/mp4` or `video/webm`
- **Access:** should have public read

---

## New Features in VideoPlayer

The new VideoPlayer component provides:

### ✅ Automatic Error Detection
```
❌ Unable to Play Video
Network error while loading video

Possible solutions:
• Check if CORS is configured on Firebase Storage
• Verify the video file format (should be MP4 or WebM)
• Try re-uploading the video
• Check browser console for detailed errors

Direct URL for testing:
https://firebasestorage.googleapis.com/...
```

### ✅ Loading States
- Shows spinner while loading
- "Ready to play" indicator when loaded
- Progress feedback

### ✅ Debug Information
- In development mode, click "Debug Info"
- Shows URL, poster, loading state, errors
- Helps identify exact problem

### ✅ Better Error Messages
- Decodes video error codes
- Provides actionable solutions
- Direct URL for manual testing

---

## Common Issues & Fixes

### Issue: "Video format not supported"
**Fix:** Convert video to MP4 (H.264 codec)
```bash
ffmpeg -i input.mov -c:v libx264 -c:a aac output.mp4
```

### Issue: "Failed to load resource: 403"
**Fix:** Update Storage Rules (Solution 1 above)

### Issue: "CORS policy blocked"
**Fix:** Apply CORS config (Solution 2 above)

### Issue: Video loads but won't play
**Fix:** Check video codec - must be H.264 for web

### Issue: Works in Chrome but not Firefox
**Fix:** Ensure WebM source is also provided

---

## Quick Command Reference

### Apply CORS (in Cloud Shell)
```bash
echo '[{"origin":["*"],"method":["GET"],"maxAgeSeconds":3600}]' > cors.json
gsutil cors set cors.json gs://botleji.firebasestorage.app
```

### Check CORS
```bash
gsutil cors get gs://botleji.firebasestorage.app
```

### List videos
```bash
gsutil ls gs://botleji.firebasestorage.app/training/videos/
```

### Make file public
```bash
gsutil acl ch -u AllUsers:R gs://botleji.firebasestorage.app/path/to/file.mp4
```

---

## Still Not Working?

### Checklist:
- [ ] Firebase Storage Rules allow public read
- [ ] CORS is configured on the bucket
- [ ] Video file is MP4 format
- [ ] Browser cache is cleared
- [ ] Hard refresh was done (Ctrl+F5)
- [ ] Tried in incognito mode
- [ ] Checked browser console for errors

### Get Help:
1. Open browser console (F12)
2. Look at the video player error message
3. Click "Debug Info" in development mode
4. Copy the exact error message
5. Check the Direct URL manually

### Nuclear Option (Last Resort):
```bash
# Make entire bucket public (TEMPORARY FOR TESTING)
gsutil iam ch allUsers:objectViewer gs://botleji.firebasestorage.app
```

⚠️ **Warning:** This makes ALL files public. Only for testing!

To revert:
```bash
gsutil iam ch -d allUsers:objectViewer gs://botleji.firebasestorage.app
```

---

## Expected Behavior After Fix

1. Upload video through admin dashboard
2. Video appears in training content list
3. Click to expand content
4. Video player shows with thumbnail
5. Click play button
6. Video streams and plays smoothly
7. Controls work (pause, volume, seek, fullscreen)

**That's it!** 🎥✨

---

## Need More Help?

The VideoPlayer component now shows detailed error messages. When it fails:

1. Look at the error message in the red box
2. Follow the suggestions provided
3. Click the "Direct URL for testing" link
4. Test if that URL works in a new tab
5. Check browser console for technical details

Good luck! 🚀

