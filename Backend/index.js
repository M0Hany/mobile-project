import express from 'express';
import pool from './db.js';
import multer from 'multer';
import path from 'path';
import cors from 'cors';
import { v4 as uuidv4 } from 'uuid';
import fs from 'fs';

const app = express();
const port = 3000;

// Create uploads directory if it doesn't exist
const uploadDir = './uploads';
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir);
}

// Enable CORS with proper options
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Accept', 'Authorization']
}));

// Body parser middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Log all requests
app.use((req, res, next) => {
    console.log('Incoming request:', {
        method: req.method,
        url: req.url,
        headers: req.headers,
        body: req.body
    });
    next();
});

// Root route
app.get('/', (req, res) => {
    res.json({ message: 'Welcome to FCI Student Portal API' });
});

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
        const ext = path.extname(file.originalname);
        cb(null, `${uuidv4()}${ext}`);
  }
});

const upload = multer({ 
    storage: storage,
    limits: {
        fileSize: 5 * 1024 * 1024 // 5MB limit
    },
    fileFilter: (req, file, cb) => {
        // Accept only image files
        if (file.mimetype.startsWith('image/')) {
            cb(null, true);
        } else {
            cb(new Error('Only image files are allowed'));
        }
    }
});

// Serve uploaded files statically
app.use('/uploads', express.static('uploads'));

app.post('/signup', async (req, res) => {
    console.log('Received signup request:', req.body);
    const { name, email, gender, level, password } = req.body;

    // Validate mandatory fields
    if (!name || !email || !password) {
        return res.status(400).json({ message: 'Name, email, and password are required' });
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
        return res.status(400).json({ message: 'Invalid email format' });
    }

    // Validate password (minimum 8 characters)
    if (password.length < 8) {
        return res.status(400).json({ message: 'Password must be at least 8 characters long' });
    }

    // Validate level if provided
    if (level !== undefined && level !== null) {
        const levelNum = parseInt(level);
        if (![1, 2, 3, 4].includes(levelNum)) {
            return res.status(400).json({ message: 'Level must be between 1 and 4' });
        }
    }

    try {
        // Check if email already exists
        const checkExisting = await pool.query(
            'SELECT * FROM users WHERE email = $1',
            [email]
        );

        if (checkExisting.rows.length > 0) {
            return res.status(400).json({ message: 'Email already registered' });
        }

        // Insert new user
        const result = await pool.query(
            'INSERT INTO users (name, email, gender, level, password) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [name, email, gender || null, level || null, password]
        );

        // Remove password from response
        const user = result.rows[0];
        delete user.password;

        res.status(201).json({
            message: 'Registration successful',
            user: user
        });
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ message: 'Error registering user', error: error.message });
    }
});

app.post('/login', async (req, res) => {
    const { email, password } = req.body;

    // Validate mandatory fields
    if (!email || !password) {
        return res.status(400).json({ message: 'Email and password are required' });
    }

    try {
        const result = await pool.query(
            'SELECT * FROM users WHERE email = $1 AND password = $2',
            [email, password]
        );

        if (result.rows.length > 0) {
            const user = result.rows[0];
            delete user.password;
            res.status(200).json({ message: 'Login successful', user: user });
        } else {
            res.status(401).json({ message: 'Invalid email or password' });
        }
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ message: 'Error logging in', error: error.message });
    }
});

