# Parse the messages returned by the node.js server in order to figure 
# out the test results. Those are one of the following:
# - SyntaxError
# - failure (including file and location of the error)
# - success

class MessageParser

  isSyntaxError: (message) -> message.indexOf('SyntaxError:') != -1

define (require, exports, module) ->
  exports.MessageParser = MessageParser
