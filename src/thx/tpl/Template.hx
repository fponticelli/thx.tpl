package thx.tpl;

import hscript.Interp;
import thx.tpl.hscript.EnhancedInterp;
import Map;
using thx.core.Maps;

class Template {
  private var template : String;
  public var variables(default, null) : Map<String, Dynamic>;
  public var helpers : Map<String, Dynamic>;

  public function new(template : String) {
    this.template = template;
    this.helpers = new Map<String, Dynamic>();
  }

  public dynamic function escape(str : String) : String
    return str;

  public function addHelper(name : String, helper : Dynamic) : Void
    helpers.set(name, helper);

  public function execute(content : IMap<String, Dynamic>) : String {
    var buffer = new Output(escape);

    // Parse the template into TBlocks for the HTemplateParser
    var parsedBlocks = new Parser().parse(template);

    // Make a hscript with the buffer as context.
    var script = new ScriptBuilder('__b__').build(parsedBlocks);

    // Make hscript parse and interpret the script.
    var parser = new hscript.Parser();
    var program = parser.parseString(script);

    var interp = new EnhancedInterp();

    variables = interp.variables;

    var bufferStack = [];

    setInterpreterVars(interp, helpers);
    setInterpreterVars(interp, content);

    interp.variables.set('__b__', buffer); // Connect the buffer to the script
    interp.variables.set('__string_buf__', function(current) {
      bufferStack.push(current);
      return new StringBuf();
    });

    interp.variables.set('__restore_buf__', function() {
      return bufferStack.pop();
    });

    interp.execute(program);

    // The buffer now holds the output.
    return buffer.toString();
  }

  private function setInterpreterVars(interp : Interp, content : IMap<String, Dynamic>) : Void
    content.tuples().map(function(t) {
      interp.variables.set(t._0, t._1);
    });
}