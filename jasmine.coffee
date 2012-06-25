# rubular funktionierender RegEx (für einen): /Failures:.*\d+\).*Stacktrace:.*?CoffeeRecommender\/(.*?)\)/
# failure messages: /Failures:.(.*)/

define (require, exports, module) ->
  ide = require 'core/ide'
  ext = require 'core/ext'
  menus = require 'ext/menus/menus'
  noderunner = require 'ext/noderunner/noderunner'
  commands = require 'ext/commands/commands'
  fs = require 'ext/filesystem/filesystem'
  panels = require 'ext/panels/panels'
  markup = require 'text!ext/jasmine/jasmine.xml'
  filelist = require 'ext/filelist/filelist'
  css = require "text!ext/jasmine/jasmine.css"

  DIVIDER_POSITION = 2300
  MENU_ENTRY_POSITION = 2400
  PANEL_POSITION = 10000
  PATH_TO_JASMINE = 'node_modules/jasmine-node/lib/jasmine-node/cli.js'

  module.exports = ext.register 'ext/jasmine/jasmine',
    name: 'Jasmine'
    dev: 'Tobias Metzke, Tobias Pfeiffer'
    type: ext.GENERAL
    alone: yes # TODO: Access to livecoffee?
    commands:
      'jasmine': hint: 'Run your tests with jasmine!'
    hotitems : {}
    markup: markup
    nodes: []
    css: css
    
    hook: () ->
      apf.importCssString(css);
      
      _self = @
      
      @markupInsertionPoint = colLeft
      panels.register this, 
        position : PANEL_POSITION,
        caption: "Jasmine",
        "class": "jasmine"
      
      commands.addCommand(
        name: "jasmine"
        hint: "run your specs with jasmine"
        bindKey:
          mac: "Command-J"
          win: "Ctrl-J"
        exec: -> _self.jasmine()
      )
      @nodes.push menus.addItemByPath("Edit/~", new apf.divider(), DIVIDER_POSITION)
      @nodes.push menus.addItemByPath("Edit/Jasmine", new apf.item({command: "jasmine"}), MENU_ENTRY_POSITION)

      @hotitems['jasmine'] = [@nodes[1]]
      @projectName = @getProjectName()
      @socketListenerRegistered = false
      
      
    init: ->
      @initButtons()
      # for the love of god do not remove, needed externally...
      @panel = windowTestPanelJasmine
      @nodes.push windowTestPanelJasmine, menuRunSettingsJasmine, stateTestRunJasmine
      
      _self = @
      
      dataGridTestProjectJasmine.addEventListener 'afterchoose', =>
      	selection = dataGridTestProjectJasmine.getSelection()
      	selection = null if selection.some (node) -> node.tagName == 'repo'
      	@run selection
      	#nodes = dataGridTestProjectJasmine.getSelection()
      	#for node in nodes
	      #	_self.setError node, 'düdüm'
	      # _self.setPass node, 'yay'
      
      ide.dispatchEvent "init.jasmine"
      @setRepoName()
      @initFilelist()
      @afterFileSave()
      
    initButtons: ->
      buttonTestRunJasmine.$ext.setAttribute("class", "light-dropdown")
      buttonTestStopJasmine.$ext.setAttribute("class", buttonTestStopJasmine.$ext.getAttribute("class") + " buttonTestStopJasmine")
      windowTestPanelJasmine.$ext.setAttribute("class", windowTestPanelJasmine.$ext.getAttribute("class") + " testpanelJasmine")
      
    # bad bad hack, Cloud9 danke.
    setRepoName: ->
      @projectName = @getProjectName()
      modelTestsJasmine.data.childNodes[1].setAttribute 'name', @projectName
      
    initFilelist: ->
      filelist.getFileList false, (data, state) =>
        return if (state != apf.SUCCESS)
        sanitizedData = data.replace(/^\./gm, "")
        sanitizedData = sanitizedData.replace(/^\/node_modules\/.*/gm, "")
        specs = sanitizedData.match(/^.*\.spec\.(js|coffee)$/gm)
        @addFiles(specs, modelTestsJasmine.queryNode("repo[1]"))
    
    addFiles: (specs, parent) -> 
      xmlFiles = ""
      specs.each (spec) ->
        xmlFiles += "<file path='" +
              apf.escapeXML(ide.davPrefix + spec) +
              "' name='" + apf.escapeXML(spec.split("/").pop()) + 
              "' type='jasmine' />"
      
      modelTestsJasmine.insert "<files>" + xmlFiles + "</files>", {insertPoint : parent}
      
    afterFileSave: ->
      ide.addEventListener 'afterfilesave', (event) =>
        name = @getFileNameFrom event.node
        @runJasmine [name]
        
    # bad bad hack, Cloud9 danke.
    getProjectName: -> document.title[0...document.title.indexOf('-') - 1]
      
    show: ->
      if (navbar.current?) && (navbar.current != this)
        navbar.current.disable()
      else
        return
      
      panels.initPanel(@)
      @enable()
      
    enable: ->
      @nodes.each (item) ->
        item.enable() if item.enable
        
    disable: ->
      @nodes.each (item) ->
        item.disable() if item.disable
        
    destroy: ->
      # stop
      
      @nodes.each (item) -> item.destroy true, true
      @nodes = []
      
      panels.unregister(@)
      
    getFileNameFrom: (node) ->
      fullFileName = node.getAttribute('name')
      name = fullFileName[0...fullFileName.indexOf('.')]
      
    run: (nodes) ->
      fileNames = []
      if nodes?
        nodes.each (node) =>
          name = @getFileNameFrom node
          fileNames.push name
      
      @runJasmine fileNames
     
    # fileNames is a simple array containing the file names
    # without fileNames all specs are executed
    runJasmine: (fileNames) ->
      # save the tested files for later use
      if fileNames?
      	@testFiles = fileNames 
      else
      	@testFiles = []
      	
      args = ['--coffee', 'spec/' ]
      # add the regex match on fileNames
      if fileNames? && fileNames.length > 0
        matchString = '('
        fileNames.each (name) -> matchString += name + '|'
        
        # replace last | with ) to complete the Regex
        matchString = matchString[0...-1] + ')' + "\\."
        args.push '--match', matchString
      
      @message = ''
      @registerSocketListener() unless @socketListenerRegistered
      noderunner.run(PATH_TO_JASMINE, args, false)    
      
    registerSocketListener: ->
      @message = '' # neuer Socket Listener, neue Message
      ide.addEventListener 'socketMessage', (event) =>
        if @panelInitialized()
          @assembleMessage(event.message.data) if event.message.type == 'node-data'
          @parseMessage() if event.message.type == 'node-exit'
      
      @socketListenerRegistered = true
        
    assembleMessage: (message) -> @message += message
    
    # check if the panel is initialized (somebody clicked on our panel,
    # if it is not we can not display test results etc.)
    panelInitialized: -> dataGridTestProjectJasmine?
    
    parseMessage: ->
      failureMessages = @message.match /Failures:\s([\s\S]*)\n+Finished/m
      if failureMessages?
        @handleFailures failureMessages
      else
        @allSpecsPass()
        
    handleFailures: (failureMessages) ->
      # separate failures are divided by an empty line
      failures = failureMessages[1].split "\n\n"
      failures.each (failure) => @parseFailure(failure)
      
    parseFailure: (failure) ->
      matches = failure.match /Message:\s([\s\S]+?)Stacktrace:[\s\S]*?(at[\s\S]*)/m
      message = matches[1]
      stacktrace = matches[2]
      errorLine = @parseStackTrace(stacktrace)
      
    parseStackTrace: (stacktrace) ->
      traces = stacktrace.split "\n"
      error = ''
      traces.each (trace) =>
        if (trace.indexOf('node_modules') == -1) && (trace.indexOf(@projectName) >= 0)
          error = trace.match(new RegExp(@projectName + '(.+)'))[1]
          error = error[0...-1] # remove the last character - \) didn't seem to work in the RegEx
          return error
          
      error
      
    
    allSpecsPass: ->
      @setNormal file for file in @findFileNodesFor()
      @setPass file for file in @findFileNodesFor(@testFiles)

    findFileNodesFor: (testFiles) ->
      model = dataGridTestProjectJasmine.$model
      files = []
      if testFiles?.length > 0
        files.push model.queryNode "//node()[@name='#{file}.spec.coffee']" for file in @testFiles
      else
        files = model.queryNode("repo[@name='#{@projectName}']").children
      files
		
    setPass : (node, msg) ->
      apf.xmldb.setAttribute node, "status", 1
      apf.xmldb.setAttribute node, "status-message", msg || ""

    setError: (node, msg) ->
      apf.xmldb.setAttribute node, "status", 0
      apf.xmldb.setAttribute node, "status-message", msg || ""
      
    setNormal: (node, msg) ->
      apf.xmldb.setAttribute node, "status", -1
      apf.xmldb.setAttribute node, "status-message", msg || ""

    jasmine: -> @runJasmine()
