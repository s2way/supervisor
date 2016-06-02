os = require 'os'
Elasticsearch = require './ElasticSearch.coffee'
esURL = require './es_url.coffee'

class SystemInfo

    es = new Elasticsearch

    name: 'SystemInfo'
    interval: 10000

    gather: ->
        data =
            applicaton: 'DataHub'
            osHostName: os.hostname()
            osPlatform: os.platform()
            osRelease: os.release()
            osType: os.type()
            osArch: os.arch()
            nodePid: process.pid
        nodeMemUsgMb = process.memoryUsage()
        data.cpus = os.cpus().length
        data.memTotMb = parseFloat((os.totalmem() / 1024 / 1024).toFixed 2)
        data.memFreeMb = parseFloat((os.freemem() / 1024 / 1024).toFixed 2)
        data.memUsedMb = parseFloat((data.memTotMb - data.memFreeMb).toFixed 2)
        data.memFreePerc = parseFloat((data.memFreeMb / data.memTotMb * 100).toFixed 2)
        data.osDaysUP = parseFloat((os.uptime() / 3600 / 24).toFixed 2)
        loadAvg = os.loadavg()
        data.loadAVG1Min = loadAvg[1]
        data.loadAVG5Min = loadAvg[2]
        data.nodeDaysUp = parseFloat((process.uptime() / 3600 / 24).toFixed 2)
        data.heapTotMb = parseFloat((nodeMemUsgMb.heapTotal / 1024 / 1024).toFixed 2)
        data.heapUsedMb = parseFloat((nodeMemUsgMb.heapUsed / 1024 / 1024).toFixed 2)
        data.memRssMb = parseFloat((nodeMemUsgMb.rss / 1024 / 1024).toFixed 2)
        data.heapFreeMb = parseFloat((data.heapTotMb - data.heapUsedMb).toFixed 2)
        data.heapFreePerc = parseFloat((data.heapFreeMb / data.heapTotMb * 100).toFixed 2)
        data

    run: (emitter) ->
        data =
            index: 'microservices'
            type: 'server_metrics'
            data: @gather()
        host = if (os.hostname()).indexOf 'vs' isnt -1 then '127.0.0.1' else esURL
        post = if (os.hostname()).indexOf 'vs' isnt -1 then 9200 else 80
        source = host: host, port: post
        es.save source, data, (e, s) ->
            emitter.emit 'error' if e
            emitter.emit 'success'

    stop: ->

Watcher = require('waferpie-utils').Watcher
watcher = new Watcher
task = new SystemInfo
watcher.register task, (err) ->
    console.log err if err?
    console.log "#{task.name} registered." unless err?