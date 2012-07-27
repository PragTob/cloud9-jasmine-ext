# Parse the messages returned by the node.js server in order to figure 
# out the test results. Those are one of the following:
# - SyntaxError
# - failure (including file and location of the error)
# - success

class ParsedMessage

  IT_BLOCK_START = '[3'
  PASSED_IT_BLOCK = '2'
  IT_TYPE = 'it'
  DESCRIBE_TYPE = 'describe'

  constructor: (message, projectName) ->
    @projectName = projectName
    @isSyntaxError = false
    @isSpecs = false
    @errorIndex = 0 # index in the errors for now, afterwards we pop or something
    @parse(message)
    
  parse: (message) ->
    if @containsSyntaxError(message)
      @isSyntaxError = true 
    else
      @parseTestResults(message)
      
  containsSyntaxError: (message) -> message.indexOf('SyntaxError:') != -1
  
  parseTestResults: (message) ->
    @failedTests = []
    @isSpecs = true
    failureStacktraces = @extractStackTrace message
    # this choice avoids more complex regex and parsing problems
    # TODO dynamically create regex?!
    if failureStacktraces?
      verboseSpecs = @extractVerboseSpecsFailed message
    else
      verboseSpecs = @extractVerboseSpecsPassed message
    @extractFailureInformation verboseSpecs, failureStacktraces
    
  extractVerboseSpecsFailed: (message) ->
    message.match(/([\s\S]*)Failures:\s/m)[1]
    
  extractVerboseSpecsPassed: (message) ->
    message.match(/([\s\S]*)Finished in\s/m)[1]
    
  extractStackTrace: (message) ->
    stacktrace = message.match(/Failures:\s([\s\S]*)\n+Finished in/m)
    if stacktrace?
      return stacktrace[1]
    else
      return null
    
  parseFailures: (message) ->
    # Ulra regex - the point after \n (at the beginning) is necessary as there is a totally weird sign
    message.match /(.+\n.\[3[12]m[\s\S]*)Failures:\s([\s\S]*)\n+Finished/m
      
  extractFailureInformation: (verboseSpecs, failureStacktraces) ->
    @extractErrorInformation failureStacktraces if failureStacktraces?
    @specs = []
    lines = verboseSpecs.split "\n"
    @parseSpecLine line for line in lines
    @sanitizeSpecs()
    
  parseSpecLine: (line) ->
    if match = line.match /^(\w+)/
      specName = match[1]
      spec =
        specName: specName
        children: []
        passed: true
      @specs.push spec
    else
      if @isItBlock line
        @addItBlock line, @currentSpec()
      else
        @addDescribeBlock line, @currentSpec()
        
  currentSpec: -> @specs[@specs.length - 1]
        
  isItBlock: (line) -> line.match /\[3\dm\s/
  
  addItBlock: (line, spec) ->
    message = line.match(/\[3[12]m\s*([\s\S]+).\[0m/)[1]
    
    if @isPassedSpec line
      passed = true
      error = null
    else
      passed = false
      spec.passed = false
      @failedTests.push spec.specName
      error = @findCorrespondingError(message)
    
    itBlock =
      message: message
      passed: passed
      type: IT_TYPE
      error: error
    spec.children.push itBlock
    
  findCorrespondingError: (message) ->
    console.log @errors 
    match = @errors[@errorIndex]
    @errorIndex++
    match
    
  addDescribeBlock: (line, spec) ->
    console.log 'Ignoring describes for now'
    null
     
  isPassedSpec: (line) ->
    line.indexOf(IT_BLOCK_START + PASSED_IT_BLOCK) != -1
      
  extractBlockInformation: (verboseSpecs) ->
    console.log 'ignoring blocks for now'
    null
    
  # convention: the first name in the first describe block is the name of the 
  # corresponding spec file (without the .spec.coffee)
  # there is no other way we can get that as of now. When errors happen in a 
  # helper file then the original spec file oft is not even in the stacktrace
  # anymore...
  extractSpecName: (verboseSpecs) -> specName = verboseSpecs.match(/(\S+)\s/)[1]
    
    
  extractErrorInformation: (failureStacktraces) ->
    @errors = []
    failures = failureStacktraces.split "\n\n"
    failures.each (failure) => 
      error = @parseFailure(failure)
      @errors.push error
      
  parseFailure: (failure) ->
    matches = failure.match /Message:\s([\s\S]+?)Stacktrace:[\s\S]*?(at[\s\S]*)/m
    message = matches[1]
    stacktrace = matches[2]
    error = @parseStackTrace(stacktrace)
    error.message = @sanitizeErrorMessage message
    error
    
  parseStackTrace: (stacktrace) ->
    traces = stacktrace.split "\n"
    error = null
    traces.each (trace) =>
      # we don't want failures from our node_modules and only from our project
      if (trace.indexOf('node_modules') == -1) && 
         (trace.indexOf(@projectName) >= 0) &&
         !error # don't go through this loop too many times
        errorLine = @parseTrace trace
        error = @parseError errorLine
        
    error
    
  parseTrace: (trace) ->
    errorLine = trace.match(new RegExp(@projectName + '(.+).'))[1]
    
  parseError: (errorLine) ->
    errorParts = errorLine.split ':'
    error =
      filePath: errorParts[0]
      fileName: @fileNameFromPath errorParts[0]
      line: errorParts[1]
      column: errorParts[2]
    error
      
  fileNameFromPath: (filePath) ->
    filePath[filePath.lastIndexOf('/') + 1...filePath.indexOf('.')]
    
  # just the error message without all the extras
  sanitizeErrorMessage: (message) ->
    matches = message.match /\[31m(.+)\[\d+m/
    matches[1]
  
  # specs without children are not worthy (probably console.log's.. hard to
  # distinguish unfortunately)
  sanitizeSpecs: ->
    cleanSpecs = []
    @specs.each (spec) -> 
      cleanSpecs.push spec if spec.children.length > 0
    @specs = cleanSpecs

define (require, exports, module) ->
  exports.ParsedMessage = ParsedMessage
