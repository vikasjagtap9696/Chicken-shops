# 📊 Sales & Reports API - Frontend Documentation

> **Base URL:** `http://localhost:5000/api`
>
> **Content-Type:** `application/json`

---

## 📋 Table of Contents

### 🔹 Reports (Sales Analytics)
1. [Daily Sales Report](#1--daily-sales-report)
2. [Product-wise Sales Report](#2--product-wise-sales-report)
3. [Revenue Summary (Today + Monthly)](#3--revenue-summary)

### 🔹 Customer CRUD & Credit Hub
4. [Get All Customers](#4--get-all-customers)
5. [Get Customer by ID](#5--get-customer-by-id)
6. [Create Customer](#6--create-customer)
7. [Update Customer (Credit Tracking)](#7--update-customer)
8. [Delete Customer](#8--delete-customer)

---

## 📅 1. Daily Sales Report
Get all completed orders for a specific date with total revenue.
- **Endpoint:** `GET /reports/daily-sales?date=YYYY-MM-DD`

## 💰 2. Revenue Summary
Get today's revenue and current month's total revenue.
- **Endpoint:** `GET /reports/revenue-summary`
- **Response:** `{ "success": true, "data": { "dailyRevenue": "4500.00", "monthlyRevenue": "85000.00" } }`

---

## 👥 3. Customer & Credit Management (ADVANCED)

### 3.1 Get All Customers (with Balances)
- **Endpoint:** `GET /customers`
- **Required Fields in Response:**
  - `id`: unique ID
  - `name`: string
  - `phone`: string
  - `creditBalance`: **Decimal** (The amount customer owes to the shop)
  - `nextPaymentDate`: **Date/ISOString** (The date when customer promised to pay)

### 3.2 Update Customer (Payment Received)
When a customer pays back their remaining amount, use this to update the database.
- **Endpoint:** `PUT /customers/:id`
- **Body Example:**
  ```json
  {
    "creditBalance": 0.0, 
    "nextPaymentDate": null 
  }
  ```

### 3.3 Create Customer
- **Endpoint:** `POST /customers`
- **Body:** `{ "name": "...", "phone": "...", "email": "...", "address": "..." }`

---

## ⚠️ Developer Notes:
1. **Credit Logic:** When an order is placed with a "Credit" payment method, the `creditBalance` of that customer must increase by the order total.
2. **Date Format:** Use `YYYY-MM-DD` for all date fields.
3. **Response Structure:** All responses must be wrapped in `{ "success": true, "data": ... }`.

---
*Last updated: 2026-02-13 for Advanced Credit Tracking.*
