package thx.tpl;

using StringTools;

import thx.tpl.Parser.TBlock;

class ScriptBuilder {
  private var context : String;

  public function new(context : String)
    this.context = context;

  public function build(blocks : Array<TBlock>) : String
    return blocks.map(blockToString).join("\n");

  public function blockToString(block : TBlock) : String
    return switch block {
      case literal(text):
        '$context.add(\'${text.replace("\'","\\'")}\');';
      case codeBlock(code):
        code;
      case printBlock(print):
        '$context.unsafeAdd($print);';
    };
}