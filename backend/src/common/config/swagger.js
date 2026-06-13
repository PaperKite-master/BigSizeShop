const swaggerSpec = {
  openapi: '3.0.3',
  info: {
    title: 'BigSize Shop API',
    version: '1.0.0',
    description: 'REST API for the BigSize Shop e-commerce platform.',
  },
  servers: [
    {
      url: '/',
      description: 'Current server',
    },
  ],
  tags: [
    { name: 'Health', description: 'Service health checks' },
    { name: 'Auth', description: 'Authentication and registration' },
    { name: 'Categories', description: 'Product category management' },
    { name: 'Products', description: 'Product catalog management' },
  ],
  paths: {
    '/health': {
      get: {
        tags: ['Health'],
        summary: 'Health check',
        responses: {
          200: {
            description: 'Service is running',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    status: { type: 'string', example: 'ok' },
                  },
                },
              },
            },
          },
        },
      },
    },
    '/auth/register': {
      post: {
        tags: ['Auth'],
        summary: 'Register a new user',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/RegisterRequest' },
            },
          },
        },
        responses: {
          201: {
            description: 'User registered successfully',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/RegisterResponse' },
              },
            },
          },
          400: {
            description: 'Missing required fields',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/ErrorResponse' },
              },
            },
          },
          409: {
            description: 'Email already exists',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/ErrorResponse' },
              },
            },
          },
        },
      },
    },
  },
  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'JWT access token',
      },
    },
    schemas: {
      ErrorResponse: {
        type: 'object',
        properties: {
          message: { type: 'string' },
        },
      },
      RegisterRequest: {
        type: 'object',
        required: ['fullName', 'email', 'password'],
        properties: {
          fullName: { type: 'string', maxLength: 100, example: 'Nguyen Van A' },
          email: { type: 'string', format: 'email', maxLength: 255, example: 'user@example.com' },
          password: { type: 'string', format: 'password', minLength: 6, example: 'secret123' },
          phone: { type: 'string', maxLength: 20, example: '0901234567' },
        },
      },
      RegisterResponse: {
        type: 'object',
        properties: {
          message: { type: 'string', example: 'Registered successfully' },
          data: { $ref: '#/components/schemas/User' },
        },
      },
      User: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          fullName: { type: 'string' },
          email: { type: 'string', format: 'email' },
          phone: { type: 'string', nullable: true },
          avatar: { type: 'string', nullable: true },
          role: { type: 'string', enum: ['USER', 'ADMIN'], default: 'USER' },
          createdAt: { type: 'string', format: 'date-time', nullable: true },
          updated_at: { type: 'string', format: 'date-time', nullable: true },
        },
      },
      Category: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          name: { type: 'string', maxLength: 100 },
          createdAt: { type: 'string', format: 'date-time', nullable: true },
          updated_at: { type: 'string', format: 'date-time', nullable: true },
        },
      },
      Product: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          categoryId: { type: 'string', format: 'uuid', nullable: true },
          name: { type: 'string', maxLength: 255 },
          description: { type: 'string', nullable: true },
          price: { type: 'number', format: 'decimal' },
          stock: { type: 'integer', default: 0 },
          imageUrl: { type: 'string', nullable: true },
          is_active: { type: 'boolean', default: true },
          createdAt: { type: 'string', format: 'date-time', nullable: true },
          updated_at: { type: 'string', format: 'date-time', nullable: true },
        },
      },
      CartItem: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          userId: { type: 'string', format: 'uuid' },
          productId: { type: 'string', format: 'uuid' },
          quantity: { type: 'integer', default: 1 },
          variant_id: { type: 'string', format: 'uuid', nullable: true },
          created_at: { type: 'string', format: 'date-time', nullable: true },
        },
      },
      Order: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          userId: { type: 'string', format: 'uuid' },
          totalPrice: { type: 'number', format: 'decimal' },
          status: { type: 'string', default: 'PENDING' },
          address: { type: 'string' },
          paymentMethod: { type: 'string', nullable: true },
          createdAt: { type: 'string', format: 'date-time', nullable: true },
          updated_at: { type: 'string', format: 'date-time', nullable: true },
        },
      },
      OrderItem: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          orderId: { type: 'string', format: 'uuid' },
          productId: { type: 'string', format: 'uuid' },
          quantity: { type: 'integer' },
          price: { type: 'number', format: 'decimal' },
          variant_id: { type: 'string', format: 'uuid', nullable: true },
        },
      },
      Address: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          user_id: { type: 'string', format: 'uuid' },
          receiver_name: { type: 'string', maxLength: 100 },
          receiver_phone: { type: 'string', maxLength: 20 },
          province: { type: 'string', nullable: true },
          district: { type: 'string', nullable: true },
          ward: { type: 'string', nullable: true },
          street_address: { type: 'string' },
          is_default: { type: 'boolean', default: false },
          created_at: { type: 'string', format: 'date-time', nullable: true },
          updated_at: { type: 'string', format: 'date-time', nullable: true },
        },
      },
      ProductVariant: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          product_id: { type: 'string', format: 'uuid' },
          variant_name: { type: 'string', maxLength: 100 },
          sku: { type: 'string', nullable: true },
          price: { type: 'number', format: 'decimal', nullable: true },
          stock: { type: 'integer', default: 0 },
          image_url: { type: 'string', nullable: true },
          created_at: { type: 'string', format: 'date-time', nullable: true },
          updated_at: { type: 'string', format: 'date-time', nullable: true },
        },
      },
      Voucher: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          code: { type: 'string', maxLength: 50 },
          title: { type: 'string', maxLength: 255 },
          description: { type: 'string', nullable: true },
          discount_type: { type: 'string' },
          discount_value: { type: 'number', format: 'decimal' },
          minimum_order_amount: { type: 'number', format: 'decimal', nullable: true },
          maximum_discount: { type: 'number', format: 'decimal', nullable: true },
          quantity: { type: 'integer', default: 0 },
          start_date: { type: 'string', format: 'date-time', nullable: true },
          end_date: { type: 'string', format: 'date-time', nullable: true },
          is_active: { type: 'boolean', default: true },
          created_at: { type: 'string', format: 'date-time', nullable: true },
        },
      },
      Notification: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          userId: { type: 'string', format: 'uuid' },
          title: { type: 'string', maxLength: 255 },
          content: { type: 'string' },
          isRead: { type: 'boolean', default: false },
          created_at: { type: 'string', format: 'date-time', nullable: true },
        },
      },
    },
  },
};

module.exports = { swaggerSpec };
