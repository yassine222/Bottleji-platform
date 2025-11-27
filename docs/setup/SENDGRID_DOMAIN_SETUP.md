# SendGrid Domain Authentication Setup

## Why Domain Authentication?

- ✅ **Better deliverability** (emails less likely to go to spam)
- ✅ **Professional branding** (emails from your domain)
- ✅ **Higher sending limits**
- ✅ **Better reputation**

---

## Step-by-Step: Domain Authentication

### Step 1: Start Domain Authentication in SendGrid

1. Go to SendGrid Dashboard: https://app.sendgrid.com/
2. Click **"Settings"** → **"Sender Authentication"**
3. Click **"Authenticate Your Domain"**
4. Choose your DNS provider:
   - If you see your provider (e.g., Cloudflare, GoDaddy, Namecheap), select it
   - Otherwise, select **"Generic"**

### Step 2: Enter Domain Information

1. **Domain**: Enter your domain (e.g., `bottleji.com`)
   - Don't include `www` or `http://`
   - Just the domain: `bottleji.com`

2. **Subdomain** (optional): Leave blank or use `mail` or `email`
   - This creates: `mail.bottleji.com` or `email.bottleji.com`
   - Or leave blank to use root domain

3. Click **"Next"**

### Step 3: Add DNS Records

SendGrid will show you DNS records to add. You'll need to add these to your domain's DNS settings:

#### Records to Add:

1. **CNAME Record 1** (for DKIM):
   - **Name/Host**: `s1._domainkey` (or similar)
   - **Value**: `s1.domainkey.u1234567.wl123.sendgrid.net`
   - **Type**: CNAME

2. **CNAME Record 2** (for DKIM):
   - **Name/Host**: `s2._domainkey` (or similar)
   - **Value**: `s2.domainkey.u1234567.wl123.sendgrid.net`
   - **Type**: CNAME

3. **CNAME Record** (for tracking):
   - **Name/Host**: `em1234` (or similar)
   - **Value**: `u1234567.wl123.sendgrid.net`
   - **Type**: CNAME

4. **TXT Record** (for SPF):
   - **Name/Host**: `@` or blank (root domain)
   - **Value**: `v=spf1 include:sendgrid.net ~all`
   - **Type**: TXT

### Step 4: Add DNS Records to Your Domain

1. **Go to your domain registrar** (where you bought the domain)
   - Examples: Cloudflare, GoDaddy, Namecheap, Google Domains

2. **Find DNS Management**:
   - Cloudflare: DNS → Records
   - GoDaddy: DNS Management
   - Namecheap: Advanced DNS

3. **Add each record** from Step 3:
   - Click "Add Record"
   - Enter the Name/Host
   - Enter the Value
   - Select the Type (CNAME or TXT)
   - Save

4. **Wait for DNS propagation** (5-60 minutes)

### Step 5: Verify in SendGrid

1. Go back to SendGrid dashboard
2. Click **"Verify"** or **"Check DNS"**
3. SendGrid will check if records are correct
4. ✅ **Domain Verified!**

---

## Step 6: Update Render Environment Variables

After domain is verified, update Render:

```
EMAIL_USER=apikey
EMAIL_PASS=your-sendgrid-api-key
SENDGRID_FROM_EMAIL=noreply@bottleji.com
USE_SENDGRID=true
```

**Important**: Use an email from your verified domain:
- ✅ `noreply@bottleji.com` (if domain is `bottleji.com`)
- ✅ `hello@bottleji.com`
- ❌ `noreply@gmail.com` (won't work)

---

## Common DNS Providers

### Cloudflare
1. Go to your domain in Cloudflare
2. DNS → Records
3. Add each CNAME and TXT record
4. Proxy status: **DNS only** (gray cloud)

### GoDaddy
1. Go to DNS Management
2. Add each record
3. Save

### Namecheap
1. Advanced DNS
2. Add each record
3. Save

### Google Domains
1. DNS → Custom records
2. Add each record
3. Save

---

## Troubleshooting

### "DNS records not found"
- Wait longer (DNS can take up to 48 hours, usually 5-60 minutes)
- Check for typos in DNS records
- Make sure you're adding to the correct domain

### "Verification failed"
- Double-check all DNS records are correct
- Make sure CNAME records point to SendGrid's servers
- Verify TXT record for SPF is correct

### "Still not verified after 24 hours"
- Contact SendGrid support
- Check if your DNS provider has any restrictions
- Verify you have access to add DNS records

---

## After Verification

Once verified:
- ✅ Emails will send from your domain
- ✅ Better deliverability
- ✅ Professional appearance
- ✅ Higher sending limits

---

## Quick Checklist

- [ ] Go to SendGrid → Sender Authentication
- [ ] Click "Authenticate Your Domain"
- [ ] Enter your domain
- [ ] Copy DNS records from SendGrid
- [ ] Add DNS records to your domain registrar
- [ ] Wait for DNS propagation (5-60 min)
- [ ] Verify in SendGrid
- [ ] Update Render with `SENDGRID_FROM_EMAIL=noreply@yourdomain.com`
- [ ] Test email sending

---

## Need Help?

If you're stuck:
1. Check SendGrid's documentation
2. Contact your domain registrar support
3. SendGrid support is helpful too

