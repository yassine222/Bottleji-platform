# Computing Power Requirements Analysis
## Bottleji Platform - 100,000 Users

**Date:** January 2025  
**User Base:** 100,000 active users  
**Usage Pattern:** ~1 drop per user per week

---

## Executive Summary

For 100,000 users with weekly drop creation, the platform requires:
- **API Backend:** 4-8 CPU cores, 8-16 GB RAM
- **Admin Dashboard:** 2-4 CPU cores, 4-8 GB RAM  
- **Database:** 8-16 GB RAM, 100-200 GB storage
- **Total Monthly Cost:** $200-400 (cloud hosting)

---

## 1. Traffic & Usage Estimates

### 1.1 User Activity Patterns

| Metric | Daily | Hourly | Peak (3x) |
|--------|-------|--------|----------|
| **Drops Created** | 14,285 | 595 | 1,785/hour |
| **Drops Collected** | ~10,000 | 417 | 1,250/hour |
| **User Logins** | ~20,000 | 833 | 2,500/hour |
| **API Requests** | ~500,000 | 20,833 | 62,500/hour |
| **WebSocket Connections** | - | 20,000-30,000 | 50,000 (peak) |

### 1.2 Request Breakdown by Endpoint

| Endpoint Category | Requests/Day | Requests/Hour | Peak/Hour |
|-------------------|--------------|---------------|-----------|
| **Authentication** | 50,000 | 2,083 | 6,250 |
| - Login | 20,000 | 833 | 2,500 |
| - Signup/OTP | 5,000 | 208 | 625 |
| - Profile Updates | 25,000 | 1,042 | 3,125 |
| **Drops** | 200,000 | 8,333 | 25,000 |
| - Create Drop | 14,285 | 595 | 1,785 |
| - List Available | 100,000 | 4,167 | 12,500 |
| - Accept/Collect | 10,000 | 417 | 1,250 |
| - View Details | 75,715 | 3,155 | 9,465 |
| **Notifications** | 150,000 | 6,250 | 18,750 |
| - Fetch Notifications | 100,000 | 4,167 | 12,500 |
| - Mark as Read | 50,000 | 2,083 | 6,250 |
| **Rewards** | 50,000 | 2,083 | 6,250 |
| - Browse Shop | 30,000 | 1,250 | 3,750 |
| - Redeem | 5,000 | 208 | 625 |
| - View History | 15,000 | 625 | 1,875 |
| **Support Tickets** | 10,000 | 417 | 1,250 |
| **Admin Dashboard** | 40,000 | 1,667 | 5,000 |
| - Dashboard Stats | 5,000 | 208 | 625 |
| - User Management | 10,000 | 417 | 1,250 |
| - Drop Management | 15,000 | 625 | 1,875 |
| - Reports/Analytics | 10,000 | 417 | 1,250 |

---

## 2. API Backend Requirements (NestJS)

### 2.1 CPU Requirements

**Calculation:**
- Average request processing: 50-100ms
- Peak requests: 62,500/hour = 1,042/minute = 17/second
- With 3x safety margin: 50 requests/second
- CPU per request: ~0.1 CPU-seconds
- **Required:** 5-8 CPU cores (with headroom)

**Recommended:** 4-8 vCPU cores

### 2.2 Memory Requirements

**Components:**
- Node.js base: 200-300 MB
- NestJS application: 300-500 MB
- WebSocket connections: 20,000 × 50 KB = 1 GB
- Request buffers: 500 MB
- Database connection pool: 200 MB
- Image processing cache: 500 MB
- **Total:** 2.7-3 GB base

**With headroom (2x):** 6-8 GB RAM  
**Recommended:** 8-16 GB RAM

### 2.3 WebSocket Connections

**Requirements:**
- Concurrent connections: 20,000-30,000
- Memory per connection: ~50 KB
- Total WebSocket memory: 1-1.5 GB
- CPU overhead: ~10-15% of total CPU

**Scaling Strategy:**
- Use Socket.IO with Redis adapter for horizontal scaling
- Consider dedicated WebSocket server if >50,000 connections

### 2.4 Database Connection Pool

**MongoDB Connections:**
- Recommended: 50-100 connections
- Each connection: ~2-5 MB memory
- Total: 100-500 MB

### 2.5 Storage Requirements

**Image Storage (Firebase Storage):**
- Average image size: 2-3 MB
- Drops per day: 14,285
- Daily storage: 28-43 GB
- Monthly storage: 840-1,290 GB
- With 30-day retention: ~1.3 TB

**Database Storage:**
- User records: 100,000 × 5 KB = 500 MB
- Drop records: 14,285/day × 30 days × 2 KB = 857 MB
- Notifications: 500,000 × 1 KB = 500 MB
- Interactions/Attempts: 1,000,000 × 1 KB = 1 GB
- **Total:** ~3 GB (growing ~1 GB/month)

---

## 3. Admin Dashboard Requirements (Next.js)

### 3.1 CPU Requirements

**Usage:**
- Concurrent admins: 10-50
- Requests per admin: 100-500/day
- Peak requests: 5,000/hour = 83/minute = 1.4/second
- **Required:** 1-2 CPU cores

