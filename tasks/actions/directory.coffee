module.exports = (grunt) ->

  fs = require 'fs'
  wrench = require 'wrench'

  initialize: ->
    @tryClearCount = 0

  beforeBuild: (next) ->
    if @tryClearCount >= 1000
      grunt.fatal 'Could not clear old directory (#{@destination}).'
      return

    do tryClear = =>
      if @data.clear and fs.existsSync @destination
        try
          wrench.rmdirSyncRecursive(@destination, yes)
          grunt.log.debug "Cleared old content (#{@destination})" 
          next()
        catch e
          grunt.log.debug "Got an error trying to delete old dir (#{@destination}). Trying again. (Error: #{error: e}"
          @tryClearCount++
          setTimeout tryClear, 10
      else
        next()

  beforeBuildFile: (next) ->


