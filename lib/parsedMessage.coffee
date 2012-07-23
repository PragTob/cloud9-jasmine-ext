# Parse the messages returned by the node.js server in order to figure 
# out the test results. Those are one of the following:
# - SyntaxError
# - failure (including file and location of the error)
# - success

class ParsedMessage

  constructor: (message, projectName) ->
    @projectName = projectName
    @isSyntaxError = false
    @isAllGreen = false
    @isFailure = false
    @parse(message)
    
  parse: (message) ->
    if @containsSyntaxError(message)
      @isSyntaxError = true 
    else
      @parseTestResults(message)
      
  containsSyntaxError: (message) -> message.indexOf('SyntaxError:') != -1
  
  parseTestResults: (message) ->
    jasmineFailures = @parseFailures(message)
    if jasmineFailures?
      @isFailure = true
      verboseSpecs = jasmineFailures[1]
      failureStacktraces = jasmineFailures[2]
      @extractFailureInformation verboseSpecs, failureStacktraces
    else
      @isAllGreen = true
      
    
  parseFailures: (message) ->
    # Ulra regex - the point after \n is necessary as there is a totally weird sign
    message.match /(.+\n.\[3[12]m[\s\S]*)Failures:\s([\s\S]*)\n+Finished/m
    
  extractFailureInformation: (verboseSpecs, failureStacktraces) ->
    @errors = []
    @failedTests = []
    failures = failureStacktraces.split "\n\n"
    failures.each (failure) => 
      error = @parseFailure(failure)
      @errors.push error
      @failedTests.push error.fileName
      
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
    errorLine = trace.match(new RegExp(@projectName + '(.+)'))[1]
    errorLine[0...-1] # remove the last character - \) didn't seem to work in the RegEx
    
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
    
  

define (require, exports, module) ->
  exports.ParsedMessage = ParsedMessage
