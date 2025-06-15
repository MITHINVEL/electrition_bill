// Simple Node.js Express server for demonstration
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Set up storage for uploaded images
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, path.join(__dirname, 'uploads'));
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + '-' + file.originalname);
  }
});
const upload = multer({ storage: storage });

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir);
}

// Example endpoint
app.get('/api/endpoint', (req, res) => {
  res.json({ message: 'Hello from Node.js backend!' });
});

// Image upload endpoint
app.post('/api/upload', upload.single('image'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No file uploaded' });
  }
  res.json({
    message: 'Image uploaded successfully',
    filename: req.file.filename,
    url: `/uploads/${req.file.filename}`
  });
});

// Serve uploaded images statically
app.use('/uploads', express.static(uploadsDir));

// Add more endpoints as needed

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
