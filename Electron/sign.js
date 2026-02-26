//@ts-check
require('dotenv').config();

const fs = require('fs');
const path = require('path');
const { notarize } = require('@electron/notarize');

module.exports = async function (params) {
  if (process.platform !== 'darwin') {
    return
  }

  let appId = 'com.coffeeliqueur.wljs'

  let appPath = path.join(
    params.appOutDir,
    `${params.packager.appInfo.productFilename}.app`
  )
  
  if (!fs.existsSync(appPath)) {
    console.log('⚠️  App bundle not found, skipping notarization')
    return
  }

  // Check for required environment variables
  if (!process.env.APPLE_ID || !process.env.APPLE_APP_SPECIFIC_PASSWORD || !process.env.APPLE_TEAM_ID) {
    console.warn('⚠️  Missing Apple ID credentials. Skipping notarization.')
    console.warn('   Required: APPLE_ID, APPLE_APP_SPECIFIC_PASSWORD, APPLE_TEAM_ID')
    return
  }

  console.log(
    `🔐 Notarizing ${appId} found at ${appPath} with Apple ID ${process.env.APPLE_ID}`
  )

  try {
    await notarize({
      appBundleId: appId,
      appPath: appPath,
      appleId: process.env.APPLE_ID,
      appleIdPassword: process.env.APPLE_APP_SPECIFIC_PASSWORD,
      teamId: process.env.APPLE_TEAM_ID,
      tool: 'notarytool',
      stapleFile: path.join(appPath, 'Contents', 'MacOS', path.basename(appPath, '.app'))
    })
  } catch (error) {
    console.error(`❌ Notarization failed:`, error.message)
    throw error
  }

  console.log(`✅ Successfully notarized ${appId}`)
}