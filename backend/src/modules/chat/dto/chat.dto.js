const { AppError } = require('../../../common/errors/app-error');

function sendMessageDto(payload) {
  const { content } = payload;

  if (!content || typeof content !== 'string' || !content.trim()) {
    throw new AppError('Message content is required', 400);
  }

  if (content.trim().length > 2000) {
    throw new AppError('Message content must be at most 2000 characters', 400);
  }

  return {
    content: content.trim(),
  };
}

module.exports = {
  sendMessageDto,
};
