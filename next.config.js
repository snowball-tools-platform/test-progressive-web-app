/** @type {import('next').NextConfig} */
const withPWA = require('next-pwa')({
  dest: 'public',
})

module.exports = withPWA({
  env: {
    CERC_TEST_WEBAPP_CONFIG1: process.env.CERC_TEST_WEBAPP_CONFIG1,
    CERC_TEST_WEBAPP_CONFIG2: process.env.CERC_TEST_WEBAPP_CONFIG2,
    CERC_WEBAPP_DEBUG: process.env.CERC_WEBAPP_DEBUG,
  },
})
