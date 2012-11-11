module.exports = (grunt) ->

  fs = require 'fs'  
  wrench = require 'wrench'

  build = require('consolidate-build')
  path = require('path')
  _ = require('underscore')

  actions = for actionPath in fs.readdirSync fs.realpathSync(path.join(__dirname, 'actions'))
    require("./actions/#{actionPath}")(grunt)

  grunt.registerMultiTask 'build', 'Build scripts', ->

    callActions = (method, args...) =>
      for action in actions
        action[method]?.apply(@, args)

    addStepsForActions = (method) =>
      for action in actions when action[method]?
        do (action) =>
          steps.push (next) =>
            action[method].apply(@, [next])

    callActions 'initialize'

    @files = grunt.file.expandFiles @data.src
    asyncDone = this.async()
    filesDone = 0
    
    @destination = path.join fs.realpathSync('.'), @data.dest
     
    steps = []

    addStepsForActions 'beforeBuild'

    for file in @files
      do (file) =>
        steps.push (next) =>
          extension = path.extname(file).substring(1)
          builder = grunt.utils._.find(build, (x) -> x.inExtension is extension)

          inExtension = builder?.inExtension ? extension
          outExtension = builder?.outExtension ? extension
          @outFile = path.join @destination, path.relative(@data.srcRoot, file[0...file.length-inExtension.length] + outExtension)

          directory = path.dirname(@outFile)
          try
            wrench.mkdirSyncRecursive(directory, '0o0777')
            grunt.log.debug "Created #{directory}"
          catch e
            grunt.fail "Got an error trying to create destination #{directory} (Error: #{e})"
          
          if builder
            builderOptions = @data[inExtension] ? {}
            builder file, builderOptions, (err, output) ->
              writeContent = if err
                console.log "Error in #{file}", err
                "alert(\"#{file}\\n#{err}\");"
              else
                output

              fs.writeFile @outFile, writeContent, ->
                grunt.log.debug "Created #{@outFile}"
                callActions 'completedFile', {file: @outFile}
                next()
          else
            inStr = fs.createReadStream(file)
            outStr = fs.createWriteStream(@outFile)
            inStr.pipe(outStr)
            grunt.log.debug "Created #{@outFile}"
            callActions 'completedFile', {file: @outFile}
            next()

    steps.push (next) =>
      callActions 'completedBuild'
      asyncDone()
      next()

    run = =>
      if steps.length
        step = steps.shift()
        step(run)

    run()