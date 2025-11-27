# 🔌 PORT Environment Variable - Explained

## What is PORT Used For?

The `PORT` environment variable tells your application **which port to listen on** for incoming HTTP requests.

---

## 🏠 Local Development vs Production

### Local Development:
- You set `PORT=3000` in your `.env` file
- Your app runs on: `http://localhost:3000`
- You control which port to use

### Production (Render):
- **Render automatically sets the PORT** for you
- Render assigns a port dynamically (could be any number)
- Your app must read `process.env.PORT` to know which port to use
- Render's load balancer routes traffic to that port

---

## 📋 How It Works in Your Code

**File**: `backend/src/main.ts`

```typescript
const port = process.env.PORT ?? 3000;
await app.listen(port, '0.0.0.0');
```

**What this does:**
- Reads `process.env.PORT` (set by Render automatically)
- Falls back to `3000` if not set (for local development)
- Listens on that port for incoming requests

---

## ✅ Do You Need PORT in Render?

### Short Answer: **NO, you don't need to set it!**

**Why?**
- ✅ Render **automatically sets** `PORT` for you
- ✅ Your code already reads `process.env.PORT`
- ✅ It will work without you setting it manually

### But You CAN Set It:
- If you want to explicitly set it to `3000`
- Usually not necessary - Render handles it

---

## 🎯 What to Do

### Option 1: Don't Set PORT (Recommended)
- ✅ Render sets it automatically
- ✅ Your code will use whatever Render assigns
- ✅ One less variable to manage

### Option 2: Set PORT = 3000 (Optional)
- If you want to be explicit
- Won't hurt, but not necessary
- Render might override it anyway

---

## 📝 Summary

| Environment | PORT Behavior |
|-------------|---------------|
| **Local Dev** | You set `PORT=3000` in `.env` |
| **Render** | Render sets it automatically - **you don't need to!** |

---

## ✅ Recommendation

**For Render deployment:**
- ❌ **Don't add PORT** - Render handles it automatically
- ✅ Your code already reads `process.env.PORT` correctly
- ✅ It will work without you setting it

**Just skip PORT** when adding environment variables to Render! 🚀

---

## 🔍 How Render Uses PORT

1. Render starts your app
2. Render sets `PORT` environment variable automatically (e.g., `PORT=10000`)
3. Your app reads `process.env.PORT` and listens on that port
4. Render's load balancer routes traffic from port 80/443 to your app's port
5. Everything works! ✨

---

## 💡 Why PORT Exists in Your .env

The `PORT=3000` in your local `.env` is for:
- **Local development** - so you can run `npm run start:dev` and access `localhost:3000`
- **Consistency** - same port every time you develop locally

**For production (Render)**: Not needed - Render handles it! ✅

