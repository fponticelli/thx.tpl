package thx.tpl;

import thx.tpl.ParserError;

class Parser {
  static inline var BRACKET_PRINT_OPEN = '{';
  static inline var BRACKET_PRINT_CLOSE = '}';
  static inline var BRACKET_CODE_OPEN = '(';
  static inline var BRACKET_CODE_CLOSE = ')';

  static var bracketMismatch = "Bracket mismatch! Inside template, non-paired brackets, '{' or '}', should be replaced by ${'{'} and ${'}'}.";

  var condMatch : EReg;
  var inConditionalMatch : EReg;
  var variableChar : EReg;

  // State variables for the parser
  var context : ParseContext;
  var bracketStack : Array<ParseContext>;
  var conditionalStack : Int;

  var pos : Int;

  var fileName : String;

  // Constructor must be put at end of class to prevent intellisense problems with regexps
  public function new() {
    // Some are quite simple, could be made with string functions instead for speed
#if macro
    condMatch = ~/^\$(if|for|while)[^A-Za-z0-9]/;
    inConditionalMatch = ~/^(}[ \t\r\n]*else if[^A-Za-z0-9]|}[ \t\r\n]*else[ \t\r\n]*{)/;
    variableChar = ~/^[_A-Za-z0-9\.]$/;
#else
    condMatch = ~/^\$(?:if|for|while)\b/;
    inConditionalMatch = ~/^(?:\}[\s\r\n]*else if\b|\}[\s\r\n]*else[\s\r\n]*\{)/;
    variableChar = ~/^[_\w\.]$/;