**Recommended:** 2-4 vCPU cores

### 3.2 Memory Requirements

**Components:**
- Next.js server: 200-400 MB
- React rendering: 100-200 MB per admin session
- API calls cache: 200-500 MB
- **Total:** 500 MB - 1.5 GB

**Recommended:** 4-8 GB RAM

### 3.3 Static Asset Serving

**Assets:**
- Logo/images: ~5 MB
- JavaScript bundles: ~2-3 MB
- CSS: ~500 KB
- **Total:** ~8 MB per page load

**Bandwidth:**
- 50 admins × 10 page loads/day × 8 MB = 4 GB/day
- Negligible compared to API traffic

---

## 4. Database Requirements (MongoDB)

### 4.1 Read/Write Operations

**Daily Operations:**
- Reads: ~400,000/day = 4.6/second average, 14/second peak
- Writes: ~50,000/day = 0.6/second average, 2/second peak
- Index lookups: ~200,000/day

**Recommended:** MongoDB Atlas M30 or equivalent
- 8 GB RAM
- 100 GB storage
- 2 vCPU cores

### 4.2 Storage Growth

**Monthly Growth:**
- Drops: ~428,550 records/month × 2 KB = 857 MB
- Notifications: ~15,000,000 records/month × 1 KB = 15 GB
- Interactions: ~30,000,000 records/month × 1 KB = 30 GB
- **Total:** ~46 GB/month

**Year 1 Storage:** ~550 GB  
**Recommended:** 200 GB initial, auto-scaling to 1 TB

### 4.3 Index Requirements

**Critical Indexes:**
- Users: email, userId (unique)
- Drops: userId, status, location (geospatial), createdAt
- Notifications: userId, isRead, createdAt
- Interactions: dropoffId, collectorId, createdAt

**Index Storage:** ~10-20% of data size = 50-100 GB

---

## 5. Network Bandwidth

### 5.1 API Traffic

**Outbound (API responses):**
- Average response: 5-10 KB
- Daily: 500,000 requests × 7.5 KB = 3.75 GB
- Monthly: ~112 GB

**Inbound (API requests):**
- Average request: 2-5 KB
- Daily: 500,000 requests × 3.5 KB = 1.75 GB
- Monthly: ~52 GB

### 5.2 Image Upload/Download

**Uploads:**
- Daily: 14,285 drops × 2.5 MB = 35.7 GB
- Monthly: ~1.07 TB

**Downloads:**
- Daily: 100,000 views × 2.5 MB = 250 GB
- Monthly: ~7.5 TB

**Total Image Bandwidth:** ~8.5 TB/month

### 5.3 WebSocket Traffic

**Per Connection:**
- Heartbeat: 100 bytes every 30s = 288 KB/day
- Notifications: 1-2 KB per notification
- Average: 5 notifications/day = 5-10 KB/day
- **Total per connection:** ~300 KB/day

**30,000 connections:** 9 GB/day = 270 GB/month

### 5.4 Total Bandwidth

| Type | Monthly |
|------|---------|
| API Requests | 164 GB |
| Image Uploads | 1.07 TB |
| Image Downloads | 7.5 TB |
| WebSocket | 270 GB |
| **Total** | **~9 TB/month** |

---

## 6. Recommended Infrastructure

### 6.1 Option 1: Cloud Provider (Recommended)

#### **Render.com**

**API Backend:**
- Service Type: Web Service
- Instance: Standard (4 vCPU, 8 GB RAM)
- Cost: ~$85/month
- Auto-scaling: Enabled (2-4 instances)

**Admin Dashboard:**
- Service Type: Web Service
- Instance: Standard (2 vCPU, 4 GB RAM)
- Cost: ~$25/month

**MongoDB:**
- Provider: MongoDB Atlas
- Tier: M30 (8 GB RAM, 100 GB storage)
- Cost: ~$57/month

**Storage:**
- Firebase Storage: Pay-as-you-go
- Estimated: $50-100/month (8.5 TB bandwidth)

**Total:** ~$217-267/month

#### **AWS/Azure/GCP**

**API Backend:**
- EC2/VM: t3.xlarge (4 vCPU, 16 GB RAM)
- Cost: ~$120/month
- Load Balancer: ~$20/month

**Admin Dashboard:**
- EC2/VM: t3.medium (2 vCPU, 4 GB RAM)
- Cost: ~$30/month

**MongoDB:**
- MongoDB Atlas M30: ~$57/month

**Storage:**
- S3/Blob Storage: ~$50-100/month

**Total:** ~$277-327/month

### 6.2 Option 2: Dedicated Server

**Specifications:**
- CPU: 8 cores (Intel Xeon or AMD EPYC)
- RAM: 32 GB
- Storage: 500 GB SSD + 2 TB HDD
- Bandwidth: 10 TB/month

**Cost:** $150-250/month (Hetzner, OVH, etc.)

**Pros:**
- Full control
- Predictable costs
- High performance

**Cons:**
- Manual scaling
- No auto-scaling
- Requires DevOps expertise

---

## 7. Scaling Considerations

### 7.1 Horizontal Scaling

