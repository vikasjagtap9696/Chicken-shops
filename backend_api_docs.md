# Chicken Mart - Backend API Documentation

ही फाईल बॅकएंड डेव्हलपरला शेअर करा, जेणेकरून त्यांना मोबाईल ॲपमधून काय डेटा येणार आहे आणि त्यांना काय रिस्पॉन्स द्यायचा आहे हे समजेल.

---

## 1. Create New Order (Sale)
**Endpoint:** `POST /api/orders`  
**Description:** जेव्हा युजर 'Confirm Order' बटण दाबतो, तेव्हा हा डेटा बॅकएंडला पाठवला जातो.

**Request Body (JSON):**
```json
{
  "customerId": "string (optional/nullable)", 
  "items": [
    {
      "productId": 101, 
      "quantity": 1.5   
    }
  ],
  "paymentMethod": "cash", // cash, online, credit
  "amountPaid": 500.0,     // ग्राहकाने दिलेली प्रत्यक्ष रक्कम
  "totalAmount": 1250.0    // बिलाची एकूण रक्कम
}
```

### **Payment Calculation Logic (बॅकएंड डेव्हलपरसाठी):**
ऑर्डर सेव्ह करताना बॅकएंडने खालील हिशोब (Calculation) करणे आवश्यक आहे:

1. **Remaining Balance (बाकी रक्कम):**
   `remainingBalance = totalAmount - amountPaid`
   
2. **Customer Ledger Update:**
   - जर `customerId` उपलब्ध असेल आणि `remainingBalance > 0` असेल, तर ही रक्कम त्या ग्राहकाच्या खात्यात (Balance) **थकबाकी (Credit)** म्हणून जोडावी.
   - जर `amountPaid > totalAmount` असेल, तर उरलेली रक्कम ग्राहकाचे **Advance** म्हणून जमा करावी.

3. **Order Status:**
   - जर `amountPaid == totalAmount` असेल, तर ऑर्डर स्टेटस `Paid` असावा.
   - जर `amountPaid < totalAmount` असेल, तर ऑर्डर स्टेटस `Partial` किंवा `Unpaid` असावा.

---

## 2. Product / Stock Model
**Endpoint:** `GET /api/stock/summary`  
**Description:** बिलिंग आणि इन्व्हेंटरी स्क्रीनवर उत्पादने दाखवण्यासाठी बॅकएंडने असा डेटा द्यावा.

**Expected Response (JSON):**
```json
{
  "data": [
    {
      "id": "101",
      "name": "Fresh Chicken",
      "category": "chicken",
      "unit": "kg",
      "price": 240.0,
      "stock": 50.0
    }
  ]
}
```

**Stock Update Logic:**
- ऑर्डर यशस्वीरित्या सेव्ह झाल्यावर, बॅकएंडने `items` लिस्ट मधील प्रत्येक `productId` चा `stock` वजा (`currentStock - quantity`) करणे अनिवार्य आहे.

---

## 3. Customer Management
**Endpoints:**
- `GET /api/customers` : ग्राहकांची यादी आणि त्यांची एकूण थकबाकी (`totalBalance`).
- `POST /api/customers` : नवीन ग्राहक नोंदणी.
- `PUT /api/customers/:id` : ग्राहकाची माहिती किंवा पेमेंट अपडेट करणे.

---

## 4. Payment Modes
ॲप सध्या खालील पेमेंट मोड्स सपोर्ट करते:
- `cash`
- `online`
- `credit` (पूर्णपणे उधारीवर माल देताना)

---
**सूचना:** मोबाईल ॲप आता `amountPaid` आणि `totalAmount` दोन्ही पाठवत आहे, जेणेकरून बॅकएंडला हिशोब करणे सोपे जाईल.
