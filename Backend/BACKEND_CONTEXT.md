# Backend Implementation Context

## Project Structure
```
Backend/
├── index.js          # Main server file
├── db.js            # Database configuration
├── uploads/         # Directory for file uploads
└── node_modules/    # Dependencies
```

## Database Schema

### Users Table
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    gender VARCHAR(10),
    level INTEGER CHECK (level BETWEEN 1 AND 4),
    password VARCHAR(255) NOT NULL,
    profile_picture VARCHAR(255),
    favorite_stores INTEGER[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Stores Table
```sql
CREATE TABLE stores (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    location VARCHAR(255),
    rating DECIMAL(3,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Products Table
```sql
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    store_id INTEGER REFERENCES stores(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(100),
    image_url VARCHAR(255),
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## API Endpoints

### Authentication Endpoints
- `POST /signup`
  - Creates new user account
  - Required fields: name, email, password
  - Optional fields: gender, level
  - Returns: user object (without password)

- `POST /login`
  - Authenticates user
  - Required fields: email, password
  - Returns: user object (without password)

### User Management Endpoints
- `PUT /update-user`
  - Updates user profile
  - Supports multipart/form-data for profile picture
  - Required field: email
  - Optional fields: name, gender, level, password, profile_picture
  - Returns: updated user object

- `GET /api/users/:email`
  - Gets user profile
  - Returns: user object (without password)

### Store Management Endpoints
- `GET /api/stores`
  - Lists all stores
  - Returns: array of store objects

- `GET /api/stores/:id`
  - Gets store details
  - Returns: store object

- `GET /api/users/:email/favorites`
  - Gets user's favorite stores
  - Returns: array of store objects

### Product Management Endpoints
Important: Route order matters! Must be defined in this exact order:

1. `GET /api/products/suggestions`
   - Gets random product suggestions
   - Returns: array of product names
   - Query: `SELECT DISTINCT name FROM products WHERE name IS NOT NULL ORDER BY RANDOM() LIMIT 5`

2. `GET /api/products/categories`
   - Gets unique product categories
   - Returns: array of category names

3. `GET /api/products/search`
   - Searches products across stores
   - Query param: query (string)
   - Returns: array of stores with matching products
   - Uses JSON aggregation for product grouping

4. `GET /api/products/:productId`
   - Gets product details
   - Returns: product object
   - Must be last due to route parameter

5. `GET /api/stores/:storeId/products`
   - Gets products for a specific store
   - Returns: array of product objects

### Favorite Management Endpoints
- `POST /api/stores/favorite/add`
  - Adds store to user's favorites
  - Required fields: email, storeId
  - Returns: updated favorite_stores array

- `POST /api/stores/favorite/remove`
  - Removes store from user's favorites
  - Required fields: email, storeId
  - Returns: updated favorite_stores array

## Important Implementation Details

### File Upload Configuration
```javascript
const storage = multer.diskStorage({
  destination: './uploads/',
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `${uuidv4()}${ext}`);
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  }
});
```

### Error Handling Pattern
```javascript
try {
    // Operation logic
    res.json(result);
} catch (err) {
    console.error('Error description:', err);
    res.status(500).json({ 
        message: 'User-friendly error message',
        details: err.message 
    });
}
```

### Database Query Pattern
```javascript
const result = await pool.query(
    'SQL_QUERY',
    [param1, param2] // Always use parameterized queries
);
```

## Common Issues and Solutions

1. Route Order
   - Specific routes must come before parameterized routes
   - Example: `/products/suggestions` before `/products/:productId`

2. JSON Aggregation
   - Use `COALESCE` with `json_agg` to handle null cases
   - Always cast empty results to `'[]'::json`

3. File Upload Handling
   - Always clean up uploaded files if operation fails
   - Use proper error handling for file operations

4. Authentication
   - Currently using simple token-based auth
   - Token stored in Authorization header
   - Format: `Bearer <token>`

## Future Improvements
1. Implement proper authentication with JWT
2. Add input validation middleware
3. Implement rate limiting
4. Add caching for frequently accessed data
5. Implement proper error logging system 