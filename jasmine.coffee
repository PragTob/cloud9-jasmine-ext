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
  css = require 'text!ext/jasmine/jasmine.css'
  {ParsedMessage} = require 'ext/jasmine/lib/parsedMessage'

  DIVIDER_POSITION = 2300
  MENU_ENTRY_POSITION = 2400
  PANEL_POSITION = 10000
  PATH_TO_JASMINE = 'node_modules/jasmine-node/lib/jasmine-node/cli.js'
  
  TEST_PASS_STATUS = 1
  TEST_ERROR_STATUS = 0
  TEST_RESET_STATUS = -1
  TEST_ERROR_MESSAGE = 'FAILED: '
  TEST_RESET_MESSAGE = 'No Result'

  module.exports = ext.register 'ext/jasmine/jasmine',
    name: 'Jasmine'
    dev: 'Tobias Metzke, Tobias Pfeiffer'
    type: ext.GENERAL
    alone: yes
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
      
      dataGridTestProjectJasmine.addEventListener 'afterchoose', =>
      	selection = dataGridTestProjectJasmine.getSelection()
      	selection = null if @containsRepo selection
      	@run selection
      
      ide.dispatchEvent "init.jasmine"
      @setRepoName()
      @initFilelist()
      @addFileSaveListener()
    
    # if only a folder containing specs is double clicked,
    # the selection returns null, thus if the input here
    # is null, the selection contains / is a repo
    containsRepo: (array) -> 
      if array?
        array.some (node) -> node.tagName == 'repo'
      else
        true
      
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
        @addFiles(specs, modelTestsJasmine.queryNode("repo[1]")) if specs?
    
    addFiles: (specs, parent) -> 
      xmlFiles = ""
      specs.each (spec) ->
        xmlFiles += "<file path='" +
              apf.escapeXML(ide.davPrefix + spec) +
              "' name='" + apf.escapeXML(spec.split("/").pop()) + 
              "' type='jasmine' />"
      
      modelTestsJasmine.insert "<files>" + xmlFiles + "</files>", {insertPoint : parent}
      
    addFileSaveListener: ->
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
      @nodes.each (item) -> item.destroy true, true
      @nodes = []
      
      panels.unregister(@)
      
    getFileNameFrom: (node) ->
      fullFileName = node.getAttribute('name')
      name = fullFileName[0...fullFileName.indexOf('.')]
      
    run: (nodes) ->
      if @containsRepo nodes
        @runJasmine()
      else
        @runSelectedNodes nodes
     
    # fileNames is a simple array containing the file names
    # without fileNames all specs are executed
    runJasmine: (fileNames) ->
      args = ['--coffee', '--verbose', 'spec/' ]

      @testFiles = @filesToTest fileNames
      if fileNames? && fileNames.length > 0
        args.push '--match', @matchString(fileNames)
      
      @executeJasmineOnNodeRunner args
      
    filesToTest: (fileNames) ->
      if fileNames?
      	fileNames
      else
        fileNodes = @findFileNodesFor()
        testFiles = []
        testFiles.push @getFileNameFrom node for node in fileNodes
        testFiles  
      
    matchString: (fileNames) ->
      matchString = '('
      fileNames.each (name) -> matchString += name + '|'
      # replace last | with ) to complete the Regex
      matchString = matchString[0...-1] + ')' + "\\."
      
    executeJasmineOnNodeRunner: (args) ->
      @message = ''
      @registerSocketListener() unless @socketListenerRegistered
      noderunner.run(PATH_TO_JASMINE, args, false)
    
    runSelectedNodes: (nodes) ->
      fileNames = []
      nodes.each (node) =>
        name = @getFileNameFrom node
        fileNames.push name
      @runJasmine fileNames
      
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
      @resetTestStatus()
      parsedMessage = new ParsedMessage(@message, @projectName)
      console.log parsedMessage
      if parsedMessage.isSyntaxError
        @handleSyntaxError()
      else if parsedMessage.isAllGreen
        @allSpecsPass()
      else if parsedMessage.isFailure
        @handleFailures(parsedMessage)
      else
        console.log 'Unknown message'
        
        
    handleSyntaxError: ->
      console.log 'Syntax error during the execution of the tests'
      # TODO: display syntax error (maybe)
      
    allSpecsPass: -> @specsPass @testFiles
        
    handleFailures: (parsedMessage) ->
      parsedMessage.errors.each (error) => @specFails error
      @testsPassExcept parsedMessage.failedTests
      
    testsPassExcept: (failedTests) ->
      passedTests = []
      passedTests.push pass for pass in @testFiles when not failedTests.contains pass
      @specsPass passedTests
    
    
    specFails: (error) ->
       @setTestFailed failed, error for failed in @findFileNodesFor([error.fileName])
      
    setTestFailed: (failedNode, error) ->
      try
        apf.xmldb.setAttribute failedNode, "errorFilePath", ide.davPrefix + error.filePath
        apf.xmldb.setAttribute failedNode, "errorLine", error.line
        apf.xmldb.setAttribute failedNode, "errorColumn", error.column
        apf.createNodeFromXpath(failedNode, 'failed')
        dataGridTestProjectJasmine.reload()
      catch error
          console.log "Caught bad error '#{error}' and didn't enjoy it. Related to the damn helper specs."
      
      @setTestStatus failedNode, TEST_ERROR_STATUS, TEST_ERROR_MESSAGE + error.message
      
    setTestStatus : (node, status, msg) ->
      try
        apf.xmldb.setAttribute node, "status", status
        apf.xmldb.setAttribute node, "status-message", msg || ""
      catch error
          console.log "Caught bad error '#{error}' and didn't enjoy it. Related to the damn helper specs."
      
    specsPass: (fileList) ->
      for file in @findFileNodesFor(fileList)
        @setTestStatus file, TEST_PASS_STATUS
        apf.createNodeFromXpath(file, 'passed')
        dataGridTestProjectJasmine.reload()
    
    resetTestStatus: ->
      @setTestStatus file, TEST_RESET_STATUS, TEST_RESET_MESSAGE for file in @findFileNodesFor()
      
    # leaving input empty leads to return of
    # all file nodes of the project
    findFileNodesFor: (testFiles) ->
      model = dataGridTestProjectJasmine.$model
      files = []
      if testFiles?
        files.push model.queryNode "//node()[@name='#{file}.spec.coffee']" for file in testFiles
      else
        files = model.queryNode("repo[@name='#{@projectName}']").children
      files
		
    goToCoffee: (node) ->
      error =
        filePath:     node.getAttribute 'errorFilePath'
        line:    node.getAttribute 'errorLine'
        column:  node.getAttribute 'errorColumn'
      livecoffee = require 'ext/livecoffee/livecoffee'
      livecoffee.show(node, error.line, error.column)

    jasmine: -> @runJasmine()
