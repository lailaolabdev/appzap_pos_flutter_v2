# Transaction Management System Documentation

## Overview

The Transaction Management System provides comprehensive functionality for handling all payment transactions within the POS system. It supports various payment methods, transaction types, and advanced features like split payments, voids, refunds, and detailed transaction tracking.

## Table of Contents

1. [Transaction Types](#transaction-types)
2. [Payment Methods](#payment-methods)
3. [Transaction Statuses](#transaction-statuses)
4. [API Endpoints](#api-endpoints)
5. [Data Models](#data-models)
6. [Transaction Flow](#transaction-flow)
7. [Advanced Features](#advanced-features)
8. [Error Handling](#error-handling)
9. [Security & Permissions](#security--permissions)
10. [Integration Examples](#integration-examples)

## Transaction Types

The system supports multiple transaction types to handle various business scenarios:

### Core Transaction Types
- **SALE** - Standard point-of-sale transaction
- **PAYMENT** - General payment processing
- **REFUND** - Full or partial refunds
- **VOID** - Transaction cancellation with proper audit trail
- **ADJUSTMENT** - Manual adjustments for corrections
- **TIP_ADJUSTMENT** - Post-transaction tip modifications

### Advanced Transaction Types
- **PARTIAL_PAYMENT** - Partial payments for orders
- **SPLIT_PAYMENT** - Multiple payment methods for single order
- **CONSOLIDATED_PAYMENT** - Combined payments for multiple orders
- **CASH_IN/CASH_OUT** - Cash drawer operations
- **PAYOUT** - Staff payouts or vendor payments
- **ONLINE_PAYMENT** - PhaJay online payment integration

## Payment Methods

The system supports a comprehensive range of payment methods:

### Traditional Methods
- **Cash** - Physical cash transactions with change calculation
- **Credit Card** - Credit card processing with detailed card info
- **Debit Card** - Debit card transactions
- **Check** - Check payments with validation

### Digital Payment Methods
- **Mobile Payment** - Mobile payment apps
- **Mobile Wallet** - Digital wallet services
- **Mobile Money** - Mobile money services
- **Bank Transfer** - Direct bank transfers
- **Digital Wallet** - Various digital wallet providers
- **Gift Card** - Gift card redemption
- **Loyalty Points** - Loyalty program point redemption
- **Voucher** - Discount vouchers and coupons

### Specialized Methods
- **Cryptocurrency** - Digital currency payments
- **Buy Now Pay Later** - BNPL services
- **Multiple** - Combined payment methods
- **Split Currency** - Multi-currency transactions

### PhaJay Bank QR Integration (Phase 1)
- **BANK_QR_JDB** - Joint Development Bank QR payments
- **BANK_QR_BCEL** - Banque pour le Commerce Extérieur Lao QR
- **BANK_QR_IB** - Indochina Bank QR payments
- **BANK_QR_LDB** - Lao Development Bank QR payments
- **PAYMENT_LINK** - Universal payment link with bank selection

## Transaction Statuses

Transaction lifecycle is managed through the following statuses:

- **PENDING** - Transaction initiated but not processed
- **PROCESSING** - Payment being processed
- **COMPLETED** - Successfully completed transaction
- **REFUNDED** - Full refund processed
- **PARTIALLY_REFUNDED** - Partial refund processed
- **VOIDED** - Transaction cancelled/voided
- **FAILED** - Transaction processing failed
- **CANCELLED** - Transaction cancelled by user/system

## API Endpoints

### Transaction Management

#### Create Transaction
```http
POST /v1/transactions
```
Creates a new transaction with payment processing.

**Request Body:**
```json
{
  "transactionType": "sale",
  "branchId": "507f1f77bcf86cd799439016",
  "orderReferences": [
    {
      "orderId": "507f1f77bcf86cd799439020",
      "pricing": {
        "grandTotal": { "amount": 25.50, "currency": "USD" }
      }
    }
  ],
  "payments": [
    {
      "method": "card",
      "customerAmount": { "amount": 25.50, "currency": "USD" },
      "cardDetails": {
        "last4": "1234",
        "brand": "visa",
        "cardType": "credit"
      }
    }
  ],
  "customer": {
    "name": "John Smith",
    "email": "john@example.com",
    "phone": "+1234567890"
  }
}
```

#### Get Transaction by ID
```http
GET /v1/transactions/{transactionId}
```
Retrieves detailed transaction information with optimized population. 
Supports both MongoDB ObjectId and business transaction ID formats.

**Parameters:**
- `transactionId` - MongoDB ObjectId (24 hex characters) or business transaction ID (e.g., TXN-dcb575bd-34bd-4adf-98ce-b35f50134edb)

**Examples:**
```http
# Using MongoDB ObjectId
GET /v1/transactions/507f1f77bcf86cd799439011

# Using business transaction ID  
GET /v1/transactions/TXN-dcb575bd-34bd-4adf-98ce-b35f50134edb
```

**Response:**
```json
{
  "_id": "507f1f77bcf86cd799439011",
  "transactionId": "TXN-20240115-001",
  "transactionType": "sale",
  "transactionStatus": "completed",
  "totals": {
    "totalLineItems": { "amount": 23.50, "currency": "USD" },
    "totalTaxes": { "amount": 2.00, "currency": "USD" },
    "grandTotal": { "amount": 25.50, "currency": "USD" }
  },
  "payments": [...],
  "orders": [...],
  "staff": {...},
  "timing": {...}
}
```

#### Get Transaction History
```http
GET /v1/transactions
```
Retrieves paginated transaction history with filtering options.

**Query Parameters:**
- `startDate` - Filter by start date (ISO format)
- `endDate` - Filter by end date (ISO format)
- `status` - Filter by transaction status
- `method` - Filter by payment method
- `branchId` - Filter by branch
- `staffId` - Filter by staff member
- `page` - Page number (default: 1)
- `limit` - Results per page (default: 20, max: 100)
- `includeSummary` - Include summary statistics (default: false)
- `timezone` - Timezone for date filtering

#### Void Transaction
```http
POST /v1/transactions/{transactionId}/void
```
Voids a transaction with proper authorization and audit trail.

**Request Body:**
```json
{
  "voidReason": "Customer cancellation",
  "managerApproval": {
    "managerId": "507f1f77bcf86cd799439013",
    "managerPin": "1234"
  },
  "notes": "Customer changed mind"
}
```

#### Get Transaction Summary
```http
GET /v1/transactions/summary
```
Provides aggregated transaction statistics and summaries.

**Query Parameters:**
- `startDate`, `endDate` - Date range
- `branchId` - Specific branch
- `groupBy` - Group results by (day, week, month, method, staff)

## Data Models

### Transaction Model Structure

```javascript
{
  // Basic Information
  transactionId: String,           // Unique transaction identifier
  transactionType: String,         // Type of transaction
  transactionStatus: String,       // Current status
  
  // Location & Context
  restaurantId: ObjectId,          // Restaurant reference
  branchId: ObjectId,              // Branch reference
  
  // Financial Information
  consolidatedTotals: {
    totalLineItems: { amount: Number, currency: String },
    totalDiscounts: { amount: Number, currency: String },
    totalTaxes: { amount: Number, currency: String },
    totalFees: { amount: Number, currency: String },
    totalTips: { amount: Number, currency: String },
    grandTotal: { amount: Number, currency: String },
    currency: String,
    calculatedAt: Date
  },
  
  // Payment Details
  payments: [{
    paymentId: String,
    method: String,
    status: String,
    customerAmount: { amount: Number, currency: String },
    tenderedAmount: { amount: Number, currency: String },
    changeGiven: { amount: Number, currency: String },
    grossAmount: { amount: Number, currency: String },
    netAmount: { amount: Number, currency: String },
    processingFees: { amount: Number, currency: String },
    
    // Method-specific details
    cashDetails: { drawerId: String },
    cardDetails: { 
      last4: String, 
      brand: String, 
      cardType: String,
      entryMethod: String,
      authCode: String
    },
    bankQrDetails: {
      bankCode: String,
      qrCodeId: String,
      referenceNumber: String
    },
    
    // Timing
    timing: {
      initiatedAt: Date,
      processedAt: Date,
      completedAt: Date
    }
  }],
  
  // Payment Summary
  paymentSummary: {
    totalPaid: { amount: Number, currency: String },
    totalRefunded: { amount: Number, currency: String },
    netAmount: { amount: Number, currency: String },
    paymentMethodBreakdown: [{
      method: String,
      amount: { amount: Number, currency: String },
      count: Number
    }]
  },
  
  // Order References
  orderReferences: [{
    orderId: ObjectId,
    pricing: {
      lineItemsTotal: { amount: Number, currency: String },
      discounts: [...],
      taxes: [...],
      fees: [...],
      tips: [...]
    }
  }],
  
  // Customer Information
  customer: {
    customerId: ObjectId,
    name: String,
    email: String,
    phone: String,
    loyaltyInfo: {
      memberId: String,
      pointsEarned: Number,
      pointsRedeemed: Number
    }
  },
  
  // Staff Information
  staff: {
    processedBy: ObjectId,
    cashier: ObjectId,
    authorizedBy: ObjectId
  },
  
  // Split Payment Details
  splitDetails: {
    isSplit: Boolean,
    splitType: String,
    splitReason: String,
    splitBy: Number,
    participants: [{
      participantId: String,
      amount: { amount: Number, currency: String },
      paymentMethod: String
    }]
  },
  
  // Void Information
  voidInfo: {
    isVoided: Boolean,
    voidedAt: Date,
    voidedBy: ObjectId,
    voidReason: String,
    originalStatus: String,
    managerApproval: {
      managerId: ObjectId,
      managerName: String,
      approvedAt: Date,
      approvalMethod: String
    }
  },
  
  // Device & Context
  deviceInfo: {
    deviceId: String,
    deviceType: String,
    appVersion: String,
    location: {
      coordinates: [Number, Number],
      address: String
    }
  },
  
  // Timing Information
  timing: {
    initiatedAt: Date,
    processedAt: Date,
    completedAt: Date,
    voidedAt: Date
  },
  
  // Additional Fields
  notes: String,
  tags: [String],
  countInTotals: Boolean,
  isTestTransaction: Boolean,
  
  // Audit Trail
  history: [{
    action: String,
    performedBy: ObjectId,
    performedAt: Date,
    changes: Object,
    notes: String
  }],
  
  // Timestamps
  createdAt: Date,
  updatedAt: Date
}
```

## Transaction Flow

### Standard Sale Transaction Flow

1. **Initiation**
   - Transaction created with `PENDING` status
   - Order references validated
   - Pricing calculations verified

2. **Payment Processing**
   - Payment method validated
   - Amount verification performed
   - External payment processing (if required)
   - Status updated to `PROCESSING`

3. **Completion**
   - Payment confirmed
   - Order status updated
   - Inventory adjustments applied
   - Status updated to `COMPLETED`
   - Receipt generation triggered

### Void Transaction Flow

1. **Void Request**
   - Manager authorization required
   - Void reason mandatory
   - Original transaction validation

2. **Processing**
   - Payment reversals initiated
   - Inventory adjustments reversed
   - Order status updated
   - Audit trail created

3. **Completion**
   - Status updated to `VOIDED`
   - Notification sent
   - Reports updated

## Advanced Features

### Split Payments

The system supports sophisticated split payment scenarios:

```javascript
{
  "splitDetails": {
    "isSplit": true,
    "splitType": "equal", // or "custom", "percentage"
    "splitReason": "group_dining",
    "splitBy": 3,
    "participants": [
      {
        "participantId": "participant-1",
        "amount": { "amount": 8.50, "currency": "USD" },
        "paymentMethod": "card"
      },
      {
        "participantId": "participant-2", 
        "amount": { "amount": 8.50, "currency": "USD" },
        "paymentMethod": "cash"
      },
      {
        "participantId": "participant-3",
        "amount": { "amount": 8.50, "currency": "USD" },
        "paymentMethod": "mobile_wallet"
      }
    ]
  }
}
```

### Multi-Currency Support

Transactions can handle multiple currencies with automatic conversion:

```javascript
{
  "payments": [{
    "method": "cash",
    "customerAmount": { "amount": 25.50, "currency": "USD" },
    "tenderedAmount": { "amount": 30.00, "currency": "USD" },
    "changeGiven": { "amount": 4.50, "currency": "USD" }
  }],
  "consolidatedTotals": {
    "grandTotal": { "amount": 25.50, "currency": "USD" },
    "exchangeRate": 1.0,
    "baseCurrency": "USD"
  }
}
```

### PhaJay Integration

The system integrates with PhaJay for online payments and bank QR codes:

```javascript
{
  "payment": {
    "method": "payment_link",
    "bankQrDetails": {
      "bankCode": "JDB",
      "qrCodeId": "QR123456789",
      "referenceNumber": "REF-PJ-001",
      "paymentLinkUrl": "https://phajay.com/pay/QR123456789"
    }
  }
}
```

### Transaction Caching

High-performance caching system for real-time transaction processing:

- **Redis Integration** - Fast transaction lookup and temporary storage
- **Cache Invalidation** - Automatic cache updates on transaction changes
- **Performance Optimization** - Reduced database queries for frequent operations

## Error Handling

### Common Error Scenarios

#### Validation Errors
```json
{
  "status": 400,
  "error": "BAD_REQUEST",
  "message": "Validation failed",
  "details": {
    "field": "payments.customerAmount",
    "reason": "Amount must be greater than 0",
    "code": "INVALID_AMOUNT"
  }
}
```

#### Payment Processing Errors
```json
{
  "status": 402,
  "error": "PAYMENT_REQUIRED",
  "message": "Payment processing failed",
  "details": {
    "paymentMethod": "card",
    "reason": "Insufficient funds",
    "code": "PAYMENT_DECLINED",
    "retryable": false
  }
}
```

#### Authorization Errors
```json
{
  "status": 401,
  "error": "UNAUTHORIZED",
  "message": "Manager authorization required for void operation",
  "details": {
    "requiredPermission": "VOID_TRANSACTIONS",
    "currentRole": "cashier"
  }
}
```

### Error Recovery

The system implements comprehensive error recovery mechanisms:

1. **Transaction Rollback** - Automatic rollback on failures
2. **Retry Logic** - Configurable retry for transient failures
3. **Manual Intervention** - Manager override capabilities
4. **Audit Logging** - Complete error tracking and audit trails

## Security & Permissions

### Required Permissions

- **VIEW_TRANSACTIONS** - View transaction history and details
- **MANAGE_TRANSACTIONS** - Create and modify transactions
- **VOID_TRANSACTIONS** - Void transactions (requires manager approval)
- **REFUND_TRANSACTIONS** - Process refunds
- **VIEW_TRANSACTION_REPORTS** - Access transaction reports and analytics

### Data Security

- **PCI Compliance** - Card data handled according to PCI DSS standards
- **Encryption** - All sensitive data encrypted at rest and in transit
- **Access Logging** - All transaction access logged for audit
- **Role-Based Access** - Granular permission system
- **PIN Verification** - Manager PIN required for sensitive operations

### Audit Trail

Every transaction maintains a complete audit trail:

```javascript
{
  "history": [
    {
      "action": "CREATED",
      "performedBy": "507f1f77bcf86cd799439012",
      "performedAt": "2024-01-15T10:25:00.000Z",
      "changes": { "status": "pending" },
      "notes": "Transaction initiated"
    },
    {
      "action": "PAYMENT_PROCESSED",
      "performedBy": "507f1f77bcf86cd799439012", 
      "performedAt": "2024-01-15T10:25:30.000Z",
      "changes": { "status": "completed" },
      "notes": "Card payment processed successfully"
    }
  ]
}
```

## Integration Examples

### Frontend Transaction Processing

```javascript
// Create a new transaction
const createTransaction = async (orderData, paymentData) => {
  try {
    const response = await fetch('/v1/transactions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        transactionType: 'sale',
        branchId: branchId,
        orderReferences: [{
          orderId: orderData.orderId,
          pricing: orderData.pricing
        }],
        payments: [paymentData],
        customer: orderData.customer,
        deviceInfo: {
          deviceId: deviceId,
          deviceType: 'tablet',
          appVersion: '1.0.0'
        }
      })
    });
    
    const transaction = await response.json();
    
    if (transaction.transactionStatus === 'completed') {
      // Handle successful transaction
      showSuccessMessage('Payment processed successfully');
      printReceipt(transaction);
    } else {
      // Handle pending/processing status
      pollTransactionStatus(transaction._id);
    }
  } catch (error) {
    handleTransactionError(error);
  }
};
```

### Mobile App Integration

```javascript
// Mobile payment processing with PhaJay
const processMobilePayment = async (amount, bankCode) => {
  const paymentData = {
    method: `bank_qr_${bankCode.toLowerCase()}`,
    customerAmount: { amount, currency: 'USD' },
    bankQrDetails: {
      bankCode: bankCode,
      returnUrl: 'app://payment-return'
    }
  };
  
  const transaction = await createTransaction(orderData, paymentData);
  
  if (transaction.payments[0].bankQrDetails?.paymentLinkUrl) {
    // Open payment URL in external browser
    openExternalUrl(transaction.payments[0].bankQrDetails.paymentLinkUrl);
  }
};
```

### Webhook Integration

```javascript
// Handle PhaJay payment webhooks
app.post('/webhooks/phajay-payment', (req, res) => {
  const { transactionId, status, referenceNumber } = req.body;
  
  // Verify webhook signature
  if (!verifyPhaJaySignature(req)) {
    return res.status(401).send('Unauthorized');
  }
  
  // Update transaction status
  updateTransactionStatus(transactionId, status, {
    externalReference: referenceNumber,
    updatedAt: new Date()
  });
  
  res.status(200).send('OK');
});
```

### Analytics Integration

```javascript
// Get transaction analytics
const getTransactionAnalytics = async (dateRange, filters) => {
  const params = new URLSearchParams({
    startDate: dateRange.start,
    endDate: dateRange.end,
    includeSummary: true,
    groupBy: 'day',
    ...filters
  });
  
  const response = await fetch(`/v1/transactions/summary?${params}`);
  const analytics = await response.json();
  
  return {
    totalRevenue: analytics.summary.totalRevenue,
    transactionCount: analytics.summary.transactionCount,
    averageTransaction: analytics.summary.averageTransaction,
    paymentMethodBreakdown: analytics.summary.paymentMethodBreakdown,
    dailyTrends: analytics.groupedData
  };
};
```

## Best Practices

### Performance Optimization

1. **Pagination** - Always use pagination for transaction lists
2. **Field Selection** - Only request necessary fields
3. **Caching** - Leverage Redis caching for frequent queries
4. **Indexing** - Ensure proper database indexes on query fields

### Error Handling

1. **Graceful Degradation** - Handle payment processor outages
2. **Retry Logic** - Implement exponential backoff for retries
3. **User Communication** - Provide clear error messages
4. **Fallback Options** - Alternative payment methods on failures

### Security

1. **Token Validation** - Always validate authentication tokens
2. **Permission Checks** - Verify permissions before operations
3. **Input Sanitization** - Sanitize all input data
4. **Audit Logging** - Log all sensitive operations

### Testing

1. **Unit Tests** - Test individual transaction components
2. **Integration Tests** - Test payment processor integrations
3. **Load Testing** - Test system under high transaction volumes
4. **Security Testing** - Regular security assessments

## Conclusion

The Transaction Management System provides a robust, secure, and scalable solution for handling all payment transactions in the POS system. With support for multiple payment methods, advanced features like split payments and voids, and comprehensive audit trails, it meets the needs of modern restaurant operations while maintaining the highest standards of security and reliability.

For additional support or questions, please refer to the API documentation or contact the development team.