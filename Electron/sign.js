//@ts-check
require('dotenv').config();

const fs = require('fs');
const path = require('path');
const notarize= require('electron-notarize');

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
        console.log('skip')
        return
    }

    console.log(
        `Notarizing ${appId} found at ${appPath} with Apple ID ${process.env.APPLE_ID}`
    )

    try {
        await notarize.notarize({
            appBundleId: appId,
            appPath: appPath,
            appleId: process.env.APPLE_ID,
            appleIdPassword: process.env.APPLE_APP_SPECIFIC_PASSWORD,
            teamId: process.env.APPLE_TEAM_ID,
            tool: 'notarytool'
            
        })
    } catch (error) {
        console.error(error)
    }

    console.log(`Done notarizing ${appId}`)
}