require('dotenv').config();
const http = require('http');
const bcrypt = require('bcryptjs');
const app = require('../src/app');
const { prisma } = require('../src/common/config/prisma');

const PORT = 4568;
const BASE_URL = `http://localhost:${PORT}`;

async function main() {
  console.log('--- START ORDER STATUS & HISTORY LOG INTEGRATION TEST ---');
  
  // 1. Setup DB test data
  console.log('1. Setting up test database records...');
  
  const testAdminEmail = 'admin_test_order@example.com';
  const testCustomerEmail = 'customer_test_order@example.com';
  const passwordHash = await bcrypt.hash('Password123', 10);
  
  // Clean up stale test data
  await prisma.order_status_logs.deleteMany({});
  await prisma.orderItem.deleteMany({});
  await prisma.order.deleteMany({});
  await prisma.cartItem.deleteMany({});
  await prisma.product.deleteMany({ where: { name: { startsWith: 'Test Order Product' } } });
  await prisma.category.deleteMany({ where: { name: 'Test Category Order' } });
  await prisma.user.deleteMany({ where: { email: { in: [testAdminEmail, testCustomerEmail] } } });
  
  // Create admin
  const admin = await prisma.user.create({
    data: {
      fullName: 'Test Admin',
      email: testAdminEmail,
      password: passwordHash,
      role: 'ADMIN'
    }
  });
  
  // Create customer
  const customer = await prisma.user.create({
    data: {
      fullName: 'Test Customer',
      email: testCustomerEmail,
      password: passwordHash,
      role: 'USER'
    }
  });

  // Create category
  const category = await prisma.category.create({
    data: { name: 'Test Category Order' }
  });

  // Create product with stock = 10
  const product = await prisma.product.create({
    data: {
      categoryId: category.id,
      name: 'Test Order Product',
      description: 'Test product for order stock checks',
      price: 100.00,
      stock: 10,
      imageUrl: 'http://example.com/order.jpg'
    }
  });

  console.log(`Setup complete. Product: ${product.name}, Stock: ${product.stock}`);

  // 2. Start the Express App
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(PORT, resolve));
  console.log(`Express server listening on port ${PORT}`);

  try {
    // 3. Login and get tokens
    console.log('\n2. Logging in...');
    const adminToken = await getLoginToken(testAdminEmail, 'Password123');
    const customerToken = await getLoginToken(testCustomerEmail, 'Password123');
    
    // 4. Test Order Creation & Initial Log
    console.log('\n3. Creating order as customer...');
    
    // Create cart item for customer (quantity = 3)
    await prisma.cartItem.create({
      data: {
        userId: customer.id,
        productId: product.id,
        quantity: 3
      }
    });

    // POST /orders
    let res = await fetchJson(`${BASE_URL}/orders`, {
      method: 'POST',
      token: customerToken,
      body: {
        address: '123 Test St, BigCity',
        paymentMethod: 'COD'
      }
    });

    if (res.status !== 201) {
      console.error('Order creation failed:', res.data);
      throw new Error(`Order creation failed. Status: ${res.status}`);
    }

    const createdOrder = res.data.data;
    console.log(`Order created successfully: ${createdOrder.id}`);
    
    // Verify product stock is decremented
    let checkProduct = await prisma.product.findUnique({ where: { id: product.id } });
    console.log(`Stock after order: ${checkProduct.stock} (Expected: 7)`);
    if (checkProduct.stock !== 7) throw new Error('Stock decrement mismatch!');

    // Verify order status log contains PENDING
    let logs = await prisma.order_status_logs.findMany({
      where: { order_id: createdOrder.id },
      orderBy: { created_at: 'asc' }
    });
    console.log(`Initial log count: ${logs.length} (Expected: 1)`);
    console.log(`Initial log details: From ${logs[0].from_status} -> To ${logs[0].to_status}`);
    if (logs[0].to_status !== 'PENDING') throw new Error('Initial status log is not PENDING');

    // 5. Test Access Control on Update Status
    console.log('\n4. Testing update status permissions...');
    
    // 5a. Without token -> 401
    res = await fetchJson(`${BASE_URL}/orders/${createdOrder.id}/status`, {
      method: 'PATCH',
      body: { status: 'CONFIRMED' }
    });
    console.log(`PATCH without token: ${res.status} (Expected: 401)`);
    if (res.status !== 401) throw new Error('Should deny guest');

    // 5b. With customer token -> 403
    res = await fetchJson(`${BASE_URL}/orders/${createdOrder.id}/status`, {
      method: 'PATCH',
      token: customerToken,
      body: { status: 'CONFIRMED' }
    });
    console.log(`PATCH with customer token: ${res.status} (Expected: 403)`);
    if (res.status !== 403) throw new Error('Should deny customer role');

    // 6. Test Valid Status Path (PENDING -> CONFIRMED -> SHIPPING -> DELIVERED)
    console.log('\n5. Testing valid status transitions (PENDING -> CONFIRMED -> SHIPPING -> DELIVERED)...');
    
    // PENDING -> CONFIRMED
    res = await fetchJson(`${BASE_URL}/orders/${createdOrder.id}/status`, {
      method: 'PATCH',
      token: adminToken,
      body: { status: 'CONFIRMED' }
    });
    console.log(`Transition to CONFIRMED: ${res.status} (Expected: 200)`);
    if (res.status !== 200) throw new Error('Failed transition to CONFIRMED');
    
    // CONFIRMED -> SHIPPING
    res = await fetchJson(`${BASE_URL}/orders/${createdOrder.id}/status`, {
      method: 'PATCH',
      token: adminToken,
      body: { status: 'SHIPPING' }
    });
    console.log(`Transition to SHIPPING: ${res.status} (Expected: 200)`);
    if (res.status !== 200) throw new Error('Failed transition to SHIPPING');

    // SHIPPING -> DELIVERED
    res = await fetchJson(`${BASE_URL}/orders/${createdOrder.id}/status`, {
      method: 'PATCH',
      token: adminToken,
      body: { status: 'DELIVERED' }
    });
    console.log(`Transition to DELIVERED: ${res.status} (Expected: 200)`);
    if (res.status !== 200) throw new Error('Failed transition to DELIVERED');

    // Verify all logs exist
    logs = await prisma.order_status_logs.findMany({
      where: { order_id: createdOrder.id },
      orderBy: { created_at: 'asc' }
    });
    console.log(`Final log count: ${logs.length} (Expected: 4)`);
    logs.forEach((log, idx) => {
      console.log(`Log ${idx + 1}: ${log.from_status || 'NULL'} -> ${log.to_status} (${log.note})`);
    });
    if (logs.length !== 4) throw new Error('Logs count mismatch');

    // 7. Test Transition Violations
    console.log('\n6. Testing state transition violations...');
    
    // Try to update from DELIVERED -> SHIPPING (Not allowed)
    res = await fetchJson(`${BASE_URL}/orders/${createdOrder.id}/status`, {
      method: 'PATCH',
      token: adminToken,
      body: { status: 'SHIPPING' }
    });
    console.log(`DELIVERED -> SHIPPING transition status: ${res.status} (Expected: 400)`);
    if (res.status !== 400) throw new Error('Should not allow transition back to SHIPPING');

    // Try to update from DELIVERED -> CANCELLED (Not allowed)
    res = await fetchJson(`${BASE_URL}/orders/${createdOrder.id}/status`, {
      method: 'PATCH',
      token: adminToken,
      body: { status: 'CANCELLED' }
    });
    console.log(`DELIVERED -> CANCELLED transition status: ${res.status} (Expected: 400)`);
    if (res.status !== 400) throw new Error('Should not allow transition to CANCELLED from DELIVERED');

    // 8. Test Cancellation & Stock Recovery
    console.log('\n7. Testing cancellation and stock recovery...');
    
    // Create cart item for second order (quantity = 4)
    await prisma.cartItem.create({
      data: {
        userId: customer.id,
        productId: product.id,
        quantity: 4
      }
    });

    // POST /orders
    res = await fetchJson(`${BASE_URL}/orders`, {
      method: 'POST',
      token: customerToken,
      body: {
        address: '456 Test Blvd, BigCity',
        paymentMethod: 'COD'
      }
    });
    
    const secondOrder = res.data.data;
    console.log(`Second order created: ${secondOrder.id}`);
    
    // Check stock decremented to 3 (7 - 4 = 3)
    checkProduct = await prisma.product.findUnique({ where: { id: product.id } });
    console.log(`Stock after second order: ${checkProduct.stock} (Expected: 3)`);
    if (checkProduct.stock !== 3) throw new Error('Second order stock decrement mismatch');

    // Cancel order via admin patch to status CANCELLED
    res = await fetchJson(`${BASE_URL}/orders/${secondOrder.id}/status`, {
      method: 'PATCH',
      token: adminToken,
      body: { status: 'CANCELLED' }
    });
    console.log(`Admin cancels second order status: ${res.status} (Expected: 200)`);
    if (res.status !== 200) throw new Error('Failed to cancel order');

    // Verify stock is restored to 7 (3 + 4 = 7)
    checkProduct = await prisma.product.findUnique({ where: { id: product.id } });
    console.log(`Stock after cancellation: ${checkProduct.stock} (Expected: 7)`);
    if (checkProduct.stock !== 7) throw new Error('Stock recovery failed');

    // Verify status logs for second order has PENDING and CANCELLED
    logs = await prisma.order_status_logs.findMany({
      where: { order_id: secondOrder.id },
      orderBy: { created_at: 'asc' }
    });
    console.log(`Second order logs count: ${logs.length} (Expected: 2)`);
    console.log(`Log 1: ${logs[0].from_status || 'NULL'} -> ${logs[0].to_status}`);
    console.log(`Log 2: ${logs[1].from_status} -> ${logs[1].to_status} (${logs[1].note})`);
    if (logs[1].to_status !== 'CANCELLED') throw new Error('Cancellation log is not CANCELLED');

    console.log('\n--- ALL TESTS PASSED SUCCESSFULLY! ---');

  } finally {
    // 9. Cleanup DB test data
    console.log('\n8. Cleaning up test database records...');
    await prisma.order_status_logs.deleteMany({});
    await prisma.orderItem.deleteMany({});
    await prisma.order.deleteMany({});
    await prisma.cartItem.deleteMany({});
    await prisma.product.deleteMany({ where: { name: { startsWith: 'Test Order Product' } } });
    await prisma.category.deleteMany({ where: { name: 'Test Category Order' } });
    await prisma.user.deleteMany({ where: { email: { in: [testAdminEmail, testCustomerEmail] } } });
    console.log('Cleanup complete.');

    // Stop server
    await new Promise((resolve) => server.close(resolve));
    console.log('Server stopped.');
  }
}

async function getLoginToken(email, password) {
  const res = await fetchJson(`${BASE_URL}/auth/login`, {
    method: 'POST',
    body: { email, password }
  });
  if (res.status !== 200) {
    throw new Error(`Login failed for ${email}: ${JSON.stringify(res.data)}`);
  }
  return res.data.data.token;
}

async function fetchJson(url, options = {}) {
  const headers = {
    'Content-Type': 'application/json'
  };
  if (options.token) {
    headers['Authorization'] = `Bearer ${options.token}`;
  }
  
  const fetchOptions = {
    method: options.method || 'GET',
    headers
  };
  if (options.body) {
    fetchOptions.body = JSON.stringify(options.body);
  }
  
  const res = await fetch(url, fetchOptions);
  let data = null;
  try {
    data = await res.json();
  } catch (err) {
    // Non-JSON response
  }
  
  return {
    status: res.status,
    data
  };
}

main().catch((err) => {
  console.error('Integration test failed with error:', err);
  process.exit(1);
});
