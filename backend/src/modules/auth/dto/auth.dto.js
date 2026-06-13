function registerDto(payload = {}) {
  return {
    fullName: String(payload.fullName || '').trim(),
    email: String(payload.email || '').trim().toLowerCase(),
    password: String(payload.password || ''),
    phone: String(payload.phone || '').trim() || null,
  };
}

function loginDto(payload = {}) {
  return {
    email: String(payload.email || '').trim().toLowerCase(),
    password: String(payload.password || ''),
  };
}

module.exports = { registerDto, loginDto };