app.put('/update-user', upload.single('profile_picture'), async (req, res) => {
    try {
        const { email, name, gender, level, password } = req.body;
        const profilePicturePath = req.file ? `/uploads/${req.file.filename}` : null;

        // Validate mandatory field
        if (!email) {
            return res.status(400).json({ message: 'Email is required' });
    }

    const fields = [];
    const values = [];
    let index = 1;

    if (name) {
            fields.push(`name = $${index}`);
        values.push(name);
            index++;
    }
    if (gender) {
            fields.push(`gender = $${index}`);
        values.push(gender);
            index++;
    }
    if (level) {
            fields.push(`level = $${index}`);
        values.push(level);
            index++;
    }
    if (password) {
            fields.push(`password = $${index}`);
        values.push(password);
            index++;
    }
        if (profilePicturePath) {
            // Get the current profile picture path to delete the old file
            const currentUser = await pool.query(
                'SELECT profile_picture FROM users WHERE email = $1',
                [email]
            );
            
            if (currentUser.rows.length > 0 && currentUser.rows[0].profile_picture) {
                const oldPath = path.join('.', currentUser.rows[0].profile_picture);
                if (fs.existsSync(oldPath)) {
                    fs.unlinkSync(oldPath);
                }
            }

            fields.push(`profile_picture = $${index}`);
            values.push(profilePicturePath);
            index++;
    }

    if (fields.length === 0) {
            return res.status(400).json({ message: 'No fields to update' });
    }

        values.push(email);

        const query = `UPDATE users SET ${fields.join(', ')} WHERE email = $${index} RETURNING *`;

        const result = await pool.query(query, values);
        if (result.rows.length > 0) {
            const user = result.rows[0];
            delete user.password; // Remove password from response
            res.status(200).json({ message: 'User updated successfully', user: user });
        } else {
            // Delete uploaded file if user update fails
            if (profilePicturePath) {
                const filePath = path.join('.', profilePicturePath);
                if (fs.existsSync(filePath)) {
                    fs.unlinkSync(filePath);
                }
            }
            res.status(404).json({ message: 'User not found' });
        }
    } catch (error) {
        // Delete uploaded file if there's an error
        if (req.file) {
            const filePath = path.join('.', 'uploads', req.file.filename);
            if (fs.existsSync(filePath)) {
                fs.unlinkSync(filePath);
            }
        }
        console.error('Update error:', error);
        res.status(500).json({ message: 'Error updating user', error: error.message });
    }
});

// Store Management Endpoints
app.get('/api/stores', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM stores');
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/stores/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query('SELECT * FROM stores WHERE id = $1', [id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Store not found' });
        }
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/stores/:id/products', async (req, res) => {
    try {
        const { id } = req.params;
        console.log(`Fetching products for store ${id}`);

        const result = await pool.query(
            `SELECT 
                p.*,
                s.name as store_name,
                s.latitude,
                s.longitude,
                s.category as store_category,
                s.rating as store_rating
            FROM products p
            JOIN stores s ON p.store_id = s.id
            WHERE p.store_id = $1
            ORDER BY p.name ASC`,
            [id]
        );

        if (result.rows.length === 0) {
            console.log(`No products found for store ${id}`);
            return res.json([]); // Return empty array instead of 404
        }

        console.log(`Found ${result.rows.length} products for store ${id}`);
        res.json(result.rows);
    } catch (err) {
        console.error('Error fetching store products:', err);
        res.status(500).json({ 
            message: 'Internal server error while fetching store products',
            details: err.message 
        });
    }
});

