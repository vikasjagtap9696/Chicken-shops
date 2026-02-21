# Chicken Mart - Frontend Documentation (Flutter)

This documentation provides an overview of the 'Chicken Mart' application's frontend structure, core modules, and key features.

---

## 1. Project Overview
**Name:** Chicken Mart Billing System  
**Technology:** Flutter (Dart)  
**State Management:** Provider  
**Backend Connection:** REST API (Node.js)  
**IP Address Config:** `172.20.10.7` (Centralized in Service files)

---

## 2. Folder Structure (`lib/`)
- **`models/`**: Defines data structures used across the app.
- **`services/`**: Handles API calls and business logic (Auth & Database).
- **`screen/`**: Contains all UI screens.
- **`widgets/`**: Reusable UI components.

---

## 3. Core Modules & Files

### **A. Services (Business Logic)**
1. **`auth_service.dart`**:
   - Manages Login, Logout, and Profile updates.
   - **Offline Login:** Supports `admin@chickenshop.com` / `123456` as a backup if the server is unreachable.
   - Session persistence using `SharedPreferences`.
2. **`database_service.dart`**:
   - Manages all data operations for Orders, Stocks, Customers, and Staff.
   - **Auto Stock Reduce:** Automatically updates local and remote stock levels after a successful sale.

### **B. Key Screens (UI)**
1. **`login_screen.dart`**: Modern UI with a dedicated orange theme, including 'Forgot Password' functionality.
2. **`dashboard_screen.dart`**: The main hub displaying today's sales, total stock value, and shortcuts to all modules.
3. **`billing_screen.dart`**: 
   - Real-time customer search.
   - Product selection grid with category filters.
   - Manual weight (Kg) input support via numeric keypad.
   - 'Due Date' selection for credit transactions.
4. **`customer_screen.dart`**:
   - Customer list with pending payment indicators (Urgent customers shown at top).
   - **CRUD:** Functionality to Add, Edit, or Delete customers.
   - 'Pay' button to update remaining balances directly.
5. **`order_list_screen.dart`**: 
   - Comprehensive order history.
   - Advanced filters for Payment Mode (Cash/Online/Credit) and Specific Dates.
6. **`inventory_screen.dart`**: Inventory tracking with category-based filtering and low-stock alerts.

### **C. Models (Data Mapping)**
- `user_model.dart`: Maps user and shop profile information.
- `customer_model.dart`: Maps customer details, phone, and credit balances.
- `stock_model.dart`: Maps product names, prices, units, and categories.
- `sale_model.dart`: Maps invoice details and individual sale items.

---

## 4. Key Features
- **Modern Orange Theme:** Professional branding throughout the application.
- **Advanced Filters:** Powerful filtering logic for orders, customers, and inventory.
- **Persistent Sessions:** Users remain logged in even after closing the app.
- **Real-time Synchronization:** Automatic sync between backend and frontend for stock and balances.

---

## 5. Setup & Configuration
- **Server IP:** To change the backend IP, update the `serverIp` variable in `services/auth_service.dart` and `services/database_service.dart`.
- **Theme Color:** The primary color is defined as `0xFFE64A19` in `main.dart`.

---
**Documented by:** AI Assistant  
**Date:** May 2024
