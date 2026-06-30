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
    { name: 'Cart', description: 'Shopping cart management' },
    { name: 'Orders', description: 'Order management and checkout' },
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
          400: { description: 'Missing required fields', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
          409: { description: 'Email already exists', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
        },
      },
    },
    '/auth/login': {
      post: {
        tags: ['Auth'],
        summary: 'Login and receive JWT',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/LoginRequest' },
            },
          },
        },
        responses: {
          200: {
            description: 'Login successful',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/LoginResponse' },
              },
            },
          },
          401: { description: 'Invalid credentials', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
        },
      },
    },
    '/auth/me': {
      get: {
        tags: ['Auth'],
        summary: 'Get current user profile',
        security: [{ bearerAuth: [] }],
        responses: {
          200: {
            description: 'User profile',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    message: { type: 'string' },
                    data: { $ref: '#/components/schemas/User' },
                  },
                },
              },
            },
          },
          401: { description: 'Unauthorized', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
        },
      },
    },
    '/auth/logout': {
      post: {
        tags: ['Auth'],
        summary: 'Logout current user',
        security: [{ bearerAuth: [] }],
        responses: {
          200: {
            description: 'Logged out',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { message: { type: 'string', example: 'Logged out successfully' } },
                },
              },
            },
          },
        },
      },
    },
    '/categories': {
      get: {
        tags: ['Categories'],
        summary: 'List all categories',
        responses: {
          200: {
            description: 'Category list',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    message: { type: 'string' },
                    data: { type: 'array', items: { $ref: '#/components/schemas/Category' } },
                  },
                },
              },
            },
          },
        },
      },
      post: {
        tags: ['Categories'],
        summary: 'Create category (admin)',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['name'],
                properties: { name: { type: 'string', example: 'Shirt' } },
              },
            },
          },
        },
        responses: {
          201: { description: 'Category created' },
          403: { description: 'Forbidden' },
        },
      },
    },
    '/categories/{id}': {
      put: {
        tags: ['Categories'],
        summary: 'Update category (admin)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        requestBody: {
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: { name: { type: 'string' } },
              },
            },
          },
        },
        responses: { 200: { description: 'Category updated' }, 404: { description: 'Not found' } },
      },
      delete: {
        tags: ['Categories'],
        summary: 'Delete category (admin)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        responses: { 200: { description: 'Category deleted' }, 404: { description: 'Not found' } },
      },
    },
    '/products': {
      get: {
        tags: ['Products'],
        summary: 'List products with dynamic filters and pagination',
        description: 'Returns a paginated list of active products. All filter parameters are optional and can be combined freely (Dynamic Query). Supports Full-text search, category (single or multiple, by UUID or name), price range, rating range, stock availability, and custom sorting.',
        parameters: [
          { name: 'page', in: 'query', description: 'Page number (≥ 1)', schema: { type: 'integer', default: 1, minimum: 1 } },
          { name: 'limit', in: 'query', description: 'Items per page (1–100)', schema: { type: 'integer', default: 10, minimum: 1, maximum: 100 } },
          { name: 'search', in: 'query', description: 'Full-text / LIKE search on product name and description', schema: { type: 'string', example: 'áo thun nam' } },
          { name: 'q', in: 'query', description: 'Alias for search', schema: { type: 'string' } },
          {
            name: 'category', in: 'query',
            description: 'Filter by category UUID or name. Repeat the param or use comma-separated values for OR logic across multiple categories. Example: ?category=uuid1&category=uuid2 or ?category=Áo,Quần',
            schema: { type: 'string' },
            example: 'Áo Thun',
          },
          { name: 'minPrice', in: 'query', description: 'Minimum product price (inclusive)', schema: { type: 'number', example: 100000 } },
          { name: 'maxPrice', in: 'query', description: 'Maximum product price (inclusive)', schema: { type: 'number', example: 500000 } },
          { name: 'minRating', in: 'query', description: 'Minimum average rating 0–5 (requires reviews table)', schema: { type: 'number', minimum: 0, maximum: 5, example: 3.5 } },
          { name: 'maxRating', in: 'query', description: 'Maximum average rating 0–5 (requires reviews table)', schema: { type: 'number', minimum: 0, maximum: 5, example: 5 } },
          { name: 'inStock', in: 'query', description: 'When true, only return products with stock > 0', schema: { type: 'boolean', example: true } },
          { name: 'sortBy', in: 'query', description: 'Sort field', schema: { type: 'string', enum: ['name', 'price', 'createdAt', 'stock', 'rating'], default: 'createdAt' } },
          { name: 'sortOrder', in: 'query', description: 'Sort direction', schema: { type: 'string', enum: ['asc', 'desc'], default: 'asc' } },
        ],
        responses: {
          200: {
            description: 'Paginated product list',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/ProductListResponse' },
              },
            },
          },
        },
      },
      post: {
        tags: ['Products'],
        summary: 'Create product (admin)',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/CreateProductRequest' },
            },
          },
        },
        responses: { 201: { description: 'Product created' } },
      },
    },
    '/products/search': {
      get: {
        tags: ['Products'],
        summary: 'Full-text search products by keyword',
        description: 'Performs a PostgreSQL `plainto_tsquery` full-text search on product name and description. A `search` or `q` parameter is required. All dynamic filter params (category, price, rating, inStock, sort) can be combined with the keyword.',
        parameters: [
          { name: 'search', in: 'query', required: false, description: 'Full-text search keyword (required if q is absent)', schema: { type: 'string', example: 'áo thun oversize' } },
          { name: 'q', in: 'query', description: 'Alias for search', schema: { type: 'string' } },
          { name: 'page', in: 'query', schema: { type: 'integer', default: 1 } },
          { name: 'limit', in: 'query', schema: { type: 'integer', default: 10, maximum: 100 } },
          { name: 'category', in: 'query', description: 'Category UUID or name (comma-separated for multi)', schema: { type: 'string' } },
          { name: 'minPrice', in: 'query', schema: { type: 'number' } },
          { name: 'maxPrice', in: 'query', schema: { type: 'number' } },
          { name: 'minRating', in: 'query', schema: { type: 'number', minimum: 0, maximum: 5 } },
          { name: 'maxRating', in: 'query', schema: { type: 'number', minimum: 0, maximum: 5 } },
          { name: 'inStock', in: 'query', schema: { type: 'boolean' } },
          { name: 'sortBy', in: 'query', schema: { type: 'string', enum: ['name', 'price', 'createdAt', 'stock', 'rating'], default: 'createdAt' } },
          { name: 'sortOrder', in: 'query', schema: { type: 'string', enum: ['asc', 'desc'], default: 'asc' } },
        ],
        responses: {
          200: { description: 'Search results', content: { 'application/json': { schema: { $ref: '#/components/schemas/ProductListResponse' } } } },
          400: { description: 'Missing search keyword', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorResponse' } } } },
        },
      },
    },
    '/products/filter': {
      get: {
        tags: ['Products'],
        summary: 'Dynamic filter – category, price, rating, stock',
        description: 'Filter products using any combination of category (UUID or name, multi-value), price range, rating range, and stock availability. No search keyword required. When minRating or maxRating is supplied the query automatically uses a raw-SQL aggregation path.',
        parameters: [
          {
            name: 'category', in: 'query',
            description: 'Category UUID or name. Repeat or comma-separate for multiple categories (OR logic).',
            schema: { type: 'string' },
            example: 'Quần',
          },
          { name: 'minPrice', in: 'query', description: 'Min price (inclusive)', schema: { type: 'number', example: 50000 } },
          { name: 'maxPrice', in: 'query', description: 'Max price (inclusive)', schema: { type: 'number', example: 300000 } },
          { name: 'minRating', in: 'query', description: 'Min average rating 0–5', schema: { type: 'number', minimum: 0, maximum: 5, example: 4 } },
          { name: 'maxRating', in: 'query', description: 'Max average rating 0–5', schema: { type: 'number', minimum: 0, maximum: 5, example: 5 } },
          { name: 'inStock', in: 'query', description: 'Only show products in stock', schema: { type: 'boolean', example: true } },
          { name: 'sortBy', in: 'query', schema: { type: 'string', enum: ['name', 'price', 'createdAt', 'stock', 'rating'], default: 'createdAt' } },
          { name: 'sortOrder', in: 'query', schema: { type: 'string', enum: ['asc', 'desc'], default: 'asc' } },
          { name: 'page', in: 'query', schema: { type: 'integer', default: 1 } },
          { name: 'limit', in: 'query', schema: { type: 'integer', default: 10, maximum: 100 } },
        ],
        responses: {
          200: { description: 'Filtered product list', content: { 'application/json': { schema: { $ref: '#/components/schemas/ProductListResponse' } } } },
        },
      },
    },
    '/products/{id}': {
      get: {
        tags: ['Products'],
        summary: 'Get product by ID',
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        responses: { 200: { description: 'Product detail' }, 404: { description: 'Not found' } },
      },
      put: {
        tags: ['Products'],
        summary: 'Update product (admin)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        responses: { 200: { description: 'Product updated' } },
      },
      delete: {
        tags: ['Products'],
        summary: 'Delete product (admin)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        responses: { 200: { description: 'Product deleted' } },
      },
    },
    '/cart': {
      get: {
        tags: ['Cart'],
        summary: 'Get current user cart',
        security: [{ bearerAuth: [] }],
        responses: { 200: { description: 'Cart retrieved' } }
      },
      post: {
        tags: ['Cart'],
        summary: 'Add item to cart',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['productId'],
                properties: {
                  productId: { type: 'string', format: 'uuid' },
                  quantity: { type: 'integer', default: 1 },
                  variantId: { type: 'string', format: 'uuid', nullable: true }
                }
              }
            }
          }
        },
        responses: { 201: { description: 'Item added' } }
      }
    },
    '/cart/{id}': {
      put: {
        tags: ['Cart'],
        summary: 'Update item quantity',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['quantity'],
                properties: { quantity: { type: 'integer' } }
              }
            }
          }
        },
        responses: { 200: { description: 'Quantity updated' } }
      },
      delete: {
        tags: ['Cart'],
        summary: 'Remove item from cart',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        responses: { 200: { description: 'Item removed' } }
      }
    },
    '/orders': {
      post: {
        tags: ['Orders'],
        summary: 'Checkout cart and create order',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['address'],
                properties: {
                  address: { type: 'string' },
                  paymentMethod: { type: 'string', default: 'COD' }
                }
              }
            }
          }
        },
        responses: { 201: { description: 'Order created' } }
      }
    },
    '/orders/{id}/cancel': {
      patch: {
        tags: ['Orders'],
        summary: 'Cancel a pending order',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        responses: { 200: { description: 'Order cancelled' } }
      }
    }
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
      LoginRequest: {
        type: 'object',
        required: ['email', 'password'],
        properties: {
          email: { type: 'string', format: 'email', example: 'user@example.com' },
          password: { type: 'string', format: 'password', example: 'secret123' },
        },
      },
      LoginResponse: {
        type: 'object',
        properties: {
          message: { type: 'string', example: 'Logged in successfully' },
          data: {
            type: 'object',
            properties: {
              token: { type: 'string' },
              user: { $ref: '#/components/schemas/User' },
            },
          },
        },
      },
      CreateProductRequest: {
        type: 'object',
        required: ['name', 'price'],
        properties: {
          categoryId: { type: 'string', format: 'uuid' },
          name: { type: 'string' },
          description: { type: 'string' },
          price: { type: 'number' },
          stock: { type: 'integer' },
          imageUrl: { type: 'string' },
          images: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                image_url: { type: 'string' },
                is_thumbnail: { type: 'boolean' },
              },
            },
          },
          variants: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                variant_name: { type: 'string' },
                sku: { type: 'string' },
                price: { type: 'number' },
                stock: { type: 'integer' },
                image_url: { type: 'string' },
              },
            },
          },
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
          avg_rating: { type: 'number', format: 'float', nullable: true, description: 'Average product rating (0–5). Null when no reviews exist.' },
          createdAt: { type: 'string', format: 'date-time', nullable: true },
          updated_at: { type: 'string', format: 'date-time', nullable: true },
          categories: { $ref: '#/components/schemas/Category', nullable: true },
          product_images: { type: 'array', items: { type: 'object', properties: { id: { type: 'string' }, image_url: { type: 'string' }, is_thumbnail: { type: 'boolean' } } } },
          product_variants: { type: 'array', items: { $ref: '#/components/schemas/ProductVariant' } },
        },
      },
      ProductListResponse: {
        type: 'object',
        properties: {
          message: { type: 'string', example: 'Products fetched' },
          data: { type: 'array', items: { $ref: '#/components/schemas/Product' } },
          meta: {
            type: 'object',
            properties: {
              total: { type: 'integer', description: 'Total matching records', example: 42 },
              page: { type: 'integer', description: 'Current page', example: 1 },
              limit: { type: 'integer', description: 'Items per page', example: 10 },
              totalPages: { type: 'integer', description: 'Total number of pages', example: 5 },
            },
          },
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