// Add to favorites
app.post('/api/stores/favorite/add', async (req, res) => {
    try {
        console.log('Received add favorite request:', req.body);
        const { email, storeId } = req.body;
        
        if (!email || storeId === undefined) {
            return res.status(400).json({ error: 'Email and storeId are required' });
        }
        
        // First, get the current favorite_stores array
        const currentResult = await pool.query(
            'SELECT favorite_stores FROM users WHERE email = $1',
            [email]
        );
        
        if (currentResult.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        let favoriteStores = currentResult.rows[0].favorite_stores || [];
        
        // Check if store is already in favorites
        if (favoriteStores.includes(storeId)) {
            return res.status(400).json({ error: 'Store already in favorites' });
        }

        // Add store to favorites
        favoriteStores.push(storeId);
        
        // Update user's favorite stores
        const result = await pool.query(
            'UPDATE users SET favorite_stores = $1 WHERE email = $2 RETURNING favorite_stores',
            [favoriteStores, email]
        );
        
        // Get the updated store details
        const storeResult = await pool.query(
            'SELECT * FROM stores WHERE id = $1',
            [storeId]
        );
        
        res.json({
            message: 'Store added to favorites',
            favorite_stores: result.rows[0].favorite_stores,
            store: storeResult.rows[0]
        });
    } catch (err) {
        console.error('Error adding favorite:', err);
        res.status(500).json({ error: 'Internal server error', details: err.message });
    }
});

// Remove from favorites
app.post('/api/stores/favorite/remove', async (req, res) => {
    try {
        console.log('Received remove favorite request:', req.body);
        const { email, storeId } = req.body;
        
        if (!email || storeId === undefined) {
            return res.status(400).json({ error: 'Email and storeId are required' });
        }
        
        // First, get the current favorite_stores array
        const currentResult = await pool.query(
            'SELECT favorite_stores FROM users WHERE email = $1',
            [email]
        );
        
        if (currentResult.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        let favoriteStores = currentResult.rows[0].favorite_stores || [];
        
        // Check if store is in favorites
        if (!favoriteStores.includes(storeId)) {
            return res.status(400).json({ error: 'Store not in favorites' });
        }

        // Remove store from favorites
        favoriteStores = favoriteStores.filter(id => id !== storeId);
        
        // Update user's favorite stores
        const result = await pool.query(
            'UPDATE users SET favorite_stores = $1 WHERE email = $2 RETURNING favorite_stores',
            [favoriteStores, email]
        );
        
        res.json({
            message: 'Store removed from favorites',
            favorite_stores: result.rows[0].favorite_stores
        });
    } catch (err) {
        console.error('Error removing favorite:', err);
        res.status(500).json({ error: 'Internal server error', details: err.message });
    }
});

app.get('/api/users/:email/favorites', async (req, res) => {
    try {
        const { email } = req.params;
        const result = await pool.query(
            'SELECT s.* FROM stores s JOIN users u ON s.id = ANY(u.favorite_stores) WHERE u.email = $1',
            [email]
        );
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Get user profile
app.get('/api/users/:email', async (req, res) => {
    try {
        const { email } = req.params;
        const result = await pool.query(
            'SELECT email, name, gender, level, profile_picture FROM users WHERE email = $1',
            [email]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Product Management Endpoints
app.get('/api/products/suggestions', async (req, res) => {
    try {
        console.log('Fetching product suggestions');
        const result = await pool.query(
            'SELECT name FROM products WHERE name IS NOT NULL GROUP BY name ORDER BY RANDOM() LIMIT 5'
        );
        
        const suggestions = result.rows.map(row => row.name);
        console.log('Found suggestions:', suggestions);
        res.json(suggestions);
    } catch (err) {
        console.error('Error fetching product suggestions:', err);
        res.status(500).json({ 
            message: 'Internal server error while fetching suggestions',
            details: err.message 
        });
    }
});

app.get('/api/products/categories', async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT DISTINCT category FROM products WHERE category IS NOT NULL'
        );
        const categories = result.rows.map(row => row.category);
        res.json(categories);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/products/search', async (req, res) => {
    try {
        const { query } = req.query;
        if (!query) {
            return res.status(400).json({ 
                message: 'Search query is required' 
            });
        }

        // Clean and prepare the search query
        const cleanQuery = decodeURIComponent(query)
            .replace(/\+/g, ' ')  // Replace + with spaces
            .trim();
            
        console.log('Original query:', query);
        console.log('Cleaned query:', cleanQuery);

        // Create the search pattern
        const searchPattern = `%${cleanQuery}%`;
        console.log('Search pattern:', searchPattern);

        // Updated query to handle partial matches more flexibly
        const result = await pool.query(
            `SELECT 
                s.*,
                COALESCE(
                    (
                        SELECT json_agg(
                            json_build_object(
                                'id', p.id,
                                'store_id', p.store_id,
                                'name', p.name,
                                'description', p.description,
                                'price', p.price,
                                'category', p.category,
                                'image_url', p.image_url,
                                'is_available', p.is_available,
                                'created_at', p.created_at
                            )
                        )
                        FROM products p
                        WHERE p.store_id = s.id 
                        AND (
                            LOWER(p.name) LIKE LOWER($1)
                            OR LOWER(p.description) LIKE LOWER($1)
                            OR LOWER(p.category) LIKE LOWER($1)
                        )
                    ),
                    '[]'::json
                ) as matching_products
            FROM stores s
            WHERE EXISTS (
                SELECT 1 
                FROM products p 
                WHERE p.store_id = s.id 
                AND (
                    LOWER(p.name) LIKE LOWER($1)
                    OR LOWER(p.description) LIKE LOWER($1)
                    OR LOWER(p.category) LIKE LOWER($1)
                )
            )`,
            [searchPattern]
        );

        const stores = result.rows.map(row => {
            const { matching_products, ...store } = row;
            return {
                ...store,
                products: matching_products || []
            };
        });

        console.log(`Found ${stores.length} stores with matching products for query: "${cleanQuery}"`);
        
        // If no results found, try a more flexible search
        if (stores.length === 0) {
            // Split query into words and search for any word match
            const words = cleanQuery.split(' ').filter(word => word.length > 0);
            const wordPatterns = words.map(word => `%${word}%`);
            
            console.log('Trying flexible search with words:', words);
            
            const flexibleResult = await pool.query(
                `SELECT 
                    s.*,
                    COALESCE(
                        (
                            SELECT json_agg(
                                json_build_object(
                                    'id', p.id,
                                    'store_id', p.store_id,
                                    'name', p.name,
                                    'description', p.description,
                                    'price', p.price,
                                    'category', p.category,
                                    'image_url', p.image_url,
                                    'is_available', p.is_available,
                                    'created_at', p.created_at
                                )
                            )
                            FROM products p
                            WHERE p.store_id = s.id 
                            AND (
                                ${wordPatterns.map((_, i) => 
                                    `LOWER(p.name) LIKE LOWER($${i + 1}) OR 
                                     LOWER(p.description) LIKE LOWER($${i + 1}) OR 
                                     LOWER(p.category) LIKE LOWER($${i + 1})`
                                ).join(' OR ')}
                            )
                        ),
                        '[]'::json
                    ) as matching_products
                FROM stores s
                WHERE EXISTS (
                    SELECT 1 
                    FROM products p 
                    WHERE p.store_id = s.id 
                    AND (
                        ${wordPatterns.map((_, i) => 
                            `LOWER(p.name) LIKE LOWER($${i + 1}) OR 
                             LOWER(p.description) LIKE LOWER($${i + 1}) OR 
                             LOWER(p.category) LIKE LOWER($${i + 1})`
                        ).join(' OR ')}
                    )
                )`,
                wordPatterns
            );

            const flexibleStores = flexibleResult.rows.map(row => {
                const { matching_products, ...store } = row;
                return {
                    ...store,
                    products: matching_products || []
                };
            });

            console.log(`Found ${flexibleStores.length} stores with flexible matching for query: "${cleanQuery}"`);
            return res.json(flexibleStores);
        }

        res.json(stores);
    } catch (err) {
        console.error('Error searching stores with products:', err);
        res.status(500).json({ 
            message: 'Internal server error while searching',
            details: err.message 
        });
    }
});

// This should be last since it has a parameter
app.get('/api/products/:productId', async (req, res) => {
    try {
        const { productId } = req.params;
        const result = await pool.query(
            'SELECT * FROM products WHERE id = $1',
            [productId]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Product not found' });
        }
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.listen(port, () => {
    console.log(`Server is running on http://localhost:${port}`);
});