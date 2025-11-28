# Render Custom Domain Setup Guide
## Setting up www.bottleji.tn and admin.bottleji.tn

---

## Domain Structure

```
www.bottleji.tn          → Marketing/Landing Site (Static Site)
admin.bottleji.tn        → Admin Dashboard (Next.js Web Service)
api.bottleji.tn          → Backend API (Optional, currently using bottleji-api.onrender.com)
```

---

## Step 1: DNS Configuration

### 1.1 Add DNS Records in Your Domain Provider

Go to your domain registrar (where you bought `bottleji.tn`) and add these DNS records:

**For Marketing Site (www.bottleji.tn):**
```
Type: CNAME
Name: www
Value: [Render Static Site URL].onrender.com
TTL: 3600
```

**For Admin Dashboard (admin.bottleji.tn):**
```
Type: CNAME
Name: admin
Value: [Your Render Admin Service].onrender.com
TTL: 3600
```

**Optional - Root Domain (bottleji.tn):**
```
Type: CNAME
Name: @ (or leave blank)
Value: www.bottleji.tn
TTL: 3600
```

**Note:** Some registrars require using `ALIAS` or `ANAME` for root domain instead of CNAME.

---

## Step 2: Configure Render Services

### 2.1 Admin Dashboard (admin.bottleji.tn)

1. **Go to your Admin Dashboard service in Render**
2. **Settings → Custom Domains**
3. **Add Custom Domain:**
   - Enter: `admin.bottleji.tn`
   - Click "Add"
4. **Render will provide DNS verification:**
   - You may need to add a TXT record for verification
   - Follow Render's instructions

5. **SSL Certificate:**
   - Render automatically provisions SSL via Let's Encrypt
   - Takes 5-10 minutes after DNS propagates

### 2.2 Marketing Site (www.bottleji.tn)

1. **Create a new Static Site in Render** (if not already created)
2. **Settings → Custom Domains**
3. **Add Custom Domain:**
   - Enter: `www.bottleji.tn`
   - Click "Add"
4. **Follow DNS verification steps**

---

## Step 3: Update Environment Variables

### 3.1 Admin Dashboard Environment Variables

In Render Dashboard → Admin Service → Environment:

**No changes needed!** The admin dashboard already uses:
- `NEXT_PUBLIC_API_URL` (optional, defaults to production API)
- `NEXT_PUBLIC_WS_URL` (optional, defaults to production WebSocket)

The domain change won't affect API calls since they're configured separately.

### 3.2 Optional: Update API Base URL

If you want to use a custom domain for API:

1. **Create API service custom domain:** `api.bottleji.tn`
2. **Update admin dashboard env var:**
   ```
   NEXT_PUBLIC_API_URL=https://api.bottleji.tn/api
   NEXT_PUBLIC_WS_URL=wss://api.bottleji.tn
   ```

---

## Step 4: Verify Setup

### 4.1 Check DNS Propagation

```bash
# Check if DNS is propagated
dig admin.bottleji.tn
dig www.bottleji.tn

# Or use online tools:
# - https://dnschecker.org
# - https://www.whatsmydns.net
```

### 4.2 Test Access

1. **Admin Dashboard:**
   - Visit: `https://admin.bottleji.tn`
   - Should redirect to login page
   - SSL should be active (green lock icon)

2. **Marketing Site:**
   - Visit: `https://www.bottleji.tn`
   - Should show your landing page

---

## Step 5: Security Considerations

### 5.1 Admin Dashboard Security

**Already implemented:**
- ✅ Session-based authentication (sessionStorage)
- ✅ Inactivity timeout
- ✅ JWT token authentication
- ✅ HTTPS/SSL encryption

**Additional recommendations:**
- Consider IP whitelisting (if you have static IPs)
- Enable 2FA for admin accounts
- Monitor access logs

### 5.2 CORS Configuration

**Backend CORS** should include:
```typescript
// In backend/src/main.ts
allowedOrigins: [
  'https://admin.bottleji.tn',
  'https://www.bottleji.tn',
  // ... other origins
]
```

---

## Step 6: Marketing Site Setup

### 6.1 Create Static Site

**Option 1: Simple HTML/CSS/JS**
- Create a folder with `index.html`
- Upload to Render Static Site
- Point custom domain to it

**Option 2: Static Site Generator**
- Use Next.js Static Export
- Or Gatsby, Hugo, etc.
- Deploy to Render Static Site

### 6.2 Recommended Structure

```
marketing-site/
├── index.html          # Homepage
├── about.html          # About page
├── download.html       # Download page
├── css/
│   └── style.css
├── js/
│   └── main.js
└── images/
    └── logo.png
```

---

## Troubleshooting

### Issue: DNS Not Resolving

**Solution:**
- Wait 24-48 hours for DNS propagation
- Check DNS records are correct
- Verify CNAME points to correct Render URL

### Issue: SSL Certificate Not Provisioning

**Solution:**
- Ensure DNS is fully propagated
- Check Render logs for SSL errors
- Try removing and re-adding custom domain

### Issue: Admin Dashboard Not Loading

**Solution:**
- Check Render service is running
- Verify environment variables
- Check browser console for errors
- Ensure CORS allows the new domain

### Issue: API Calls Failing

**Solution:**
- Verify `NEXT_PUBLIC_API_URL` is set correctly
- Check backend CORS includes `admin.bottleji.tn`
- Test API endpoint directly

---

## Cost Considerations

**Render Custom Domains:**
- ✅ **Free** - Custom domains are included
- ✅ **Free SSL** - Let's Encrypt certificates
- ✅ **No additional cost** for subdomains

**Only costs:**
- Your domain registration (~$10-20/year for .tn)
- Render service hosting (already paying)

---

## Final Checklist

- [ ] DNS records added (www, admin)
- [ ] Custom domains added in Render
- [ ] DNS verification completed
- [ ] SSL certificates provisioned
- [ ] Admin dashboard accessible at admin.bottleji.tn
- [ ] Marketing site accessible at www.bottleji.tn
- [ ] Backend CORS updated (if needed)
- [ ] Environment variables verified
- [ ] All links and redirects tested

---

## Example DNS Configuration

**For Namecheap/GoDaddy/Other Providers:**

```
Type    Name    Value                              TTL
CNAME   www     your-static-site.onrender.com      3600
CNAME   admin   your-admin-service.onrender.com    3600
CNAME   @       www.bottleji.tn                   3600
```

**For Cloudflare:**

1. Add domain to Cloudflare
2. Set DNS records:
   - `www` → CNAME → `your-static-site.onrender.com`
   - `admin` → CNAME → `your-admin-service.onrender.com`
3. Set SSL/TLS to "Full" or "Full (strict)"
4. Enable "Always Use HTTPS"

---

## Next Steps

1. **Set up marketing site** on `www.bottleji.tn`
2. **Test admin dashboard** on `admin.bottleji.tn`
3. **Update app store listings** with new website URL
4. **Update email templates** with new admin URL
5. **Monitor logs** for any issues

---

**Document Version:** 1.0  
**Last Updated:** January 2025

