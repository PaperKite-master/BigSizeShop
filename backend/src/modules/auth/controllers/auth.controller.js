const { asyncHandler } = require('../../../common/utils/async-handler');
const authService = require('../services/auth.service');

const register = asyncHandler(async (req, res) => {
  const user = await authService.register(req.body);

  res.status(201).json({
    message: 'Registered successfully',
    data: user,
  });
});

const login = asyncHandler(async (req, res) => {
  const result = await authService.login(req.body);

  res.json({
    message: 'Logged in successfully',
    data: result,
  });
});

const me = asyncHandler(async (req, res) => {
  const user = await authService.getMe(req.user.id);

  res.json({
    message: 'User profile fetched',
    data: user,
  });
});

const logout = asyncHandler(async (req, res) => {
  const result = await authService.logout();

  res.json(result);
});

module.exports = {
  register,
  login,
  me,
  logout,
};
