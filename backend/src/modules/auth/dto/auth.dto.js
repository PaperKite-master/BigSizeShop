function registerDto(payload = {}) {
  return {
    fullName: String(payload.fullName || '').trim(),
    email: String(payload.email || '').trim().toLowerCase(),
    password: String(payload.password || ''),
    phone: String(payload.phone || '').trim(),
  };
}

module.exports = { registerDto };