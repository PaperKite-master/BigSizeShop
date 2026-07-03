const { asyncHandler } = require('../../../common/utils/async-handler');
const notificationService = require('../services/notification.service');
const { AppError } = require('../../../common/errors/app-error');

const sendBroadcast = asyncHandler(async (req, res) => {
  const { title, body, data } = req.body;

  if (!title || !body) {
    throw new AppError('Title and body are required for broadcast notifications.', 400);
  }

  const result = await notificationService.sendBroadcastNotification(title, body, data);

  res.json({
    message: 'Broadcast notification sent successfully',
    data: result,
  });
});

module.exports = {
  sendBroadcast,
};