**API Backend:**
- Use load balancer (Nginx, AWS ALB)
- Stateless application (easy to scale)
- Session storage in Redis
- WebSocket: Use Redis adapter for Socket.IO

**Admin Dashboard:**
- Stateless Next.js app
- Can run multiple instances
- Use CDN for static assets

### 7.2 Vertical Scaling

**When to Scale Up:**
- CPU usage consistently >70%
- Memory usage >80%
- Response times >500ms
- Database connection pool exhausted

### 7.3 Database Scaling

**Read Replicas:**
- Add 1-2 read replicas for heavy read operations
- Route analytics queries to replicas

**Sharding:**
- Consider when database >500 GB
- Shard by userId or geographic region

---

## 8. Performance Optimizations

### 8.1 Caching Strategy

**Redis Cache:**
- User sessions: 1-2 GB
- Frequently accessed data: 500 MB
- API response cache: 1-2 GB
- **Total:** 3-5 GB Redis instance

**CDN:**
- Static assets (admin dashboard)
- Image thumbnails
- API responses (where appropriate)

### 8.2 Database Optimizations

- Index all frequently queried fields
- Use compound indexes for complex queries
- Implement query result pagination
- Archive old data (>90 days) to cold storage

### 8.3 Image Optimization

- Compress images on upload (target: <1 MB)
- Generate multiple sizes (thumbnail, medium, full)
- Use WebP format where supported
- Lazy load images in mobile app

---

## 9. Monitoring & Alerts

### 9.1 Key Metrics

**API:**
- Request rate (requests/second)
- Response time (p50, p95, p99)
- Error rate
- CPU/Memory usage
- Database connection pool usage

**Database:**
- Query performance
- Index usage
- Storage growth
- Replication lag

**WebSocket:**
- Active connections
- Message throughput
- Connection errors

### 9.2 Alert Thresholds

- CPU >80% for 5 minutes
- Memory >85% for 5 minutes
- Response time p95 >1 second
- Error rate >1%
- Database connections >80% of pool

---

## 10. Cost Breakdown (Monthly)

| Component | Low Estimate | High Estimate |
|-----------|--------------|---------------|
| API Backend (4 vCPU, 8 GB) | $85 | $120 |
| Admin Dashboard (2 vCPU, 4 GB) | $25 | $30 |
| MongoDB Atlas M30 | $57 | $57 |
| Firebase Storage (8.5 TB) | $50 | $100 |
| Load Balancer | $0 | $20 |
| Redis Cache (optional) | $15 | $30 |
| CDN (optional) | $10 | $30 |
| Monitoring/Logging | $10 | $20 |
| **Total** | **$252** | **$407** |

---

## 11. Growth Projections

### 11.1 200,000 Users (2x)

**Requirements:**
- API: 8-12 vCPU, 16-24 GB RAM
- Database: M40 (16 GB RAM, 200 GB storage)
- Bandwidth: ~18 TB/month
- **Cost:** ~$400-600/month

### 11.2 500,000 Users (5x)

**Requirements:**
- API: 16-24 vCPU, 32-48 GB RAM (multiple instances)
- Database: M50 (32 GB RAM, 500 GB storage) + read replicas
- Bandwidth: ~45 TB/month
- **Cost:** ~$800-1,200/month

---

## 12. Recommendations

### 12.1 Initial Setup (100K users)

1. **Start with Render.com** for simplicity
   - API: Standard instance (4 vCPU, 8 GB)
   - Dashboard: Standard instance (2 vCPU, 4 GB)
   - Auto-scaling enabled

2. **MongoDB Atlas M30**
   - 8 GB RAM, 100 GB storage
   - Enable auto-scaling

3. **Firebase Storage**
   - Pay-as-you-go pricing
   - Implement image compression

4. **Add Redis** (optional but recommended)
   - 3-5 GB instance for caching
   - Reduces database load by 30-40%

### 12.2 Optimization Priorities

1. **Implement caching** (Redis)
2. **Optimize database queries** (indexes, pagination)
3. **Compress images** (reduce storage/bandwidth by 50-70%)
4. **Use CDN** for static assets
5. **Monitor and alert** on key metrics

### 12.3 Scaling Plan

**Phase 1 (0-100K users):** Single instance, basic monitoring  
**Phase 2 (100K-200K users):** Add load balancer, read replicas  
**Phase 3 (200K+ users):** Horizontal scaling, dedicated services

---

## 13. Conclusion

For **100,000 users** with weekly drop creation:

- **Minimum viable:** 4 vCPU, 8 GB RAM (API) + 2 vCPU, 4 GB RAM (Dashboard)
- **Recommended:** 4-8 vCPU, 8-16 GB RAM (API) + 2-4 vCPU, 4-8 GB RAM (Dashboard)
- **Monthly cost:** $250-400 (cloud hosting)
- **Key bottleneck:** Image bandwidth (8.5 TB/month)
- **Scaling strategy:** Horizontal scaling via load balancer

The platform is well-architected for horizontal scaling. The main cost driver is image storage/bandwidth, which can be optimized through compression and CDN usage.

---

**Document Version:** 1.0  
**Last Updated:** January 2025

