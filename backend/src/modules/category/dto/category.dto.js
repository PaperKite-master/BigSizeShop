function createCategoryDto(payload = {}) {
  return {
    name: String(payload.name || '').trim(),
  };
}

function updateCategoryDto(payload = {}) {
  const data = {};

  if (payload.name !== undefined) {
    data.name = String(payload.name).trim();
  }

  return data;
}

module.exports = { createCategoryDto, updateCategoryDto };
