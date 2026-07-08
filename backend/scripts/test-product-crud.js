require('dotenv').config();
const http = require('http');
const bcrypt = require('bcryptjs');
const app = require('../src/app');
const { prisma } = require('../src/common/config/prisma');

const PORT = 4567;
const BASE_URL = `http://localhost:${PORT}`;

async function main() {
  console.log('--- START PRODUCT CRUD & RBAC INTEGRATION TEST ---');
  
  // 1. Setup DB test data
  console.log('1. Setting up test database records...');
  
  const testAdminEmail = 'admin_test@example.com';
  const testCustomerEmail = 'customer_test@example.com';
  const passwordHash = await bcrypt.hash('Password123', 10);
  
  // Clean up any stale test records from previous run
  await prisma.product.deleteMany({ where: { name: { startsWith: 'Test Product' } } });
  await prisma.category.deleteMany({ where: { name: 'Test Category' } });
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
  console.log(`Created test admin: ${admin.email}`);

  // Create customer
  const customer = await prisma.user.create({
    data: {
      fullName: 'Test Customer',
      email: testCustomerEmail,
      password: passwordHash,
      role: 'USER'
    }
  });
  console.log(`Created test customer: ${customer.email}`);

  // Create category
  const category = await prisma.category.create({
    data: {
      name: 'Test Category'
    }
  });
  console.log(`Created test category: ${category.name} (${category.id})`);

  // 2. Start the Express App
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(PORT, resolve));
  console.log(`Express server listening on port ${PORT}`);

  try {
    // 3. Login and get tokens
    console.log('\n2. Logging in...');
    const adminToken = await getLoginToken(testAdminEmail, 'Password123');
    const customerToken = await getLoginToken(testCustomerEmail, 'Password123');
    
    console.log('Admin Token acquired:', adminToken ? 'YES' : 'NO');
    console.log('Customer Token acquired:', customerToken ? 'YES' : 'NO');

    // 4. Test POST /products (Create)
    console.log('\n3. Testing POST /products (Create Product)...');
    
    const productPayload = {
      categoryId: category.id,
      name: 'Test Product 1',
      description: 'A great product for testing',
      price: 199.99,
      stock: 50,
      imageUrl: 'http://example.com/main.jpg',
      images: [
        { image_url: 'http://example.com/thumb1.jpg', is_thumbnail: true },
        { image_url: 'http://example.com/thumb2.jpg', is_thumbnail: false }
      ],
      variants: [
        { variant_name: 'Size XL', sku: 'TEST-PROD1-XL', price: 199.99, stock: 25 },
        { variant_name: 'Size XXL', sku: 'TEST-PROD1-XXL', price: 219.99, stock: 25 }
      ]
    };

    // 4a. Without token
    let res = await fetchJson(`${BASE_URL}/products`, {
      method: 'POST',
      body: productPayload
    });
    console.log('POST without token status:', res.status, '(Expected: 401)');
    
    // 4b. With customer token
    res = await fetchJson(`${BASE_URL}/products`, {
      method: 'POST',
      token: customerToken,
      body: productPayload
    });
    console.log('POST with customer token status:', res.status, '(Expected: 403)');

    // 4c. With admin token
    res = await fetchJson(`${BASE_URL}/products`, {
      method: 'POST',
      token: adminToken,
      body: productPayload
    });
    console.log('POST with admin token status:', res.status, '(Expected: 201)');
    
    if (res.status !== 201) {
      console.error('Error payload:', res.data);
      throw new Error(`Failed to create product. Status: ${res.status}`);
    }

    const createdProduct = res.data.data;
    console.log(`Created product ID: ${createdProduct.id}`);
    console.log(`Images count: ${createdProduct.product_images?.length}`);
    console.log(`Variants count: ${createdProduct.product_variants?.length}`);

    // 5. Test PUT /products/:id (Update)
    console.log('\n4. Testing PUT /products/:id (Update Product)...');
    
    const updatePayload = {
      name: 'Test Product 1 Updated',
      price: 249.99,
      // Let's see if update payload handles updated images and variants
      images: [
        { image_url: 'http://example.com/thumb1-updated.jpg', is_thumbnail: true }
      ],
      variants: [
        { variant_name: 'Size XL Updated', sku: 'TEST-PROD1-XL', price: 249.99, stock: 30 }
      ]
    };

    // 5a. Without token
    res = await fetchJson(`${BASE_URL}/products/${createdProduct.id}`, {
      method: 'PUT',
      body: updatePayload
    });
    console.log('PUT without token status:', res.status, '(Expected: 401)');

    // 5b. With customer token
    res = await fetchJson(`${BASE_URL}/products/${createdProduct.id}`, {
      method: 'PUT',
      token: customerToken,
      body: updatePayload
    });
    console.log('PUT with customer token status:', res.status, '(Expected: 403)');

    // 5c. With admin token
    res = await fetchJson(`${BASE_URL}/products/${createdProduct.id}`, {
      method: 'PUT',
      token: adminToken,
      body: updatePayload
    });
    console.log('PUT with admin token status:', res.status, '(Expected: 200)');
    
    if (res.status !== 200) {
      console.error('Error payload:', res.data);
      throw new Error(`Failed to update product. Status: ${res.status}`);
    }
    
    const updatedProduct = res.data.data;
    console.log(`Updated product price: ${updatedProduct.price} (Expected: 249.99)`);
    console.log(`Updated product images count: ${updatedProduct.product_images?.length} (Expected: 1)`);
    console.log(`Updated product variants count: ${updatedProduct.product_variants?.length} (Expected: 1)`);
    console.log('Updated product images details:', updatedProduct.product_images);
    console.log('Updated product variants details:', updatedProduct.product_variants);

    // 6. Test DELETE /products/:id (Delete)
    console.log('\n5. Testing DELETE /products/:id (Delete Product)...');
    
    // 6a. Without token
    res = await fetchJson(`${BASE_URL}/products/${createdProduct.id}`, {
      method: 'DELETE'
    });
    console.log('DELETE without token status:', res.status, '(Expected: 401)');

    // 6b. With customer token
    res = await fetchJson(`${BASE_URL}/products/${createdProduct.id}`, {
      method: 'DELETE',
      token: customerToken
    });
    console.log('DELETE with customer token status:', res.status, '(Expected: 403)');

    // 6c. With admin token
    res = await fetchJson(`${BASE_URL}/products/${createdProduct.id}`, {
      method: 'DELETE',
      token: adminToken
    });
    console.log('DELETE with admin token status:', res.status, '(Expected: 200)');

    if (res.status !== 200) {
      console.error('Error payload:', res.data);
      throw new Error(`Failed to delete product. Status: ${res.status}`);
    }

    // Verify product is gone
    const checkProduct = await prisma.product.findUnique({
      where: { id: createdProduct.id }
    });
    console.log('Product exists in DB after delete:', checkProduct ? 'YES' : 'NO', '(Expected: NO)');

  } finally {
    // 7. Cleanup DB test data
    console.log('\n6. Cleaning up test data from DB...');
    await prisma.product.deleteMany({ where: { name: { startsWith: 'Test Product' } } });
    await prisma.category.deleteMany({ where: { name: 'Test Category' } });
    await prisma.user.deleteMany({ where: { email: { in: [testAdminEmail, testCustomerEmail] } } });
    console.log('Cleanup finished.');

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
