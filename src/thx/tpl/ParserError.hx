/**
 * @author Waneck
 * @author Franco Ponticelli
 */

package thx.tpl;

class ParserError extends thx.core.Error {
  public var msg(default, null):String;
  public var line(default, null):Int;
  public var excerpt(default, null):String;

  public function new(msg, line, ?excerpt) {
    super(null);
    this.msg = msg;
    this.line = line;
    this.excerpt = excerpt;
  }

  override public function toString() {
    var excerpt = this.excerpt;
    if (excerpt != null) {
      var nl = excerpt.indexOf("\n");
      if (nl != -1)
        excerpt = excerpt.substr(0, nl);
    }
    return msg + " @ " + line + (excerpt != null ? (" ( \"" + excerpt + "\" )") : "");
  }
}