#end
  }

  function parseScriptPart(template : String, startBrace : String, endBrace : String) : String {
    var insideSingleQuote = false,
        insideDoubleQuote = false,
        // If startbrace is empty, assume we are in the script already.
        stack = (startBrace == '') ? 1 : 0,
        i = -1;

    while(++i < template.length) {
      var char = template.charAt(i);

      if(!insideDoubleQuote && !insideSingleQuote) {
        if (char == startBrace) {
          ++stack;
        } else if (char == endBrace) {
          --stack;

          if(stack == 0)
            return template.substr(0, i+1);
          if (stack < 0)
            error('Unbalanced braces for block: ', template.substr(0, 100));
        } else if (char == '"') {
          insideDoubleQuote = true;
        } else if (char == "'") {
          insideSingleQuote = true;
        }
      } else if(insideDoubleQuote && char == '"' && template.charAt(i-1) != '\\') {
        insideDoubleQuote = false;
      } else if(insideSingleQuote && char == "'" && template.charAt(i-1) != '\\') {
        insideSingleQuote = false;
      }
    }

    return error('Failed to find a closing delimiter for the script block', template.substr(0, 100));
  }

  inline function error(message : String, ?excerpt : String) {
    var p = getPos();
    return throw new ParserError(message, excerpt, p);
  }

  function getPos() : haxe.PosInfos {
    return {
      methodName : null,
      lineNumber : pos, // TODO
      fileName : fileName,
      customParams : [],
      className : null
    };
  }

  function parseContext(template : String) : ParseContext {
    // If a single $ is found, go into code context.
    if (peek(template) == '$' && peek(template, 1) != '$')
      return ParseContext.code;

    // Same if we're inside a conditional and a } is found.
    if (conditionalStack > 0 && peek(template) == '}')
      switch(bracketStack[bracketStack.length - 1]) {
        case code: return ParseContext.code;
        default:
      }

    // Otherwise parse pure text.
    return ParseContext.literal;
  }

  function accept(template : String, acceptor : String -> Bool, throwAtEnd : Bool)
    return parseString(template, function(chr : String) {
        return acceptor(chr) ? ParseResult.keepGoing : ParseResult.doneSkipCurrent;
      }, throwAtEnd);

  function isIdentifier(char : String, first = true)
    return first
      ? (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') || char == '_'
      : (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') || (char >= '0' && char <= '9') || char == '_';

  function acceptIdentifier(template : String) {
    var first = true;
    return accept(template, function(chr : String) {
        var status = isIdentifier(chr, first);
        first = false;
        return status;
      }, false);
  }

  function acceptBracket(template : String, bracket : String)
    return parseScriptPart(template, bracket, bracket == '(' ? ')' : ']');

  /**
   * Main block parse method, called from parse().
   */
  function parseBlock(template : String) : Block
    return (context == ParseContext.code) ? parseCodeBlock(template) : parseLiteral(template);

  function parseConditional(template : String) : Block {
    var str = parseScriptPart(template, '', '{');
    return { block: TBlock.codeBlock(str.substr(1)), length: str.length, start:this.pos };
  }

  function peek(template : String, offset = 0)
    return template.length > offset ? template.charAt(offset) : null;

  function parseVariable(template : String) : Block {
    var output = "",
        char : String = null,
        part : String = null;

    // Remove $
    template = template.substr(1);

    do {
      // Parse identifier
      part = acceptIdentifier(template);
      template = template.substr(part.length);

      output += part;
      char = peek(template);

      // Look for brackets
      while (char == '(' || char == '[') {
        part = acceptBracket(template, char);
        template = template.substr(part.length);

        output += part;
        char = peek(template);
      }

      // Look for . and if the char after that is an identifier
      if (char == '.' && isIdentifier(peek(template, 1))) {
        template = template.substr(1);

        output += '.';
      } else {
        break;
      }
    } while (char != null);

    return { block: TBlock.printBlock(output), length: output.length + 1, start:this.pos };
  }

  function parseVariableChar(char : String) : ParseResult
    return (variableChar.match(char)#if macro && variableChar.matchedPos().pos == 0 #end) ? ParseResult.keepGoing : ParseResult.doneSkipCurrent;

  function parseCodeBlock(template : String) : Block {
    // Test if at end of a conditional
    if (bracketStack.length > 0 && peek(template) == '}') {
      // It may not be an end, just a continuation (else if, else)
      if (inConditionalMatch.match(template) #if macro && inConditionalMatch.matchedPos().pos == 0 #end) {
        var str = parseScriptPart(template, '', '{');
        return { block: TBlock.codeBlock(str), length: str.length, start:this.pos };
      }

      if (switch (bracketStack.pop()) {
        case code: --conditionalStack < 0;
        default: true;
      })
        error(bracketMismatch);

      return { block: TBlock.codeBlock('}'), length: 1, start:this.pos };
    }

    // Test for conditional code block
    if (condMatch.match(template) #if macro && condMatch.matchedPos().pos == 0 #end) {
      bracketStack.push(code);
      ++conditionalStack;

      return parseConditional(template);
    }

    // Test for variable like $name
    if (peek(template) == '$' && isIdentifier(peek(template, 1)))
      return parseVariable(template);

    // Test for code or print block ${ or $(
    var startBrace = peek(template, 1),
        endBrace = (startBrace == BRACKET_CODE_OPEN) ? BRACKET_CODE_CLOSE : BRACKET_PRINT_CLOSE,
        str = parseScriptPart(template.substr(1), startBrace, endBrace),
        noBraces = StringTools.trim(str.substr(1, str.length - 2));

    if(startBrace == BRACKET_CODE_OPEN)
      return { block: TBlock.codeBlock(noBraces), length: str.length + 1, start:this.pos };
    else // (
      return { block: TBlock.printBlock(noBraces), length: str.length + 1, start:this.pos };
  }

  function parseString(str : String, modifier : String -> ParseResult, throwAtEnd : Bool) : String {
    var insideSingleQuote = false,
        insideDoubleQuote = false,
        i = -1;

    while(++i < str.length) {
      var char = str.charAt(i);

      if(!insideDoubleQuote && !insideSingleQuote) {
        switch(modifier(char)) {
          case ParseResult.doneIncludeCurrent:
            return str.substr(0, i + 1);

          case ParseResult.doneSkipCurrent:
            return str.substr(0, i);

          case ParseResult.keepGoing:
            // Just do as he says!
        }

        if (char == '"')
          insideDoubleQuote = true;
        else if (char == "'")
          insideSingleQuote = true;
      } else if(insideDoubleQuote && char == '"' && str.charAt(i-1) != '\\') {
        insideDoubleQuote = false;
      } else if(insideSingleQuote && char == "'" && str.charAt(i-1) != '\\') {
        insideSingleQuote = false;
      }
    }

    if(throwAtEnd)
      error('Failed to find a closing delimiter', str.substr(0, 100));

    return str;
  }

  function parseLiteral(template : String) : Block {
    var len = template.length,
        i = -1;

    while (++i < len) {
      var char = template.charAt(i);
      switch(char) {
        case '$':
          // Test for escaped $
          if (len > i + 1 && template.charAt(i + 1) != '$') {
            return {
              block: TBlock.literal(escapeLiteral(template.substr(0, i))),
              length: i,
              start: this.pos
            };
          }
          i++;
        case '}':
          if (bracketStack.length > 0) {
            switch (bracketStack[bracketStack.length - 1]) {
              case code:
                return {
                  block: TBlock.literal(escapeLiteral(template.substr(0, i))),
                  length: i,
                  start:this.pos
                };
              case literal:
                bracketStack.pop();
            }
          } else {
             error(bracketMismatch);
          }
        case '{':
          bracketStack.push(literal);
      }
    }

    return {
      block: TBlock.literal(escapeLiteral(template)),
      length: len,
      start: this.pos
    };
  }

  function escapeLiteral(input : String) : String
    return StringTools.replace(input, '$'+'$', '$');

  /**
   * Takes a template string as input and returns an AST made of TBlock instances.
   */
  public function parse(template : String, ?fileName : String) : Array<TBlock> {
    this.fileName = null == fileName ? 'untitled' : fileName;
    this.pos = 0;

    var output = new Array<TBlock>();
    bracketStack = [];
    conditionalStack = 0;

    while (template != '') {
      context = parseContext(template);
      var block = parseBlock(template);

      if(block.block != null)
        output.push(block.block);

      template = template.substr(block.length);
      this.pos += block.length;
    }

    if (bracketStack.length != 0) error(bracketMismatch);

    return output;
  }

  public function parseWithPosition(template:String) : Array<Block> {
    this.pos = 0;

    var output = new Array<Block>();
    bracketStack = [];
    conditionalStack = 0;

    while (template != '') {
      context = parseContext(template);
      var block = parseBlock(template);

      if(block.block != null)
        output.push(block);

      template = template.substr(block.length);
      this.pos += block.length;
    }

    if (bracketStack.length != 0) error(bracketMismatch);

    return output;
  }
}

enum TBlock {
  // Pure text
  literal(s : String);
  // Code
  codeBlock(s : String);
  // Code that should be printed immediately
  printBlock(s : String);
}

private typedef Block = {
  var block : TBlock;
  var start : Int;
  var length : Int;
}

private enum ParseContext {
  literal;
  code;
}

private enum ParseResult {
  keepGoing;
  doneIncludeCurrent;
  doneSkipCurrent;
}