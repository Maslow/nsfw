const redis = require('redis')
const options = require('./options.js')
const fs = require('fs-extra')
const Promise = require('bluebird')
const path = require('path')

Promise.promisifyAll(fs)
Promise.promisifyAll(redis)

const dataPath = options.data_path


fs.ensureDirSync(`${dataPath}/report`)
fs.ensureDirSync(`${dataPath}/report/images`)
let imglogger = new console.Console(
    fs.createWriteStream(`${dataPath}/report/illegal.csv`)
)


let redisOptions = options.redis
let client = redis.createClient(redisOptions)

main()

async function main() {
    let try_times = 0
    let i = 0
    while (try_times < 10) {
        let ret = await getIllegalImageFromQueue()
        if (!ret) {
            try_times++
            console.log(`Failed to get data from redis, delaying 1s and then try again. Attempts: ${try_times}/10`)
            await Promise.delay(1000)
            continue
        }
        i++
        try_times = 0
        let [score, imgPath] = ret.split(options.sep)
        let newPath = await copyImageFile(imgPath)
        let row = `${i}${options.sep}${ret}`
        console.log(row)
        imglogger.log(row)
        client.lpush('illegal.list.backup', ret)
    }
}


async function copyImageFile(imgPath){
    let dest = `${dataPath}/report/images/`
    await fs.ensureDirAsync(dest)
    let basename = path.basename(imgPath)
    let filepath = path.join(`${dest}`, `${basename}`)
    await fs.copyAsync(imgPath, filepath)
    return filepath
}

async function getIllegalImageFromQueue() {
    try {
        let res = await client.rpopAsync('illegal.list')
        return res || null
    } catch (err) {
        cosnole.error(err)
        return null
    }
}
