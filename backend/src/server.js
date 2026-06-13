require('dotenv').config();

const { validateEnv } = require('./common/config/env');
const app = require('./app');

validateEnv();

const port = process.env.PORT || 4000;

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});