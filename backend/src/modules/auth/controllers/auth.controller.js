const { asyncHandler } = require('../../../common/utils/async-handler');
const authService = require('../services/auth.service');

const register = asyncHandler(async (req, res) => {
  const user = await authService.register(req.body);

  res.status(201).json({
    message: 'Registered successfully',
    data: user,
  });
});

module.exports = {
  register,
};